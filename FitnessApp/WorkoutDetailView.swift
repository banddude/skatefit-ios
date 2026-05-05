import SwiftUI
import AVFoundation

struct WorkoutDetailView: View {
    let workoutName: String
    let workoutIcon: String
    let workoutColor: Color
    let exercises: [WorkoutExercise]

    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedExerciseIndex: Int? = nil
    @State private var difficulty: WorkoutDifficulty = .intermediate
    @StateObject private var videoPreloader: VideoPreloader

    private struct WorkoutPresentation: Identifiable {
        let id = UUID()
        let exerciseIndex: Int
    }

    @State private var workoutPresentation: WorkoutPresentation? = nil

    init(workoutName: String, workoutIcon: String, workoutColor: Color, exercises: [WorkoutExercise], initialDifficulty: WorkoutDifficulty = .intermediate) {
        self.workoutName = workoutName
        self.workoutIcon = workoutIcon
        self.workoutColor = workoutColor
        self.exercises = exercises
        self._difficulty = State(initialValue: initialDifficulty)
        self._videoPreloader = StateObject(wrappedValue: VideoPreloader(exercises: exercises))
    }

    private var difficulties: [WorkoutDifficulty] { WorkoutDifficulty.allCases }
    private var selectedIdx: Int { difficulties.firstIndex(of: difficulty) ?? 1 }

    private func difficultyColor(_ d: WorkoutDifficulty) -> Color {
        switch d {
        case .beginner: return Neon.cyan
        case .intermediate: return Neon.magenta
        case .advanced: return Neon.lime
        }
    }

    private var exercisesBySection: [String: [WorkoutExercise]] {
        Dictionary(grouping: exercises, by: { $0.section })
    }

    private var sections: [String] {
        WorkoutSection.allSections.filter { exercisesBySection[$0] != nil }
    }

    private var difficultyAccent: Color {
        switch difficulty {
        case .beginner: return Neon.cyan
        case .intermediate: return Neon.magenta
        case .advanced: return Neon.lime
        }
    }

    private var totalMinutes: String {
        let total = exercises.reduce(0) { $0 + $1.totalSeconds(for: difficulty) }
        if total == 0 { return "—" }
        return "\(Int(ceil(Double(total) / 60.0)))"
    }

    var body: some View {
        ZStack {
            NeonGridFloor()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    heroCard
                        .padding(.horizontal, 18)
                        .padding(.top, Neon.Space.sm)

                    ForEach(sections, id: \.self) { section in
                        sectionView(for: section)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            videoPreloader.startLoading()
            // Prioritize this workout's videos in the download queue
            let videos = exercises.compactMap { $0.videoFile }
            VideoDownloadQueue.shared.prioritize(fileNames: videos)
        }
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
        VStack(alignment: .leading, spacing: Neon.Space.lg) {
            HStack(alignment: .center, spacing: Neon.Space.md) {
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [workoutColor, Neon.violet],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: Neon.Stroke.medium
                        )
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(Neon.bg))
                    Image(systemName: workoutIcon)
                        .font(Neon.font(22, .semibold))
                        .foregroundColor(workoutColor)
                        .neonGlow(workoutColor, radius: Neon.Glow.icon, opacity: Neon.Glow.strong)
                }

                VStack(alignment: .leading, spacing: Neon.Space.xs) {
                    Text(workoutName.uppercased())
                        .font(Neon.font(20, .heavy))
                        .foregroundColor(.white)
                        .tracking(1.2)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    HStack(spacing: Neon.Space.sm) {
                        metaPill(value: "\(exercises.count)", unit: "moves", color: Neon.cyan)
                        metaSeparator
                        metaPill(value: totalMinutes, unit: "min", color: Neon.amber)
                    }
                }

                Spacer()
            }

            difficultySlider

            Button(action: { workoutPresentation = WorkoutPresentation(exerciseIndex: 0) }) {
                HStack(spacing: Neon.Space.sm) {
                    Image(systemName: "play.fill")
                        .font(Neon.font(16, .heavy))
                    Text("START")
                        .tracking(2)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(NeonButtonStyle(color: workoutColor))
        }
        .padding(.vertical, Neon.Space.sm)
    }

    private func metaPill(value: String, unit: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(value)
                .font(Neon.font(14, .heavy))
                .foregroundColor(color)
            Text(unit.uppercased())
                .font(Neon.font(10, .bold))
                .foregroundColor(Neon.textMid)
                .tracking(0.5)
        }
    }

    private var metaSeparator: some View {
        Circle().fill(Neon.textLow).frame(width: 2, height: 2)
    }

    private var difficultyIcon: String {
        switch difficulty {
        case .beginner: return "leaf.fill"
        case .intermediate: return "flame.fill"
        case .advanced: return "bolt.fill"
        }
    }

    private var difficultySlider: some View {
        VStack(spacing: Neon.Space.sm) {
            Text(difficulty.displayName.uppercased())
                .font(Neon.font(13, .heavy))
                .foregroundColor(difficultyAccent)
                .tracking(2)
                .neonGlow(difficultyAccent, radius: Neon.Glow.icon, opacity: Neon.Glow.muted)
                .animation(Neon.Anim.press, value: difficulty)

            GeometryReader { geo in
                let thumbSize: CGFloat = 28
                let trackWidth = max(geo.size.width - thumbSize, 1)
                let segs = max(difficulties.count - 1, 1)
                let step = trackWidth / CGFloat(segs)
                let activeColor = difficultyAccent

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Neon.panel)
                        .frame(height: Neon.Space.sm)
                        .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: Neon.Stroke.thin))
                        .padding(.horizontal, thumbSize / 2)

                    Capsule()
                        .fill(activeColor.opacity(0.55))
                        .frame(width: max(0, step * CGFloat(selectedIdx)) + thumbSize, height: Neon.Space.sm)
                        .neonGlow(activeColor, radius: Neon.Glow.icon, opacity: Neon.Glow.muted)

                    ForEach(0..<difficulties.count, id: \.self) { idx in
                        Circle()
                            .fill(idx <= selectedIdx ? activeColor : Color.white.opacity(0.35))
                            .frame(width: 6, height: 6)
                            .offset(x: thumbSize / 2 + step * CGFloat(idx) - 3)
                    }

                    Image(systemName: difficultyIcon)
                        .font(Neon.font(13, .heavy))
                        .foregroundColor(.white)
                        .frame(width: thumbSize, height: thumbSize)
                        .background(Circle().fill(activeColor))
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .neonGlow(activeColor, radius: Neon.Glow.hero, opacity: 0.85)
                        .offset(x: step * CGFloat(selectedIdx))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedIdx)
                }
                .frame(maxWidth: .infinity)
                .frame(height: thumbSize)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let x = value.location.x - thumbSize / 2
                            let raw = x / step
                            let idx = max(0, min(difficulties.count - 1, Int(raw.rounded())))
                            if difficulties[idx] != difficulty {
                                difficulty = difficulties[idx]
                            }
                        }
                )
            }
            .frame(height: 28)
        }
    }

    private func sectionView(for section: String) -> some View {
        VStack(alignment: .leading, spacing: Neon.Space.md) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(section.sectionColor.opacity(0.7), lineWidth: Neon.Stroke.medium)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Neon.bg))
                    Image(systemName: section.sectionIcon)
                        .font(Neon.font(13, .semibold))
                        .foregroundColor(section.sectionColor)
                        .neonGlow(section.sectionColor, radius: Neon.Glow.icon, opacity: Neon.Glow.standard)
                }

                Text(section.uppercased())
                    .font(Neon.font(15, .heavy))
                    .foregroundColor(.white)
                    .tracking(1.5)

                Spacer()

                Text("× \(exercisesBySection[section]?.count ?? 0)")
                    .font(Neon.font(12, .heavy))
                    .foregroundColor(Neon.amber)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .overlay(Capsule().stroke(Neon.amber.opacity(0.7), lineWidth: Neon.Stroke.thin))
                    .background(Capsule().fill(Neon.amber.opacity(0.12)))
            }
            .padding(.horizontal, 18)

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
            .padding(.horizontal, 18)
        }
    }

}

struct WorkoutExerciseRow: View {
    let exercise: WorkoutExercise
    let difficulty: WorkoutDifficulty

    @ObservedObject private var thumbnailCache = ThumbnailCache.shared
    @State private var resolvedVideoURL: URL?

    private let displayMove: String

    init(exercise: WorkoutExercise, difficulty: WorkoutDifficulty) {
        self.exercise = exercise
        self.difficulty = difficulty
        self.displayMove = exercise.move.replacingOccurrences(of: "-", with: " ")
    }

    private var thumbnail: UIImage? {
        thumbnailCache.thumbnail(for: exercise.videoFile)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Layer 1: static thumbnail (always visible as background)
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    AppIconVideoPlaceholder(compact: true)
                }

                // Layer 2: looping video fades in on top when ready
                if let videoURL = resolvedVideoURL {
                    LoopingVideoThumbnail(url: videoURL)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            LinearGradient(
                colors: [Color.black.opacity(0.0), Color.black.opacity(0.6), Color.black.opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack {
                Spacer()
                Text(displayMove.uppercased())
                    .font(Neon.font(11, .heavy))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black, radius: 2)
                    .padding(.horizontal, 4)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .tracking(0.5)

                Text(exercise.instructions(for: difficulty))
                    .font(Neon.font(9, .bold))
                    .foregroundColor(Neon.cyan)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black, radius: 2)
                    .padding(.horizontal, 4)
                    .padding(.top, 2)
                    .padding(.bottom, 8)
                    .lineLimit(2)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(exercise.section.sectionColor.opacity(0.6), lineWidth: Neon.Stroke.thin)
        )
        .shadow(color: exercise.section.sectionColor.opacity(0.35), radius: Neon.Glow.icon, x: 0, y: 0)
        .aspectRatio(9/16, contentMode: .fit)
        .task(id: exercise.videoFileName) {
            resolvedVideoURL = await VideoService.shared.getVideoURLAsync(for: exercise.videoFileName)
        }
    }
}

#Preview {
    NavigationView {
        WorkoutDetailView(
            workoutName: "Full Body Workout",
            workoutIcon: "figure.strengthtraining.traditional",
            workoutColor: .blue,
            exercises: []
        )
    }
}
