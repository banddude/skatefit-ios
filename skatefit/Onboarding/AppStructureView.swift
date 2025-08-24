import SwiftUI

struct AppStructureView: View {
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.blue)
                
                Text("How Workouts Work")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Every workout follows a proven structure to maximize your skateboarding performance.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 20)
            
            // Workout Structure
            VStack(spacing: 24) {
                WorkoutPhaseCard(
                    icon: "thermometer.low",
                    title: "Warm-up",
                    duration: "5-8 mins",
                    description: "Activate muscles and prepare your body for training",
                    color: .orange,
                    examples: ["Joint mobility", "Dynamic stretches", "Light activation"]
                )
                
                Image(systemName: "arrow.down")
                    .foregroundColor(.secondary)
                
                WorkoutPhaseCard(
                    icon: "figure.strengthtraining.traditional",
                    title: "Main Workout",
                    duration: "15-20 mins",
                    description: "Build strength, balance, and skateboarding-specific skills",
                    color: .purple,
                    examples: ["Balance training", "Strength exercises", "Plyometrics"]
                )
                
                Image(systemName: "arrow.down")
                    .foregroundColor(.secondary)
                
                WorkoutPhaseCard(
                    icon: "leaf",
                    title: "Cool-down",
                    duration: "5-8 mins",
                    description: "Stretch and relax muscles to aid recovery",
                    color: .teal,
                    examples: ["Static stretches", "Flexibility", "Relaxation"]
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Total time
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                Text("Total workout time: 25-35 minutes")
                    .font(.callout)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 30)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

struct WorkoutPhaseCard: View {
    let icon: String
    let title: String
    let duration: String
    let description: String
    let color: Color
    let examples: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                Text(duration)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .foregroundColor(color)
                    .cornerRadius(8)
            }
            
            Text(description)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            HStack(spacing: 6) {
                ForEach(examples, id: \.self) { example in
                    Text(example)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(.systemGray6))
                        .foregroundColor(.secondary)
                        .cornerRadius(6)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    AppStructureView()
}