import Foundation

// Basic Network Service for API Calls

// Define potential errors
enum NetworkError: Error, Equatable {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error)
    case serverError(statusCode: Int, message: String?)
    case unauthorized
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed(let error):
            return "Network request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message ?? "Unknown error")"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
    
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.invalidResponse, .invalidResponse),
             (.unauthorized, .unauthorized):
            return true
        case (.requestFailed(let lhsError), .requestFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.decodingError(let lhsError), .decodingError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.serverError(let lhsCode, let lhsMsg), .serverError(let rhsCode, let rhsMsg)):
            return lhsCode == rhsCode && lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

// Basic response structure for login/register if needed
struct AuthResponse: Codable {
    let token: String
    // Include user data if returned
}

// Response wrapper for workouts endpoint
struct WorkoutsResponse: Codable {
    let workouts: [Workout]
    let page: Int
    let pages: Int
    let total: Int
}

// Simple error message structure from server
struct ErrorMessage: Codable {
    let message: String
}

@MainActor
class NetworkService {
    static let shared = NetworkService()
    private init() {} // Singleton

    private let baseURL = URL(string: "https://skatefit-server-production.up.railway.app")!
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    // Store the auth token (simple implementation, consider Keychain for production)
    private var authToken: String? {
        didSet {
            // Persist token if needed (e.g., UserDefaults or Keychain)
            print("Auth Token Set: \(authToken ?? "nil")")
        }
    }

    // Function to set the token (e.g., after login)
    func setAuthToken(_ token: String?) {
        self.authToken = token
    }

    // Generic function for making requests
    private func makeRequest<T: Decodable>(endpoint: String, method: String = "GET", body: Data? = nil, requiresAuth: Bool = true) async throws -> T {
        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth {
            guard let token = authToken else {
                print("Auth token missing for authenticated request to \(endpoint)")
                throw NetworkError.unauthorized
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = body
        }

        print("Making request: [\(method)] \(url.absoluteString)")
        
        let (data, response): (Data, URLResponse)
        do {
            let result = try await URLSession.shared.data(for: request)
            data = result.0
            response = result.1
        } catch {
            print("Network request failed with error: \(error)")
            print("Error details: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("URLError code: \(urlError.code.rawValue)")
                print("URLError description: \(urlError.localizedDescription)")
            }
            throw NetworkError.requestFailed(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid response type")
            throw NetworkError.invalidResponse
        }

        print("Response Status Code: \(httpResponse.statusCode)")
        print("Response Data Size: \(data.count) bytes")
        
        if data.count > 0 {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response preview: \(String(responseString.prefix(200)))")
            }
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
             if httpResponse.statusCode == 401 { // Unauthorized
                 throw NetworkError.unauthorized
             }
             // Try to decode server error message
             let errorMessage = try? decoder.decode(ErrorMessage.self, from: data)
             print("Server Error [\(httpResponse.statusCode)]: \(errorMessage?.message ?? "No message")")
             throw NetworkError.serverError(statusCode: httpResponse.statusCode, message: errorMessage?.message)
        }

        do {
            // Configure decoder (e.g., date handling)
            decoder.dateDecodingStrategy = .iso8601 // Common strategy for JS dates
            let decodedObject = try decoder.decode(T.self, from: data)
            return decodedObject
        } catch {
             print("Decoding Error for \(T.self): \(error)")
            throw NetworkError.decodingError(error)
        }
    }
    
    // --- Specific API Call Functions ---
    
    // MARK: - Authentication
    func login(credentials: LoginCredentials) async throws -> AuthResponse {
         let endpoint = "api/users/login"
         let body = try encoder.encode(credentials)
         // Login response likely contains the token
         let response: AuthResponse = try await makeRequest(endpoint: endpoint, method: "POST", body: body, requiresAuth: false)
         setAuthToken(response.token) // Store the token upon successful login
         return response
    }
    
    func register(credentials: RegisterCredentials) async throws -> AuthResponse {
         let endpoint = "api/users/register"
         let body = try encoder.encode(credentials)
         let response: AuthResponse = try await makeRequest(endpoint: endpoint, method: "POST", body: body, requiresAuth: false)
         setAuthToken(response.token) // Store token on registration too
         return response
    }
    
    // MARK: - Workouts
    func fetchWorkouts(difficulty: String?, category: String?, search: String?) async throws -> [Workout] {
        var queryItems: [URLQueryItem] = []
        if let difficulty = difficulty { queryItems.append(URLQueryItem(name: "difficulty", value: difficulty)) }
        if let category = category { queryItems.append(URLQueryItem(name: "category", value: category)) }
        if let search = search, !search.isEmpty { queryItems.append(URLQueryItem(name: "search", value: search)) }
        
        var components = URLComponents()
        components.path = "api/workouts"
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let endpoint = components.string else { throw NetworkError.invalidURL }
        
        let response: WorkoutsResponse = try await makeRequest(endpoint: endpoint, method: "GET", requiresAuth: false)
        return response.workouts
    }
    
     func fetchSavedWorkoutIDs() async throws -> [String] {
         // Assuming the profile endpoint returns saved workout IDs
         // Adjust if there's a dedicated endpoint
         let profile: UserProfile = try await fetchUserProfile()
         return profile.savedWorkouts ?? []
     }
     
    func saveWorkout(id: String) async throws {
        let endpoint = "api/users/workouts/save/\(id)"
        // The request itself is the action, no specific response needed beyond success/failure
        let _: EmptyResponse = try await makeRequest(endpoint: endpoint, method: "POST", requiresAuth: true)
    }
    
    func unsaveWorkout(id: String) async throws {
        let endpoint = "api/users/workouts/save/\(id)"
        let _: EmptyResponse = try await makeRequest(endpoint: endpoint, method: "DELETE", requiresAuth: true)
    }
    
    // MARK: - User Profile / Dashboard
    func fetchUserProfile() async throws -> UserProfile {
         // Assuming profile endpoint returns all needed data (stats, saved items)
         let endpoint = "api/users/profile"
         return try await makeRequest(endpoint: endpoint, requiresAuth: true)
    }
    
    // MARK: - Blog Posts
    func fetchBlogPosts() async throws -> [BlogPost] {
        let endpoint = "api/blog"
        return try await makeRequest(endpoint: endpoint, method: "GET", requiresAuth: false)
    }
    
    func fetchBlogPost(id: String) async throws -> BlogPost {
        let endpoint = "api/blog/\(id)"
        return try await makeRequest(endpoint: endpoint, method: "GET", requiresAuth: false)
    }
    
    // MARK: - Exercises (Add similar functions as needed)
    // func fetchExercises(...) async throws -> [Exercise] { ... }
    // func saveExercise(...) async throws { ... }
    // func unsaveExercise(...) async throws { ... }
}

// Helper struct for empty responses if API returns {} or similar on success
struct EmptyResponse: Codable {}

// Placeholder credentials structs (match API expectations)
struct LoginCredentials: Codable {
    let email: String
    let password: String
}

struct RegisterCredentials: Codable {
    let name: String // Assuming name is needed for registration
    let email: String
    let password: String
}

// UserProfile struct moved to Models.swift 