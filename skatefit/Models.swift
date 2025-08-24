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

// MARK: - Workout Exercise Model
struct WorkoutExercise: Identifiable, Codable {
    let id = UUID()
    var section: String
    var move: String
    var description: String
    var jsonFile: String
    var videoFile: String? // Video file name (without extension)
    var beginner: String
    var intermediate: String
    var advanced: String
    
    enum CodingKeys: String, CodingKey {
        case section, move, description
        case jsonFile = "json_file"
        case videoFile = "video_file"
        case beginner, intermediate, advanced
    }
    
    func instructions(for difficulty: WorkoutDifficulty) -> String {
        switch difficulty {
        case .beginner: return beginner
        case .intermediate: return intermediate
        case .advanced: return advanced
        }
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