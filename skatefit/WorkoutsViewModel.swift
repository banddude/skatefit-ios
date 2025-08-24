import SwiftUI
import Combine

@MainActor
class WorkoutsViewModel: ObservableObject {
    
    @Published var isLoading = true
    @Published var error: String? = nil
    @Published var searchQuery = ""
    @Published var selectedDifficulty: String? = nil
    @Published var selectedCategory: String? = nil
    @Published var sortOption: SortOption = .newest
    @Published var showFilters = false

    @Published private(set) var allWorkouts: [Workout] = [] // Raw fetched data
    @Published private(set) var filteredAndSortedWorkouts: [Workout] = []
    @Published private(set) var availableDifficulties: [String] = []
    @Published private(set) var availableCategories: [String] = []
    
    @Published var savedWorkoutIDs: Set<String> = Set()
    @Published var savingWorkoutId: String? = nil

    private var networkService = NetworkService.shared // Add NetworkService instance
    private var cancellables = Set<AnyCancellable>()
    private var searchQuerySubject = PassthroughSubject<String, Never>()

    enum SortOption: String, CaseIterable, Identifiable {
        case newest = "Newest First"
        case oldest = "Oldest First"
        case durationAsc = "Duration (Low to High)"
        case durationDesc = "Duration (High to Low)"
        // Add calories later if needed
        // case caloriesAsc = "Calories (Low to High)"
        // case caloriesDesc = "Calories (High to Low)"
        
        var id: String { self.rawValue }
    }

    init() {
        setupBindings()
        fetchInitialData()
    }

    private func setupBindings() {
        // Combine publishers for filters and sorting
        // Use the fetched `allWorkouts` as the base for filtering
        searchQuerySubject
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .combineLatest($selectedDifficulty, $selectedCategory, $sortOption) { query, difficulty, category, sort -> (String, String?, String?, SortOption) in
                return (query, difficulty, category, sort)
            }
            .map { [weak self] (query, difficulty, category, sort) -> [Workout] in
                guard let self = self else { return [] }
                // Filter/sort the currently loaded `allWorkouts`
                return self.filterAndSort(workouts: self.allWorkouts, query: query, difficulty: difficulty, category: category, sort: sort)
            }
            .receive(on: RunLoop.main)
            .assign(to: &$filteredAndSortedWorkouts)
        
        $searchQuery
            .sink { [weak self] query in self?.searchQuerySubject.send(query) }
            .store(in: &cancellables)
    }

    func fetchInitialData() {
        isLoading = true
        error = nil
        
        Task {
            async let workoutsFetch: () = fetchWorkouts()
            async let savedIDsFetch: () = fetchSavedWorkoutIDs()
            
            // Wait for both fetches to complete
            _ = await [workoutsFetch, savedIDsFetch]
            
            // Only set loading to false after both are done (or errored)
            if self.error == nil { // Don't turn off loading if there was an error
                 isLoading = false
            }
        }
    }
    
    // Fetches the main list of workouts
    private func fetchWorkouts() async {
         print("Fetching workouts from Railway server...")
         do {
             let fetchedWorkouts = try await networkService.fetchWorkouts(
                difficulty: selectedDifficulty, 
                category: selectedCategory, 
                search: searchQuery
             )
             self.allWorkouts = fetchedWorkouts
             self.extractFilterOptions() // Update filters based on fetched data
             print("Workouts fetched: \(fetchedWorkouts.count)")
             
         } catch let networkError as NetworkError {
             self.error = "Failed to load workouts: \(networkError.localizedDescription)"
             print("Error fetching workouts: \(networkError)")
             self.isLoading = false
         } catch {
             self.error = "An unexpected error occurred while fetching workouts."
             print("Unexpected error fetching workouts: \(error)")
             self.isLoading = false
         }
     }
     
     // Mock saved workouts for now
     private func fetchSavedWorkoutIDs() async {
         print("Loading mock saved workout IDs...")
         // Mock some saved workouts for testing
         self.savedWorkoutIDs = Set(["67bfcf6059d64837c53941b8"])
         print("Mock saved workout IDs loaded: \(savedWorkoutIDs.count)")
     }

    private func extractFilterOptions() {
        let difficulties = Set(allWorkouts.map { $0.difficulty })
        let categories = Set(allWorkouts.flatMap { $0.categories ?? [] })
        
        self.availableDifficulties = Array(difficulties).sorted()
        self.availableCategories = Array(categories).sorted()
    }

    private func filterAndSort(workouts: [Workout], query: String, difficulty: String?, category: String?, sort: SortOption) -> [Workout] {
        var filtered = workouts

        // Filter by search query
        if !query.isEmpty {
            let lowercasedQuery = query.lowercased()
            filtered = filtered.filter {
                $0.title.lowercased().contains(lowercasedQuery) ||
                ($0.description?.lowercased().contains(lowercasedQuery) ?? false) ||
                ($0.categories?.contains(where: { $0.lowercased().contains(lowercasedQuery) }) ?? false)
            }
        }

        // Filter by difficulty
        if let difficulty = difficulty, !difficulty.isEmpty {
            filtered = filtered.filter { $0.difficulty.caseInsensitiveCompare(difficulty) == .orderedSame }
        }

        // Filter by category
        if let category = category, !category.isEmpty {
            filtered = filtered.filter { $0.categories?.contains(where: { $0.caseInsensitiveCompare(category) == .orderedSame }) ?? false }
        }

        // Sort
        switch sort {
        case .newest:
            filtered.sort { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
        case .oldest:
            filtered.sort { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
        case .durationAsc:
            filtered.sort { $0.duration < $1.duration }
        case .durationDesc:
            filtered.sort { $0.duration > $1.duration }
        }

        return filtered
    }
    
    func clearFilters() {
        selectedDifficulty = nil
        selectedCategory = nil
    }

    // --- Updated Save/Unsave Logic ---
    func toggleSaveWorkout(workoutId: String) {
        guard savingWorkoutId == nil else { return }
        
        savingWorkoutId = workoutId
        let wasSaved = savedWorkoutIDs.contains(workoutId)
        
        Task {
            do {
                if wasSaved {
                    print("Attempting to unsave workout: \(workoutId)")
                    try await networkService.unsaveWorkout(id: workoutId)
                    savedWorkoutIDs.remove(workoutId)
                    print("Unsaved successfully")
                } else {
                    print("Attempting to save workout: \(workoutId)")
                    try await networkService.saveWorkout(id: workoutId)
                    savedWorkoutIDs.insert(workoutId)
                     print("Saved successfully")
                }
            } catch {
                print("Failed to \(wasSaved ? "unsave" : "save") workout \(workoutId): \(error)")
                // Optionally show an error to the user (e.g., via another @Published var)
            }
            savingWorkoutId = nil
        }
    }
} 