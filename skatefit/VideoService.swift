import Foundation
import AVFoundation

class VideoService: ObservableObject {
    static let shared = VideoService()
    
    private let gitHubContentService = GitHubContentService.shared
    
    private init() {}
    
    func getVideoURL(for fileName: String) -> URL? {
        // Priority 1: Check for bundled video first (fastest)
        if let bundledURL = getBundledVideoURL(for: fileName) {
            print("Using bundled video: \(fileName)")
            return bundledURL
        }
        
        // Priority 2: Check if video is cached from GitHub
        let cacheDirectory = getCacheDirectory()
        let cachedVideoURL = cacheDirectory.appendingPathComponent("videos").appendingPathComponent(fileName.hasSuffix(".mp4") ? fileName : "\(fileName).mp4")
        
        if FileManager.default.fileExists(atPath: cachedVideoURL.path) {
            print("Using cached video from GitHub: \(fileName)")
            return cachedVideoURL
        }
        
        // Priority 3: Return placeholder and trigger background download
        print("Video not available locally, will download: \(fileName)")
        downloadVideoInBackground(fileName: fileName)
        
        return getPlaceholderVideoURL()
    }
    
    /// Async version for explicit remote video loading
    func getVideoURLAsync(for fileName: String) async -> URL? {
        // First check bundled and cached
        if let url = getVideoURL(for: fileName), 
           url != getPlaceholderVideoURL() {
            return url
        }
        
        // Download from GitHub if needed
        do {
            let remoteURL = try await gitHubContentService.downloadVideo(fileName: fileName)
            print("Downloaded video: \(fileName)")
            return remoteURL
        } catch {
            print("Failed to download video \(fileName): \(error)")
            return getPlaceholderVideoURL()
        }
    }
    
    
    private func getBundledVideoURL(for fileName: String) -> URL? {
        print("Looking for video: \(fileName)")
        
        // Priority 1: Look for SDR H.264 versions first
        if let url = Bundle.main.url(forResource: fileName, withExtension: "mp4", subdirectory: "sdr") {
            print("Found SDR video: \(fileName).mp4 at \(url)")
            return url
        }
        
        // Priority 2: Look for .mp4 files in videos subdirectory
        if let url = Bundle.main.url(forResource: fileName, withExtension: "mp4", subdirectory: "videos") {
            print("Found video in videos folder: \(fileName).mp4 at \(url)")
            return url
        }
        
        // Priority 3: Look for .mp4 files in main bundle root
        if let url = Bundle.main.url(forResource: fileName, withExtension: "mp4") {
            print("Found video in bundle root: \(fileName).mp4 at \(url)")
            return url
        }
        
        // Priority 4: Try .mov files in videos subdirectory
        if let url = Bundle.main.url(forResource: fileName, withExtension: "mov", subdirectory: "videos") {
            print("Found mov video in videos folder: \(fileName).mov at \(url)")
            return url
        }
        
        // Final fallback: .mov files in bundle root
        if let url = Bundle.main.url(forResource: fileName, withExtension: "mov") {
            print("Found mov video in bundle root: \(fileName).mov at \(url)")
            return url
        }
        
        print("❌ No video found for: \(fileName)")
        print("📁 Bundle path: \(Bundle.main.bundlePath)")
        
        // List what's actually in the videos folder
        if let videosPath = Bundle.main.path(forResource: "videos", ofType: nil),
           let videoContents = try? FileManager.default.contentsOfDirectory(atPath: videosPath) {
            print("📹 Videos folder contents: \(videoContents)")
            let matches = videoContents.filter { $0.contains(fileName) }
            print("🔍 Files containing '\(fileName)': \(matches)")
        }
        
        print("⚠️ Using placeholder video")
        return getPlaceholderVideoURL()
    }
    
    
    private func getPlaceholderVideoURL() -> URL? {
        return Bundle.main.url(forResource: "placeholder_video", withExtension: "mp4")
    }
    
    func preloadVideo(fileName: String) {
        guard let url = getVideoURL(for: fileName) else { return }
        
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        // Preload the video
        playerItem.preferredForwardBufferDuration = 5.0
    }
    
    func isVideoAvailable(fileName: String) -> Bool {
        // Check if bundled
        if Bundle.main.url(forResource: fileName, withExtension: "mp4") != nil ||
           Bundle.main.url(forResource: fileName, withExtension: "mp4", subdirectory: "videos") != nil ||
           Bundle.main.url(forResource: fileName, withExtension: "mov") != nil ||
           Bundle.main.url(forResource: fileName, withExtension: "mov", subdirectory: "videos") != nil {
            return true
        }
        
        // Check if cached from GitHub
        let cacheDirectory = getCacheDirectory()
        let cachedVideoURL = cacheDirectory.appendingPathComponent("videos").appendingPathComponent(fileName.hasSuffix(".mp4") ? fileName : "\(fileName).mp4")
        return FileManager.default.fileExists(atPath: cachedVideoURL.path)
    }
    
    // MARK: - Private Helper Methods
    
    private func getCacheDirectory() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("GitHubContent")
    }
    
    private func downloadVideoInBackground(fileName: String) {
        Task {
            do {
                _ = try await gitHubContentService.downloadVideo(fileName: fileName)
                print("Background download completed for: \(fileName)")
            } catch {
                print("Background download failed for \(fileName): \(error)")
            }
        }
    }
}
