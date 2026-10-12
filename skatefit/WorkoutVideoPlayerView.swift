import SwiftUI
import AVFoundation
import AVKit

struct WorkoutVideoPlayerView: UIViewRepresentable {
    let player: AVPlayer?
    var onLongPress: () -> Void = {}

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = view.bounds
        playerLayer.needsDisplayOnBoundsChange = true
        view.layer.addSublayer(playerLayer)

        context.coordinator.playerLayer = playerLayer
        context.coordinator.attach(to: player)
        context.coordinator.onLongPress = onLongPress
        let gesture = UILongPressGestureRecognizer(
            target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:))
        )
        gesture.minimumPressDuration = 0.5
        gesture.allowableMovement = 12
        gesture.cancelsTouchesInView = false
        gesture.delegate = context.coordinator
        view.addGestureRecognizer(gesture)

        configureAudioSession()
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onLongPress = onLongPress
        if context.coordinator.player !== player {
            context.coordinator.attach(to: player)
        }

        if let playerLayer = context.coordinator.playerLayer {
            DispatchQueue.main.async {
                playerLayer.frame = uiView.bounds
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var playerLayer: AVPlayerLayer?
        weak var player: AVPlayer?
        var onLongPress: () -> Void = {}
        private var endObserver: NSObjectProtocol?

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            // UIKit enters began after the threshold, before the finger lifts.
            handleLongPressState(gesture.state)
        }

        func handleLongPressState(_ state: UIGestureRecognizer.State) {
            if state == .began { onLongPress() }
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }

        func attach(to newPlayer: AVPlayer?) {
            guard player !== newPlayer else { return }

            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
                self.endObserver = nil
            }

            player = newPlayer
            playerLayer?.player = newPlayer

            guard let newPlayer else { return }

            newPlayer.isMuted = true
            newPlayer.automaticallyWaitsToMinimizeStalling = false
            newPlayer.play()

            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: newPlayer.currentItem,
                queue: .main
            ) { [weak newPlayer] _ in
                newPlayer?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                    newPlayer?.play()
                }
            }
        }

        deinit {
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
        }
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
}
