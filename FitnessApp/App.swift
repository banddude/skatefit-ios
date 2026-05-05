import SwiftUI

@main
struct FitnessApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var onboardingManager = OnboardingManager.shared
    @StateObject private var contentManager = ContentManager.shared
    @State private var showOnboarding = false

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(themeManager)
                .environmentObject(contentManager)
                .preferredColorScheme(themeManager.colorScheme)
                .onAppear {
                    Task {
                        await contentManager.initializeContent()

                        // Start background video download for all exercises
                        let allVideos = contentManager.workoutContainers.flatMap { workout in
                            workout.exercises.compactMap { $0.videoFile }
                        }
                        VideoDownloadQueue.shared.queueAll(fileNames: allVideos)

                        if !onboardingManager.isOnboardingCompleted {
                            showOnboarding = true
                        }
                    }
                }
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView()
                        .environmentObject(themeManager)
                }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        WorkoutsView()
    }
}
