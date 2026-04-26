import SwiftUI

struct WorkoutsView: View {
    @EnvironmentObject var contentManager: ContentManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showOnboarding = false
    @State private var expandedWorkoutId: UUID? = nil

    private var headerView: some View {
        HStack(alignment: .center, spacing: 14) {
            if let appIcon = AppConfig.getAppIcon() {
                Image(uiImage: appIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(AppConfig.appName)
                    .font(.system(size: 32, weight: .heavy, design: .default))
                    .foregroundColor(themeManager.isDarkMode ? .white : .primary)
                    .onLongPressGesture {
                        contentManager.clearCache()
                    }

                Text("Skate. Train. Recover.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(1.2)
            }

            Spacer()

            Button(action: { showOnboarding = true }) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.yellow)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var workoutsList: some View {
        VStack(spacing: 14) {
            ForEach(contentManager.workoutContainers) { workout in
                let isExpanded = expandedWorkoutId == workout.id
                WorkoutDifficultyCard(
                    workout: workout,
                    isExpanded: isExpanded,
                    onTap: toggleExpansion(for: workout)
                )
            }
        }
        .padding(.horizontal, 20)
    }

    private func toggleExpansion(for workout: WorkoutContainer) -> () -> Void {
        return {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                if expandedWorkoutId == workout.id {
                    expandedWorkoutId = nil
                } else {
                    expandedWorkoutId = workout.id
                }
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Subtle ambient gradient background
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(red: 0.04, green: 0.03, blue: 0.08),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        headerView

                        if contentManager.workoutContainers.isEmpty {
                            if contentManager.isInitializing {
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .controlSize(.large)
                                        .tint(.white)
                                    Text("Loading workouts…")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 80)
                            } else if let error = contentManager.initializationError {
                                VStack(spacing: 14) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.orange)
                                    Text("Unable to load workouts")
                                        .font(.headline)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                    Button("Retry") {
                                        Task { await contentManager.initializeContent() }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.white)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 60)
                            } else {
                                Text("No workouts available")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 50)
                            }
                        } else {
                            workoutsList
                        }
                        Spacer(minLength: 20)
                    }
                    .padding(.vertical, 12)
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
            .navigationBarHidden(true)
            .scrollDismissesKeyboard(.immediately)
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView()
            }
        }
    }
}



// MARK: - Workout Difficulty Card
struct WorkoutDifficultyCard: View {
    let workout: WorkoutContainer
    let isExpanded: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    private var exerciseCount: Int { workout.exercises.count }

    private var estimatedDuration: String {
        let warmupCount = workout.exercises.filter { $0.section == "Warm-up" }.count
        let mainCount = workout.exercises.filter { $0.section == "Main" }.count
        let cooldownCount = workout.exercises.filter { $0.section == "Cool-down" }.count
        let totalMinutes = (warmupCount * 2) + (mainCount * 3) + (cooldownCount * 2)
        return "\(max(totalMinutes - 5, 1))-\(totalMinutes + 5) min"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onTap) {
                HStack(spacing: 14) {
                    // Icon in colored circle
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        workout.workoutColor.opacity(0.45),
                                        workout.workoutColor.opacity(0.18)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 46, height: 46)
                        Image(systemName: workout.workoutIcon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(workout.workoutColor)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(workout.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 10, weight: .semibold))
                            Text("\(exerciseCount) exercises")
                                .font(.system(size: 12, weight: .medium))

                            Text("·")
                                .font(.system(size: 12, weight: .medium))

                            Image(systemName: "clock")
                                .font(.system(size: 10, weight: .semibold))
                            Text(estimatedDuration)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableCardButtonStyle())

            if isExpanded {
                HStack(spacing: 10) {
                    ForEach(WorkoutDifficulty.allCases, id: \.self) { difficulty in
                        NavigationLink(destination: WorkoutDetailView(
                            workoutName: workout.name,
                            workoutIcon: workout.workoutIcon,
                            workoutColor: workout.workoutColor,
                            difficulty: difficulty,
                            exercises: workout.exercises
                        )) {
                            HStack(spacing: 6) {
                                Image(systemName: difficultyIcon(for: difficulty))
                                    .font(.system(size: 11, weight: .bold))
                                Text(difficulty.displayName)
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(
                                LinearGradient(
                                    colors: [
                                        difficulty.color.opacity(0.85),
                                        difficulty.color.opacity(0.55)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .shadow(color: difficulty.color.opacity(0.35), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            workout.workoutColor.opacity(0.18),
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
                            workout.workoutColor.opacity(0.55),
                            workout.workoutColor.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: workout.workoutColor.opacity(isExpanded ? 0.25 : 0.12), radius: isExpanded ? 14 : 8, x: 0, y: 4)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: isExpanded)
    }

    private func difficultyIcon(for difficulty: WorkoutDifficulty) -> String {
        switch difficulty {
        case .beginner: return "leaf.fill"
        case .intermediate: return "flame.fill"
        case .advanced: return "bolt.fill"
        }
    }
}

// Press feedback for the main card row
struct PressableCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}


#Preview {
    WorkoutsView()
}
