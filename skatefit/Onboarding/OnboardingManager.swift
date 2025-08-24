import Foundation

class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    
    private let onboardingCompletedKey = "OnboardingCompleted"
    
    private init() {}
    
    var isOnboardingCompleted: Bool {
        get {
            UserDefaults.standard.bool(forKey: onboardingCompletedKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: onboardingCompletedKey)
        }
    }
    
    func completeOnboarding() {
        isOnboardingCompleted = true
    }
    
    func resetOnboarding() {
        isOnboardingCompleted = false
    }
}