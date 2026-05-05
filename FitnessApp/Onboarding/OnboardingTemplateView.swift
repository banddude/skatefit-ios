import SwiftUI

struct OnboardingCardView: View {
    let data: OnboardingCard

    var body: some View {
        HStack(alignment: .center, spacing: Neon.Space.lg) {
            if let icon = data.icon {
                NeonIconCircle(icon: icon, color: data.displayColor, size: 50, iconSize: 20)
            } else {
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(colors: [data.displayColor, Neon.violet], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: Neon.Stroke.medium
                        )
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(Neon.bg))
                    Text(String(data.title.prefix(1)).uppercased())
                        .font(Neon.font(20, .heavy))
                        .foregroundColor(data.displayColor)
                }
            }

            VStack(alignment: .leading, spacing: Neon.Space.xs) {
                Text(data.title.uppercased())
                    .font(Neon.font(14, .heavy))
                    .foregroundColor(.white)
                    .tracking(1)

                Text(data.description)
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
        .neonOutline(color: data.displayColor, radius: Neon.Radius.medium, lineWidth: Neon.Stroke.thin, glow: Neon.Glow.card)
    }
}

struct OnboardingTemplateView: View {
    let icon: String
    let title: String
    let description: String
    let cardData: [OnboardingCard]
    let proTip: String?

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: Neon.Space.md) {
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(colors: [Neon.magenta, Neon.violet], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: Neon.Stroke.medium
                        )
                        .frame(width: 80, height: 80)
                        .background(Circle().fill(Neon.bg))
                    Image(systemName: icon)
                        .font(Neon.font(32, .semibold))
                        .foregroundColor(Neon.magenta)
                        .neonGlow(Neon.magenta, radius: Neon.Glow.hero, opacity: Neon.Glow.standard)
                }
                .padding(.top, Neon.Space.sm)

                Text(title.uppercased())
                    .font(Neon.font(20, .heavy))
                    .foregroundColor(.white)
                    .tracking(1.5)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(Neon.font(13, .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Neon.textMid)
                    .padding(.horizontal, Neon.Space.xxl)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 6)

            VStack(spacing: Neon.Space.md) {
                ForEach(cardData) { data in
                    OnboardingCardView(data: data)
                }
            }
            .padding(.horizontal, Neon.Space.lg)

            if let proTip = proTip {
                HStack(alignment: .top, spacing: Neon.Space.md) {
                    Image(systemName: "lightbulb.fill")
                        .font(Neon.font(14, .semibold))
                        .foregroundColor(Neon.amber)
                        .neonGlow(Neon.amber, radius: Neon.Glow.icon, opacity: Neon.Glow.standard)
                    VStack(alignment: .leading, spacing: Neon.Space.xs) {
                        Text("TIP")
                            .font(Neon.font(10, .heavy))
                            .foregroundColor(Neon.amber)
                            .tracking(2)
                        Text(proTip)
                            .font(Neon.font(12, .medium))
                            .multilineTextAlignment(.leading)
                            .foregroundColor(Neon.textHi)
                            .lineSpacing(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(Neon.Space.lg)
                .background(
                    RoundedRectangle(cornerRadius: Neon.Radius.small, style: .continuous)
                        .fill(Neon.bg)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Neon.Radius.small, style: .continuous)
                        .stroke(Neon.amber.opacity(Neon.Stroke.muted), lineWidth: Neon.Stroke.thin)
                )
                .shadow(color: Neon.amber.opacity(0.3), radius: Neon.Glow.icon, x: 0, y: 0)
                .padding(.horizontal, Neon.Space.lg)
            }

            Color.clear.frame(height: 80)
        }
        .padding(.top, 6)
    }
}
