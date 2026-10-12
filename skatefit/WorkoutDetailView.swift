import SwiftUI

struct WorkoutDetailView: View {
    let workoutName: String
    let difficulty: WorkoutDifficulty
    let exercises: [WorkoutExercise]

    private struct WorkoutPresentation: Identifiable {
        let id = UUID()
        let exerciseIndex: Int
    }

    @State private var workoutPresentation: WorkoutPresentation?

    private var exercisesBySection: [String: [WorkoutExercise]] {
        Dictionary(grouping: exercises, by: { $0.section })
    }

    private var sections: [String] {
        ["Warm-up", "Main", "Cool-down"].filter { exercisesBySection[$0] != nil }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard

                ForEach(sections, id: \.self) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            WorkoutSectionBadge(section: section)

                            Spacer()

                            Text("\(exercisesBySection[section]?.count ?? 0) exercises")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)

                        VStack(spacing: 8) {
                            ForEach(exercisesBySection[section] ?? []) { exercise in
                                Button {
                                    if let exerciseIndex = exercises.firstIndex(where: {
                                        $0.move == exercise.move && $0.section == exercise.section
                                    }) {
                                        workoutPresentation = WorkoutPresentation(exerciseIndex: exerciseIndex)
                                    }
                                } label: {
                                    WorkoutExerciseRow(
                                        exercise: exercise,
                                        difficulty: difficulty,
                                        section: section
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Opens this exercise in the workout player")
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
            WorkoutPlayerView(
                workoutName: workoutName,
                difficulty: difficulty,
                exercises: exercises,
                startingIndex: presentation.exerciseIndex
            )
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                HStack(spacing: 12) {
                    WorkoutIdentityIcon(
                        systemName: workoutIcon,
                        color: workoutIdentityColor
                    )

                    VStack(alignment: .leading, spacing: 7) {
                        Text(workoutName)
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 8) {
                            DifficultyBadge(difficulty: difficulty)

                            Label("\(exercises.count) exercises", systemImage: "list.bullet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Label("\(totalDuration) min", systemImage: "clock")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(Capsule())
                    .accessibilityElement(children: .combine)
            }

            Button {
                workoutPresentation = WorkoutPresentation(exerciseIndex: 0)
            } label: {
                Label("Start Workout", systemImage: "play.fill")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.borderedProminent)
            .disabled(exercises.isEmpty)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(workoutIdentityColor.opacity(0.28), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private var totalDuration: Int {
        let warmupCount = exercisesBySection["Warm-up"]?.count ?? 0
        let mainCount = exercisesBySection["Main"]?.count ?? 0
        let cooldownCount = exercisesBySection["Cool-down"]?.count ?? 0
        return (warmupCount * 2) + (mainCount * 3) + (cooldownCount * 2)
    }

    private var workoutIcon: String {
        switch workoutName {
        case "Full Body Workout": return "figure.strengthtraining.traditional"
        case "Mobility & Activation": return "figure.flexibility"
        case "Strength": return "dumbbell.fill"
        case "Core & Stability": return "figure.core.training"
        default: return "figure.run"
        }
    }

    private var workoutIdentityColor: Color {
        switch workoutName {
        case "Full Body Workout": return .cyan
        case "Mobility & Activation": return .orange
        case "Strength": return .pink
        case "Core & Stability": return .teal
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
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "play.circle.fill")
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .accessibilityHidden(true)

                Text(exercise.move)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }

            HStack(alignment: .top, spacing: 8) {
                DifficultyBadge(difficulty: difficulty)

                Text(exercise.instructions(for: difficulty))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text(exercise.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.14), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(exercise.move), \(section), \(difficulty.displayName), \(exercise.instructions(for: difficulty))"
        )
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
