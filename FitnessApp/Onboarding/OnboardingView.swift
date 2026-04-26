import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var onboardingManager = OnboardingManager.shared
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0

    private let pages = [
        AnyView(OnboardingWelcomeView()),
        AnyView(DifficultyExplanationView()),
        AnyView(EquipmentOverviewView()),
        AnyView(VideoTutorialView())
    ]

    private let progressColors: [Color] = [.accentColor, .mint, .purple, .orange]

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
            .animation(.easeInOut(duration: 0.4), value: currentPage)

            VStack(spacing: 0) {
                // Progress bar
                HStack(spacing: 6) {
                    ForEach(0..<pages.count, id: \.self) { index in
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
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        pages[index]
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
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
                            withAnimation(.spring()) {
                                dragOffset = 0
                            }
                        }
                    }
            )

            // Floating navigation buttons
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    if currentPage > 0 {
                        navButton(
                            label: "Back",
                            icon: "chevron.left",
                            iconLeading: true,
                            primary: false
                        ) {
                            withAnimation(.easeInOut(duration: 0.25)) {
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

                    let isLast = currentPage == pages.count - 1
                    navButton(
                        label: isLast ? "Get Started" : "Next",
                        icon: isLast ? "arrow.right" : "chevron.right",
                        iconLeading: false,
                        primary: true
                    ) {
                        if isLast {
                            completeOnboarding()
                        } else {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                currentPage += 1
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }

    @ViewBuilder
    private func navButton(label: String, icon: String?, iconLeading: Bool, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if iconLeading, let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                }
                Text(label)
                    .font(.system(size: 15, weight: .bold))
                if !iconLeading, let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 13)
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
                        lineWidth: 1
                    )
            )
            .shadow(color: primary ? pageAccent.opacity(0.45) : .clear, radius: 12, x: 0, y: 5)
        }
        .buttonStyle(PressableCardButtonStyle())
    }

    private func completeOnboarding() {
        onboardingManager.completeOnboarding()
        dismiss()
    }
}

#Preview {
    OnboardingView()
}
