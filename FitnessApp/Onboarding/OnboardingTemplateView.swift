import SwiftUI

// Reusable Card View
struct OnboardingCardView: View {
    let data: OnboardingCard

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                data.displayColor.opacity(0.55),
                                data.displayColor.opacity(0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                if let icon = data.icon {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                } else {
                    Text(String(data.title.prefix(1)))
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(data.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)

                Text(data.description)
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
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            data.displayColor.opacity(0.18),
                            Color(red: 0.10, green: 0.10, blue: 0.13).opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            data.displayColor.opacity(0.55),
                            data.displayColor.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: data.displayColor.opacity(0.18), radius: 8, x: 0, y: 4)
    }
}

// The main template view
struct OnboardingTemplateView: View {
    let icon: String
    let title: String
    let description: String
    let cardData: [OnboardingCard]
    let proTip: String?

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.65))
                    .padding(.horizontal, 20)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 4)

            VStack(spacing: 12) {
                ForEach(cardData) { data in
                    OnboardingCardView(data: data)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 20)

            if let proTip = proTip {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.yellow)
                    Text(proTip)
                        .font(.system(size: 13, weight: .medium))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.yellow.opacity(0.06))
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.yellow.opacity(0.35), lineWidth: 1)
                )
                .padding(.horizontal, 20)
            }

            Color.clear.frame(height: 80)
        }
        .padding(.top, 6)
    }
}
