import Foundation

class VideoDownloadQueue {
    static let shared = VideoDownloadQueue()

    private var queue: [String] = []
    private var activeDownloads: Set<String> = []
    private var highPriority: Set<String> = []
    private let maxConcurrent = 4
    private var task: Task<Void, Never>?

    private init() {}

    /// Queue all video filenames for background download at low priority
    func queueAll(fileNames: [String]) {
        let unique = Array(Set(fileNames))
        let cached = unique.filter { VideoService.shared.isVideoAvailable(fileName: $0) }
        let needed = unique.filter { !VideoService.shared.isVideoAvailable(fileName: $0) }

        print("Video queue: \(cached.count) already cached, \(needed.count) to download")

        if needed.isEmpty { return }

        queue = needed
        startNextBatch()
    }

    /// Move these filenames to the front of the queue
    func prioritize(fileNames: [String]) {
        let needed = fileNames.filter { !VideoService.shared.isVideoAvailable(fileName: $0) && !activeDownloads.contains($0) }
        guard !needed.isEmpty else { return }

        // Remove from queue, insert at front
        queue.removeAll { needed.contains($0) }
        queue.insert(contentsOf: needed, at: 0)
        highPriority.formUnion(needed)

        // If we have capacity, start more downloads
        if activeDownloads.count < maxConcurrent {
            startNextBatch()
        }
    }

    private func startNextBatch() {
        guard task == nil else { return }
        task = Task {
            while !queue.isEmpty && !Task.isCancelled {
                // Fill up to maxConcurrent
                while activeDownloads.count < maxConcurrent, let fileName = queue.first {
                    queue.removeFirst()
                    activeDownloads.insert(fileName)
                    let _ = highPriority.contains(fileName)
                    highPriority.remove(fileName)

                    Task {
                        _ = try? await GitHubContentService.shared.downloadVideo(fileName: fileName)
                        _ = await MainActor.run {
                            activeDownloads.remove(fileName)
                        }
                    }
                }
                // Wait for a slot to open
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
            }
            task = nil
            print("Video download queue complete")
        }
    }
}
