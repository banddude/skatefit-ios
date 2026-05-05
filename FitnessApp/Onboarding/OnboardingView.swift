import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var onboardingManager = OnboardingManager.shared
    @StateObject private var dataLoader = OnboardingDataLoader()
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0

    private let progressColors: [Color] = [Neon.cyan, Neon.amber, Neon.magenta, Neon.violet]
    private let pageCount = 4

    private var pageAccent: Color {
        progressColors[min(currentPage, progressColors.count - 1)]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    pageAccent.opacity(0.22),
                    Color.black.opacity(0.95),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
            .animation(Neon.Anim.reveal, value: currentPage)

            VStack(spacing: 0) {
                if let onboarding = dataLoader.data?.onboarding {
                    HStack(spacing: Neon.Space.sm) {
                        ForEach(0..<pageCount, id: \.self) { index in
                            Capsule()
                                .fill(
                                    index <= currentPage
                                    ? AnyShapeStyle(
                                        LinearGradient(
                                            colors: [
                                                progressColors[index],
                                                progressColors[index].opacity(0.55)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    : AnyShapeStyle(Color.white.opacity(0.12))
                                )
                                .frame(height: 4)
                                .animation(Neon.Anim.standard, value: currentPage)
                        }
                    }
                    .padding(.horizontal, Neon.Space.xl)
                    .padding(.top, Neon.Space.md)

                    TabView(selection: $currentPage) {
                        OnboardingWelcomeView(welcomeData: onboarding.welcome)
                            .tag(0)
                        DifficultyExplanationView(difficultyData: onboarding.difficulty)
                            .tag(1)
                        EquipmentOverviewView(equipmentData: onboarding.equipment)
                            .tag(2)
                        VideoTutorialView(tutorialData: onboarding.tutorial)
                            .tag(3)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                } else {
                    onboardingStateView
                }
            }
            .offset(y: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 100 {
                            completeOnboarding()
                        } else {
                            withAnimation(Neon.Anim.press) {
                                dragOffset = 0
                            }
                        }
                    }
            )

            if dataLoader.data != nil {
                VStack {
                    Spacer()
                    HStack(spacing: Neon.Space.md) {
                        if currentPage > 0 {
                            navButton(
                                label: "Back",
                                icon: "chevron.left",
                                iconLeading: true,
                                primary: false
                            ) {
                                withAnimation(Neon.Anim.quick) {
                                    currentPage -= 1
                                }
                            }
                        } else {
                            navButton(
                                label: "Skip",
                                icon: nil,
                                iconLeading: false,
                                primary: false
                            ) {
                                completeOnboarding()
                            }
                        }

                        Spacer()

                        let isLast = currentPage == pageCount - 1
                        navButton(
                            label: isLast ? "Get Started" : "Next",
                            icon: isLast ? "arrow.right" : "chevron.right",
                            iconLeading: false,
                            primary: true
                        ) {
                            if isLast {
                                completeOnboarding()
                            } else {
                                withAnimation(Neon.Anim.quick) {
                                    currentPage += 1
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Neon.Space.xl)
                    .padding(.bottom, Neon.Space.xxl)
                }
            }
        }
        .task {
            await dataLoader.loadOnboardingDataIfNeeded()
        }
    }

    @ViewBuilder
    private func navButton(label: String, icon: String?, iconLeading: Bool, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Neon.Space.sm) {
                if iconLeading, let icon = icon {
                    Image(systemName: icon)
                        .font(Neon.font(13, .bold))
                }
                Text(label)
                    .font(Neon.font(15, .bold))
                if !iconLeading, let icon = icon {
                    Image(systemName: icon)
                        .font(Neon.font(13, .bold))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 13)
            .frame(minHeight: Neon.touchTarget)
            .background(
                Group {
                    if primary {
                        LinearGradient(
                            colors: [
                                pageAccent,
                                pageAccent.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.clear
                    }
                }
            )
            .background(primary ? AnyShapeStyle(Color.clear) : AnyShapeStyle(.ultraThinMaterial))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        primary ? Color.white.opacity(0.18) : Color.white.opacity(0.15),
                        lineWidth: Neon.Stroke.thin
                    )
            )
            .shadow(color: primary ? pageAccent.opacity(Neon.Glow.muted) : .clear, radius: Neon.Glow.card, x: 0, y: 5)
        }
        .buttonStyle(PressableCardButtonStyle())
    }

    private func completeOnboarding() {
        onboardingManager.completeOnboarding()
        dismiss()
    }

    private var onboardingStateView: some View {
        VStack(spacing: Neon.Space.lg) {
            if let appIcon = AppConfig.getAppIcon() {
                Image(uiImage: appIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: Neon.Radius.large, style: .continuous))
            }

            if dataLoader.isLoading {
                ProgressView()
                    .tint(Neon.magenta)
                Text("CONNECTING TO GITHUB")
                    .font(Neon.font(13, .heavy))
                    .foregroundColor(Neon.cyan)
                    .tracking(2.5)
            } else {
                Text("ONBOARDING UNAVAILABLE")
                    .font(Neon.font(15, .heavy))
                    .foregroundColor(.white)
                    .tracking(2)

                Text(dataLoader.errorMessage ?? "Unable to load onboarding right now.")
                    .font(Neon.font(12, .medium))
                    .foregroundColor(Neon.textMid)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Neon.Space.xl)

                HStack(spacing: Neon.Space.md) {
                    navButton(
                        label: "Skip",
                        icon: nil,
                        iconLeading: false,
                        primary: false
                    ) {
                        completeOnboarding()
                    }

                    navButton(
                        label: "Retry",
                        icon: "arrow.clockwise",
                        iconLeading: false,
                        primary: true
                    ) {
                        Task {
                            await dataLoader.loadOnboardingData()
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, Neon.Space.xl)
    }
}
