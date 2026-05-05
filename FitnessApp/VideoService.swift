import Foundation
import AVFoundation

class VideoService: ObservableObject {
    static let shared = VideoService()

    private let gitHubContentService = GitHubContentService.shared
    private let defaults = UserDefaults.standard
    private let videoVersionKey = "VideoCacheVersion"
    private let videoVersionMapKey = "VideoVersionMap"

    private init() {}

    // MARK: - Public Methods

    func getVideoURL(for fileName: String) -> URL? {
        let cachedVideoURL = cacheURL(for: fileName)

        if FileManager.default.fileExists(atPath: cachedVideoURL.path) {
            return cachedVideoURL
        }

        return getBundledVideoURL(for: fileName)
    }

    func getVideoURLAsync(for fileName: String) async -> URL? {
        if let url = getVideoURL(for: fileName) {
            // Check if this cached file is stale (content version changed)
            if isVideoStale(fileName: fileName) {
                if let freshURL = try? await gitHubContentService.downloadVideo(fileName: fileName) {
                    markVideoCurrent(fileName: fileName)
                    return freshURL
                }
            }
            return url
        }

        do {
            let remoteURL = try await gitHubContentService.downloadVideo(fileName: fileName)
            markVideoCurrent(fileName: fileName)
            return remoteURL
        } catch {
            print("Failed to download video \(fileName): \(error)")
            return nil
        }
    }

    func isVideoAvailable(fileName: String) -> Bool {
        if Bundle.main.url(forResource: fileName, withExtension: "mp4") != nil ||
           Bundle.main.url(forResource: fileName, withExtension: "mp4", subdirectory: "videos") != nil ||
           Bundle.main.url(forResource: fileName, withExtension: "mov") != nil ||
           Bundle.main.url(forResource: fileName, withExtension: "mov", subdirectory: "videos") != nil {
            return true
        }
        return FileManager.default.fileExists(atPath: cacheURL(for: fileName).path)
    }

    /// Called when content version changes (new commit). Stales all cached videos
    /// so they'll be re-downloaded on next access.
    func invalidateVideoCache() {
        let currentVersion = defaults.string(forKey: "GitHubContentVersion") ?? "unknown"
        let savedVersion = defaults.string(forKey: videoVersionKey)

        if currentVersion != savedVersion {
            print("Video cache invalidated: content version changed from \(savedVersion ?? "none") to \(currentVersion)")
            defaults.set(currentVersion, forKey: videoVersionKey)
            defaults.removeObject(forKey: videoVersionMapKey)
        }
    }

    // MARK: - Private Methods

    private func isVideoStale(fileName: String) -> Bool {
        let map = defaults.dictionary(forKey: videoVersionMapKey) as? [String: String] ?? [:]
        let currentVersion = defaults.string(forKey: "GitHubContentVersion") ?? "unknown"
        return map[normalized(fileName)] != currentVersion
    }

    private func markVideoCurrent(fileName: String) {
        let currentVersion = defaults.string(forKey: "GitHubContentVersion") ?? "unknown"
        var map = defaults.dictionary(forKey: videoVersionMapKey) as? [String: String] ?? [:]
        map[normalized(fileName)] = currentVersion
        defaults.set(map, forKey: videoVersionMapKey)
    }

    private func normalized(_ fileName: String) -> String {
        fileName.hasSuffix(".mp4") ? fileName : "\(fileName).mp4"
    }

    private func cacheURL(for fileName: String) -> URL {
        getCacheDirectory()
            .appendingPathComponent("videos")
            .appendingPathComponent(normalized(fileName))
    }

    private func getBundledVideoURL(for fileName: String) -> URL? {
        if let url = Bundle.main.url(forResource: fileName, withExtension: "mp4", subdirectory: "sdr") {
            return url
        }
        if let url = Bundle.main.url(forResource: fileName, withExtension: "mp4", subdirectory: "videos") {
            return url
        }
        if let url = Bundle.main.url(forResource: fileName, withExtension: "mp4") {
            return url
        }
        if let url = Bundle.main.url(forResource: fileName, withExtension: "mov", subdirectory: "videos") {
            return url
        }
        if let url = Bundle.main.url(forResource: fileName, withExtension: "mov") {
            return url
        }
        return nil
    }

    private func getCacheDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("GitHubContent")
    }
}
