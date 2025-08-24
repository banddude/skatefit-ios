import Foundation
import AVFoundation

class VideoService: ObservableObject {
    static let shared = VideoService()
    
    private init() {}
    
    func getVideoURL(for fileName: String) -> URL? {
        // Simply return bundled video URL
        if let bundledURL = getBundledVideoURL(for: fileName) {
            print("Using bundled video: \(fileName)")
            return bundledURL
        }
        
        // Return placeholder if no bundled video available
        return getPlaceholderVideoURL()
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
        return Bundle.main.url(forResource: fileName, withExtension: "mp4") != nil ||
               Bundle.main.url(forResource: fileName, withExtension: "mp4", subdirectory: "videos") != nil ||
               Bundle.main.url(forResource: fileName, withExtension: "mov") != nil ||
               Bundle.main.url(forResource: fileName, withExtension: "mov", subdirectory: "videos") != nil
    }
}
