import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var onboardingManager = OnboardingManager.shared
    @State private var currentPage = 0
    
    private let pages = [
        AnyView(WelcomeOnboardingView()),
        AnyView(DifficultyExplanationView()),
        AnyView(EquipmentOverviewView()),
        AnyView(AppStructureView()),
        AnyView(VideoTutorialView())
    ]
    
    var body: some View {
        VStack {
            // Progress bar
            HStack {
                ForEach(0..<pages.count, id: \.self) { index in
                    Rectangle()
                        .fill(index <= currentPage ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: 3)
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
            
            // Navigation buttons
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .foregroundColor(.secondary)
                } else {
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .foregroundColor(.secondary)
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
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(25)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func completeOnboarding() {
        onboardingManager.completeOnboarding()
        dismiss()
    }
}

#Preview {
    OnboardingView()
}