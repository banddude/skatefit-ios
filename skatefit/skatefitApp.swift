//
//  skatefitApp.swift
//  skatefit
//
//  Created by Mike Shaffer on 4/23/25.
//

import SwiftUI

@main
struct skatefitApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var onboardingManager = OnboardingManager.shared
    @StateObject private var contentManager = ContentManager.shared
    @State private var isShowingSplash = true
    @State private var showOnboarding = false

    var body: some Scene {
        WindowGroup {
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-UITestExercisePlayer") {
                WorkoutPlayerView(
                    workoutName: "UI Test Workout",
                    difficulty: .intermediate,
                    exercises: uiTestExercises,
                    startingIndex: 0,
                    videoURLOverride: uiTestVideoURL
                )
                .preferredColorScheme(.dark)
            } else {
                appContent
            }
#else
            appContent
#endif
        }
    }

    @ViewBuilder
    private var appContent: some View {
        if isShowingSplash {
            SplashView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
                .onAppear {
                    Task {
                        await contentManager.initializeContent()
                        contentManager.downloadAllVideos()

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                self.isShowingSplash = false
                                if !onboardingManager.isOnboardingCompleted {
                                    self.showOnboarding = true
                                }
                            }
                        }
                    }
                }
        } else {
            MainTabView()
                .environmentObject(themeManager)
                .environmentObject(contentManager)
                .preferredColorScheme(themeManager.colorScheme)
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView()
                }
        }
    }

#if DEBUG
    private var uiTestVideoURL: URL? {
        guard let encoded = ProcessInfo.processInfo.environment["UITEST_VIDEO_BASE64"],
              let data = Data(base64Encoded: encoded) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("synthetic-replay.mp4")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch { return nil }
    }

    private var uiTestExercises: [WorkoutExercise] {
        [
            WorkoutExercise(
                section: "Warm-up",
                move: "UI Test Exercise One",
                description: "First exercise used to verify long press behavior.",
                detailedDescription: "First detail sentence. Second detail sentence. Third detail sentence. Fourth detail sentence.",
                jsonFile: "ui_test_one.json",
                videoFile: nil,
                beginner: "20 seconds",
                intermediate: "30 seconds",
                advanced: "45 seconds"
            ),
            WorkoutExercise(
                section: "Main",
                move: "UI Test Exercise Two",
                description: "Second exercise used to verify paging remains available.",
                detailedDescription: nil,
                jsonFile: "ui_test_two.json",
                videoFile: nil,
                beginner: "5 reps",
                intermediate: "8 reps",
                advanced: "12 reps"
            )
        ]
    }
#endif
}

struct MainTabView: View {
    var body: some View {
        WorkoutsView()
    }
}
