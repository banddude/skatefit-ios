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
            if isShowingSplash {
                SplashView()
                    .environmentObject(themeManager)
                    .preferredColorScheme(themeManager.colorScheme)
                    .onAppear {
                        // Initialize content and hide splash screen
                        Task {
                            await contentManager.initializeContent()
                            
                            // Preload essential videos in background
                            contentManager.preloadEssentialVideos()
                            
                            // Hide splash screen after content is ready (or after 3 seconds max)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation {
                                    self.isShowingSplash = false
                                    // Show onboarding if not completed
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
    }
}

// Main View - Just Workouts
struct MainTabView: View {
    var body: some View {
        WorkoutsView()
    }
}
