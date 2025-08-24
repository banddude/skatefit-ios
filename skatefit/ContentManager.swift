import Foundation
import SwiftUI
import Combine

@MainActor
class ContentManager: ObservableObject {
    nonisolated static let shared = ContentManager()
    
    @Published var isInitializing = false
    @Published var initializationError: String?
    @Published var workoutContainers: [WorkoutContainer] = []
    @Published var contentUpdateAvailable = false
    
    private let gitHubContentService: GitHubContentService
    private var cancellables = Set<AnyCancellable>()
    private var updateCheckTimer: Timer?
    
    nonisolated private init() {
        self.gitHubContentService = GitHubContentService.shared
        self.cancellables = Set<AnyCancellable>()
        
        Task { @MainActor in
            setupBindings()
            schedulePeriodicUpdates()
        }
    }
    
    // MARK: - Public Methods
    
    /// Initialize content on app startup
    func initializeContent() async {
        guard !isInitializing else { return }
        
        isInitializing = true
        initializationError = nil
        
        do {
            // First try to load from GitHub (cached or fresh)
            workoutContainers = try await gitHubContentService.loadWorkouts()
            
            // Check for updates in background
            await gitHubContentService.checkForUpdates()
            
            print("Content initialized successfully with \(workoutContainers.count) workouts")
            
        } catch {
            initializationError = "Failed to load workout content from GitHub: \(error.localizedDescription)"
            print("Failed to load workouts from GitHub: \(error)")
        }
        
        isInitializing = false
    }
    
    /// Force refresh content from GitHub
    func refreshContent() async {
        // Prevent multiple simultaneous refreshes
        guard !isInitializing else { return }
        
        isInitializing = true
        initializationError = nil
        
        do {
            // Force clear ALL cache and reset version tracking
            gitHubContentService.clearCache()
            
            // Clear current workouts to ensure fresh state
            workoutContainers = []
            
            // Download fresh workouts directly (bypassing cache check) with retry logic
            var freshWorkouts: [WorkoutContainer] = []
            var attempt = 0
            let maxAttempts = 3
            
            repeat {
                attempt += 1
                do {
                    freshWorkouts = try await gitHubContentService.downloadAndCacheWorkouts()
                    break
                } catch {
                    if attempt == maxAttempts {
                        throw error
                    }
                    print("Refresh attempt \(attempt) failed, retrying...")
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                }
            } while attempt < maxAttempts
            
            // Update the workouts array with fresh data
            workoutContainers = freshWorkouts
            contentUpdateAvailable = false
            
            // Download any new videos that aren't cached
            downloadAllVideos()
            
            print("Content refreshed successfully with \(freshWorkouts.count) workouts")
        } catch {
            print("Failed to refresh content: \(error)")
            initializationError = "Failed to refresh content: \(error.localizedDescription)"
        }
        
        isInitializing = false
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
    
    private func setupBindings() {
        // Listen to GitHub service update availability
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