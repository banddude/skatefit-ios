import SwiftUI

struct VideoTutorialView: View {
    let tutorialData: InfoSection

    var body: some View {
        OnboardingTemplateView(
            icon: tutorialData.icon,
            title: tutorialData.title,
            description: tutorialData.description,
            cardData: tutorialData.cards,
            proTip: tutorialData.proTip
        )
    }
}
