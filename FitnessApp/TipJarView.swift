import SwiftUI
import StoreKit

struct TipJarView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var manager = TipJarManager.shared
    @State private var showManageSubscriptions = false

    private static let cachedAppIcon = AppConfig.getAppIcon()
    private static let privacyPolicyURL = URL(string: "https://banddude.github.io/skate-fit-files/PRIVACY_POLICY")!
    private static let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    var body: some View {
        ZStack {
            NeonGridFloor()

            ScrollView {
                VStack(spacing: Neon.Space.xl) {
                    header
                    tipCards
                }
                .padding(.horizontal, Neon.Space.xl)
                .padding(.top, 50)
                .padding(.bottom, 40)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(Neon.font(14, .bold))
                    .foregroundColor(Neon.textMid)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Neon.panel))
                    .overlay(Circle().stroke(Neon.textLow.opacity(0.4), lineWidth: 1))
            }
            .padding(.trailing, Neon.Space.lg)
            .padding(.top, Neon.Space.lg)
        }
        .overlay {
            if manager.showThankYou {
                thankYouOverlay
            }
        }
        .task {
            if manager.oneTimeProducts.isEmpty {
                await manager.loadProducts()
            } else {
                await manager.updateSubscriptionStatus()
            }
        }
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
    }

    private var header: some View {
        VStack(spacing: Neon.Space.md) {
            if let appIcon = Self.cachedAppIcon {
                Image(uiImage: appIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                LinearGradient(colors: [Neon.magenta.opacity(0.7), Neon.cyan.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: Neon.Stroke.medium
                            )
                    )
                    .neonGlow(Neon.magenta, radius: Neon.Glow.hero, opacity: 0.6)
            }

            Text("SUPPORT \(AppConfig.appName.uppercased())")
                .font(Neon.font(22, .heavy))
                .foregroundColor(.white)
                .tracking(2)

            Text("If \(AppConfig.appName) helps you skate better, buy me a drink.")
                .font(Neon.font(13, .medium))
                .foregroundColor(Neon.textMid)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Neon.Space.md)
        }
    }

    private var tipCards: some View {
        VStack(spacing: Neon.Space.lg) {
            ForEach(TipJarManager.TipTier.allCases, id: \.self) { tier in
                tipCard(for: tier)
            }

            if let error = manager.errorMessage {
                Text(error)
                    .font(Neon.font(11, .medium))
                    .foregroundColor(Neon.magenta)
                    .padding(.top, Neon.Space.sm)
            }

            Text("Tips are optional and don't unlock any features.\n\(AppConfig.appName) is free, forever.")
                .font(Neon.font(10, .medium))
                .foregroundColor(Neon.textLow)
                .multilineTextAlignment(.center)
                .tracking(0.5)
                .padding(.top, Neon.Space.sm)

            Text("Monthly tips are auto-renewing subscriptions billed to your Apple Account. They renew each month until cancelled in Settings, at least 24 hours before the end of the current period. Cancel anytime.")
                .font(Neon.font(9, .medium))
                .foregroundColor(Neon.textLow)
                .multilineTextAlignment(.center)
                .padding(.top, 2)

            HStack(spacing: Neon.Space.lg) {
                Link("Privacy Policy", destination: Self.privacyPolicyURL)
                Link("Terms of Use", destination: Self.termsOfUseURL)
                if manager.activeMonthlyTier != nil {
                    Button("Manage Subscription") { showManageSubscriptions = true }
                }
            }
            .font(Neon.font(10, .semibold))
            .foregroundColor(Neon.cyan)
            .padding(.top, 2)
        }
    }

    private func tipCard(for tier: TipJarManager.TipTier) -> some View {
        let accent = tier.accent
        let oneTimeProduct = manager.oneTimeProducts[tier]
        let monthlyProduct = manager.monthlyProducts[tier]
        let isActiveMonthly = manager.activeMonthlyTier == tier

        return VStack(spacing: 0) {
            HStack(spacing: Neon.Space.sm) {
                Text(tier.emoji)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 2) {
                    Text(tier.displayName.uppercased())
                        .font(Neon.font(16, .heavy))
                        .foregroundColor(.white)
                        .tracking(1)

                    Text(oneTimeProduct?.displayPrice ?? tier.fallbackPrice)
                        .font(Neon.font(13, .bold))
                        .foregroundColor(accent)
                }

                Spacer()

                if isActiveMonthly {
                    Text("MONTHLY ✓")
                        .font(Neon.font(10, .heavy))
                        .tracking(1)
                        .foregroundColor(accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .overlay(Capsule().stroke(accent.opacity(0.6), lineWidth: 1))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            HStack(spacing: Neon.Space.sm) {
                Button(action: {
                    if let product = oneTimeProduct {
                        Task { await manager.purchase(product) }
                    }
                }) {
                    Text("TIP \(oneTimeProduct?.displayPrice ?? tier.fallbackPrice)")
                        .font(Neon.font(12, .bold))
                        .tracking(1.5)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TipButtonStyle(color: accent, enabled: oneTimeProduct != nil))
                .disabled(oneTimeProduct == nil)

                Button(action: {
                    if isActiveMonthly {
                        showManageSubscriptions = true
                    } else if let monthly = monthlyProduct {
                        Task { await manager.purchase(monthly) }
                    }
                }) {
                    Text(isActiveMonthly ? "MANAGE" : "\(monthlyProduct?.displayPrice ?? tier.fallbackPrice)/MO")
                        .font(Neon.font(12, .bold))
                        .tracking(1.5)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TipButtonStyle(color: accent, enabled: monthlyProduct != nil || isActiveMonthly))
                .disabled(monthlyProduct == nil && !isActiveMonthly)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: Neon.Radius.medium, style: .continuous)
                .fill(Neon.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Neon.Radius.medium, style: .continuous)
                .stroke(accent.opacity(0.5), lineWidth: Neon.Stroke.thin)
        )
        .neonGlow(accent, radius: Neon.Glow.card, opacity: 0.35)
    }

    private var thankYouOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { manager.dismissThankYou() }

            VStack(spacing: Neon.Space.lg) {
                Text(manager.purchasedTier?.emoji ?? "🎉")
                    .font(.system(size: 56))

                Text("THANKS, SKATER!")
                    .font(Neon.font(22, .heavy))
                    .foregroundColor(.white)
                    .tracking(2)
                    .neonGlow(Neon.magenta, radius: Neon.Glow.hero, opacity: 0.7)

                if let tier = manager.purchasedTier {
                    Text("Your \(tier.displayName.lowercased()) keeps the wheels turning.")
                        .font(Neon.font(13, .medium))
                        .foregroundColor(Neon.textMid)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Button(action: { manager.dismissThankYou() }) {
                    Text("RAD")
                        .tracking(2)
                }
                .buttonStyle(NeonButtonStyle(color: Neon.magenta))
                .padding(.top, Neon.Space.sm)
            }
            .padding(Neon.Space.xxl)
            .background(
                RoundedRectangle(cornerRadius: Neon.Radius.large, style: .continuous)
                    .fill(Neon.bgDeep)
                    .overlay(
                        RoundedRectangle(cornerRadius: Neon.Radius.large, style: .continuous)
                            .stroke(Neon.magenta.opacity(0.5), lineWidth: Neon.Stroke.medium)
                    )
            )
            .neonGlow(Neon.magenta, radius: Neon.Glow.hero, opacity: 0.5)
            .padding(.horizontal, 40)
        }
    }
}

private struct TipButtonStyle: ButtonStyle {
    let color: Color
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(enabled ? .white : Neon.textLow)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(enabled
                        ? (configuration.isPressed ? color.opacity(0.3) : color.opacity(0.15))
                        : Neon.panel
                    )
            )
            .overlay(Capsule().stroke(enabled ? color.opacity(0.6) : Neon.textLow.opacity(0.3), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(Neon.Anim.press, value: configuration.isPressed)
    }
}

#Preview {
    TipJarView()
}
