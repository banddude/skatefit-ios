import Foundation
import SwiftUI // For Color

// Placeholder User Stats Model
struct UserStats {
    var totalWorkouts: Int = 0
    var workoutMinutes: Int = 0
    var currentStreak: Int = 0
    var caloriesBurned: Int = 0
    var recentWorkoutsCount: Int = 0
    var recentMinutes: Int = 0
    var recentCalories: Int = 0
    var lastWorkoutDate: Date? = nil
}

// Placeholder Workout Model
struct Workout: Identifiable, Codable {
    let id = UUID()
    var workoutId: String // Original ID from backend
    var title: String
    var description: String? = nil
    var difficulty: String
    var duration: Int // Minutes - Might represent total calculated duration
    var thumbnailUrl: String? = nil // URL String
    var isPremium: Bool = false
    var completedDate: Date? = nil
    var equipment: [String]? = [] // Added from React code
    var categories: [String]? = [] // Added from React code
    var createdAt: Date? = nil // Added from React code
    var instructor: String? = nil
    var videoUrl: String? = nil
    var benefits: [String]? = []
    var estimatedCalories: Int? = nil
    var targetMuscleGroups: [String]? = []
    
    enum CodingKeys: String, CodingKey {
        case workoutId = "_id"
        case title
        case description
        case difficulty
        case duration
        case thumbnailUrl
        case isPremium
        case completedDate
        case equipment
        case categories
        case createdAt
        case instructor
        case videoUrl
        case benefits
        case estimatedCalories
        case targetMuscleGroups
    }
}

// Placeholder Exercise Model
struct Exercise: Identifiable, Codable {
    let id = UUID()
    var exerciseId: String // Original ID from backend
    var name: String
    var targetMuscles: String? = nil
    var difficulty: String? = nil
    var equipment: String? = nil
    var thumbnailUrl: String? = nil // URL String
    var muscleDiagramUrl: String? = nil // URL String
    // Add other fields as needed
    
    enum CodingKeys: String, CodingKey {
        case exerciseId
        case name
        case targetMuscles
        case difficulty
        case equipment
        case thumbnailUrl
        case muscleDiagramUrl
    }
}

// Struct for displayable stat item
struct StatItem: Identifiable {
    let id = UUID()
    let name: String
    let value: String
    let iconName: String
    let change: String
    let changeType: StatChangeType
}

enum StatChangeType {
    case positive, negative, neutral
    
    var color: Color {
        switch self {
        case .positive: return .green
        case .negative: return .red
        case .neutral: return .gray
        }
    }
}

// MARK: - Workout Difficulty
enum WorkoutDifficulty: String, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
    
    var color: Color {
        switch self {
        case .beginner: return .mint
        case .intermediate: return .blue
        case .advanced: return .purple
        }
    }
}

// MARK: - Structured Exercise Data (from `data` block in exercise JSON)

struct EquipmentSpec: Codable {
    var kind: String
    var intensity: String?
    var weightLb: Double?
    var weightLbHigh: Double?
    var weightCount: Int?

    enum CodingKeys: String, CodingKey {
        case kind, intensity
        case weightLb = "weight_lb"
        case weightLbHigh = "weight_lb_high"
        case weightCount = "weight_count"
    }

    func displayString() -> String? {
        let bareKinds: Set<String> = ["none", "bodyweight"]
        if bareKinds.contains(kind) { return nil }

        let lbStr: String? = {
            guard let lb = weightLb else { return nil }
            if let high = weightLbHigh { return "\(formatNumber(lb))-\(formatNumber(high)) lb" }
            return "\(formatNumber(lb)) lb"
        }()

        if let count = weightCount, count > 1, let lb = lbStr {
            return "\(count)×\(lb) \(kind)"
        }
        if let lb = lbStr {
            return "\(lb) \(kind)"
        }
        if let intensity = intensity {
            return "\(intensity) \(kind)"
        }
        return kind
    }
}

struct DPRData: Codable {
    var seconds: Double?
    var secondsHigh: Double?
    var phases: [String]?
    var perUnit: String?
    var descriptor: String?
    var mode: String?
    var pulses: Int?

    enum CodingKeys: String, CodingKey {
        case seconds
        case secondsHigh = "seconds_high"
        case phases
        case perUnit = "per_unit"
        case descriptor, mode, pulses
    }
}

struct LevelData: Codable {
    var count: Double?
    var countHigh: Double?
    var unit: String?
    var holdSeconds: Double?
    var holdSecondsHigh: Double?
    var durationSeconds: Double?
    var per: String?
    var rounds: Int?
    var secondaryHoldSeconds: Double?
    var pulses: Int?
    var equipment: EquipmentSpec?
    var totalSeconds: Int?

    enum CodingKeys: String, CodingKey {
        case count
        case countHigh = "count_high"
        case unit
        case holdSeconds = "hold_seconds"
        case holdSecondsHigh = "hold_seconds_high"
        case durationSeconds = "duration_seconds"
        case per, rounds, pulses, equipment
        case secondaryHoldSeconds = "secondary_hold_seconds"
        case totalSeconds = "total_seconds"
    }

    func displayString() -> String {
        var parts: [String] = []

        if let count = count {
            var qty = formatNumber(count)
            if let high = countHigh { qty = "\(formatNumber(count))-\(formatNumber(high))" }
            parts.append("\(qty) \(unit ?? "reps")")
        } else if let hold = holdSeconds {
            var s = formatNumber(hold)
            if let high = holdSecondsHigh { s = "\(formatNumber(hold))-\(formatNumber(high))" }
            parts.append("\(s) sec hold")
        } else if let dur = durationSeconds {
            parts.append("\(formatNumber(dur)) sec")
        }

        if let per = per {
            switch per {
            case "side": parts.append("each side")
            case "leg": parts.append("each leg")
            case "foot": parts.append("each foot")
            case "direction": parts.append("each direction")
            case "way": parts.append("each way")
            default: parts.append("each \(per)")
            }
        }

        if let pulses = pulses {
            parts.append("\(pulses) pulses")
        }

        if let secHold = secondaryHoldSeconds, count != nil || holdSeconds == nil {
            parts.append("\(formatNumber(secHold)) sec hold")
        }

        if let rounds = rounds, rounds > 1 {
            parts.append("\(rounds) rounds")
        }

        if let eq = equipment?.displayString() {
            parts.append(eq)
        }

        return parts.joined(separator: " · ")
    }
}

struct ExerciseStructured: Codable {
    var dpr: DPRData?
    var beginner: LevelData?
    var intermediate: LevelData?
    var advanced: LevelData?

    func level(for difficulty: WorkoutDifficulty) -> LevelData? {
        switch difficulty {
        case .beginner: return beginner
        case .intermediate: return intermediate
        case .advanced: return advanced
        }
    }
}

struct DurationSecondsByLevel: Codable {
    var beginner: Int?
    var intermediate: Int?
    var advanced: Int?

    func seconds(for difficulty: WorkoutDifficulty) -> Int {
        switch difficulty {
        case .beginner: return beginner ?? 0
        case .intermediate: return intermediate ?? 0
        case .advanced: return advanced ?? 0
        }
    }
}

private func formatNumber(_ v: Double) -> String {
    if v.truncatingRemainder(dividingBy: 1) == 0 { return "\(Int(v))" }
    return String(format: "%g", v)
}

func formatDuration(_ seconds: Int) -> String {
    if seconds < 60 { return "\(seconds)s" }
    let m = seconds / 60
    let s = seconds % 60
    return s == 0 ? "\(m) min" : "\(m)m \(s)s"
}

// MARK: - Workout Exercise Model
struct WorkoutExercise: Identifiable, Codable {
    let id = UUID()
    var section: String
    var move: String
    var description: String
    var detailedDescription: String?
    var jsonFile: String
    var videoFile: String? // Video file name (without extension)
    var beginner: String
    var intermediate: String
    var advanced: String
    var exerciseType: [String]?
    var equipment: [String]?
    var targetMuscles: [String]?
    var benefit: String?
    var durationPerRep: String?
    var data: ExerciseStructured?
    var durationSeconds: DurationSecondsByLevel?
    var transitionSeconds: Int?

    enum CodingKeys: String, CodingKey {
        case section, move, description
        case detailedDescription = "detailed_description"
        case jsonFile = "json_file"
        case videoFile = "video_file"
        case beginner, intermediate, advanced
        case exerciseType = "exercise_type"
        case equipment
        case targetMuscles = "target_muscles"
        case benefit = "benefit"
        case durationPerRep = "duration_per_rep"
        case data
        case durationSeconds = "duration_seconds"
        case transitionSeconds = "transition_seconds"
    }

    func instructions(for difficulty: WorkoutDifficulty) -> String {
        if let level = data?.level(for: difficulty) {
            let s = level.displayString()
            if !s.isEmpty { return s }
        }
        switch difficulty {
        case .beginner: return beginner
        case .intermediate: return intermediate
        case .advanced: return advanced
        }
    }

    func workSeconds(for difficulty: WorkoutDifficulty) -> Int {
        if let s = durationSeconds?.seconds(for: difficulty), s > 0 { return s }
        return data?.level(for: difficulty)?.totalSeconds ?? 0
    }

    func totalSeconds(for difficulty: WorkoutDifficulty) -> Int {
        workSeconds(for: difficulty) + (transitionSeconds ?? 0)
    }

    func getVideoURL() -> URL? {
        guard let videoFile = videoFile, !videoFile.isEmpty else {
            print("⚠️ No video file specified for exercise: \(move)")
            return nil
        }
        return VideoService.shared.getVideoURL(for: videoFile)
    }

    var videoFileName: String {
        return videoFile ?? jsonFile.replacingOccurrences(of: ".json", with: "")
    }
}

// MARK: - Workout Container Model
struct WorkoutContainer: Identifiable, Codable {
    let id = UUID()
    var name: String
    var icon: String?
    var color: String?
    var exercises: [WorkoutExercise]
    private var _cache = WorkoutCache()

    init(name: String, icon: String? = nil, color: String? = nil, exercises: [WorkoutExercise]) {
        self.name = name
        self.icon = icon
        self.color = color
        self.exercises = exercises
    }

    enum CodingKeys: String, CodingKey {
        case name, icon, color, exercises
    }
    
    // Helper computed properties for SwiftUI
    var workoutIcon: String {
        return icon ?? "figure.run"
    }
    
    var workoutColor: Color {
        switch color?.lowercased() {
        case "blue": return .blue
        case "orange": return .orange
        case "purple": return .purple
        case "teal": return .teal
        case "green": return .green
        case "red": return .red
        case "yellow": return .yellow
        case "pink": return .pink
        case "gray": return .gray
        default: return .gray
        }
    }

    func totalSeconds(for difficulty: WorkoutDifficulty) -> Int {
        let key = difficulty.rawValue
        if let cached = _cache.totalSeconds[key] { return cached }
        let exerciseTotal = exercises.reduce(0) { $0 + $1.totalSeconds(for: difficulty) }
        let sectionBreaks = max(0, distinctSectionCount - 1) * 30
        let result = exerciseTotal + sectionBreaks
        _cache.totalSeconds[key] = result
        return result
    }

    private var distinctSectionCount: Int {
        if let cached = _cache.sectionCount { return cached }
        var seen: Set<String> = []
        var count = 0
        for ex in exercises {
            if !seen.contains(ex.section) {
                seen.insert(ex.section)
                count += 1
            }
        }
        _cache.sectionCount = count
        return count
    }
}

private final class WorkoutCache {
    var totalSeconds: [String: Int] = [:]
    var sectionCount: Int?
}

// MARK: - GitHub Data Loading Models

// ExerciseData: Matches the JSON structure in the exercises/ folder
struct ExerciseData: Codable {
    let id: String
    let move: String
    let description: String
    let detailedDescription: String?
    let section: String?
    let exerciseType: [String]?
    let equipment: [String]?
    let targetMuscles: [String]?
    let videoFile: String?
    let jsonFile: String
    let beginner: String
    let intermediate: String
    let advanced: String
    let benefit: String?
    let durationPerRep: String?
    let data: ExerciseStructured?
    let durationSeconds: DurationSecondsByLevel?
    let transitionSeconds: Int?

    enum CodingKeys: String, CodingKey {
        case id, move, description
        case detailedDescription = "detailed_description"
        case section
        case exerciseType = "exercise_type"
        case equipment
        case targetMuscles = "target_muscles"
        case videoFile = "video_file"
        case jsonFile = "json_file"
        case beginner, intermediate, advanced
        case benefit = "benefit"
        case durationPerRep = "duration_per_rep"
        case data
        case durationSeconds = "duration_seconds"
        case transitionSeconds = "transition_seconds"
    }

    // Custom decoder to handle both String and [String] for exercise_type and equipment
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        move = try container.decode(String.self, forKey: .move)
        description = try container.decode(String.self, forKey: .description)
        detailedDescription = try? container.decode(String.self, forKey: .detailedDescription)
        section = try? container.decode(String.self, forKey: .section)
        targetMuscles = try? container.decode([String].self, forKey: .targetMuscles)
        videoFile = try? container.decode(String.self, forKey: .videoFile)
        jsonFile = try container.decode(String.self, forKey: .jsonFile)
        beginner = try container.decode(String.self, forKey: .beginner)
        intermediate = try container.decode(String.self, forKey: .intermediate)
        advanced = try container.decode(String.self, forKey: .advanced)
        benefit = try? container.decode(String.self, forKey: .benefit)
        durationPerRep = try? container.decode(String.self, forKey: .durationPerRep)
        data = try? container.decode(ExerciseStructured.self, forKey: .data)
        durationSeconds = try? container.decode(DurationSecondsByLevel.self, forKey: .durationSeconds)
        transitionSeconds = try? container.decode(Int.self, forKey: .transitionSeconds)

        // Handle exercise_type as either String or [String]
        if let typeArray = try? container.decode([String].self, forKey: .exerciseType) {
            exerciseType = typeArray
        } else if let typeString = try? container.decode(String.self, forKey: .exerciseType) {
            exerciseType = [typeString]
        } else {
            exerciseType = nil
        }

        // Handle equipment as either String or [String]
        if let equipArray = try? container.decode([String].self, forKey: .equipment) {
            equipment = equipArray
        } else if let equipString = try? container.decode(String.self, forKey: .equipment) {
            equipment = [equipString]
        } else {
            equipment = nil
        }
    }
}

// ExerciseReference: References in workout files
struct ExerciseReference: Codable {
    let exerciseId: String
    let section: String?
    let beginner: String?
    let intermediate: String?
    let advanced: String?

    enum CodingKeys: String, CodingKey {
        case exerciseId = "exercise_id"
        case section, beginner, intermediate, advanced
    }
}

// WorkoutReference: Matches workout JSON files from workouts/ folder
struct WorkoutReference: Codable {
    let name: String
    let icon: String?
    let color: String?
    let exercises: [ExerciseReference]
}

// MARK: - API Specific Models

// Blog Post Model (Matches API Response)
struct BlogPost: Identifiable, Codable {
    let id = UUID()
    var blogId: String // Original _id from backend
    var title: String
    var content: String
    var excerpt: String
    var date: String
    var featuredImage: FeaturedImage
    var tags: [String]
    var published: Bool
    var createdAt: String?
    var updatedAt: String?
    
    struct FeaturedImage: Codable {
        var url: String
        var alt: String
    }
    
    enum CodingKeys: String, CodingKey {
        case blogId = "_id"
        case title, content, excerpt, date, featuredImage, tags, published, createdAt, updatedAt
    }
}

// User Profile Model (Matches API Response)
struct UserProfile: Codable {
    // Let's assume the API might use _id for user ID
    let id: String? // Optional: Map from _id if needed during decoding
    let name: String
    let email: String
    // Dashboard stats fields (make non-optional based on API guarantees, or keep optional)
    let totalWorkouts: Int? 
    let workoutMinutes: Int?
    let currentStreak: Int?
    let caloriesBurned: Int?
    let lastWorkoutDate: String? // Keep as ISO String from backend
    // Saved items
    let savedWorkouts: [String]? // Array of Workout IDs
    let savedExercises: [String]? // Array of Exercise IDs
    // Add other fields from API as needed (location, bio, etc.)
    
    // If API uses _id, provide custom coding keys
    enum CodingKeys: String, CodingKey {
        case id = "_id" // Map _id from JSON to id property
        case name, email, totalWorkouts, workoutMinutes, currentStreak, caloriesBurned, lastWorkoutDate, savedWorkouts, savedExercises
    }
}

// Modify Workout and Exercise to include API ID (_id) if needed
// Example for Workout:
/*
 struct Workout: Identifiable, Codable { // Make Codable
     let id = UUID() // Keep for SwiftUI Identifiable conformance
     let apiId: String // Store the _id from the API
     var title: String
     // ... other properties ...
 
     enum CodingKeys: String, CodingKey {
         case apiId = "_id"
         case title // Map other keys explicitly if needed
         // ... map other properties ...
     }
 }
 */ 
