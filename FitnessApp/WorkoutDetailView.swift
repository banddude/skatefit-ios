import SwiftUI
import AVFoundation

struct WorkoutDetailView: View {
    let workoutName: String
    let workoutIcon: String
    let workoutColor: Color
    let difficulty: WorkoutDifficulty
    let exercises: [WorkoutExercise]

    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedExerciseIndex: Int? = nil
    @StateObject private var videoPreloader: VideoPreloader

    private struct WorkoutPresentation: Identifiable {
        let id = UUID()
        let exerciseIndex: Int
    }

    @State private var workoutPresentation: WorkoutPresentation? = nil

    init(workoutName: String, workoutIcon: String, workoutColor: Color, difficulty: WorkoutDifficulty, exercises: [WorkoutExercise]) {
        self.workoutName = workoutName
        self.workoutIcon = workoutIcon
        self.workoutColor = workoutColor
        self.difficulty = difficulty
        self.exercises = exercises
        self._videoPreloader = StateObject(wrappedValue: VideoPreloader(exercises: exercises))
    }

    private var exercisesBySection: [String: [WorkoutExercise]] {
        Dictionary(grouping: exercises, by: { $0.section })
    }

    private var sections: [String] {
        WorkoutSection.allSections.filter { exercisesBySection[$0] != nil }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    workoutColor.opacity(0.22),
                    Color.black.opacity(0.95),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroCard
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    ForEach(sections, id: \.self) { section in
                        sectionView(for: section)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear { videoPreloader.startLoading() }
        .onDisappear { videoPreloader.cleanup() }
        .fullScreenCover(item: $workoutPresentation) { presentation in
            WorkoutPlayerView(
                workoutName: workoutName,
                workoutColor: workoutColor,
                difficulty: difficulty,
                exercises: exercises,
                startingIndex: presentation.exerciseIndex,
                videoPreloader: videoPreloader
            )
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    workoutColor.opacity(0.6),
                                    workoutColor.opacity(0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    Image(systemName: workoutIcon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(workoutName)
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    HStack(spacing: 8) {
                        Label(difficulty.displayName, systemImage: difficultyIcon)
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(difficulty.color.opacity(0.22))
                            )
                            .overlay(
                                Capsule().stroke(difficulty.color.opacity(0.5), lineWidth: 1)
                            )
                            .foregroundColor(difficulty.color)
                    }
                }

                Spacer()
            }

            // Stat strip
            HStack(spacing: 0) {
                statBlock(value: "\(exercises.count)", label: "Exercises", icon: "list.bullet")
                Divider().frame(height: 30).overlay(Color.white.opacity(0.15))
                statBlock(value: "\(totalDuration)", label: "Minutes", icon: "clock.fill")
                Divider().frame(height: 30).overlay(Color.white.opacity(0.15))
                statBlock(value: "\(sections.count)", label: "Sections", icon: "square.stack.3d.up.fill")
            }
            .padding(.vertical, 4)

            // Primary CTA
            Button(action: { workoutPresentation = WorkoutPresentation(exerciseIndex: 0) }) {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text("Start Workout")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [
                            workoutColor,
                            workoutColor.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: workoutColor.opacity(0.45), radius: 14, x: 0, y: 6)
            }
            .buttonStyle(PressableCardButtonStyle())
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(workoutColor.opacity(0.08))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            workoutColor.opacity(0.55),
                            workoutColor.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private func statBlock(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(workoutColor)
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.55))
                .textCase(.uppercase)
                .tracking(0.6)
        }
        .frame(maxWidth: .infinity)
    }

    private var difficultyIcon: String {
        switch difficulty {
        case .beginner: return "leaf.fill"
        case .intermediate: return "flame.fill"
        case .advanced: return "bolt.fill"
        }
    }

    private func sectionView(for section: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(section.sectionColor.opacity(0.22))
                        .frame(width: 32, height: 32)
                    Image(systemName: section.sectionIcon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(section.sectionColor)
                }

                Text(section)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text("\(exercisesBySection[section]?.count ?? 0)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
            }
            .padding(.horizontal, 20)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(exercisesBySection[section] ?? [], id: \.id) { exercise in
                    Button(action: {
                        if let exerciseIndex = exercises.firstIndex(where: { $0.move == exercise.move && $0.section == exercise.section }) {
                            workoutPresentation = WorkoutPresentation(exerciseIndex: exerciseIndex)
                        }
                    }) {
                        WorkoutExerciseRow(exercise: exercise, difficulty: difficulty)
                    }
                    .buttonStyle(PressableCardButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var totalDuration: Int {
        let warmupCount = exercisesBySection[WorkoutSection.warmUp]?.count ?? 0
        let mainCount = exercisesBySection[WorkoutSection.main]?.count ?? 0
        let cooldownCount = exercisesBySection[WorkoutSection.coolDown]?.count ?? 0
        return (warmupCount * 2) + (mainCount * 3) + (cooldownCount * 2)
    }
}

struct WorkoutExerciseRow: View {
    let exercise: WorkoutExercise
    let difficulty: WorkoutDifficulty

    @ObservedObject private var thumbnailCache = ThumbnailCache.shared

    private var thumbnail: UIImage? {
        thumbnailCache.thumbnail(for: exercise.videoFile)
    }

    private var displayMove: String {
        exercise.move.replacingOccurrences(of: "-", with: " ")
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Group {
                    if let thumbnail = thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    } else {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        exercise.section.sectionColor.opacity(0.5),
                                        exercise.section.sectionColor.opacity(0.85)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                .clipped()

                // Bottom-up gradient for legibility
                LinearGradient(
                    colors: [Color.black.opacity(0), Color.black.opacity(0.45), Color.black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack {
                    Spacer()
                    Text(displayMove)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black, radius: 3)
                        .padding(.horizontal, 6)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    Text(exercise.instructions(for: difficulty))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .shadow(color: .black, radius: 2)
                        .padding(.horizontal, 4)
                        .padding(.top, 2)
                        .padding(.bottom, 8)
                        .lineLimit(2)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    NavigationView {
        WorkoutDetailView(
            workoutName: "Full Body Workout",
            workoutIcon: "figure.strengthtraining.traditional",
            workoutColor: .blue,
            difficulty: .intermediate,
            exercises: []
        )
    }
}
