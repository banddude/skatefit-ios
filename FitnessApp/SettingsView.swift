import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var contentManager: ContentManager
    @State private var healthManager = HealthKitManager.shared
    @State private var showCacheCleared = false
    @State private var showTipJar = false

    private static let cachedAppIcon = AppConfig.getAppIcon()

    var body: some View {
        ZStack {
            NeonGridFloor()

            ScrollView {
                VStack(spacing: Neon.Space.xl) {
                    header
                    healthKitSection
                    tipJarSection
                    aboutSection
                }
                .padding(.horizontal, Neon.Space.xl)
                .padding(.top, 50)
                .padding(.bottom, 40)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(Neon.font(14, .bold))
                    .foregroundColor(Neon.textMid)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Neon.panel))
                    .overlay(Circle().stroke(Neon.textLow.opacity(0.4), lineWidth: 1))
            }
            .padding(.trailing, Neon.Space.lg)
            .padding(.top, Neon.Space.lg)
        }
        .overlay {
            if showCacheCleared {
                cacheClearedToast
            }
        }
        .task {
            healthManager.checkAuthorizationStatus()
        }
        .fullScreenCover(isPresented: $showTipJar) {
            TipJarView()
        }
    }

    private var header: some View {
        VStack(spacing: Neon.Space.md) {
            if let appIcon = Self.cachedAppIcon {
                Image(uiImage: appIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                LinearGradient(colors: [Neon.magenta.opacity(0.7), Neon.cyan.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: Neon.Stroke.medium
                            )
                    )
                    .neonGlow(Neon.magenta, radius: Neon.Glow.hero, opacity: 0.5)
            }

            Text("SETTINGS")
                .font(Neon.font(22, .heavy))
                .foregroundColor(.white)
                .tracking(2)
        }
    }

    // MARK: - HealthKit

    private var healthKitSection: some View {
        VStack(spacing: Neon.Space.md) {
            sectionHeader(title: "APPLE HEALTH", icon: "heart.circle.fill", color: Neon.lime)

            if !healthManager.isAvailable {
                settingsCard {
                    VStack(spacing: Neon.Space.sm) {
                        Text("Apple Health is not available on this device.")
                            .font(Neon.font(12, .medium))
                            .foregroundColor(Neon.textMid)
                            .multilineTextAlignment(.center)
                    }
                }
            } else if healthManager.isAuthorized {
                settingsCard {
                    VStack(spacing: Neon.Space.md) {
                        HStack(spacing: Neon.Space.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(Neon.font(18, .bold))
                                .foregroundColor(Neon.lime)
                                .neonGlow(Neon.lime, radius: Neon.Glow.icon, opacity: Neon.Glow.standard)

                            Text("CONNECTED")
                                .font(Neon.font(13, .heavy))
                                .foregroundColor(Neon.lime)
                                .tracking(1.5)

                            Spacer()
                        }

                        Text("Workouts are automatically saved to Apple Health and count toward your Move and Exercise rings.")
                            .font(Neon.font(11, .medium))
                            .foregroundColor(Neon.textMid)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Circle().fill(Neon.lime).frame(width: 4, height: 4)
                                Text("Session duration is tracked while you workout")
                                    .font(Neon.font(10, .medium))
                                    .foregroundColor(Neon.textMid)
                            }
                            HStack(spacing: 6) {
                                Circle().fill(Neon.lime).frame(width: 4, height: 4)
                                Text("Estimated calories based on workout difficulty")
                                    .font(Neon.font(10, .medium))
                                    .foregroundColor(Neon.textMid)
                            }
                            HStack(spacing: 6) {
                                Circle().fill(Neon.textLow).frame(width: 4, height: 4)
                                Text("No heart rate or personal health data collected")
                                    .font(Neon.font(10, .medium))
                                    .foregroundColor(Neon.textLow)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Button(action: { healthManager.openHealthApp() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.right.square")
                                    .font(Neon.font(11, .semibold))
                                Text("OPEN APPLE HEALTH")
                                    .font(Neon.font(11, .bold))
                                    .tracking(1)
                            }
                            .foregroundColor(Neon.lime)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(Neon.lime.opacity(0.1)))
                            .overlay(Capsule().stroke(Neon.lime.opacity(0.4), lineWidth: 1))
                        }
                    }
                }
            } else {
                settingsCard {
                    VStack(spacing: Neon.Space.md) {
                        Text("Connect \(AppConfig.appName) to Apple Health to log your workouts and fill your Fitness rings.")
                            .font(Neon.font(12, .medium))
                            .foregroundColor(Neon.textMid)
                            .multilineTextAlignment(.center)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Circle().fill(Neon.cyan).frame(width: 4, height: 4)
                                Text("Tracks session duration and estimated calories")
                                    .font(Neon.font(10, .medium))
                                    .foregroundColor(Neon.textLow)
                            }
                            HStack(spacing: 6) {
                                Circle().fill(Neon.textLow).frame(width: 4, height: 4)
                                Text("No heart rate or personal health data collected")
                                    .font(Neon.font(10, .medium))
                                    .foregroundColor(Neon.textLow)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Button(action: { Task { await healthManager.requestAuthorization() } }) {
                            HStack(spacing: 6) {
                                Image(systemName: "heart.circle")
                                    .font(Neon.font(11, .semibold))
                                Text("CONNECT TO APPLE HEALTH")
                                    .font(Neon.font(11, .bold))
                                    .tracking(1)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(NeonButtonStyle(color: Neon.lime))
                    }
                }
            }
        }
    }

    // MARK: - About

    private var tipJarSection: some View {
        VStack(spacing: Neon.Space.md) {
            sectionHeader(title: "SUPPORT", icon: "heart.circle.fill", color: Neon.magenta)

            settingsCard {
                Button(action: { showTipJar = true }) {
                    HStack(spacing: Neon.Space.md) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(Neon.font(20, .bold))
                            .foregroundColor(Neon.magenta)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Neon.magenta.opacity(0.12)))
                            .overlay(Circle().stroke(Neon.magenta.opacity(0.4), lineWidth: 1))

                        VStack(alignment: .leading, spacing: 3) {
                            Text("BUY ME A DRINK")
                                .font(Neon.font(12, .heavy))
                                .foregroundColor(.white)
                                .tracking(1.5)
                            Text("Support SkateFit development with an optional tip.")
                                .font(Neon.font(10, .medium))
                                .foregroundColor(Neon.textMid)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(Neon.font(12, .bold))
                            .foregroundColor(Neon.magenta)
                    }
                }
            }
        }
    }

    private var aboutSection: some View {
        VStack(spacing: Neon.Space.md) {
            sectionHeader(title: "ABOUT", icon: "info.circle.fill", color: Neon.cyan)

            settingsCard {
                VStack(spacing: Neon.Space.md) {
                    HStack {
                        Text("VERSION")
                            .font(Neon.font(11, .bold))
                            .foregroundColor(Neon.textMid)
                            .tracking(1)
                        Spacer()
                        Text(appVersion)
                            .font(Neon.font(11, .bold))
                            .foregroundColor(Neon.cyan)
                    }

                    Rectangle()
                        .fill(Neon.textLow.opacity(0.2))
                        .frame(height: 1)

                    Button(action: clearCache) {
                        HStack {
                            Text("CLEAR CACHE")
                                .font(Neon.font(11, .bold))
                                .foregroundColor(Neon.amber)
                                .tracking(1)
                            Spacer()
                            Image(systemName: "trash")
                                .font(Neon.font(11, .semibold))
                                .foregroundColor(Neon.amber)
                        }
                    }
                }
            }
        }
    }

    private var cacheClearedToast: some View {
        VStack {
            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Neon.lime)
                Text("Cache cleared")
                    .font(Neon.font(12, .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Capsule().fill(Neon.bgDeep).overlay(Capsule().stroke(Neon.lime.opacity(0.5), lineWidth: 1)))
            .neonGlow(Neon.lime, radius: Neon.Glow.card, opacity: 0.4)
            .padding(.bottom, 40)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(Neon.Anim.standard, value: showCacheCleared)
    }

    // MARK: - Helpers

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    private func clearCache() {
        contentManager.clearCache()
        withAnimation { showCacheCleared = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showCacheCleared = false }
        }
    }

    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(Neon.font(12, .semibold))
                .foregroundColor(color)
            Text(title)
                .font(Neon.font(12, .heavy))
                .foregroundColor(color)
                .tracking(2)
            Spacer()
        }
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Neon.Radius.medium, style: .continuous)
                .fill(Neon.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Neon.Radius.medium, style: .continuous)
                .stroke(Neon.textLow.opacity(0.3), lineWidth: Neon.Stroke.thin)
        )
    }
}

#Preview {
    SettingsView()
}
