import SwiftUI

struct OnboardingGesturesView: View {
    @StateObject private var dataLoader = OnboardingDataLoader()

    var body: some View {
        Group {
            if let tutorialData = dataLoader.data?.onboarding.tutorial {
                OnboardingTemplateView(
                    icon: tutorialData.icon,
                    title: tutorialData.title,
                    description: tutorialData.description,
                    cardData: tutorialData.cards,
                    proTip: tutorialData.proTip
                )
            } else {
                VStack(spacing: Neon.Space.xl) {
                    ProgressView().tint(Neon.magenta)
                    Text("Loading...")
                        .font(Neon.font(13, .heavy))
                        .foregroundColor(Neon.textMid)
                        .tracking(2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Neon.bg)
            }
        }
    }
}

#Preview {
    OnboardingGesturesView()
}