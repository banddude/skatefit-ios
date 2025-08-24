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
    @State private var isShowingSplash = true
    @State private var showOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if isShowingSplash {
                SplashView()
                    .environmentObject(themeManager)
                    .preferredColorScheme(themeManager.colorScheme)
                    .onAppear {
                        // Hide splash screen after 2 seconds, then check onboarding
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                self.isShowingSplash = false
                                // Show onboarding if not completed
                                if !onboardingManager.isOnboardingCompleted {
                                    self.showOnboarding = true
                                }
                            }
                        }
                    }
            } else {
                MainTabView()
                    .environmentObject(themeManager)
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
