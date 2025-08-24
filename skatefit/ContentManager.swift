import Foundation
import SwiftUI
import Combine

@MainActor
class ContentManager: ObservableObject {
    static let shared = ContentManager()
    
    @Published var isInitializing = false
    @Published var initializationError: String?
    @Published var workoutContainers: [WorkoutContainer] = []
    @Published var contentUpdateAvailable = false
    
    private let gitHubContentService = GitHubContentService.shared
    private var cancellables = Set<AnyCancellable>()
    private var updateCheckTimer: Timer?
    
    private init() {
        setupBindings()
        schedulePeriodicUpdates()
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
            print("Failed to load from GitHub, trying local fallback: \(error)")
            
            // Fallback to local workouts.json if GitHub fails
            do {
                workoutContainers = try loadLocalWorkouts()
                print("Using local fallback workouts: \(workoutContainers.count)")
            } catch {
                initializationError = "Failed to load workout content: \(error.localizedDescription)"
                print("Complete failure to load workouts: \(error)")
            }
        }
        
        isInitializing = false
    }
    
    /// Force refresh content from GitHub
    func refreshContent() async {
        do {
            try await gitHubContentService.updateContent()
            workoutContainers = try await gitHubContentService.loadWorkouts()
            print("Content refreshed successfully")
        } catch {
            print("Failed to refresh content: \(error)")
            // Keep existing content, don't show error to user unless critical
        }
    }
    
    /// Preload essential videos for offline experience
    func preloadEssentialVideos() {
        Task {
            let essentialVideos = getEssentialVideoFiles()
            print("Preloading \(essentialVideos.count) essential videos...")
            
            for videoFile in essentialVideos.prefix(5) { // Limit to first 5 to avoid overwhelming
                do {
                    _ = try await gitHubContentService.downloadVideo(fileName: videoFile)
                    print("Preloaded: \(videoFile)")
                } catch {
                    print("Failed to preload \(videoFile): \(error)")
                }
            }
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
    
    private func loadLocalWorkouts() throws -> [WorkoutContainer] {
        guard let url = Bundle.main.url(forResource: "workouts", withExtension: "json") else {
            throw NSError(domain: "ContentManager", code: 1, 
                         userInfo: [NSLocalizedDescriptionKey: "Local workouts.json not found"])
        }
        
        let data = try Data(contentsOf: url)
        let workouts = try JSONDecoder().decode([WorkoutContainer].self, from: data)
        return workouts
    }
    
    private func getEssentialVideoFiles() -> [String] {
        // Get video files from first workout of each container for quick startup experience
        var essentialFiles: [String] = []
        
        for container in workoutContainers {
            if let firstExercise = container.exercises.first,
               let videoFile = firstExercise.videoFile {
                essentialFiles.append(videoFile)
            }
        }
        
        return essentialFiles
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