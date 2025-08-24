import Foundation
import Combine

class GitHubContentService: ObservableObject {
    static let shared = GitHubContentService()
    
    // GitHub repo info
    private let repoOwner = "banddude"
    private let repoName = "skate-fit-files"
    private let branch = "main"
    
    // Cache directory for downloaded content
    private let cacheDirectory: URL
    private let workoutsFileName = "workouts.json"
    
    @Published var isUpdating = false
    @Published var lastUpdateDate: Date?
    @Published var updateAvailable = false
    
    private let userDefaults = UserDefaults.standard
    private let lastUpdateKey = "GitHubContentLastUpdate"
    private let contentVersionKey = "GitHubContentVersion"
    
    private init() {
        // Set up cache directory in Documents
        let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                    in: .userDomainMask).first!
        self.cacheDirectory = documentsPath.appendingPathComponent("GitHubContent")
        
        // Create cache directory if needed
        try? FileManager.default.createDirectory(at: cacheDirectory, 
                                               withIntermediateDirectories: true)
        
        // Load last update date
        if let date = userDefaults.object(forKey: lastUpdateKey) as? Date {
            self.lastUpdateDate = date
        }
        
        print("GitHubContentService initialized with cache at: \(cacheDirectory.path)")
    }
    
    // MARK: - Public Methods
    
    /// Load workouts.json from cache or download if needed
    func loadWorkouts() async throws -> [WorkoutContainer] {
        let cachedWorkoutsURL = cacheDirectory.appendingPathComponent(workoutsFileName)
        
        // Try to load from cache first
        if FileManager.default.fileExists(atPath: cachedWorkoutsURL.path) {
            print("Loading workouts from cache...")
            let data = try Data(contentsOf: cachedWorkoutsURL)
            let workouts = try JSONDecoder().decode([WorkoutContainer].self, from: data)
            
            // Check for updates in background if cache is older than 1 hour
            if shouldCheckForUpdates() {
                Task { await checkForUpdates() }
            }
            
            return workouts
        } else {
            // No cache, download fresh
            print("No cached workouts found, downloading...")
            return try await downloadAndCacheWorkouts()
        }
    }
    
    /// Download video file from GitHub and cache locally
    func downloadVideo(fileName: String) async throws -> URL {
        let videoFileName = fileName.hasSuffix(".mp4") ? fileName : "\(fileName).mp4"
        let cachedVideoURL = cacheDirectory.appendingPathComponent("videos").appendingPathComponent(videoFileName)
        
        // Return cached version if exists
        if FileManager.default.fileExists(atPath: cachedVideoURL.path) {
            print("Video already cached: \(videoFileName)")
            return cachedVideoURL
        }
        
        // Create videos directory if needed
        let videosDir = cacheDirectory.appendingPathComponent("videos")
        try FileManager.default.createDirectory(at: videosDir, withIntermediateDirectories: true)
        
        // Download from GitHub LFS
        let downloadURL = buildVideoDownloadURL(fileName: videoFileName)
        print("Downloading video: \(downloadURL)")
        
        let (data, _) = try await URLSession.shared.data(from: downloadURL)
        
        // Check if this is an LFS pointer file
        if let dataString = String(data: data, encoding: .utf8),
           dataString.contains("version https://git-lfs.github.com/spec/v1") {
            print("Received LFS pointer, extracting actual download URL...")
            
            // Parse the LFS pointer to get the SHA
            let lines = dataString.components(separatedBy: .newlines)
            guard let oidLine = lines.first(where: { $0.starts(with: "oid sha256:") }),
                  let _ = oidLine.components(separatedBy: ":").last else {
                throw NSError(domain: "GitHubContentService", code: 2, 
                             userInfo: [NSLocalizedDescriptionKey: "Failed to parse LFS pointer"])
            }
            
            // Download from LFS media URL
            let lfsURL = URL(string: "https://media.githubusercontent.com/media/\(repoOwner)/\(repoName)/\(branch)/videos/\(videoFileName)")!
            print("Downloading from LFS media URL: \(lfsURL)")
            
            let (actualData, _) = try await URLSession.shared.data(from: lfsURL)
            try actualData.write(to: cachedVideoURL)
            print("Video cached from LFS: \(videoFileName) (\(actualData.count) bytes)")
            return cachedVideoURL
        } else {
            // Direct file, not LFS
            try data.write(to: cachedVideoURL)
            print("Video cached: \(videoFileName) (\(data.count) bytes)")
            return cachedVideoURL
        }
    }
    
    /// Check if updates are available
    func checkForUpdates() async {
        guard !isUpdating else { return }
        
        await MainActor.run { isUpdating = true }
        
        do {
            let currentVersion = getCurrentContentVersion()
            let latestVersion = try await getLatestContentVersion()
            
            await MainActor.run {
                self.updateAvailable = latestVersion != currentVersion
                self.isUpdating = false
            }
            
            print("Content version check: current=\(currentVersion), latest=\(latestVersion)")
        } catch {
            print("Error checking for updates: \(error)")
            await MainActor.run { isUpdating = false }
        }
    }
    
    /// Force update content from GitHub
    func updateContent() async throws {
        guard !isUpdating else { return }
        
        await MainActor.run { isUpdating = true }
        
        do {
            // Download fresh workouts
            _ = try await downloadAndCacheWorkouts()
            
            // Update version and timestamp
            let latestVersion = try await getLatestContentVersion()
            userDefaults.set(latestVersion, forKey: contentVersionKey)
            userDefaults.set(Date(), forKey: lastUpdateKey)
            
            await MainActor.run {
                self.lastUpdateDate = Date()
                self.updateAvailable = false
                self.isUpdating = false
            }
            
            print("Content updated successfully")
        } catch {
            await MainActor.run { isUpdating = false }
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    func downloadAndCacheWorkouts() async throws -> [WorkoutContainer] {
        // Use GitHub API to bypass CDN caching issues
        let apiURL = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/contents/\(workoutsFileName)")!
        print("Fetching workouts.json info from GitHub API: \(apiURL)")
        
        // Get file info from GitHub API
        let (apiData, _) = try await URLSession.shared.data(from: apiURL)
        
        guard let apiResponse = try JSONSerialization.jsonObject(with: apiData) as? [String: Any],
              let downloadURL = apiResponse["download_url"] as? String else {
            throw NSError(domain: "GitHubContentService", code: 3, 
                         userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL from GitHub API"])
        }
        
        // Add timestamp to force fresh download
        let timestamp = Int(Date().timeIntervalSince1970)
        let freshDownloadURL = URL(string: "\(downloadURL)?cache=\(timestamp)")!
        print("Downloading workouts from fresh URL: \(freshDownloadURL)")
        
        let (data, _) = try await URLSession.shared.data(from: freshDownloadURL)
        print("Downloaded \(data.count) bytes of data")
        
        // Debug: Print first few characters to see what we got
        if let dataString = String(data: data, encoding: .utf8) {
            print("Response preview: \(String(dataString.prefix(200)))")
        }
        
        // Parse and validate
        let workouts = try JSONDecoder().decode([WorkoutContainer].self, from: data)
        print("Parsed \(workouts.count) workouts successfully")
        
        // Debug: Print workout names
        let workoutNames = workouts.map { $0.name }
        print("Workout names: \(workoutNames)")
        
        // Cache the data
        let cachedWorkoutsURL = cacheDirectory.appendingPathComponent(workoutsFileName)
        try data.write(to: cachedWorkoutsURL)
        
        // Update timestamp
        userDefaults.set(Date(), forKey: lastUpdateKey)
        await MainActor.run { lastUpdateDate = Date() }
        
        print("Downloaded and cached \(workouts.count) workouts")
        return workouts
    }
    
    private func buildFileDownloadURL(fileName: String) -> URL {
        // Use raw GitHub URLs for direct file access with cache busting
        let timestamp = Int(Date().timeIntervalSince1970)
        return URL(string: "https://raw.githubusercontent.com/\(repoOwner)/\(repoName)/\(branch)/\(fileName)?cache=\(timestamp)")!
    }
    
    private func buildVideoDownloadURL(fileName: String) -> URL {
        // For LFS files, we need to use GitHub's LFS media download URL
        // First we'll get the LFS pointer, then fetch from the actual LFS storage
        return URL(string: "https://raw.githubusercontent.com/\(repoOwner)/\(repoName)/\(branch)/videos/\(fileName)")!
    }
    
    private func shouldCheckForUpdates() -> Bool {
        guard let lastUpdate = lastUpdateDate else { return true }
        return Date().timeIntervalSince(lastUpdate) > 3600 // 1 hour
    }
    
    private func getCurrentContentVersion() -> String {
        return userDefaults.string(forKey: contentVersionKey) ?? "unknown"
    }
    
    private func getLatestContentVersion() async throws -> String {
        // Use GitHub API to get the latest commit SHA of the main branch
        let apiURL = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/branches/\(branch)")!
        let (data, _) = try await URLSession.shared.data(from: apiURL)
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let commit = json["commit"] as? [String: Any],
           let sha = commit["sha"] as? String {
            return String(sha.prefix(8)) // Use first 8 chars of SHA
        }
        
        throw NSError(domain: "GitHubContentService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get latest version"])
    }
    
    // MARK: - Cache Management
    
    func clearWorkoutsCache() {
        let cachedWorkoutsURL = cacheDirectory.appendingPathComponent(workoutsFileName)
        try? FileManager.default.removeItem(at: cachedWorkoutsURL)
        print("Workouts cache cleared")
    }
    
    func clearCache() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        userDefaults.removeObject(forKey: lastUpdateKey)
        userDefaults.removeObject(forKey: contentVersionKey)
        
        lastUpdateDate = nil
        updateAvailable = false
        
        print("Cache cleared")
    }
    
    func getCacheSize() -> String {
        guard let enumerator = FileManager.default.enumerator(at: cacheDirectory, 
                                                             includingPropertiesForKeys: [.fileSizeKey]) else {
            return "0 MB"
        }
        
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let fileSize = resourceValues.fileSize {
                totalSize += Int64(fileSize)
            }
        }
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }
}
