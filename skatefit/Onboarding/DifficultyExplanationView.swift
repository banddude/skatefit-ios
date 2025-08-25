import SwiftUI

struct DifficultyExplanationView: View {
    private let cardData: [OnboardingCardData] = [
        OnboardingCardData(icon: nil, title: "Beginner", description: "Perfect for getting started. Lower repetitions and lighter weights to build foundation and form.", color: .mint, gesture: nil),
        OnboardingCardData(icon: nil, title: "Intermediate", description: "Step up your game. Moderate repetitions and medium weights to build strength and endurance.", color: .blue, gesture: nil),
        OnboardingCardData(icon: nil, title: "Advanced", description: "Challenge yourself. Higher repetitions and heavy weights for maximum gains and performance.", color: .purple, gesture: nil)
    ]

    var body: some View {
        OnboardingTemplateView(
            icon: "figure.strengthtraining.traditional",
            title: "Difficulty Levels",
            description: "Each workout has three difficulty options. Choose any level when you start a workout session.",
            cardData: cardData,
            proTip: "Select your preferred difficulty each time you start a workout"
        )
    }
}

#Preview {
    DifficultyExplanationView()
}