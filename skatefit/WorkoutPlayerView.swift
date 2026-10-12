import SwiftUI
import AVFoundation
import AVKit

final class ExercisePlaybackController: ObservableObject {
    let player: AVPlayer?

    init(videoURL: URL?) {
        player = videoURL.map { AVPlayer(url: $0) }
    }

    func restart(completion: @escaping (Bool) -> Void = { _ in }) {
        guard let player else { completion(false); return }

        player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
            if finished { player.play() }
            completion(finished)
        }
    }
}

struct WorkoutPlayerView: View {
    let workoutName: String
    let difficulty: WorkoutDifficulty
    let exercises: [WorkoutExercise]
    let startingIndex: Int
    var videoURLOverride: URL? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var currentExerciseIndex: Int
    @State private var showExerciseDetails = false

    init(workoutName: String, difficulty: WorkoutDifficulty, exercises: [WorkoutExercise], startingIndex: Int, videoURLOverride: URL? = nil) {
        self.workoutName = workoutName
        self.difficulty = difficulty
        self.exercises = exercises
        self.startingIndex = startingIndex
        self.videoURLOverride = videoURLOverride
        self.currentExerciseIndex = startingIndex
    }

    var body: some View {
        ZStack {
            TabView(selection: $currentExerciseIndex) {
                ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                    SingleExercisePageView(
                        exercise: exercise,
                        difficulty: difficulty,
                        index: index,
                        total: exercises.count,
                        showExerciseDetails: $showExerciseDetails,
                        videoURLOverride: videoURLOverride
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea()

            VStack {
                HStack {
                    if exercises.indices.contains(currentExerciseIndex) {
                        sectionBadge(for: exercises[currentExerciseIndex].section)
                    }

                    Spacer()

                    Text(workoutName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer()

                    Button("Done") {
                        dismiss()
                    }
                    .font(.body)
                    .foregroundColor(.white)
                    .accessibilityHint("Closes the workout player")
                }
                .padding(.horizontal)
                .padding(.top, 50)
                .padding(.bottom, 10)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                Spacer()
            }

            if showExerciseDetails && exercises.indices.contains(currentExerciseIndex) {
                exerciseDetailsOverlay(for: exercises[currentExerciseIndex])
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let verticalDistance = value.translation.height
                    let horizontalDistance = abs(value.translation.width)
                    if verticalDistance > 100 && verticalDistance > horizontalDistance * 1.2 {
                        dismiss()
                    }
                }
        )
    }

    private func sectionBadge(for section: String) -> some View {
        Label(section, systemImage: getSectionIcon(section))
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(sectionColor(section).opacity(0.9))
            .clipShape(Capsule())
            .fixedSize()
            .accessibilityLabel("Section: \(section)")
    }

    private func exerciseDetailsOverlay(for exercise: WorkoutExercise) -> some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showExerciseDetails = false
                    }
                }

            VStack(spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(exercise.section, systemImage: getSectionIcon(exercise.section))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(sectionColor(exercise.section))

                        Text(exercise.move)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showExerciseDetails = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Close exercise details")
                }

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Overview")
                                .font(.headline)

                            Text(exercise.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if !exercise.detailedGuideSegments.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Detailed Guide")
                                    .font(.headline)

                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(Array(exercise.detailedGuideSegments.enumerated()), id: \.offset) { index, paragraph in
                                        Label(paragraph, systemImage: "circle.small.fill")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                            .lineSpacing(4)
                                            .fixedSize(horizontal: false, vertical: true)

                                        if index < exercise.detailedGuideSegments.count - 1 {
                                            Divider()
                                        }
                                    }
                                }
                                .padding(14)
                                .background(Color(UIColor.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Instructions")
                                .font(.headline)

                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: difficulty.iconName)
                                    .font(.body)
                                    .foregroundColor(difficulty.color)
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(difficulty.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(difficulty.color)

                                    Text(exercise.instructions(for: difficulty))
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .lineSpacing(3)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.3), radius: 20)
            )
            .padding(20)
            .accessibilityIdentifier("exercise-details-overlay")
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    private func sectionColor(_ section: String) -> Color {
        switch section {
        case "Warm-up": return .orange
        case "Main": return .pink
        case "Cool-down": return .teal
        default: return .gray
        }
    }

    private func getSectionIcon(_ section: String) -> String {
        switch section {
        case "Warm-up": return "thermometer.low"
        case "Main": return "figure.strengthtraining.traditional"
        case "Cool-down": return "leaf"
        default: return "circle"
        }
    }
}

struct SingleExercisePageView: View {
    let exercise: WorkoutExercise
    let difficulty: WorkoutDifficulty
    let index: Int
    let total: Int

    @Binding var showExerciseDetails: Bool
    @StateObject private var playbackController: ExercisePlaybackController

    init(
        exercise: WorkoutExercise,
        difficulty: WorkoutDifficulty,
        index: Int,
        total: Int,
        showExerciseDetails: Binding<Bool>,
        videoURLOverride: URL? = nil
    ) {
        self.exercise = exercise
        self.difficulty = difficulty
        self.index = index
        self.total = total
        self._showExerciseDetails = showExerciseDetails
        self._playbackController = StateObject(wrappedValue: ExercisePlaybackController(videoURL: videoURLOverride ?? exercise.getVideoURL()))
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                WorkoutVideoPlayerView(player: playbackController.player, onLongPress: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showExerciseDetails = true
                    }
                })
                .frame(width: geometry.size.width, height: geometry.size.height)
                .accessibilityIdentifier("exercise-video-\(index)")
                .accessibilityHint("Long press for exercise details")
            }
            .ignoresSafeArea()

            VStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Exercise \(index + 1) of \(total)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .fontWeight(.medium)

                        Spacer()
                    }

                    ProgressView(value: Double(index + 1) / Double(max(total, 1)))
                        .tint(.white)
                        .scaleEffect(y: 2)

                    Text(exercise.move)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black, radius: 2)
                        .padding(.top, 8)
                        .accessibilityIdentifier("exercise-title-\(index)")

                    if playbackController.player != nil {
                        HStack {
                            Spacer()

                            Button {
                                playbackController.restart()
                            } label: {
                                Label("Replay", systemImage: "arrow.counterclockwise")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(0.55))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("replay-video-button")
                            .accessibilityLabel("Replay exercise video")
                            .accessibilityHint("Restarts the current exercise video from the beginning")
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 80)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                Spacer()

                VStack(spacing: 18) {
                    Text(exercise.description)
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .shadow(color: .black, radius: 2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: difficulty.iconName)
                                    .font(.caption)
                                    .accessibilityHidden(true)

                                Text("\(difficulty.displayName) target")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white.opacity(0.9))

                            Text(exercise.instructions(for: difficulty))
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 30)
                    .accessibilityIdentifier("exercise-target-information")
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(difficulty.displayName) target: \(exercise.instructions(for: difficulty))")
                }
                .padding(.bottom, 50)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.2), Color.black.opacity(0.78)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }


}

#Preview {
    WorkoutPlayerView(
        workoutName: "Full Body Workout",
        difficulty: .intermediate,
        exercises: [],
        startingIndex: 0
    )
}
