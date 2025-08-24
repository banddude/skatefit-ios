import SwiftUI
import AVFoundation
import AVKit

struct SingleExercisePlayerView: View {
    let exercise: WorkoutExercise
    let difficulty: WorkoutDifficulty
    
    @Environment(\.dismiss) var dismiss
    @State private var showExerciseDetails = false
    
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
            .allowsHitTesting(false) // Prevent text overlays from blocking tap gestures
            
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
            .allowsHitTesting(false) // Prevent bottom UI from blocking tap gestures
            
            // Invisible tap overlay to capture tap gestures
            Color.clear
                .ignoresSafeArea(.all)
                .onTapGesture {
                    print("🎯 Tap detected! Toggling exercise details")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showExerciseDetails.toggle()
                    }
                    print("📋 Exercise details now: \(showExerciseDetails)")
                }
            
            // Exercise Details Overlay
            if showExerciseDetails {
                exerciseDetailsOverlay
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
                HStack {
                    // Debug button - remove in production
                    Button("Info") {
                        print("🔘 Debug button pressed")
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showExerciseDetails.toggle()
                        }
                    }
                    .foregroundColor(.white)
                    
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Exercise Details Overlay
    private var exerciseDetailsOverlay: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.8)
                .ignoresSafeArea(.all)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showExerciseDetails = false
                    }
                }
            
            // Details card
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.section)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        Text(exercise.move)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showExerciseDetails = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 10)
                
                Divider()
                
                // Exercise details content
                VStack(alignment: .leading, spacing: 16) {
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(exercise.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Instructions for current difficulty
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Instructions (\(difficulty.displayName))")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.body)
                                .foregroundColor(difficulty.color)
                            
                            Text(exercise.instructions(for: difficulty))
                                .font(.body)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(difficulty.color.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // All difficulty levels
                    VStack(alignment: .leading, spacing: 8) {
                        Text("All Difficulty Levels")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 6) {
                            difficultyRow(level: .beginner, instructions: exercise.beginner)
                            difficultyRow(level: .intermediate, instructions: exercise.intermediate)
                            difficultyRow(level: .advanced, instructions: exercise.advanced)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.3), radius: 20)
            )
            .padding(20)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
    
    private func difficultyRow(level: WorkoutDifficulty, instructions: String) -> some View {
        HStack {
            Circle()
                .fill(level.color)
                .frame(width: 8, height: 8)
            
            Text(level.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(level == difficulty ? level.color : .secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(instructions)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(level == difficulty ? level.color.opacity(0.1) : Color.clear)
        .cornerRadius(6)
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