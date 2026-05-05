import Foundation
import SwiftUI
import Combine
import AVFoundation

class ContentManager: ObservableObject {
    static let shared = ContentManager()
    
    @Published var isInitializing = false
    @Published var initializationError: String?
    @Published var workoutContainers: [WorkoutContainer] = []
    @Published private(set) var sortedWorkouts: [WorkoutContainer] = []
    @Published var contentUpdateAvailable = false
    
    private let gitHubContentService: GitHubContentService
    private var cancellables = Set<AnyCancellable>()
    private var updateCheckTimer: Timer?
    
    private init() {
        self.gitHubContentService = GitHubContentService.shared
        self.cancellables = Set<AnyCancellable>()
        
        setupBindings()
        schedulePeriodicUpdates()
    }
    
    // MARK: - Public Methods
    
    /// Initialize content on app startup — loads cache instantly, updates in background
    func initializeContent() async {
        await MainActor.run {
            guard !isInitializing else { return }
            isInitializing = true
            initializationError = nil
        }

        // Step 1: Load from local cache immediately (milliseconds)
        if gitHubContentService.hasCachedWorkouts() {
            do {
                let cached = try await gitHubContentService.loadWorkoutsFromCache()
                await MainActor.run {
                    workoutContainers = cached
                    sortedWorkouts = cached.sorted { $0.totalSeconds(for: .intermediate) < $1.totalSeconds(for: .intermediate) }
                    isInitializing = false
                    ThumbnailCache.shared.preloadThumbnails(for: cached)
                }
                print("Loaded \(cached.count) workouts from cache instantly")

                // Step 2: Check for updates in background
                Task {
                    await gitHubContentService.checkForUpdates()
                }
                return
            } catch {
                print("Cache load failed, falling back to download: \(error)")
            }
        }

        // Step 3: No cache available, download fresh
        do {
            let containers = try await gitHubContentService.loadWorkouts()
            await MainActor.run {
                workoutContainers = containers
                sortedWorkouts = containers.sorted { $0.totalSeconds(for: .intermediate) < $1.totalSeconds(for: .intermediate) }
                ThumbnailCache.shared.preloadThumbnails(for: containers)
            }
            print("Downloaded \(containers.count) workouts")

            Task {
                await gitHubContentService.checkForUpdates()
            }
        } catch {
            await MainActor.run {
                initializationError = "Failed to load workout content: \(error.localizedDescription)"
            }
            print("Failed to load workouts: \(error)")
        }

        await MainActor.run {
            isInitializing = false
        }
    }
    
    /// Force refresh content from GitHub
    func refreshContent() async {
        // Prevent multiple simultaneous refreshes
        await MainActor.run {
            guard !isInitializing else { return }
            isInitializing = true
            initializationError = nil
        }
        
        do {
            // Force clear ALL cache and reset version tracking
            gitHubContentService.clearCache()
            
            // Clear current workouts to ensure fresh state
            await MainActor.run {
                workoutContainers = []
            }
            
            // Download fresh workouts directly (bypassing cache check) with retry logic
            let freshWorkouts = try await downloadWorkoutsWithRetry()
            
            // Update the workouts array with fresh data
            await MainActor.run {
                workoutContainers = freshWorkouts
                sortedWorkouts = freshWorkouts.sorted { $0.totalSeconds(for: .intermediate) < $1.totalSeconds(for: .intermediate) }
                contentUpdateAvailable = false
                // Preload thumbnails for new content
                ThumbnailCache.shared.preloadThumbnails(for: freshWorkouts)
            }
            
            // Download any new videos that aren't cached
            downloadAllVideos()
            
            print("Content refreshed successfully with \(freshWorkouts.count) workouts")
        } catch {
            print("Failed to refresh content: \(error)")
            await MainActor.run {
                initializationError = "Failed to refresh content: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            isInitializing = false
        }
    }
    
    /// Download ALL videos for seamless offline experience
    func downloadAllVideos() {
        Task {
            let allVideos = getAllVideoFiles()
            print("Downloading all \(allVideos.count) videos for offline use...")
            
            for (index, videoFile) in allVideos.enumerated() {
                // Check if video is already cached
                let cacheDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    .appendingPathComponent("GitHubContent")
                let cachedVideoURL = cacheDirectory.appendingPathComponent("videos").appendingPathComponent(videoFile.hasSuffix(".mp4") ? videoFile : "\(videoFile).mp4")
                
                if FileManager.default.fileExists(atPath: cachedVideoURL.path) {
                    print("Already cached (\(index + 1)/\(allVideos.count)): \(videoFile)")
                    continue
                }
                
                do {
                    _ = try await gitHubContentService.downloadVideo(fileName: videoFile)
                    print("Downloaded (\(index + 1)/\(allVideos.count)): \(videoFile)")
                } catch {
                    print("Failed to download \(videoFile): \(error)")
                }
            }
            print("✅ All videos downloaded successfully!")
        }
    }
    
    // MARK: - Private Methods
    
    private func downloadWorkoutsWithRetry() async throws -> [WorkoutContainer] {
        var attempt = 0
        let maxAttempts = 3
        
        repeat {
            attempt += 1
            do {
                return try await gitHubContentService.downloadAndCacheWorkouts()
            } catch {
                if attempt == maxAttempts {
                    throw error
                }
                print("Refresh attempt \(attempt) failed, retrying...")
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            }
        } while attempt < maxAttempts
        
        // This should never be reached due to the throw above, but Swift requires it
        fatalError("Unexpected code path in downloadWorkoutsWithRetry")
    }
    
    private func setupBindings() {
        gitHubContentService.$updateAvailable
            .receive(on: DispatchQueue.main)
            .assign(to: \.contentUpdateAvailable, on: self)
            .store(in: &cancellables)
    }
    
    private func schedulePeriodicUpdates() {
        // Check for updates every 30 minutes when app is active
        updateCheckTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { _ in
            Task { @MainActor in
                await self.gitHubContentService.checkForUpdates()
            }
        }
    }
    
    
    private func getAllVideoFiles() -> [String] {
        // Get ALL video files from all workouts
        var allFiles: [String] = []
        
        for container in workoutContainers {
            for exercise in container.exercises {
                if let videoFile = exercise.videoFile, !videoFile.isEmpty {
                    allFiles.append(videoFile)
                }
            }
        }
        
        // Remove duplicates and return
        return Array(Set(allFiles))
    }
    
    // MARK: - Cache Management
    
    func getCacheInfo() -> (size: String, lastUpdate: Date?) {
        return (
            size: gitHubContentService.getCacheSize(),
            lastUpdate: gitHubContentService.lastUpdateDate
        )
    }
    
    func clearCache() {
        gitHubContentService.clearCache()
        // Reinitialize after clearing
        Task {
            await initializeContent()
        }
    }
    
    deinit {
        updateCheckTimer?.invalidate()
    }
}

// MARK: - Environment Integration

struct ContentManagerEnvironmentKey: EnvironmentKey {
    static let defaultValue = ContentManager.shared
}

extension EnvironmentValues {
    var contentManager: ContentManager {
        get { self[ContentManagerEnvironmentKey.self] }
        set { self[ContentManagerEnvironmentKey.self] = newValue }
    }
}

// MARK: - Thumbnail Cache

/// Singleton cache for exercise video thumbnails
/// Preloads thumbnails in the background when workouts are loaded
class ThumbnailCache: ObservableObject {
    static let shared = ThumbnailCache()

    private let cache = NSCache<NSString, UIImage>()
    private var loadingTasks: [String: Task<Void, Never>] = [:]

    @Published private(set) var loadedCount = 0
    @Published private(set) var totalCount = 0

    private init() {
        cache.countLimit = 200
    }

    /// Get a cached thumbnail, or nil if not yet loaded
    func thumbnail(for videoFile: String?) -> UIImage? {
        guard let videoFile = videoFile, !videoFile.isEmpty else { return nil }
        return cache.object(forKey: videoFile as NSString)
    }

    /// Preload thumbnails for all exercises in the given workouts
    func preloadThumbnails(for workouts: [WorkoutContainer]) {
        var videoFiles: Set<String> = []
        for workout in workouts {
            for exercise in workout.exercises {
                if let videoFile = exercise.videoFile, !videoFile.isEmpty {
                    videoFiles.insert(videoFile)
                }
            }
        }

        totalCount = videoFiles.count
        loadedCount = 0

        let files = Array(videoFiles)
        loadingTasks["_batch"] = Task {
            let batchSize = 4
            for batchStart in stride(from: 0, to: files.count, by: batchSize) {
                guard !Task.isCancelled else { break }
                let batch = files[batchStart..<min(batchStart + batchSize, files.count)]
                await withTaskGroup(of: Void.self) { group in
                    for videoFile in batch {
                        group.addTask {
                            await self.loadSingleThumbnail(for: videoFile)
                        }
                    }
                }
            }
            _ = await MainActor.run { loadingTasks.removeValue(forKey: "_batch") }
        }
    }

    private func loadSingleThumbnail(for videoFile: String) async {
        guard let url = getVideoURL(for: videoFile) else { return }
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        do {
            let (cgImage, _) = try await imageGenerator.image(at: .zero)
            let uiImage = UIImage(cgImage: cgImage)
            await MainActor.run {
                cache.setObject(uiImage, forKey: videoFile as NSString)
                loadedCount += 1
            }
        } catch {}
    }

    private func getVideoURL(for videoFile: String) -> URL? {
        let videoFileName = videoFile.hasSuffix(".mp4") ? videoFile : "\(videoFile).mp4"
        let cacheDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("GitHubContent")
            .appendingPathComponent("videos")
        let localURL = cacheDirectory.appendingPathComponent(videoFileName)

        if FileManager.default.fileExists(atPath: localURL.path) {
            return localURL
        }
        return nil
    }

    func clearCache() {
        cache.removeAllObjects()
        loadedCount = 0
        totalCount = 0
    }
}