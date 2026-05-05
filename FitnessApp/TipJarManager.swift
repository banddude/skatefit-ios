import Foundation
import StoreKit
import SwiftUI

@MainActor
@Observable
final class TipJarManager {
    static let shared = TipJarManager()

    enum TipTier: String, CaseIterable {
        case spareChange = "com.mikeshaffer.skatefit.tip_sparechange"
        case redBull = "com.mikeshaffer.skatefit.tip_redbull"
        case icedOatLatte = "com.mikeshaffer.skatefit.tip_oatlatte"

        var displayName: String {
            switch self {
            case .spareChange: return "Spare Change"
            case .redBull: return "Red Bull"
            case .icedOatLatte: return "Iced Oat Latte"
            }
        }

        var emoji: String {
            switch self {
            case .spareChange: return "💸"
            case .redBull: return "⚡️"
            case .icedOatLatte: return "☕️"
            }
        }

        var accent: SwiftUI.Color {
            switch self {
            case .spareChange: return Neon.magenta
            case .redBull: return Neon.lime
            case .icedOatLatte: return Neon.amber
            }
        }

        var fallbackPrice: String {
            switch self {
            case .spareChange: return "$0.99"
            case .redBull: return "$2.99"
            case .icedOatLatte: return "$5.99"
            }
        }
    }

    private(set) var oneTimeProducts: [TipTier: Product] = [:]
    private(set) var subscriptionProducts: [TipTier: Product] = [:]
    private(set) var isLoading = false
    private(set) var purchasedTier: TipTier?
    private(set) var showThankYou = false
    var errorMessage: String?

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
    }

    nonisolated deinit {
        Task { @MainActor [weak self] in
            self?.transactionListener?.cancel()
        }
    }

    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let oneTimeIDs = TipTier.allCases.map { $0.rawValue }
            let subIDs = TipTier.allCases.map { $0.rawValue + "_monthly" }

            let allIDs = oneTimeIDs + subIDs
            let products = try await Product.products(for: allIDs)

            for product in products {
                if product.type == .consumable {
                    if let tier = TipTier(rawValue: product.id) {
                        oneTimeProducts[tier] = product
                    }
                } else if product.type == .autoRenewable {
                    let baseID = product.id.replacingOccurrences(of: "_monthly", with: "")
                    if let tier = TipTier(rawValue: baseID) {
                        subscriptionProducts[tier] = product
                    }
                }
            }
        } catch {
            errorMessage = "Could not load tips. Try again later."
        }

        isLoading = false
    }

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                purchasedTier = tierForProduct(product)
                showThankYou = true
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = "Purchase failed. Try again."
        }
    }

    func dismissThankYou() {
        showThankYou = false
        purchasedTier = nil
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                do {
                    let transaction = try self.checkVerifiedAsync(result)
                    await transaction.finish()
                    await MainActor.run {
                        self.showThankYou = true
                    }
                } catch {
                    // Ignore invalid transactions
                }
            }
        }
    }

    private func checkVerified(_ result: Product.PurchaseResult) throws -> StoreKit.Transaction {
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                return transaction
            case .unverified:
                throw StoreError.verificationFailed
            }
        default:
            throw StoreError.verificationFailed
        }
    }

    private func checkVerified(_ result: VerificationResult<StoreKit.Transaction>) throws -> StoreKit.Transaction {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified:
            throw StoreError.verificationFailed
        }
    }

    nonisolated private func checkVerifiedAsync(_ result: VerificationResult<StoreKit.Transaction>) throws -> StoreKit.Transaction {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified:
            throw StoreError.verificationFailed
        }
    }

    private func tierForProduct(_ product: Product) -> TipTier? {
        let baseID = product.id.replacingOccurrences(of: "_monthly", with: "")
        return TipTier(rawValue: baseID)
    }

    private enum StoreError: Error {
        case verificationFailed
    }
}
