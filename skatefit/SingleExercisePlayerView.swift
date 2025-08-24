import SwiftUI
import AVFoundation
import AVKit

struct SingleExercisePlayerView: View {
    let exercise: WorkoutExercise
    let difficulty: WorkoutDifficulty
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Full screen background video using custom player that properly fills
            GeometryReader { geometry in
                if let videoURL = exercise.getVideoURL() {
                    WorkoutVideoPlayerView(player: AVPlayer(url: videoURL))
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                } else {
                    Color.black
                }
            }
            .ignoresSafeArea(.all)
            
            // Top UI with gradient background
            VStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(exercise.section)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    // Exercise title
                    Text(exercise.move)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black, radius: 2)
                        .padding(.top, 8)
                }
                .padding(.horizontal)
                .padding(.top)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                Spacer()
            }
            
            // Bottom UI with description and reps
            VStack {
                Spacer()
                
                VStack(spacing: 20) {
                    // Description
                    Text(exercise.description)
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .padding(.horizontal, 30)
                        .shadow(color: .black, radius: 2)
                    
                    // Rep Info
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.title3)
                            .foregroundColor(.white)
                        
                        Text(exercise.instructions(for: difficulty))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(difficulty.color.opacity(0.9))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.5), radius: 6)
                }
                .padding(.bottom, 0)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.2), Color.black.opacity(0.75)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(.all)
                )
            }
        }
        .navigationTitle(exercise.move)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Text(exercise.section)
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(sectionColor(exercise.section))
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .fixedSize()
                    .shadow(radius: 0)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func sectionColor(_ section: String) -> Color {
        switch section {
        case "Warm-up": return .orange
        case "Main": return .purple
        case "Cool-down": return .teal
        default: return .gray
        }
    }
}

#Preview {
    SingleExercisePlayerView(
        exercise: WorkoutExercise(
            section: "Warm-up",
            move: "Lay-back knee hugs", 
            description: "Laying on your back with your legs extended, pull one knee toward your chest with hands behind the thigh, keep head up to engage core",
            jsonFile: "lay_back_knee_hugs.json",
            videoFile: "lay_back_knee_hugs",
            beginner: "10 reps each side (1 round)",
            intermediate: "12 reps each side (2 rounds)", 
            advanced: "15 reps each side (3 rounds)"
        ),
        difficulty: .beginner
    )
}