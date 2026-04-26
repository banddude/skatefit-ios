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
                                onDismiss: { dismiss() },
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
                .onAppear {
                    scrolledID = startingIndex
                }
                .onChange(of: scrolledID) { _, newValue in
                    if let newValue = newValue {
                        currentExerciseIndex = newValue
                    }
                }
            }
            .ignoresSafeArea(.all)

            // Exercise Details Overlay
            if showExerciseDetails && currentExerciseIndex < exercises.count {
                exerciseDetailsOverlay(for: exercises[currentExerciseIndex])
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    // If dragged down more than 100 points, dismiss
                    if value.translation.height > 100 {
                        dismiss()
                    }
                }
        )
    }
    
    // MARK: - Exercise Details Overlay
    private func exerciseDetailsOverlay(for exercise: WorkoutExercise) -> some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.8)
                .ignoresSafeArea(.all)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showExerciseDetails = false
                    }
                }
            
            // Details card
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.section)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        Text(exercise.move)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showExerciseDetails = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Exercise details content
                ScrollView {
                    exerciseDetailsContent(exercise: exercise)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.3), radius: 20)
            )
            .padding(20)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
    
    // MARK: - Exercise Details Content
    private func exerciseDetailsContent(exercise: WorkoutExercise) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Brief Description
            VStack(alignment: .leading, spacing: 2) {
                Text("Overview")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(exercise.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Detailed Description (if available)
            if let detailedDescription = exercise.detailedDescription, !detailedDescription.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Detailed Guide")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text(detailedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            // Instructions for current difficulty
            VStack(alignment: .leading, spacing: 2) {
                Text("Instructions (\(difficulty.displayName))")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.caption)
                        .foregroundColor(difficulty.color)
                    
                    Text(exercise.instructions(for: difficulty))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            exerciseAdditionalInfo(exercise: exercise)
        }
    }
    
    // MARK: - Additional Exercise Info
    private func exerciseAdditionalInfo(exercise: WorkoutExercise) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Equipment
            if let equipment = exercise.equipment, !equipment.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Equipment")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fontWeight(.semibold)

                    ForEach(equipment, id: \.self) { item in
                        HStack(spacing: 6) {
                            Image(systemName: "wrench.and.screwdriver")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text(item.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Target Muscles
            if let muscles = exercise.targetMuscles, !muscles.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target Muscles")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fontWeight(.semibold)

                    ForEach(muscles, id: \.self) { muscle in
                        HStack(spacing: 6) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.caption2)
                                .foregroundColor(.red)
                            Text(muscle.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Benefit
            if let benefit = exercise.benefit, !benefit.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Benefit")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fontWeight(.semibold)

                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text(benefit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            // Duration per rep
            if let duration = exercise.durationPerRep, !duration.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duration")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fontWeight(.semibold)

                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text(duration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Exercise Type
            if let types = exercise.exerciseType, !types.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Exercise Type")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fontWeight(.semibold)

                    ForEach(types, id: \.self) { type in
                        HStack(spacing: 6) {
                            Image(systemName: "tag")
                                .font(.caption2)
                                .foregroundColor(.purple)
                            Text(type.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
}

// Simplified version of SingleExercisePlayerView for embedding
struct SingleExercisePageView: View {
    let exercise: WorkoutExercise
    let difficulty: WorkoutDifficulty
    let index: Int
    let total: Int
    let workoutName: String
    let onDismiss: () -> Void
    @Binding var showExerciseDetails: Bool
    let player: AVPlayer?

    private var displayMove: String {
        exercise.move.replacingOccurrences(of: "-", with: " ")
    }

    // Fallback player if preloaded one is nil
    @State private var fallbackPlayer: AVPlayer?

    private var activePlayer: AVPlayer? {
        player ?? fallbackPlayer
    }

    var body: some View {
        ZStack {
            // Full screen background video using preloaded player
            GeometryReader { geometry in
                if let player = activePlayer {
                    WorkoutVideoPlayerView(player: player)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        .onLongPressGesture(minimumDuration: 0.5) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showExerciseDetails.toggle()
                            }
                        }
                } else {
                    Color.black
                        .onLongPressGesture(minimumDuration: 0.5) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showExerciseDetails.toggle()
                            }
                        }
                }
            }
            .ignoresSafeArea(.all)
            .onAppear {
                // Create fallback player if preloaded one is nil
                if player == nil && fallbackPlayer == nil {
                    if let url = exercise.getVideoURL() {
                        let asset = AVURLAsset(url: url)
                        let item = AVPlayerItem(asset: asset)
                        item.preferredForwardBufferDuration = 2.0
                        let newPlayer = AVPlayer(playerItem: item)
                        newPlayer.isMuted = true
                        newPlayer.automaticallyWaitsToMinimizeStalling = false
                        fallbackPlayer = newPlayer
                    }
                }
            }

            // UI overlay that respects safe areas
            VStack {
                // Unified top section: workout name + Done, then progress + exercise title
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(workoutName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Spacer()

                        Button("Done", action: onDismiss)
                            .font(.body)
                            .foregroundColor(.white)
                    }

                    HStack {
                        Text("Exercise \(index + 1) of \(total)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .fontWeight(.medium)
                        Spacer()
                    }

                    ProgressView(value: Double(index + 1) / Double(total))
                        .tint(.white)
                        .scaleEffect(y: 2)

                    Text(displayMove)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black, radius: 2)
                        .padding(.top, 4)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal)
                .padding(.top, 60) // Safe area for status bar / Dynamic Island
                .padding(.bottom, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0.4), Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                Spacer()
                
                // Bottom UI
                VStack(spacing: 20) {
                    Text(exercise.description)
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .shadow(color: .black, radius: 2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    VStack(spacing: 4) {
                        Text(exercise.instructions(for: difficulty))
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(difficulty.color.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4)
                }
                .padding(.bottom, 50) // Extra padding for safe area
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.2), Color.black.opacity(0.75)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            
            
        }
    }
    
}

// MARK: - Video Preloader

/// Preloads all AVPlayers for a workout's exercises
class VideoPreloader: ObservableObject {
    @Published private(set) var isLoading = true
    @Published private(set) var loadedCount = 0

    private var players: [Int: AVPlayer] = [:]
    private let exercises: [WorkoutExercise]
    private var loadTask: Task<Void, Never>?

    init(exercises: [WorkoutExercise]) {
        self.exercises = exercises
    }

    /// Start loading all videos (call from WorkoutDetailView.onAppear)
    func startLoading() {
        guard loadTask == nil else { return }

        loadTask = Task {
            // Load first video synchronously for immediate playback
            if exercises.count > 0, let url = exercises[0].getVideoURL() {
                let player = createPlayer(url: url)
                await MainActor.run {
                    players[0] = player
                    loadedCount = 1
                }
            }

            // Load rest in background
            for index in 1..<exercises.count {
                guard !Task.isCancelled else { break }

                if let url = exercises[index].getVideoURL() {
                    let player = createPlayer(url: url)
                    await MainActor.run {
                        players[index] = player
                        loadedCount = index + 1
                    }
                }
            }

            await MainActor.run {
                isLoading = false
            }
        }
    }

    /// Get player for index (returns nil if not yet loaded)
    func player(for index: Int) -> AVPlayer? {
        players[index]
    }

    /// Create a configured player
    private func createPlayer(url: URL) -> AVPlayer {
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.preferredForwardBufferDuration = 2.0

        let player = AVPlayer(playerItem: playerItem)
        player.isMuted = true
        player.automaticallyWaitsToMinimizeStalling = false

        return player
    }

    /// Clean up all resources
    func cleanup() {
        loadTask?.cancel()
        loadTask = nil

        for (_, player) in players {
            player.pause()
            player.replaceCurrentItem(with: nil)
        }
        players.removeAll()
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