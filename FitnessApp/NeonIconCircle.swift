import SwiftUI

struct NeonIconCircle: View {
    let icon: String
    var color: Color = Neon.magenta
    var size: CGFloat = 50
    var iconSize: CGFloat = 22

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(colors: [color, Neon.violet], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: Neon.Stroke.medium
                )
                .frame(width: size, height: size)
                .background(Circle().fill(Neon.bg))
            Image(systemName: icon)
                .font(Neon.font(iconSize, .semibold))
                .foregroundColor(color)
                .neonGlow(color, radius: Neon.Glow.icon, opacity: Neon.Glow.standard)
        }
    }
}
