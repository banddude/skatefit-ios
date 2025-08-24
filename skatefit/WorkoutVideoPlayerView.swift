import SwiftUI
import AVFoundation
import AVKit

struct WorkoutVideoPlayerView: UIViewRepresentable {
    let player: AVPlayer?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        guard let player = player else { return view }
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill // This ensures full screen coverage
        playerLayer.frame = view.bounds
        playerLayer.needsDisplayOnBoundsChange = true // Prevent scaling animations
        view.layer.addSublayer(playerLayer)
        
        // Store reference to player layer for updates
        context.coordinator.playerLayer = playerLayer
        
        // Configure audio session to allow background music
        configureAudioSession()
        
        // Configure for smooth gif-like playback
        player.isMuted = true // Silent for gif-like experience
        player.automaticallyWaitsToMinimizeStalling = false
        
        // Start playing and setup seamless looping
        player.play()
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update player layer frame when view bounds change
        if let playerLayer = context.coordinator.playerLayer {
            DispatchQueue.main.async {
                playerLayer.frame = uiView.bounds
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var playerLayer: AVPlayerLayer?
    }
    
    private func configureAudioSession() {
        do {
            // Set audio session category to allow mixing with other audio
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
}