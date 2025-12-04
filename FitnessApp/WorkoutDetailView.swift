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
    
    // Group exercises by section
    private var exercisesBySection: [String: [WorkoutExercise]] {
        Dictionary(grouping: exercises, by: { $0.section })
    }
    
    private var sections: [String] {
        WorkoutSection.allSections.filter { exercisesBySection[$0] != nil }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header Card
                VStack(alignment: .leading, spacing: 16) {
                    // Title and info
                    HStack {
                        HStack(spacing: 12) {
                            Image(systemName: workoutIcon)
                                .font(.title2)
                                .foregroundColor(workoutColor)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(workoutName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                HStack(spacing: 12) {
                                    Label(difficulty.displayName, systemImage: "star.fill")
                                        .font(.caption)
                                        .foregroundColor(difficulty.color)
                                    
                                    Label("\(exercises.count) exercises", systemImage: "list.bullet")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Duration badge
                        Text("\(totalDuration) min")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(workoutColor.opacity(0.2))
                            .foregroundColor(workoutColor)
                            .cornerRadius(10)
                    }
                    
                    // Start Workout Button - styled like WorkoutsView difficulty buttons
                    HStack {
                        Spacer()
                        Button(action: {
                            workoutPresentation = WorkoutPresentation(exerciseIndex: 0)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(difficulty.color)
                                
                                Text("Start Workout")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(difficulty.color.opacity(0.3), lineWidth: 1)
                            )
                        }
                        Spacer()
                    }
                }
                .padding(16)
                .background(themeManager.isDarkMode ? Color.black : Color(.systemBackground))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(workoutColor.opacity(0.5), lineWidth: 1.5)
                )
                .padding(.horizontal)
                
                // Exercise Sections
                ForEach(sections, id: \.self) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        // Section header
                        HStack {
                            Image(systemName: section.sectionIcon)
                                .font(.title3)
                                .foregroundColor(section.sectionColor)
                            
                            Text(section)
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text("\(exercisesBySection[section]?.count ?? 0) exercises")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        // Exercise cards grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)
                        ], spacing: 10) {
                            ForEach(exercisesBySection[section] ?? [], id: \.id) { exercise in
                                Button(action: {
                                    // Find the actual index in the full exercises array
                                    if let exerciseIndex = exercises.firstIndex(where: { $0.move == exercise.move && $0.section == exercise.section }) {
                                        workoutPresentation = WorkoutPresentation(exerciseIndex: exerciseIndex)
                                    }
                                }) {
                                    WorkoutExerciseRow(exercise: exercise, difficulty: difficulty)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            videoPreloader.startLoading()
        }
        .onDisappear {
            videoPreloader.cleanup()
        }
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
    
    private var totalDuration: Int {
        // Calculate approximate total duration based on exercises
        let warmupCount = exercisesBySection[WorkoutSection.warmUp]?.count ?? 0
        let mainCount = exercisesBySection[WorkoutSection.main]?.count ?? 0
        let cooldownCount = exercisesBySection[WorkoutSection.coolDown]?.count ?? 0
        
        // Rough estimate: 2 min per warm-up/cooldown, 3 min per main exercise
        return (warmupCount * 2) + (mainCount * 3) + (cooldownCount * 2)
    }
    
    // Helper functions for dynamic styling
    
}

struct WorkoutExerciseRow: View {
    let exercise: WorkoutExercise
    let difficulty: WorkoutDifficulty

    @ObservedObject private var thumbnailCache = ThumbnailCache.shared

    private var thumbnail: UIImage? {
        thumbnailCache.thumbnail(for: exercise.videoFile)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background thumbnail or placeholder
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
                                        exercise.section.sectionColor.opacity(0.4),
                                        exercise.section.sectionColor.opacity(0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                .clipped()

                // Dark overlay to push thumbnail to background
                Color.black.opacity(0.4)

                // Title
                VStack {
                    Spacer()

                    Text(exercise.move)
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black, radius: 3)
                        .padding(.horizontal, 6)

                    Spacer()
                    Spacer()
                }

                // Reps at bottom
                VStack {
                    Spacer()

                    Text(exercise.instructions(for: difficulty))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black, radius: 2)
                        .padding(.horizontal, 2)
                        .padding(.bottom, 10)
                }
            }
            .cornerRadius(10)
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