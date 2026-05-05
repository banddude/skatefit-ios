import Foundation
import HealthKit
import UIKit

@MainActor
@Observable
final class HealthKitManager {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()

    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.characteristicType(forIdentifier: .biologicalSex)!,
        HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!
    ]

    private let shareTypes: Set<HKSampleType> = [
        HKObjectType.workoutType(),
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
    ]

    private(set) var isAuthorized = false
    private(set) var isAvailable: Bool

    private init() {
        isAvailable = HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }

        do {
            try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
            isAuthorized = true
            return true
        } catch {
            isAuthorized = false
            return false
        }
    }

    func checkAuthorizationStatus() {
        guard isAvailable else {
            isAuthorized = false
            return
        }
        let status = store.authorizationStatus(for: HKObjectType.workoutType())
        isAuthorized = (status == .sharingAuthorized)
    }

    func saveWorkout(
        name: String,
        difficulty: WorkoutDifficulty,
        exerciseCount: Int,
        startDate: Date,
        endDate: Date
    ) async {
        guard isAuthorized else { return }

        let duration = endDate.timeIntervalSince(startDate)
        let minutes = duration / 60.0

        // MET-based calorie estimate: skate fitness ~4-8 METs
        let met: Double
        switch difficulty {
        case .beginner: met = 4.0
        case .intermediate: met = 6.0
        case .advanced: met = 8.0
        }
        // Average adult ~70kg fallback
        let calories = met * 70.0 * minutes / 60.0

        let energyUnit = HKUnit.kilocalorie()
        let energyQuantity = HKQuantity(unit: energyUnit, doubleValue: calories)

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .functionalStrengthTraining
        configuration.locationType = .indoor

        let builder = HKWorkoutBuilder(
            healthStore: store,
            configuration: configuration,
            device: nil
        )

        do {
            try await builder.beginCollection(at: startDate)

            let energySample = HKQuantitySample(
                type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
                quantity: energyQuantity,
                start: startDate,
                end: endDate,
                metadata: [
                    "WorkoutName": name,
                    "Difficulty": difficulty.displayName,
                    "Exercises": String(exerciseCount)
                ]
            )

            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
                builder.add([energySample]) { success, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: success)
                    }
                }
            }

            try await builder.endCollection(at: endDate)
            try await builder.finishWorkout()
            print("HealthKit: saved workout '\(name)' (\(Int(minutes))min, \(Int(calories))cal)")
        } catch {
            print("HealthKit: failed to save workout: \(error)")
        }
    }

    func openHealthApp() {
        if let url = URL(string: "x-apple-health://") {
            UIApplication.shared.open(url)
        }
    }
}
