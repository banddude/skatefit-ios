import SwiftUI

struct VideoTutorialView: View {
    private let cardData: [OnboardingCardData] = [
        OnboardingCardData(icon: "hand.draw", title: "Swipe Between Exercises (← →)", description: "Swipe left or right to move through your workout exercises", color: .blue, gesture: nil),
        OnboardingCardData(icon: "hand.tap.fill", title: "Long Press for Details (HOLD)", description: "Long press on the video to see detailed exercise instructions", color: .purple, gesture: nil),
        OnboardingCardData(icon: "arrow.down.circle.fill", title: "Swipe Down to Exit (↓)", description: "Swipe down to leave your workout and return to the main screen", color: .orange, gesture: nil)
    ]

    var body: some View {
        OnboardingTemplateView(
            icon: "play.rectangle.fill",
            title: "Using Your Workouts",
            description: "Simple gestures to navigate through your training sessions.",
            cardData: cardData,
            proTip: "Watch the entire exercise once before starting to understand the movement pattern."
        )
    }
}

#Preview {
    VideoTutorialView()
}