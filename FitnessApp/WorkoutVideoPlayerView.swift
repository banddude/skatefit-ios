import SwiftUI
import AVFoundation
import AVKit

struct AppIconVideoPlaceholder: View {
    var compact = false
    var showSpinner = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Neon.panel,
                    Neon.bg,
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: compact ? Neon.Space.sm : Neon.Space.lg) {
                if let appIcon = AppConfig.getAppIcon() {
                    Image(uiImage: appIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: compact ? 54 : 108, height: compact ? 54 : 108)
                        .clipShape(RoundedRectangle(cornerRadius: compact ? 14 : Neon.Radius.large, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: compact ? 14 : Neon.Radius.large, style: .continuous)
                                .stroke(
                                    LinearGradient(colors: [Neon.cyan.opacity(0.7), Neon.magenta.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: Neon.Stroke.medium
                                )
                        )
                        .neonGlow(Neon.magenta, radius: compact ? Neon.Glow.card : Neon.Glow.hero, opacity: 0.55)
                } else {
                    Image(systemName: "figure.skateboarding")
                        .font(Neon.font(compact ? 22 : 40, .heavy))
                        .foregroundColor(.white)
                }

                if showSpinner {
                    ProgressView()
                        .tint(Neon.cyan)
                        .controlSize(compact ? .small : .regular)
                }
            }
            .padding(compact ? Neon.Space.md : Neon.Space.xl)
        }
    }
}

struct WorkoutVideoPlayerView: UIViewRepresentable {
    let player: AVPlayer?

    func makeUIView(context: Context) -> UIView {
        let view = PlayerContainerView()
        view.backgroundColor = .black

        guard let player = player else { return view }

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        view.playerLayer = playerLayer
        view.layer.addSublayer(playerLayer)

        // Store reference for coordinator
        context.coordinator.playerLayer = playerLayer
        context.coordinator.player = player

        // Configure audio session
        configureAudioSession()

        // Configure for smooth playback
        player.isMuted = true
        player.automaticallyWaitsToMinimizeStalling = false

        // Setup looping
        context.coordinator.setupLooping(for: player)

        // Reset and play
        player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
            player.play()
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let containerView = uiView as? PlayerContainerView,
              let playerLayer = context.coordinator.playerLayer,
              let player = context.coordinator.player else { return }

        // Update frame without animation
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = containerView.bounds
        CATransaction.commit()

        // Ensure player is playing when view updates (handles recycled views)
        if player.rate == 0 && player.currentItem != nil {
            player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                player.play()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.cleanup()
    }

    class Coordinator {
        var playerLayer: AVPlayerLayer?
        var player: AVPlayer?
        var loopObserver: Any?

        func setupLooping(for player: AVPlayer) {
            // Remove any existing observer
            if let observer = loopObserver {
                NotificationCenter.default.removeObserver(observer)
            }

            loopObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { [weak player] _ in
                player?.seek(to: .zero)
                player?.play()
            }
        }

        func cleanup() {
            if let observer = loopObserver {
                NotificationCenter.default.removeObserver(observer)
                loopObserver = nil
            }
        }

        deinit {
            cleanup()
        }
    }

    // Custom UIView that updates layer frame on layout
    class PlayerContainerView: UIView {
        var playerLayer: AVPlayerLayer?

        override func layoutSubviews() {
            super.layoutSubviews()
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            playerLayer?.frame = bounds
            CATransaction.commit()
        }
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

// MARK: - Looping Video Thumbnail

struct LoopingVideoThumbnail: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> LoopingPlayerContainerView {
        let view = LoopingPlayerContainerView()
        view.backgroundColor = .clear
        view.configure(url: url)
        return view
    }

    func updateUIView(_ uiView: LoopingPlayerContainerView, context: Context) {
        if uiView.currentURL != url {
            uiView.configure(url: url)
        }
    }

    static func dismantleUIView(_ uiView: LoopingPlayerContainerView, coordinator: ()) {
        uiView.teardown()
    }

    final class LoopingPlayerContainerView: UIView {
        private(set) var currentURL: URL?
        private var queuePlayer: AVQueuePlayer?
        private var looper: AVPlayerLooper?
        private var playerLayer: AVPlayerLayer?

        func configure(url: URL) {
            teardown()
            currentURL = url

            let asset = AVURLAsset(url: url)
            let item = AVPlayerItem(asset: asset)
            let queue = AVQueuePlayer(playerItem: item)
            queue.isMuted = true
            queue.automaticallyWaitsToMinimizeStalling = false

            let loop = AVPlayerLooper(player: queue, templateItem: item)
            let layer = AVPlayerLayer(player: queue)
            layer.videoGravity = .resizeAspectFill
            layer.frame = bounds
            layer.opacity = 0
            self.layer.addSublayer(layer)

            queuePlayer = queue
            looper = loop
            playerLayer = layer

            queue.play()

            // Fade in once first frame renders
            var timeObserver: Any?
            timeObserver = queue.addBoundaryTimeObserver(forTimes: [NSValue(time: CMTime(seconds: 0.05, preferredTimescale: 600))], queue: .main) { [weak self] in
                guard let self = self else { return }
                if let layer = self.playerLayer, layer.opacity == 0 {
                    CATransaction.begin()
                    CATransaction.setAnimationDuration(0.3)
                    layer.opacity = 1
                    CATransaction.commit()
                }
                if let observer = timeObserver {
                    queue.removeTimeObserver(observer)
                }
            }
        }

        func teardown() {
            queuePlayer?.pause()
            queuePlayer?.removeAllItems()
            playerLayer?.removeFromSuperlayer()
            queuePlayer = nil
            looper = nil
            playerLayer = nil
            currentURL = nil
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            playerLayer?.frame = bounds
            CATransaction.commit()
        }
    }
}
