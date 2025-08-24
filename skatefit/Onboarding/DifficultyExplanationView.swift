import SwiftUI

struct DifficultyExplanationView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.blue)
                
                Text("Difficulty Levels")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Each workout has three difficulty options. Choose any level when you start a workout session.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 10)
            
            // Difficulty Cards
            VStack(spacing: 16) {
                DifficultyCard(
                    difficulty: .beginner,
                    description: "Perfect for getting started. Lower repetitions and lighter weights to build foundation and form.",
                    examples: ["10 reps", "Light bands", "Basic movements"]
                )
                
                DifficultyCard(
                    difficulty: .intermediate,
                    description: "Step up your game. Moderate repetitions and medium weights to build strength and endurance.",
                    examples: ["12-15 reps", "Medium bands", "Complex movements"]
                )
                
                DifficultyCard(
                    difficulty: .advanced,
                    description: "Challenge yourself. Higher repetitions and heavy weights for maximum gains and performance.",
                    examples: ["15+ reps", "Heavy weights", "Advanced techniques"]
                )
            }
            .padding(.horizontal, 20)
            
            Spacer(minLength: 10)
            
            // Note
            Text("💡 Select your preferred difficulty each time you start a workout")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .padding(.bottom, 10)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

struct DifficultyCard: View {
    let difficulty: WorkoutDifficulty
    let description: String
    let examples: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(difficulty.displayName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(difficulty.color)
                
                Spacer()
                
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(difficulty.color)
            }
            
            Text(description)
                .font(.callout)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            HStack(spacing: 6) {
                ForEach(examples, id: \.self) { example in
                    Text(example)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(difficulty.color.opacity(0.1))
                        .foregroundColor(difficulty.color)
                        .cornerRadius(6)
                }
                Spacer()
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(difficulty.color.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    DifficultyExplanationView()
}