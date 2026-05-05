import SwiftUI
import AVFoundation
import AVKit

struct WorkoutPlayerView: View {
    let workoutName: String
    let workoutColor: Color
    let difficulty: WorkoutDifficulty
    let exercises: [WorkoutExercise]
    let startingIndex: Int
    @ObservedObject var videoPreloader: VideoPreloader

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @State private var currentExerciseIndex: Int
    @State private var showExerciseDetails = false
    @State private var workoutStartDate = Date()
    @State private var elapsedSeconds: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showHealthKitToast = false

    init(workoutName: String, workoutColor: Color, difficulty: WorkoutDifficulty, exercises: [WorkoutExercise], startingIndex: Int, videoPreloader: VideoPreloader) {
        self.workoutName = workoutName
        self.workoutColor = workoutColor
        self.difficulty = difficulty
        self.exercises = exercises
        self.startingIndex = startingIndex
        self.videoPreloader = videoPreloader
        self._currentExerciseIndex = State(initialValue: startingIndex)
    }

    @State private var scrolledID: Int?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(exercises.indices, id: \.self) { index in
                            SingleExercisePageView(
                                exercise: exercises[index],
                                difficulty: difficulty,
                                index: index,
                                total: exercises.count,
                                workoutName: workoutName,
                                elapsedText: elapsedText,
                                onDismiss: { endWorkoutAndDismiss() },
                                showExerciseDetails: $showExerciseDetails,
                                player: videoPreloader.player(for: index)
                            )
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .id(index)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $scrolledID)
                .onAppear { scrolledID = startingIndex }
                .onChange(of: scrolledID) { _, newValue in
                    if let newValue = newValue {
                        currentExerciseIndex = newValue
                    }
                }
            }
            .ignoresSafeArea(.all)

            if showExerciseDetails && currentExerciseIndex < exercises.count {
                exerciseDetailsOverlay(for: exercises[currentExerciseIndex])
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 100 {
                        endWorkoutAndDismiss()
                    }
                }
        )
        .onAppear {
            workoutStartDate = Date()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                Task { @MainActor in
                    elapsedSeconds += 1
                }
            }
        }
        .overlay {
            if showHealthKitToast {
                healthKitToast
            }
        }
    }

    private var difficultyAccent: Color {
        switch difficulty {
        case .beginner: return Neon.cyan
        case .intermediate: return Neon.magenta
        case .advanced: return Neon.lime
        }
    }

    private var elapsedText: String {
        let mins = Int(elapsedSeconds) / 60
        let secs = Int(elapsedSeconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func endWorkoutAndDismiss() {
        timer?.invalidate()
        timer = nil

        let endDate = Date()
        if elapsedSeconds >= 60 {
            Task {
                await HealthKitManager.shared.saveWorkout(
                    name: workoutName,
                    difficulty: difficulty,
                    exerciseCount: exercises.count,
                    startDate: workoutStartDate,
                    endDate: endDate
                )
                withAnimation { showHealthKitToast = true }
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                dismiss()
            }
        } else {
            dismiss()
        }
    }

    private var healthKitToast: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "heart.circle.fill")
                    .foregroundColor(Neon.lime)
                Text("Saved to Apple Health")
                    .font(Neon.font(12, .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Capsule().fill(Neon.bgDeep).overlay(Capsule().stroke(Neon.lime.opacity(0.5), lineWidth: 1)))
            .neonGlow(Neon.lime, radius: Neon.Glow.card, opacity: 0.4)
            .padding(.bottom, 60)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(Neon.Anim.standard, value: showHealthKitToast)
    }

    private func exerciseDetailsOverlay(for exercise: WorkoutExercise) -> some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea(.all)
                .onTapGesture {
                    withAnimation(Neon.Anim.quick) {
                        showExerciseDetails = false
                    }
                }

            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(exercise.section.uppercased())
                            .font(Neon.font(10, .heavy))
                            .foregroundColor(.white)
                            .tracking(2)
                            .padding(.horizontal, Neon.Space.sm)
                            .padding(.vertical, 3)
                            .overlay(Capsule().stroke(exercise.section.sectionColor.opacity(Neon.Stroke.strong), lineWidth: Neon.Stroke.thin))
                            .background(Capsule().fill(exercise.section.sectionColor.opacity(0.18)))

                        NeonGradientText(
                            text: exercise.move.replacingOccurrences(of: "-", with: " ").uppercased(),
                            size: 18,
                            weight: .heavy,
                            tracking: 1.0
                        )
                        .lineLimit(2)
                    }

                    Spacer()

                    Button(action: {
                        withAnimation(Neon.Anim.quick) {
                            showExerciseDetails = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(Neon.font(14, .heavy))
                            .foregroundColor(.white)
                            .frame(width: Neon.touchTarget, height: Neon.touchTarget)
                            .background(Circle().fill(Neon.bg))
                            .overlay(Circle().stroke(Neon.magenta.opacity(Neon.Stroke.strong), lineWidth: Neon.Stroke.thin))
                            .neonGlow(Neon.magenta, radius: Neon.Glow.card, opacity: Neon.Glow.standard)
                    }
                }
                .padding(Neon.Space.lg)

                Rectangle()
                    .fill(LinearGradient(colors: [Neon.magenta.opacity(0.6), Neon.violet.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 1)

                ScrollView {
                    exerciseDetailsContent(exercise: exercise)
                        .padding(Neon.Space.lg)
                }
            }
            .background(Neon.bg)
            .clipShape(RoundedRectangle(cornerRadius: Neon.Radius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Neon.Radius.large, style: .continuous)
                    .stroke(
                        LinearGradient(colors: [Neon.magenta, Neon.violet], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: Neon.Stroke.medium
                    )
            )
            .shadow(color: Neon.magenta.opacity(0.6), radius: Neon.Glow.hero, x: 0, y: 0)
            .padding(Neon.Space.xl)
        }
        .transition(.opacity)
    }

    private func exerciseDetailsContent(exercise: WorkoutExercise) -> some View {
        VStack(alignment: .leading, spacing: Neon.Space.lg) {
            infoSection(title: "OVERVIEW", icon: "doc.text.fill", color: Neon.cyan) {
                Text(exercise.description)
                    .font(Neon.font(13, .medium))
                    .foregroundColor(Neon.textHi)
                    .lineSpacing(3)
            }

            if let detailedDescription = exercise.detailedDescription, !detailedDescription.isEmpty {
                infoSection(title: "GUIDE", icon: "book.fill", color: Neon.purple) {
                    Text(detailedDescription)
                        .font(Neon.font(13, .medium))
                        .foregroundColor(Neon.textHi)
                        .lineSpacing(3)
                }
            }

            infoSection(title: "INSTRUCTIONS", icon: "list.number", color: difficultyAccent) {
                Text(exercise.instructions(for: difficulty))
                    .font(Neon.font(14, .bold))
                    .foregroundColor(.white)
            }

            exerciseAdditionalInfo(exercise: exercise)
        }
    }

    private func infoSection<C: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: Neon.Space.sm) {
            HStack(spacing: Neon.Space.sm) {
                Image(systemName: icon)
                    .font(Neon.font(11, .heavy))
                    .foregroundColor(color)
                    .neonGlow(color, radius: 6, opacity: Neon.Stroke.strong)
                Text(title)
                    .font(Neon.font(11, .heavy))
                    .foregroundColor(color)
                    .tracking(2)
            }
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Neon.Space.md)
                .background(
                    RoundedRectangle(cornerRadius: Neon.Radius.small, style: .continuous).fill(Neon.panel)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Neon.Radius.small, style: .continuous)
                        .stroke(color.opacity(0.45), lineWidth: Neon.Stroke.thin)
                )
        }
    }

    private func exerciseAdditionalInfo(exercise: WorkoutExercise) -> some View {
        VStack(alignment: .leading, spacing: Neon.Space.lg) {
            if let equipment = exercise.equipment, !equipment.isEmpty {
                infoSection(title: "EQUIPMENT", icon: "wrench.and.screwdriver.fill", color: Neon.amber) {
                    chipFlow(items: equipment, color: Neon.amber)
                }
            }
            if let muscles = exercise.targetMuscles, !muscles.isEmpty {
                infoSection(title: "MUSCLES", icon: "figure.strengthtraining.traditional", color: Neon.magenta) {
                    chipFlow(items: muscles, color: Neon.magenta)
                }
            }
            if let benefit = exercise.benefit, !benefit.isEmpty {
                infoSection(title: "BENEFIT", icon: "star.fill", color: Neon.lime) {
                    Text(benefit)
                        .font(Neon.font(13, .medium))
                        .foregroundColor(Neon.textHi)
                        .lineSpacing(2)
                }
            }
            if let duration = exercise.durationPerRep, !duration.isEmpty {
                infoSection(title: "DURATION", icon: "timer", color: Neon.cyan) {
                    Text(duration)
                        .font(Neon.font(13, .medium))
                        .foregroundColor(Neon.textHi)
                }
            }
            if let types = exercise.exerciseType, !types.isEmpty {
                infoSection(title: "TYPE", icon: "tag.fill", color: Neon.purple) {
                    chipFlow(items: types, color: Neon.purple)
                }
            }
        }
    }

    private func chipFlow(items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                Text(item.uppercased())
                    .font(Neon.font(11, .heavy))
                    .foregroundColor(color)
                    .tracking(1.2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .overlay(Capsule().stroke(color.opacity(0.6), lineWidth: Neon.Stroke.thin))
                    .background(Capsule().fill(color.opacity(0.12)))
            }
        }
    }
}

struct SingleExercisePageView: View {
    let exercise: WorkoutExercise
    let difficulty: WorkoutDifficulty
    let index: Int
    let total: Int
    let workoutName: String
    let elapsedText: String
    let onDismiss: () -> Void
    @Binding var showExerciseDetails: Bool
    let player: AVPlayer?

    private let displayMove: String

    init(exercise: WorkoutExercise, difficulty: WorkoutDifficulty, index: Int, total: Int, workoutName: String, elapsedText: String, onDismiss: @escaping () -> Void, showExerciseDetails: Binding<Bool>, player: AVPlayer?) {
        self.exercise = exercise
        self.difficulty = difficulty
        self.index = index
        self.total = total
        self.workoutName = workoutName
        self.elapsedText = elapsedText
        self.onDismiss = onDismiss
        self._showExerciseDetails = showExerciseDetails
        self.player = player
        self.displayMove = exercise.move.replacingOccurrences(of: "-", with: " ")
        self._fallbackPlayer = State(initialValue: nil)
        self._isLoadingVideo = State(initialValue: false)
    }

    private var difficultyAccent: Color {
        switch difficulty {
        case .beginner: return Neon.cyan
        case .intermediate: return Neon.magenta
        case .advanced: return Neon.lime
        }
    }

    @State private var fallbackPlayer: AVPlayer?
    @State private var isLoadingVideo = false

    private var activePlayer: AVPlayer? {
        player ?? fallbackPlayer
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                if let player = activePlayer {
                    WorkoutVideoPlayerView(player: player)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        .onLongPressGesture(minimumDuration: 0.5) {
                            withAnimation(Neon.Anim.standard) {
                                showExerciseDetails.toggle()
                            }
                        }
                } else {
                    AppIconVideoPlaceholder(showSpinner: isLoadingVideo)
                        .onLongPressGesture(minimumDuration: 0.5) {
                            withAnimation(Neon.Anim.standard) {
                                showExerciseDetails.toggle()
                            }
                        }
                }
            }
            .ignoresSafeArea(.all)
            .onAppear {
                if player == nil && fallbackPlayer == nil {
                    isLoadingVideo = true
                    Task {
                        if let url = await VideoService.shared.getVideoURLAsync(for: exercise.videoFileName) {
                            let asset = AVURLAsset(url: url)
                            let item = AVPlayerItem(asset: asset)
                            item.preferredForwardBufferDuration = 2.0
                            let newPlayer = AVPlayer(playerItem: item)
                            newPlayer.isMuted = true
                            newPlayer.automaticallyWaitsToMinimizeStalling = false
                            fallbackPlayer = newPlayer
                        }
                        isLoadingVideo = false
                    }
                }
            }

            VStack(spacing: 0) {
                // TOP HUD
                VStack(spacing: 14) {
                    HStack(alignment: .center) {
                        Text(workoutName.uppercased())
                            .font(Neon.font(12, .heavy))
                            .foregroundColor(.white)
                            .tracking(2)
                            .padding(.horizontal, Neon.Space.md)
                            .padding(.vertical, 6)
                            .overlay(Capsule().stroke(Neon.magenta.opacity(0.6), lineWidth: Neon.Stroke.thin))
                            .background(Capsule().fill(Neon.bg.opacity(0.6)))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Text(elapsedText)
                            .font(Neon.font(12, .heavy))
                            .foregroundColor(Neon.cyan)
                            .monospacedDigit()
                            .padding(.horizontal, Neon.Space.sm)
                            .padding(.vertical, 6)
                            .overlay(Capsule().stroke(Neon.cyan.opacity(0.4), lineWidth: Neon.Stroke.thin))
                            .background(Capsule().fill(Neon.bg.opacity(0.6)))

                        Spacer()

                        Button(action: onDismiss) {
                            HStack(spacing: Neon.Space.xs) {
                                Image(systemName: "xmark")
                                    .font(Neon.font(11, .heavy))
                                Text("EXIT")
                                    .font(Neon.font(11, .heavy))
                                    .tracking(1.5)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, Neon.Space.md)
                            .padding(.vertical, Neon.Space.sm)
                            .background(
                                Capsule().fill(
                                    LinearGradient(colors: [Neon.magenta, Neon.violet], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                            )
                            .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: Neon.Stroke.thin))
                            .shadow(color: Neon.magenta.opacity(0.6), radius: Neon.Glow.card, x: 0, y: 0)
                            .frame(minWidth: Neon.touchTarget, minHeight: Neon.touchTarget)
                        }
                    }

                    HStack(spacing: 10) {
                        Text("\(index + 1)/\(total)")
                            .font(Neon.font(12, .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, Neon.Space.xs)
                            .background(Capsule().fill(Neon.bg.opacity(0.7)))
                            .overlay(Capsule().stroke(difficultyAccent.opacity(Neon.Stroke.strong), lineWidth: Neon.Stroke.thin))

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: Neon.Space.sm)
                                    .overlay(
                                        Capsule().stroke(Color.white.opacity(0.15), lineWidth: Neon.Stroke.thin)
                                    )
                                Capsule()
                                    .fill(
                                        LinearGradient(colors: [difficultyAccent, Neon.magenta], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .frame(width: max(Neon.Space.sm, geo.size.width * CGFloat(index + 1) / CGFloat(total)), height: Neon.Space.sm)
                                    .shadow(color: difficultyAccent.opacity(Neon.Stroke.strong), radius: Neon.Space.sm, x: 0, y: 0)
                            }
                        }
                        .frame(height: Neon.Space.sm)
                    }

                    Text(displayMove.uppercased())
                        .font(Neon.font(22, .heavy))
                        .foregroundColor(.white)
                        .tracking(1.2)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .shadow(color: .black, radius: Neon.Space.xs, x: 0, y: 2)
                        .padding(.top, 6)
                }
                .padding(.horizontal, Neon.Space.lg)
                .padding(.top, 56)
                .padding(.bottom, 14)
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0.7), Color.black.opacity(0.3), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                Spacer()

                // BOTTOM HUD
                Text(exercise.instructions(for: difficulty))
                    .font(Neon.font(15, .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .shadow(color: .black, radius: 3)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: Neon.Radius.medium, style: .continuous).fill(Neon.bg.opacity(0.8))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Neon.Radius.medium, style: .continuous)
                            .stroke(difficultyAccent.opacity(0.55), lineWidth: Neon.Stroke.thin)
                    )
                    .shadow(color: difficultyAccent.opacity(0.4), radius: Neon.Glow.card, x: 0, y: 0)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 38)
                .padding(.top, Neon.Space.xxl)
                .background(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.4), Color.black.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }
}

class VideoPreloader: ObservableObject {
    @Published private(set) var isLoading = true
    @Published private(set) var loadedCount = 0

    private var players: [Int: AVPlayer] = [:]
    private var videoURLs: [Int: URL] = [:]
    private let exercises: [WorkoutExercise]
    private var loadTask: Task<Void, Never>?

    init(exercises: [WorkoutExercise]) {
        self.exercises = exercises
    }

    func startLoading() {
        guard loadTask == nil else { return }

        loadTask = Task {
            // Load first video with priority
            if exercises.count > 0 {
                if let url = await VideoService.shared.getVideoURLAsync(for: exercises[0].videoFileName) {
                    let player = createPlayer(url: url)
                    await MainActor.run {
                        self.videoURLs[0] = url
                        players[0] = player
                        loadedCount = 1
                    }
                }
            }

            // Load remaining videos in parallel (max 4 concurrent)
            guard !Task.isCancelled else {
                await MainActor.run { isLoading = false }
                return
            }

            let remaining = Array(1..<exercises.count)
            let batchSize = 4
            for batchStart in stride(from: 0, to: remaining.count, by: batchSize) {
                guard !Task.isCancelled else { break }
                let batch = remaining[batchStart..<min(batchStart + batchSize, remaining.count)]
                await withTaskGroup(of: (Int, AVPlayer?, URL?).self) { group in
                    for index in batch {
                        let fileName = exercises[index].videoFileName
                        group.addTask {
                            guard !Task.isCancelled else { return (index, nil, nil) }
                            if let url = await VideoService.shared.getVideoURLAsync(for: fileName) {
                                return (index, self.createPlayer(url: url), url)
                            }
                            return (index, nil, nil)
                        }
                    }
                    for await (index, player, url) in group {
                        guard let player = player else { continue }
                        await MainActor.run {
                            if let url = url { self.videoURLs[index] = url }
                            self.players[index] = player
                            self.loadedCount = self.players.count
                        }
                    }
                }
            }

            await MainActor.run { isLoading = false }
        }
    }

    func player(for index: Int) -> AVPlayer? {
        players[index]
    }

    func videoURL(for index: Int) -> URL? {
        videoURLs[index]
    }

    private func createPlayer(url: URL) -> AVPlayer {
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.preferredForwardBufferDuration = 2.0

        let player = AVPlayer(playerItem: playerItem)
        player.isMuted = true
        player.automaticallyWaitsToMinimizeStalling = false

        return player
    }

    func cleanup() {
        loadTask?.cancel()
        loadTask = nil

        for (_, player) in players {
            player.pause()
            player.replaceCurrentItem(with: nil)
        }
        players.removeAll()
        videoURLs.removeAll()
    }

    deinit {
        cleanup()
    }
}

#Preview {
    WorkoutPlayerView(
        workoutName: "Full Body Workout",
        workoutColor: .blue,
        difficulty: .intermediate,
        exercises: [],
        startingIndex: 0,
        videoPreloader: VideoPreloader(exercises: [])
    )
}
