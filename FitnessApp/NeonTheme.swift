import SwiftUI

enum Neon {
    static let bg = Color.black
    static let bgDeep = Color(red: 0.02, green: 0.01, blue: 0.05)
    static let panel = Color(red: 0.06, green: 0.04, blue: 0.10)
    static let panelHi = Color(red: 0.10, green: 0.07, blue: 0.16)
    static let line = Color.white.opacity(0.06)

    // logo gradient: hot magenta -> deep violet
    static let magenta = Color(red: 0.93, green: 0.20, blue: 0.86)
    static let pink = Color(red: 1.00, green: 0.30, blue: 0.78)
    static let purple = Color(red: 0.55, green: 0.18, blue: 0.95)
    static let violet = Color(red: 0.36, green: 0.10, blue: 0.85)
    static let cyan = Color(red: 0.20, green: 0.95, blue: 1.00)
    static let lime = Color(red: 0.55, green: 1.00, blue: 0.30)
    static let amber = Color(red: 1.00, green: 0.78, blue: 0.20)

    static let textHi = Color.white
    static let textMid = Color.white.opacity(0.72)
    static let textLow = Color.white.opacity(0.45)

    static let logoGradient = LinearGradient(
        colors: [pink, magenta, purple, violet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func font(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight)
    }

    // MARK: - Design system scales

    enum Space {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
    }

    enum Radius {
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 22
    }

    enum Glow {
        static let icon: CGFloat = 10
        static let card: CGFloat = 14
        static let hero: CGFloat = 20

        static let muted: Double = 0.5
        static let standard: Double = 0.65
        static let strong: Double = 0.75
    }

    enum Stroke {
        static let muted: Double = 0.5
        static let strong: Double = 0.7
        static let thin: CGFloat = 1
        static let medium: CGFloat = 1.2
    }

    enum Anim {
        static let quick: Animation = .easeInOut(duration: 0.2)
        static let standard: Animation = .easeInOut(duration: 0.3)
        static let reveal: Animation = .easeInOut(duration: 0.4)
        static let press: Animation = .spring(response: 0.22, dampingFraction: 0.7)
        static let pulse: Animation = .easeInOut(duration: 2.4).repeatForever(autoreverses: true)
    }

    static let touchTarget: CGFloat = 44
}

// MARK: - Neon outline (thin gradient stroke + outer glow)
struct NeonOutline: ViewModifier {
    var color: Color = Neon.magenta
    var radius: CGFloat = 18
    var lineWidth: CGFloat = 1.2
    var glow: CGFloat = 14

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.10),
                                Neon.panel.opacity(0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                color.opacity(0.95),
                                color.opacity(0.45),
                                Neon.violet.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: lineWidth
                    )
            )
            .shadow(color: color.opacity(0.55), radius: glow * 0.5, x: 0, y: 0)
            .shadow(color: color.opacity(0.25), radius: glow, x: 0, y: 0)
    }
}

extension View {
    func neonOutline(color: Color = Neon.magenta, radius: CGFloat = 18, lineWidth: CGFloat = 1.2, glow: CGFloat = 14) -> some View {
        modifier(NeonOutline(color: color, radius: radius, lineWidth: lineWidth, glow: glow))
    }

    func neonGlow(_ color: Color = Neon.magenta, radius: CGFloat = 12, opacity: Double = 0.6) -> some View {
        self
            .shadow(color: color.opacity(opacity), radius: radius * 0.4, x: 0, y: 0)
            .shadow(color: color.opacity(opacity * 0.55), radius: radius, x: 0, y: 0)
    }
}

// MARK: - Title text (plain white with subtle neon glow)
struct NeonGradientText: View {
    let text: String
    var size: CGFloat = 28
    var weight: Font.Weight = .heavy
    var gradient: LinearGradient = Neon.logoGradient
    var tracking: CGFloat = 1.2

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: weight))
            .tracking(tracking)
            .foregroundStyle(gradient)
            .shadow(color: Neon.magenta.opacity(0.45), radius: 10, x: 0, y: 0)
    }
}

// MARK: - Synthwave background
struct NeonGridFloor: View {
    var showGrid: Bool = false

    private static let cachedBackground: UIImage = {
        let size = CGSize(width: 393, height: 852)
        let renderer = ImageRenderer(content:
            ZStack {
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(red: 0.05, green: 0.02, blue: 0.10),
                        Color(red: 0.10, green: 0.03, blue: 0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                RadialGradient(
                    colors: [
                        Neon.magenta.opacity(0.35),
                        Neon.purple.opacity(0.15),
                        .clear
                    ],
                    center: .init(x: 0.5, y: 0.0),
                    startRadius: 20,
                    endRadius: 380
                )
            }
            .frame(width: size.width, height: size.height)
        )
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage ?? UIImage()
    }()

    var body: some View {
        ZStack {
            Image(uiImage: Self.cachedBackground)
                .resizable()
                .ignoresSafeArea()

            if showGrid {
                GeometryReader { geo in
                    NeonGrid()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Neon.cyan.opacity(0.0),
                                    Neon.cyan.opacity(0.35),
                                    Neon.magenta.opacity(0.6)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            style: StrokeStyle(lineWidth: 1, lineCap: .round)
                        )
                        .frame(width: geo.size.width, height: geo.size.height * 0.45)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.85)
                        .blur(radius: 0.4)
                        .opacity(0.75)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
    }
}

private struct NeonGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let horizon = CGPoint(x: rect.midX, y: -rect.height * 0.2)
        let bottom = rect.height
        let cols = 12

        // vertical lines fanning to horizon
        for i in 0...cols {
            let x = rect.width * CGFloat(i) / CGFloat(cols)
            p.move(to: CGPoint(x: x, y: bottom))
            p.addLine(to: horizon)
        }

        // horizontal lines, exponentially spaced for perspective
        let rows = 10
        for j in 0...rows {
            let t = pow(CGFloat(j) / CGFloat(rows), 1.7)
            let y = bottom * (1 - t)
            p.move(to: CGPoint(x: 0, y: y))
            p.addLine(to: CGPoint(x: rect.width, y: y))
        }
        return p
    }
}

// MARK: - Neon button
struct NeonButtonStyle: ButtonStyle {
    var color: Color = Neon.magenta
    var radius: CGFloat = 14

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Neon.font(15, .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [color, Neon.violet],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: color.opacity(configuration.isPressed ? 0.25 : 0.6), radius: configuration.isPressed ? 6 : 14, x: 0, y: 0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.18, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

// MARK: - Screen wrapper
struct NeonScreen<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        ZStack {
            NeonGridFloor()
            content
        }
    }
}
