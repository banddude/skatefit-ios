import SwiftUI

struct VideoTutorialView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "play.rectangle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.blue)
                
                Text("How to Use Videos")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Master the controls to get the most out of your workouts.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 10)
            
            // Video Controls
            VStack(spacing: 16) {
                ControlCard(
                    icon: "hand.draw",
                    title: "Swipe to Navigate",
                    description: "Swipe left or right to move between exercises in your workout",
                    gesture: "← →"
                )
                
                ControlCard(
                    icon: "hand.tap",
                    title: "Tap for Details",
                    description: "Tap anywhere on the video to see exercise instructions and reps",
                    gesture: "TAP"
                )
                
                ControlCard(
                    icon: "arrow.down.circle",
                    title: "Swipe Down to Exit",
                    description: "Swipe down from the top to exit the workout and return to the main screen",
                    gesture: "↓"
                )
                
                ControlCard(
                    icon: "play.circle",
                    title: "Videos Loop",
                    description: "Each exercise video will automatically loop so you can follow along",
                    gesture: "∞"
                )
            }
            .padding(.horizontal, 20)
            
            Spacer(minLength: 10)
            
            // Tip
            VStack(spacing: 6) {
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundColor(.yellow)
                    Text("Pro Tip")
                        .font(.callout)
                        .fontWeight(.semibold)
                }
                
                Text("Watch the entire exercise once before starting to understand the movement pattern.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 10)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

struct ControlCard: View {
    let icon: String
    let title: String
    let description: String
    let gesture: String
    
    var body: some View {
        HStack(spacing: 12) {
            VStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text(gesture)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

#Preview {
    VideoTutorialView()
}