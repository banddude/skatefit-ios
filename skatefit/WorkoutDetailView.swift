import SwiftUI

struct WorkoutDetailView: View {
    let workoutName: String
    let difficulty: WorkoutDifficulty
    let exercises: [WorkoutExercise]
    
    @State private var selectedExerciseIndex: Int? = nil
    
    private struct WorkoutPresentation: Identifiable {
        let id = UUID()
        let exerciseIndex: Int
    }
    
    @State private var workoutPresentation: WorkoutPresentation? = nil
    
    // Group exercises by section
    private var exercisesBySection: [String: [WorkoutExercise]] {
        Dictionary(grouping: exercises, by: { $0.section })
    }
    
    private var sections: [String] {
        ["Warm-up", "Main", "Cool-down"].filter { exercisesBySection[$0] != nil }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header Card
                VStack(alignment: .leading, spacing: 16) {
                    // Title and info
                    HStack {
                        HStack(spacing: 12) {
                            Image(systemName: getWorkoutIcon(workoutName))
                                .font(.title2)
                                .foregroundColor(getWorkoutColor(workoutName))
                            
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
                            .background(getWorkoutColor(workoutName).opacity(0.2))
                            .foregroundColor(getWorkoutColor(workoutName))
                            .cornerRadius(10)
                    }
                    
                    // Start Workout Button - styled like WorkoutsView difficulty buttons
                    Button(action: {
                        workoutPresentation = WorkoutPresentation(exerciseIndex: 0)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.body)
                                .foregroundColor(difficulty.color)
                            
                            Text("Start Workout")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(difficulty.color.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(getWorkoutColor(workoutName).opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal)
                
                // Exercise Sections
                ForEach(sections, id: \.self) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        // Section header
                        HStack {
                            Image(systemName: getSectionIcon(section))
                                .font(.title3)
                                .foregroundColor(getSectionColor(section))
                            
                            Text(section)
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text("\(exercisesBySection[section]?.count ?? 0) exercises")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        // Exercise cards
                        VStack(spacing: 8) {
                            ForEach(Array(exercisesBySection[section]?.enumerated() ?? [].enumerated()), id: \.element.id) { sectionIndex, exercise in
                                Button(action: {
                                    // Find the actual index in the full exercises array
                                    if let exerciseIndex = exercises.firstIndex(where: { $0.move == exercise.move && $0.section == exercise.section }) {
                                        print("DEBUG: Tapped exercise: \(exercise.move)")
                                        print("DEBUG: Found at index: \(exerciseIndex)")
                                        workoutPresentation = WorkoutPresentation(exerciseIndex: exerciseIndex)
                                    }
                                }) {
                                    WorkoutExerciseRow(exercise: exercise, difficulty: difficulty, section: section)
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
        .fullScreenCover(item: $workoutPresentation) { presentation in
            let _ = print("DEBUG: fullScreenCover creating WorkoutPlayerView with index: \(presentation.exerciseIndex)")
            WorkoutPlayerView(
                workoutName: workoutName,
                difficulty: difficulty,
                exercises: exercises,
                startingIndex: presentation.exerciseIndex
            )
        }
    }
    
    private var totalDuration: Int {
        // Calculate approximate total duration based on exercises
        let warmupCount = exercisesBySection["Warm-up"]?.count ?? 0
        let mainCount = exercisesBySection["Main"]?.count ?? 0
        let cooldownCount = exercisesBySection["Cool-down"]?.count ?? 0
        
        // Rough estimate: 2 min per warm-up/cooldown, 3 min per main exercise
        return (warmupCount * 2) + (mainCount * 3) + (cooldownCount * 2)
    }
    
    // Helper functions for dynamic styling
    private func getWorkoutIcon(_ workoutName: String) -> String {
        switch workoutName {
        case "Full Body Workout": return "figure.strengthtraining.traditional"
        case "Mobility & Activation": return "figure.flexibility"
        case "Strength": return "dumbbell.fill"
        case "Core & Stability": return "figure.core.training"
        default: return "figure.run"
        }
    }
    
    private func getWorkoutColor(_ workoutName: String) -> Color {
        switch workoutName {
        case "Full Body Workout": return .blue
        case "Mobility & Activation": return .orange
        case "Strength": return .purple
        case "Core & Stability": return .teal
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
    
    private func getSectionColor(_ section: String) -> Color {
        switch section {
        case "Warm-up": return .orange
        case "Main": return .purple
        case "Cool-down": return .teal
        default: return .gray
        }
    }
}

struct WorkoutExerciseRow: View {
    let exercise: WorkoutExercise
    let difficulty: WorkoutDifficulty
    let section: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Exercise title with play icon
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "play.circle")
                        .font(.title3)
                        .foregroundColor(getSectionColor(section))
                    
                    Text(exercise.move)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Instructions
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(difficulty.color)
                    .frame(width: 16)
                
                Text(exercise.instructions(for: difficulty))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(difficulty.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Description
            Text(exercise.description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(getSectionColor(section).opacity(0.2), lineWidth: 1)
        )
    }
    
    private func getSectionColor(_ section: String) -> Color {
        switch section {
        case "Warm-up": return .orange
        case "Main": return .purple
        case "Cool-down": return .teal
        default: return .gray
        }
    }
}

#Preview {
    NavigationView {
        WorkoutDetailView(
            workoutName: "Full Body Workout",
            difficulty: .intermediate,
            exercises: []
        )
    }
}