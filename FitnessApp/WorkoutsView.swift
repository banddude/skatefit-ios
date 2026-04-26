import SwiftUI

struct WorkoutsView: View {
    @EnvironmentObject var contentManager: ContentManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showOnboarding = false
    @State private var expandedWorkoutId: UUID? = nil

    let columns = [GridItem(.adaptive(minimum: 300), spacing: 15)]

    private var headerView: some View {
        HStack {
            HStack(alignment: .bottom, spacing: 11) {
                // App icon - automatically uses the icon from Assets.xcassets
                if let appIcon = AppConfig.getAppIcon() {
                    Image(uiImage: appIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                }

                Text(AppConfig.appName)
                    .font(.system(size: 39, weight: .bold, design: .default))
                    .foregroundColor(themeManager.isDarkMode ? .white : .primary)
                    .onLongPressGesture {
                        contentManager.clearCache()
                    }
            }
            
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
    }
    
    private var workoutsList: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(contentManager.workoutContainers) { workout in
                let isExpanded = expandedWorkoutId == workout.id
                WorkoutDifficultyCard(
                    workout: workout,
                    isExpanded: isExpanded,
                    onTap: toggleExpansion(for: workout)
                )
            }
        }
        .padding(.horizontal)
    }
    
    private func toggleExpansion(for workout: WorkoutContainer) -> () -> Void {
        return {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                if expandedWorkoutId == workout.id {
                    expandedWorkoutId = nil
                } else {
                    expandedWorkoutId = workout.id
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    headerView
                    
                    if contentManager.workoutContainers.isEmpty {
                        if contentManager.isInitializing {
                            VStack(spacing: 8) {
                                ProgressView()
                                Text("Loading workouts from GitHub...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 50)
                        } else if let error = contentManager.initializationError {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 32))
                                    .foregroundColor(.orange)
                                Text("Unable to load workouts")
                                    .font(.headline)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                Button("Retry") {
                                    Task {
                                        await contentManager.initializeContent()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 50)
                        } else {
                            Text("No workouts available")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 50)
                        }
                    } else {
                        workoutsList
                    }
                    Spacer()
                }
                .padding(.vertical)
            }
            .refreshable {
                await withCheckedContinuation { continuation in
                    Task.detached {
                        await contentManager.refreshContent()
                        continuation.resume()
                    }
                }
            }
            .navigationBarHidden(true)
            .scrollDismissesKeyboard(.immediately)
            .background(themeManager.isDarkMode ? Color.black : Color(.systemBackground))
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView()
            }
        }
    }
}



// MARK: - Workout Difficulty Card
struct WorkoutDifficultyCard: View {
    let workout: WorkoutContainer
    let isExpanded: Bool
    let onTap: () -> Void
    
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
            // Header with icon and title (always visible)
            Button(action: onTap) {
                HStack {
                    Image(systemName: workout.workoutIcon)
                        .font(.title3)
                        .foregroundColor(workout.workoutColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.name)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("\(exerciseCount) exercises")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        // Duration badge
                        Text(estimatedDuration)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(workout.workoutColor.opacity(0.2))
                            .foregroundColor(workout.workoutColor)
                            .cornerRadius(8)
                        
                        // Expand/collapse indicator
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Difficulty buttons (only visible when expanded)
            if isExpanded {
                HStack(spacing: 8) {
                    ForEach(WorkoutDifficulty.allCases, id: \.self) { difficulty in
                        NavigationLink(destination: WorkoutDetailView(
                            workoutName: workout.name,
                            workoutIcon: workout.workoutIcon,
                            workoutColor: workout.workoutColor,
                            difficulty: difficulty,
                            exercises: workout.exercises
                        )) {
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(difficulty.color)
                                
                                Text(difficulty.displayName)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
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
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .padding(14)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: isExpanded)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(workout.workoutColor.opacity(0.5), lineWidth: 1.5)
        )
    }
    
}


#Preview {
    WorkoutsView()
} 
