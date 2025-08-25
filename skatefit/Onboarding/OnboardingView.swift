import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var onboardingManager = OnboardingManager.shared
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    
    private let pages = [
        AnyView(WelcomeOnboardingView()),
        AnyView(DifficultyExplanationView()),
        AnyView(EquipmentOverviewView()),
        AnyView(VideoTutorialView())
    ]
    
    private let progressColors: [Color] = [.accentColor, .mint, .purple, .orange]
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack {
                // Progress bar - styled like WorkoutsView
                HStack {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Rectangle()
                            .fill(index <= currentPage ? progressColors[index] : Color(.tertiarySystemGroupedBackground))
                            .frame(height: 4)
                            .cornerRadius(2)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
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
            
            // Floating Navigation buttons
            VStack {
                Spacer()
                HStack {
                    if currentPage > 0 {
                        Button("Back") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(radius: 4)
                    } else {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .shadow(radius: 4)
                    }
                    
                    Spacer()
                    
                    Button(currentPage == pages.count - 1 ? "Get Started" : "Next") {
                        if currentPage == pages.count - 1 {
                            completeOnboarding()
                        } else {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                    }
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(radius: 4)
                }
                .padding()
            }
        }
    }
    
    private func completeOnboarding() {
        onboardingManager.completeOnboarding()
        dismiss()
    }
}

#Preview {
    OnboardingView()
}