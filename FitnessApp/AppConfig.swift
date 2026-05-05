import Foundation
import UIKit

/// Central configuration for app branding and content
/// To rebrand the app, simply change the `brand` variable below
struct AppConfig {
    // MARK: - Brand Configuration
    // Change this one variable to rebrand the entire app
    // Example: "skate", "office", "yoga", "dance", etc.
    static let brand = "skate"
    static let displayName = "SkateFit"

    // MARK: - Derived Properties

    /// Display name for the app (e.g., "YourBrandFit", "SkateFit", "OfficeFit")
    static var appName: String {
        return displayName
    }

    /// GitHub repository configuration
    static let githubOwner = "banddude"  // Your GitHub username
    static let githubRepo = "fit-files"      // Your content repository name
    static let githubBranch = "main"

    /// Content folder path in GitHub repo (e.g., "yourbrandfit", "skatefit", "officefit")
    static var contentFolder: String {
        return brand + "fit"
    }

    /// Full content base URL for GitHub raw files
    static var contentBaseURL: String {
        return "https://raw.githubusercontent.com/\(githubOwner)/\(githubRepo)/\(githubBranch)/\(contentFolder)"
    }

    /// GitHub API base URL
    static var githubAPIBaseURL: String {
        return "https://api.github.com/repos/\(githubOwner)/\(githubRepo)"
    }

    /// Get the app icon from the bundle
    static func getAppIcon() -> UIImage? {
        // Try to get the app icon from the asset catalog
        // Note: The actual icon file names vary by size, so we try multiple common sizes
        if let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let iconName = iconFiles.last {
            // Try to load the icon
            if let image = UIImage(named: iconName) {
                return image
            }
        }

        // Fallback: try to get icon from Assets
        let possibleNames = ["AppIcon60x60", "AppIcon76x76", "AppIcon"]
        for name in possibleNames {
            if let image = UIImage(named: name) {
                return image
            }
        }

        return nil
    }
}
