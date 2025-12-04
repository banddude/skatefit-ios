import Foundation
import Combine

class GitHubContentService: ObservableObject {
    static let shared = GitHubContentService()
    
    // GitHub repo info (dynamically configured via AppConfig)
    private let repoOwner = AppConfig.githubOwner
    private let repoName = AppConfig.githubRepo
    private let branch = AppConfig.githubBranch
    
    // Cache directory for downloaded content
    private let cacheDirectory: URL
    private let exercisesCacheDir: URL
    private let workoutsCacheDir: URL
    
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
        self.exercisesCacheDir = cacheDirectory.appendingPathComponent("exercises")
        self.workoutsCacheDir = cacheDirectory.appendingPathComponent("workouts")

        // Create cache directories if needed
        try? FileManager.default.createDirectory(at: cacheDirectory,
                                               withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: exercisesCacheDir,
                                               withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: workoutsCacheDir,
                                               withIntermediateDirectories: true)

        // Load last update date
        if let date = userDefaults.object(forKey: lastUpdateKey) as? Date {
            self.lastUpdateDate = date
        }

        print("GitHubContentService initialized with cache at: \(cacheDirectory.path)")
    }
    
    // MARK: - Public Methods
    
    /// Load workouts from cached individual files or download if needed
    func loadWorkouts() async throws -> [WorkoutContainer] {
        // Check if we have cached files
        if hasCachedWorkouts() {
            print("Loading workouts from individual cached files...")
            let workouts = try await loadWorkoutsFromCache()

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

    /// Check if we have cached workout and exercise files
    private func hasCachedWorkouts() -> Bool {
        guard let workoutFiles = try? FileManager.default.contentsOfDirectory(at: workoutsCacheDir, includingPropertiesForKeys: nil),
              let exerciseFiles = try? FileManager.default.contentsOfDirectory(at: exercisesCacheDir, includingPropertiesForKeys: nil) else {
            return false
        }
        return !workoutFiles.isEmpty && !exerciseFiles.isEmpty
    }

    /// Load workouts from cached individual files
    private func loadWorkoutsFromCache() async throws -> [WorkoutContainer] {
        // Load cached exercises
        let exerciseFiles = try FileManager.default.contentsOfDirectory(at: exercisesCacheDir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }

        var exercises: [String: ExerciseData] = [:]
        for fileURL in exerciseFiles {
            let data = try Data(contentsOf: fileURL)
            let exercise = try JSONDecoder().decode(ExerciseData.self, from: data)
            exercises[exercise.id] = exercise
        }

        // Load cached workouts and merge with exercises
        let workoutFiles = try FileManager.default.contentsOfDirectory(at: workoutsCacheDir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }

        var workouts: [WorkoutContainer] = []
        for fileURL in workoutFiles {
            let data = try Data(contentsOf: fileURL)
            let workoutRef = try JSONDecoder().decode(WorkoutReference.self, from: data)

            // Merge exercise data
            let mergedExercises = workoutRef.exercises.compactMap { ref -> WorkoutExercise? in
                guard let exercise = exercises[ref.exerciseId] else {
                    print("Warning: Exercise '\(ref.exerciseId)' not found in cache")
                    return nil
                }

                return WorkoutExercise(
                    section: ref.section ?? exercise.section ?? "Main",
                    move: exercise.move,
                    description: exercise.description,
                    detailedDescription: exercise.detailedDescription,
                    jsonFile: exercise.jsonFile,
                    videoFile: exercise.videoFile,
                    beginner: ref.beginner ?? exercise.beginner,
                    intermediate: ref.intermediate ?? exercise.intermediate,
                    advanced: ref.advanced ?? exercise.advanced,
                    exerciseType: exercise.exerciseType,
                    equipment: exercise.equipment,
                    targetMuscles: exercise.targetMuscles,
                    benefit: exercise.benefit,
                    durationPerRep: exercise.durationPerRep
                )
            }

            workouts.append(WorkoutContainer(
                name: workoutRef.name,
                icon: workoutRef.icon,
                color: workoutRef.color,
                exercises: mergedExercises
            ))
        }

        print("Loaded \(workouts.count) workouts from cache")
        return workouts
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
            let lfsURL = URL(string: "https://media.githubusercontent.com/media/\(repoOwner)/\(repoName)/\(branch)/\(AppConfig.contentFolder)/videos/\(videoFileName)")!
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
        // Step 1: Download and cache all exercise files individually
        print("Downloading exercises from GitHub...")
        let exercises = try await downloadAndCacheExercises()
        print("Downloaded and cached \(exercises.count) exercises")

        // Step 2: Download and cache all workout files individually
        print("Downloading workout files from GitHub...")
        let workoutFiles = try await downloadAndCacheWorkoutFiles()
        print("Downloaded and cached \(workoutFiles.count) workout files")

        // Step 3: Merge exercise data with workout references in memory
        var workouts: [WorkoutContainer] = []
        for workoutRef in workoutFiles {
            let mergedExercises = workoutRef.exercises.compactMap { ref -> WorkoutExercise? in
                guard let exercise = exercises[ref.exerciseId] else {
                    print("Warning: Exercise '\(ref.exerciseId)' not found")
                    return nil
                }

                return WorkoutExercise(
                    section: ref.section ?? exercise.section ?? "Main",
                    move: exercise.move,
                    description: exercise.description,
                    detailedDescription: exercise.detailedDescription,
                    jsonFile: exercise.jsonFile,
                    videoFile: exercise.videoFile,
                    beginner: ref.beginner ?? exercise.beginner,
                    intermediate: ref.intermediate ?? exercise.intermediate,
                    advanced: ref.advanced ?? exercise.advanced,
                    exerciseType: exercise.exerciseType,
                    equipment: exercise.equipment,
                    targetMuscles: exercise.targetMuscles,
                    benefit: exercise.benefit,
                    durationPerRep: exercise.durationPerRep
                )
            }

            workouts.append(WorkoutContainer(
                name: workoutRef.name,
                icon: workoutRef.icon,
                color: workoutRef.color,
                exercises: mergedExercises
            ))
        }

        // Update timestamp
        userDefaults.set(Date(), forKey: lastUpdateKey)
        await MainActor.run { lastUpdateDate = Date() }

        print("Successfully loaded \(workouts.count) workouts")
        return workouts
    }
    
    // Helper: Download and cache all exercise files individually
    private func downloadAndCacheExercises() async throws -> [String: ExerciseData] {
        let apiURL = URL(string: "\(AppConfig.githubAPIBaseURL)/contents/\(AppConfig.contentFolder)/exercises")!
        let (data, _) = try await URLSession.shared.data(from: apiURL)

        guard let files = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw NSError(domain: "GitHubContentService", code: 4,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to list exercise files"])
        }

        var exercises: [String: ExerciseData] = [:]

        for file in files {
            guard let fileName = file["name"] as? String,
                  fileName.hasSuffix(".json"),
                  let downloadURL = file["download_url"] as? String else { continue }

            let (exerciseData, _) = try await URLSession.shared.data(from: URL(string: downloadURL)!)
            let exercise = try JSONDecoder().decode(ExerciseData.self, from: exerciseData)
            exercises[exercise.id] = exercise

            // Cache the individual exercise file
            let cacheURL = exercisesCacheDir.appendingPathComponent(fileName)
            try exerciseData.write(to: cacheURL)
        }

        return exercises
    }

    // Helper: Download and cache all workout files individually
    private func downloadAndCacheWorkoutFiles() async throws -> [WorkoutReference] {
        let apiURL = URL(string: "\(AppConfig.githubAPIBaseURL)/contents/\(AppConfig.contentFolder)/workouts")!
        let (data, _) = try await URLSession.shared.data(from: apiURL)

        guard let files = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw NSError(domain: "GitHubContentService", code: 5,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to list workout files"])
        }

        var workoutRefs: [WorkoutReference] = []

        for file in files {
            guard let fileName = file["name"] as? String,
                  fileName.hasSuffix(".json"),
                  let downloadURL = file["download_url"] as? String else { continue }

            let (workoutData, _) = try await URLSession.shared.data(from: URL(string: downloadURL)!)
            let workoutRef = try JSONDecoder().decode(WorkoutReference.self, from: workoutData)
            workoutRefs.append(workoutRef)

            // Cache the individual workout file
            let cacheURL = workoutsCacheDir.appendingPathComponent(fileName)
            try workoutData.write(to: cacheURL)
        }

        return workoutRefs
    }

    private func buildFileDownloadURL(fileName: String) -> URL {
        // Use raw GitHub URLs for direct file access with cache busting
        let timestamp = Int(Date().timeIntervalSince1970)
        return URL(string: "\(AppConfig.contentBaseURL)/\(fileName)?cache=\(timestamp)")!
    }
    
    private func buildVideoDownloadURL(fileName: String) -> URL {
        // For LFS files, we need to use GitHub's LFS media download URL
        // First we'll get the LFS pointer, then fetch from the actual LFS storage
        return URL(string: "\(AppConfig.contentBaseURL)/videos/\(fileName)")!
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
        let apiURL = URL(string: "\(AppConfig.githubAPIBaseURL)/branches/\(branch)")!
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
        // Clear individual workout files
        try? FileManager.default.removeItem(at: workoutsCacheDir)
        try? FileManager.default.createDirectory(at: workoutsCacheDir, withIntermediateDirectories: true)

        // Clear individual exercise files
        try? FileManager.default.removeItem(at: exercisesCacheDir)
        try? FileManager.default.createDirectory(at: exercisesCacheDir, withIntermediateDirectories: true)

        print("Workouts and exercises cache cleared")
    }
    
    func clearCache() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: exercisesCacheDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: workoutsCacheDir, withIntermediateDirectories: true)

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
