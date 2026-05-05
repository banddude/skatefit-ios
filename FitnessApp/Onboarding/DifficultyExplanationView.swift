import SwiftUI

struct DifficultyExplanationView: View {
    let difficultyData: InfoSection

    var body: some View {
        OnboardingTemplateView(
            icon: difficultyData.icon,
            title: difficultyData.title,
            description: difficultyData.description,
            cardData: difficultyData.cards,
            proTip: difficultyData.proTip
        )
    }
}
