import SwiftUI

struct OnboardingWelcomeView: View {
    let welcomeData: WelcomeSection
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: Neon.Space.lg) {
                if let appIcon = AppConfig.getAppIcon() {
                    Image(uiImage: appIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: Neon.Radius.large, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Neon.Radius.large, style: .continuous)
                                .stroke(
                                    LinearGradient(colors: [Neon.magenta, Neon.violet], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: Neon.Stroke.medium
                                )
                        )
                        .neonGlow(Neon.magenta, radius: pulse ? Neon.Glow.hero + 8 : Neon.Glow.hero, opacity: pulse ? Neon.Glow.strong : Neon.Glow.standard)
                        .animation(Neon.Anim.pulse, value: pulse)
                }

                Text("WELCOME TO")
                    .font(Neon.font(13, .semibold))
                    .foregroundColor(Neon.cyan.opacity(0.85))
                    .tracking(3)

                Text(AppConfig.appName)
                    .font(Neon.font(28, .heavy))
                    .foregroundColor(.white)
                    .tracking(2.4)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .padding(.top, Neon.Space.sm)

            VStack(spacing: Neon.Space.sm) {
                Text(welcomeData.subtitle.uppercased())
                    .font(Neon.font(13, .heavy))
                    .foregroundColor(Neon.cyan)
                    .multilineTextAlignment(.center)
                    .tracking(2)
                    .neonGlow(Neon.cyan, radius: Neon.Glow.icon, opacity: Neon.Glow.muted)

                Text(welcomeData.description)
                    .font(Neon.font(13, .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Neon.textMid)
                    .padding(.horizontal, 22)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: Neon.Space.md) {
                ForEach(welcomeData.features) { feature in
                    FeatureCard(
                        icon: feature.icon,
                        title: feature.title,
                        description: feature.description,
                        color: feature.displayColor
                    )
                }
            }
            .padding(.horizontal, Neon.Space.lg)

            Color.clear.frame(height: 80)
        }
        .padding(.top, Neon.Space.sm)
        .onAppear { pulse = true }
    }
}

struct FeatureCard: View {
    let icon: String?
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .center, spacing: Neon.Space.lg) {
            if let icon = icon {
                NeonIconCircle(icon: icon, color: color, size: 50, iconSize: 20)
            } else {
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(colors: [color, Neon.violet], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: Neon.Stroke.medium
                        )
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(Neon.bg))
                    Text(String(title.prefix(1)).uppercased())
                        .font(Neon.font(20, .heavy))
                        .foregroundColor(color)
                }
            }

            VStack(alignment: .leading, spacing: Neon.Space.xs) {
                Text(title.uppercased())
                    .font(Neon.font(14, .heavy))
                    .foregroundColor(.white)
                    .tracking(1)

                Text(description)
                    .font(Neon.font(12, .medium))
                    .foregroundColor(Neon.textMid)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Neon.Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .neonOutline(color: color, radius: Neon.Radius.medium, lineWidth: Neon.Stroke.thin, glow: Neon.Glow.card)
    }
}
