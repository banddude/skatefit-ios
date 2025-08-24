import SwiftUI

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = true {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    init() {
        isDarkMode = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool ?? true
    }
    
    var colorScheme: ColorScheme {
        return isDarkMode ? .dark : .light
    }
}