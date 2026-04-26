import SwiftUI

struct OnboardingWelcomeView: View {
    @StateObject private var dataLoader = OnboardingDataLoader()
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Group {
            if let welcomeData = dataLoader.data?.onboarding.welcome {
                VStack(spacing: 14) {
                    VStack(spacing: 12) {
                        if let appIcon = AppConfig.getAppIcon() {
                            Image(uiImage: appIcon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(color: .black.opacity(0.5), radius: 14, x: 0, y: 8)
                        }

                        Text(welcomeData.title)
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 6) {
                        Text(welcomeData.subtitle)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.accentColor)
                            .multilineTextAlignment(.center)

                        Text(welcomeData.description)
                            .font(.system(size: 13, weight: .medium))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.65))
                            .padding(.horizontal, 20)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 12) {
                        ForEach(welcomeData.features) { feature in
                            FeatureCard(
                                icon: feature.icon,
                                title: feature.title,
                                description: feature.description,
                                color: feature.displayColor
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 20)

                    Color.clear.frame(height: 80)
                }
                .padding(.top, 6)
            } else {
                VStack(spacing: 20) {
                    if let appIcon = AppConfig.getAppIcon() {
                        Image(uiImage: appIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 96, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }

                    ProgressView().tint(.white)
                    Text("Loading...")
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct FeatureCard: View {
    let icon: String?
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.55),
                                color.opacity(0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                } else {
                    Text(String(title.prefix(1)))
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(0.18),
                            Color(red: 0.10, green: 0.10, blue: 0.13).opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            color.opacity(0.55),
                            color.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: color.opacity(0.18), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    OnboardingWelcomeView()
}
