import SwiftUI

struct WorkoutsView: View {
    @StateObject private var viewModel = WorkoutsViewModel()
    @State private var showOnboarding = false

    let columns = [GridItem(.adaptive(minimum: 300), spacing: 15)]
    
    // Load workouts from JSON
    @State private var workoutContainers: [WorkoutContainer] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    // Header
                    HStack {
                        Text("Workouts")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: {
                            showOnboarding = true
                        }) {
                            Image(systemName: "lightbulb")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Main Content Area
                    if workoutContainers.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 50)
                    } else {
                        // Workouts Grid - Show difficulty options
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(workoutContainers) { workout in
                                WorkoutDifficultyCard(workout: workout)
                            }
                        }
                        .padding(.horizontal)
                    }
                    Spacer() // Push content to top
                }
                .padding(.vertical)
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground))
            .onTapGesture {
                 // Dismiss keyboard on tap outside
                 hideKeyboard()
             }
            .onAppear {
                loadWorkouts()
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView()
            }
        }
    }
    
    private func loadWorkouts() {
        guard let url = Bundle.main.url(forResource: "workouts", withExtension: "json") else {
            print("Error: workouts.json not found in bundle.")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let containers = try JSONDecoder().decode([WorkoutContainer].self, from: data)
            workoutContainers = containers
            print("Successfully loaded \(containers.count) workouts")
        } catch {
            print("Error decoding workouts.json: \(error)")
        }
    }
}

// MARK: - Helper Views

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search workouts...", text: $text)
                 .autocorrectionDisabled(true)
                 .textInputAutocapitalization(.never)
             if !text.isEmpty {
                 Button {
                     text = ""
                 } label: {
                     Image(systemName: "xmark.circle.fill")
                         .foregroundColor(.secondary)
                 }
             }
        }
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct FiltersView: View {
    @ObservedObject var viewModel: WorkoutsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Filters")
                    .font(.headline)
                 Spacer()
                 if viewModel.selectedDifficulty != nil || viewModel.selectedCategory != nil {
                     Button("Clear All") { viewModel.clearFilters() }
                         .font(.callout)
                 }
            }

            // Difficulty Filter
            if !viewModel.availableDifficulties.isEmpty {
                FilterButtonGroup(title: "Difficulty", options: viewModel.availableDifficulties, selection: $viewModel.selectedDifficulty)
            }
            
            // Category Filter
            if !viewModel.availableCategories.isEmpty {
                 FilterButtonGroup(title: "Category", options: viewModel.availableCategories, selection: $viewModel.selectedCategory)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

struct FilterButtonGroup: View {
    let title: String
    let options: [String]
    @Binding var selection: String?
    
    // Arrange options into rows
    private var rows: [[String]] {
        options.chunked(into: 3) // Adjust number per row as needed
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.subheadline).foregroundColor(.secondary)
            ForEach(rows, id: \.self) { row in
                HStack {
                    ForEach(row, id: \.self) { option in
                        Button(option.capitalized) {
                            selection = (selection == option) ? nil : option
                        }
                        .buttonStyle(FilterButtonStyle(isSelected: selection == option))
                        .lineLimit(1)
                    }
                    Spacer() // Push buttons to the left
                }
            }
        }
    }
}

struct FilterButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundColor(isSelected ? .white : .primary)
            .background(isSelected ? Color.accentColor : Color(.systemGray5))
            .cornerRadius(15)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct ActiveFiltersRow: View {
    @ObservedObject var viewModel: WorkoutsViewModel
    
    var body: some View {
        HStack(spacing: 5) {
            if let difficulty = viewModel.selectedDifficulty {
                 ActiveFilterPill(text: "Difficulty: \(difficulty.capitalized)") { viewModel.selectedDifficulty = nil }
            }
            if let category = viewModel.selectedCategory {
                 ActiveFilterPill(text: "Category: \(category.capitalized)") { viewModel.selectedCategory = nil }
            }
        }
        .frame(height: (viewModel.selectedDifficulty != nil || viewModel.selectedCategory != nil) ? nil : 0) // Hide if no filters
         .clipped()
    }
}

struct ActiveFilterPill: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption2)
                .lineLimit(1)
            Button(action: action) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.2))
        .foregroundColor(.accentColor)
        .cornerRadius(15)
    }
}

struct WorkoutCardView: View {
    let workout: Workout
    @ObservedObject var viewModel: WorkoutsViewModel
    
    private var isSaved: Bool { viewModel.savedWorkoutIDs.contains(workout.workoutId) }
    private var isSaving: Bool { viewModel.savingWorkoutId == workout.workoutId }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header (Title and Save Button)
            HStack(alignment: .top) {
                Text(workout.title)
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
                Button {
                    viewModel.toggleSaveWorkout(workoutId: workout.workoutId)
                } label: {
                    if isSaving {
                        ProgressView().frame(width: 15, height: 15)
                    } else {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    }
                }
                .disabled(isSaving)
                .foregroundColor(.accentColor)
            }

            // Categories
            if let categories = workout.categories, !categories.isEmpty {
                HStack {
                    ForEach(categories.prefix(3), id: \.self) { category in
                        Text(category)
                            .font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
            }

            // Description
            if let description = workout.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Equipment
            if let equipment = workout.equipment, !equipment.isEmpty {
                 Text("Equipment: \(equipment.joined(separator: ", "))")
                     .font(.caption2)
                     .foregroundColor(.gray)
                     .lineLimit(1)
            }

            Spacer()

            // Footer (Duration, Difficulty)
            HStack {
                Label("\(workout.duration) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(workout.difficulty.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(difficultyColor(workout.difficulty).opacity(0.2))
                    .foregroundColor(difficultyColor(workout.difficulty))
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty.lowercased() {
            case "beginner": return .green
            case "intermediate": return .orange
            case "advanced": return .red
            default: return .gray
        }
    }
}

// Helper for chunking arrays (for filter rows)
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

// Helper to hide keyboard
#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

// MARK: - Workout Difficulty Card
struct WorkoutDifficultyCard: View {
    let workout: WorkoutContainer
    
    // Calculate workout stats
    private var exerciseCount: Int {
        workout.exercises.count
    }
    
    private var estimatedDuration: String {
        let warmupCount = workout.exercises.filter { $0.section == "Warm-up" }.count
        let mainCount = workout.exercises.filter { $0.section == "Main" }.count
        let cooldownCount = workout.exercises.filter { $0.section == "Cool-down" }.count
        let totalMinutes = (warmupCount * 2) + (mainCount * 3) + (cooldownCount * 2)
        return "\(totalMinutes-5)-\(totalMinutes+5) mins"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and title
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: workout.workoutIcon)
                        .font(.title3)
                        .foregroundColor(workout.workoutColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.name)
                            .font(.subheadline)
                            .fontWeight(.bold)
                        
                        Text("\(exerciseCount) exercises")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Duration badge
                Text(estimatedDuration)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(workout.workoutColor.opacity(0.2))
                    .foregroundColor(workout.workoutColor)
                    .cornerRadius(8)
            }
            
            // Difficulty buttons
            HStack(spacing: 8) {
                ForEach(WorkoutDifficulty.allCases, id: \.self) { difficulty in
                    NavigationLink(destination: WorkoutDetailView(
                        workoutName: workout.name,
                        difficulty: difficulty,
                        exercises: workout.exercises
                    )) {
                        VStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(difficulty.color)
                            
                            Text(difficulty.displayName)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(getDifficultyDetails(difficulty))
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(difficulty.color.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(workout.workoutColor.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func getDifficultyDetails(_ difficulty: WorkoutDifficulty) -> String {
        switch difficulty {
        case .beginner: return "Light"
        case .intermediate: return "Moderate"
        case .advanced: return "Intense"
        }
    }
}

// MARK: - Difficulty Tips View
struct DifficultyTipsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Difficulty Levels")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    DifficultyTipRow(
                        difficulty: .beginner,
                        description: "Perfect for getting started. Lower repetitions and lighter weights to build foundation and form."
                    )
                    
                    DifficultyTipRow(
                        difficulty: .intermediate,
                        description: "Step up your game. Moderate repetitions and medium weights to build strength and endurance."
                    )
                    
                    DifficultyTipRow(
                        difficulty: .advanced,
                        description: "Challenge yourself. Higher repetitions and heavy weights for maximum gains and performance."
                    )
                }
                .padding()
                
                Spacer()
            }
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }
}

struct DifficultyTipRow: View {
    let difficulty: WorkoutDifficulty
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(difficulty.displayName)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 100)
                .padding(.vertical, 8)
                .background(difficulty.color)
                .cornerRadius(8)
            
            Text(description)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

#Preview {
    WorkoutsView()
} 