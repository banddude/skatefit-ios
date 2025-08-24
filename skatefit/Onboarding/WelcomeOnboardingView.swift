import SwiftUI

struct WelcomeOnboardingView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Logo and Title
            VStack(spacing: 20) {
                Image(systemName: "figure.skating")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                
                Text("Welcome to SkateFit")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            
            // Description
            VStack(spacing: 16) {
                Text("Skateboarding-Specific Fitness")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Text("Build the strength, balance, and mobility you need to improve your skateboarding performance.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                
                Text("Train like a skater, progress like a pro.")
                    .font(.callout)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            
            Spacer()
            
            // Features
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "target", title: "Skateboarding-focused exercises")
                FeatureRow(icon: "figure.strengthtraining.traditional", title: "Progressive difficulty levels")
                FeatureRow(icon: "play.rectangle", title: "Video-guided workouts")
                FeatureRow(icon: "clock", title: "Quick 15-30 minute sessions")
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(title)
                .font(.body)
            Spacer()
        }
    }
}

#Preview {
    WelcomeOnboardingView()
}