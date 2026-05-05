import SwiftUI
import Foundation

// MARK: - Root Structure
struct OnboardingData: Codable {
    let onboarding: OnboardingContent
}

struct OnboardingContent: Codable {
    let welcome: WelcomeSection
    let difficulty: InfoSection
    let equipment: InfoSection
    let tutorial: InfoSection
}

// MARK: - Section Types

struct WelcomeSection: Codable {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let features: [OnboardingCard]
}

struct InfoSection: Codable {
    let icon: String
    let title: String
    let description: String
    let proTip: String
    let cards: [OnboardingCard]
}

// MARK: - Unified Card Model

struct OnboardingCard: Codable, Identifiable {
    let id: UUID
    let icon: String?
    let title: String
    let description: String
    let color: String

    // Computed property for color conversion
    var displayColor: Color {
        color.swiftUIColor
    }

    // Custom decoding to generate UUID automatically
    enum CodingKeys: String, CodingKey {
        case icon, title, description, color
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.icon = try container.decodeIfPresent(String.self, forKey: .icon)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.color = try container.decode(String.self, forKey: .color)
    }

    // For programmatic creation
    init(icon: String?, title: String, description: String, color: String) {
        self.id = UUID()
        self.icon = icon
        self.title = title
        self.description = description
        self.color = color
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(icon, forKey: .icon)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(color, forKey: .color)
    }
}

// MARK: - Data Loader

@MainActor
final class OnboardingDataLoader: ObservableObject {
    @Published var data: OnboardingData?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let githubBaseURL = AppConfig.contentBaseURL
    private var hasLoaded = false

    func loadOnboardingDataIfNeeded() async {
        guard !hasLoaded else { return }
        await loadOnboardingData()
    }

    func loadOnboardingData() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            var components = URLComponents(string: "\(githubBaseURL)/onboarding.json")
            components?.queryItems = [
                URLQueryItem(name: "cache", value: String(Int(Date().timeIntervalSince1970)))
            ]

            guard let url = components?.url else {
                throw URLError(.badURL)
            }

            let (payload, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }

            data = try JSONDecoder().decode(OnboardingData.self, from: payload)
            hasLoaded = true
            print("Successfully loaded onboarding data from GitHub")
        } catch {
            errorMessage = "Unable to load onboarding right now."
            print("Error fetching onboarding data from GitHub: \(error)")
        }

        isLoading = false
    }
}
