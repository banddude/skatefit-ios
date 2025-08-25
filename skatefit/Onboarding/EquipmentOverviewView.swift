import SwiftUI

struct EquipmentOverviewView: View {
    private let cardData: [OnboardingCardData] = [
        OnboardingCardData(icon: "circle.dashed", title: "Resistance Bands", description: "Light, medium, and heavy resistance", color: .mint, gesture: nil),
        OnboardingCardData(icon: "dumbbell.fill", title: "Dumbbells", description: "5-20 lbs adjustable weights", color: .blue, gesture: nil),
        OnboardingCardData(icon: "circle.fill", title: "Medicine Ball", description: "6-12 lbs for core work", color: .purple, gesture: nil),
        OnboardingCardData(icon: "square.stack.3d.up", title: "Step/Box", description: "For step-ups and balance", color: .orange, gesture: nil)
    ]

    var body: some View {
        OnboardingTemplateView(
            icon: "dumbbell.fill",
            title: "What You'll Need",
            description: "Simple equipment you probably already have or can easily get.",
            cardData: cardData,
            proTip: "Missing equipment? No worries! Every exercise has alternatives."
        )
    }
}

#Preview {
    EquipmentOverviewView()
}