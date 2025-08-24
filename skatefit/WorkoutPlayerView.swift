import SwiftUI
import AVFoundation
import AVKit

struct WorkoutPlayerView: View {
    let workoutName: String
    let difficulty: WorkoutDifficulty
    let exercises: [WorkoutExercise]
    let startingIndex: Int
    
    @Environment(\.dismiss) var dismiss
    @State private var currentExerciseIndex: Int
    
    init(workoutName: String, difficulty: WorkoutDifficulty, exercises: [WorkoutExercise], startingIndex: Int) {
        self.workoutName = workoutName
        self.difficulty = difficulty
        self.exercises = exercises
        self.startingIndex = startingIndex
        self._currentExerciseIndex = State(initialValue: startingIndex)
        print("DEBUG: WorkoutPlayerView init with startingIndex: \(startingIndex)")
    }
    
    var body: some View {
        let _ = print("DEBUG: WorkoutPlayerView body rendering with currentExerciseIndex: \(currentExerciseIndex)")
        ZStack {
            TabView(selection: $currentExerciseIndex) {
                ForEach(exercises.indices, id: \.self) { index in
                    SingleExercisePageView(
                        exercise: exercises[index],
                        difficulty: difficulty,
                        index: index,
                        total: exercises.count
                    )
                    .tag(index)
                    .onAppear {
                        print("DEBUG: Page \(index) appeared")
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea(.all)
            .onAppear {
                print("DEBUG: TabView appeared, should show index: \(currentExerciseIndex)")
            }
            
            // Custom navigation bar overlay
            VStack {
                HStack {
                    // Section badge (same styling as SingleExercisePlayerView)
                    if currentExerciseIndex < exercises.count {
                        Text(exercises[currentExerciseIndex].section)
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(sectionColor(exercises[currentExerciseIndex].section))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .fixedSize()
                            .shadow(radius: 0)
                    }
                    
                    Spacer()
                    
                    // Workout title
                    Text(workoutName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Done button (same styling as SingleExercisePlayerView)
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body)
                    .foregroundColor(.white)
                }
                .padding(.horizontal)
                .padding(.top, 50) // Account for status bar
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
    
    private func sectionColor(_ section: String) -> Color {
        switch section {
        case "Warm-up": return .orange
        case "Main": return .purple
        case "Cool-down": return .teal
        default: return .gray
        }
    }
}

// Simplified version of SingleExercisePlayerView for embedding
struct SingleExercisePageView: View {
    let exercise: WorkoutExercise
    let difficulty: WorkoutDifficulty
    let index: Int
    let total: Int
    
    var body: some View {
        ZStack {
            // Full screen background video using custom player that properly fills
            GeometryReader { geometry in
                if let videoURL = exercise.getVideoURL() {
                    WorkoutVideoPlayerView(player: AVPlayer(url: videoURL))
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                } else {
                    Color.black
                }
            }
            .ignoresSafeArea(.all)
            
            // UI overlay that respects safe areas
            VStack {
                // Top UI with gradient background
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Exercise \(index + 1) of \(total)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    ProgressView(value: Double(index + 1) / Double(total))
                        .tint(.white)
                        .scaleEffect(y: 2)
                    
                    Text(exercise.move)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black, radius: 2)
                        .padding(.top, 8)
                }
                .padding(.horizontal)
                .padding(.top, 80) // Extra padding for safe area and nav bar
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]),
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
                        .lineLimit(3)
                        .padding(.horizontal, 30)
                        .shadow(color: .black, radius: 2)
                    
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.title3)
                            .foregroundColor(.white)
                        
                        Text(exercise.instructions(for: difficulty))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(difficulty.color.opacity(0.9))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.5), radius: 6)
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

#Preview {
    WorkoutPlayerView(
        workoutName: "Full Body Workout",
        difficulty: .intermediate,
        exercises: [],
        startingIndex: 0
    )
}