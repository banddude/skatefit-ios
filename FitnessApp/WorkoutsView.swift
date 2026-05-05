import SwiftUI

struct WorkoutsView: View {
    @EnvironmentObject var contentManager: ContentManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showOnboarding = false
    @State private var showSettings = false

    private static let cachedAppIcon = AppConfig.getAppIcon()

    private var headerView: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 14) {
                    if let appIcon = Self.cachedAppIcon {
                        Image(uiImage: appIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Neon.magenta.opacity(0.7), lineWidth: 1)
                            )
                            .neonGlow(Neon.magenta, radius: Neon.Glow.hero, opacity: 0.7)
                    }

                    Text(AppConfig.appName)
                        .font(Neon.font(40, .heavy))
                        .foregroundColor(.white)
                        .tracking(2.4)
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .layoutPriority(1)
                        .onLongPressGesture { contentManager.clearCache() }
                }

                Text("SKATE · TRAIN · RECOVER")
                    .font(Neon.font(10, .semibold))
                    .foregroundColor(Neon.cyan.opacity(0.85))
                    .tracking(3)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(Neon.font(16, .semibold))
                    .foregroundColor(Neon.cyan)
                    .frame(width: Neon.touchTarget, height: Neon.touchTarget)
                    .background(
                        Circle()
                            .fill(Neon.panel)
                    )
                    .overlay(
                        Circle().stroke(Neon.cyan.opacity(0.6), lineWidth: Neon.Stroke.thin)
                    )
                    .neonGlow(Neon.cyan, radius: Neon.Glow.card, opacity: 0.55)
            }

            Button(action: { showOnboarding = true }) {
                Image(systemName: "lightbulb.fill")
                    .font(Neon.font(16, .semibold))
                    .foregroundColor(Neon.amber)
                    .frame(width: Neon.touchTarget, height: Neon.touchTarget)
                    .background(
                        Circle()
                            .fill(Neon.panel)
                    )
                    .overlay(
                        Circle().stroke(Neon.amber.opacity(0.6), lineWidth: Neon.Stroke.thin)
                    )
                    .neonGlow(Neon.amber, radius: Neon.Glow.card, opacity: 0.55)
            }
        }
        .padding(.horizontal, Neon.Space.xl)
        .padding(.top, Neon.Space.sm)
    }

    private var sortedWorkouts: [WorkoutContainer] {
        contentManager.sortedWorkouts
    }

    private var workoutsList: some View {
        LazyVStack(spacing: Neon.Space.sm) {
            ForEach(sortedWorkouts, id: \.id) { workout in
                NavigationLink(destination: WorkoutDetailView(
                    workoutName: workout.name,
                    workoutIcon: workout.workoutIcon,
                    workoutColor: workout.workoutColor,
                    exercises: workout.exercises
                )) {
                    WorkoutNeonCard(workout: workout)
                }
                .buttonStyle(PressableCardButtonStyle())
            }
        }
        .padding(.horizontal, Neon.Space.lg)
    }

    var body: some View {
        NavigationView {
            ZStack {
                NeonGridFloor()

                GeometryReader { geo in
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        headerView

                        Spacer(minLength: 0)

                        if contentManager.workoutContainers.isEmpty {
                            if contentManager.isInitializing {
                                VStack(spacing: Neon.Space.md) {
                                    ProgressView()
                                        .controlSize(.large)
                                        .tint(Neon.magenta)
                                    Text("LOADING")
                                        .font(Neon.font(13, .bold))
                                        .foregroundColor(Neon.textMid)
                                        .tracking(3)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 80)
                            } else if let error = contentManager.initializationError {
                                VStack(spacing: 14) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(Neon.font(40, .semibold))
                                        .foregroundColor(Neon.magenta)
                                        .neonGlow(Neon.magenta, radius: Neon.Glow.hero)
                                    Text("UNABLE TO LOAD")
                                        .font(Neon.font(15, .heavy))
                                        .foregroundColor(.white)
                                        .tracking(2)
                                    Text(error)
                                        .font(Neon.font(12, .medium))
                                        .foregroundColor(Neon.textLow)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                    Button(action: { Task { await contentManager.initializeContent() } }) {
                                        Text("RETRY")
                                            .tracking(2)
                                    }
                                    .buttonStyle(NeonButtonStyle())
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 60)
                            } else {
                                Text("NO WORKOUTS")
                                    .font(Neon.font(14, .bold))
                                    .foregroundColor(Neon.textLow)
                                    .tracking(3)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 50)
                            }
                        } else {
                            workoutsList
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, Neon.Space.md)
                    .frame(minHeight: geo.size.height)
                }
                .refreshable {
                    await withCheckedContinuation { continuation in
                        Task.detached {
                            await contentManager.refreshContent()
                            continuation.resume()
                        }
                    }
                }
                }
            }
            .navigationBarHidden(true)
            .scrollDismissesKeyboard(.immediately)
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView()
            }
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Neon workout card
struct WorkoutNeonCard: View {
    let workout: WorkoutContainer

    private var exerciseCount: Int { workout.exercises.count }
    private var roundsCount: Int {
        Set(workout.exercises.map { $0.section }).count
    }
    private var accent: Color { workout.workoutColor }

    private var collapsedMinutes: Int? {
        let total = workout.totalSeconds(for: .intermediate)
        guard total > 0 else { return nil }
        return Int(ceil(Double(total) / 60.0))
    }

    private var minutesRange: String? {
        let beg = workout.totalSeconds(for: .beginner)
        let adv = workout.totalSeconds(for: .advanced)
        guard beg > 0 && adv > 0 else { return nil }
        let begM = Int(ceil(Double(beg) / 60.0))
        let advM = Int(ceil(Double(adv) / 60.0))
        if begM == advM { return "\(begM)" }
        return "\(begM)-\(advM)"
    }

    @State private var glowPhase: Double = 0

    var body: some View {
        HStack(spacing: Neon.Space.md) {
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [accent, Neon.violet],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: Neon.Stroke.medium
                    )
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Neon.bg))
                Image(systemName: workout.workoutIcon)
                    .font(Neon.font(18, .semibold))
                    .foregroundColor(accent)
                    .neonGlow(accent, radius: Neon.Glow.icon + 4 * glowPhase, opacity: 0.6 + 0.3 * glowPhase)
            }

            VStack(alignment: .leading, spacing: Neon.Space.xs) {
                Text(workout.name.uppercased())
                    .font(Neon.font(14, .heavy))
                    .foregroundColor(.white)
                    .tracking(0.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                HStack(spacing: 6) {
                    metaPill(value: "\(exerciseCount)", unit: "moves", color: Neon.cyan)
                    if let mins = minutesRange {
                        metaSeparator
                        metaPill(value: mins, unit: "min", color: Neon.amber)
                    }
                }
            }

            Spacer(minLength: 4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, Neon.Space.md)
        .contentShape(Rectangle())
        .neonOutline(color: accent, radius: Neon.Radius.medium, lineWidth: Neon.Stroke.medium, glow: Neon.Glow.card + 8 * glowPhase)
        .drawingGroup()
        .onAppear {
            withAnimation(Neon.Anim.pulse) {
                glowPhase = 1
            }
        }
    }

    private func metaPill(value: String, unit: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(value)
                .font(Neon.font(13, .heavy))
                .foregroundColor(color)
            Text(unit.uppercased())
                .font(Neon.font(10, .bold))
                .foregroundColor(Neon.textMid)
                .tracking(0.5)
        }
    }

    private var metaSeparator: some View {
        Circle()
            .fill(Neon.textLow)
            .frame(width: 2, height: 2)
    }
}

// Press feedback for the main card row
struct PressableCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .brightness(configuration.isPressed ? 0.08 : 0)
            .animation(Neon.Anim.press, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }
}


#Preview {
    WorkoutsView()
}
