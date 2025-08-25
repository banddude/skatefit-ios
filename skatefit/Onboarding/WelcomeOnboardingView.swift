import SwiftUI

struct WelcomeOnboardingView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Logo and Title
            VStack(spacing: 16) {
                Image(systemName: "figure.skating")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Welcome to SkateFit")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            
            // Description
            VStack(spacing: 12) {
                Text("Skateboarding-Specific Fitness")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
                
                Text("Build the strength, balance, and mobility you need to dominate the streets and skate parks.")
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
            
            // Features - styled like WorkoutsView cards
            VStack(spacing: 12) {
                FeatureCard(icon: "target", title: "Skate-Specific Training", description: "Exercises designed for skateboarding strength and balance", color: .mint)
                FeatureCard(icon: "star.fill", title: "3 Difficulty Levels", description: "Progress from beginner to advanced at your own pace", color: .blue)
                FeatureCard(icon: "play.rectangle.fill", title: "Follow-Along Videos", description: "Crystal clear demonstrations for every exercise", color: .purple)
                FeatureCard(icon: "clock.fill", title: "Quick Sessions", description: "Get stronger in just 25-35 minutes", color: .orange)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    WelcomeOnboardingView()
}