# Fitness App Template

A multi-brand fitness app template that can be rebranded by changing a single variable. The app dynamically loads workout content from GitHub based on your brand name.

## Quick Start: Creating Your Branded App

### 1. Change the Brand Name

Open `AppConfig.swift` and change the `brand` variable:

```swift
static let brand = "yourbrand"  // Change "skate" to your brand name
```

This ONE change controls:
- Which folder the app loads content from on GitHub (`fit-files/yourbrand/`)
- Where videos, workouts, and exercises are fetched from
- The app's onboarding content

### 2. Set Up Your Content Repository

Your content must be hosted in a GitHub repository with this structure:

```
fit-files/
└── yourbrand/           # Must match the brand name in AppConfig
    ├── onboarding.json
    ├── workouts/
    │   ├── workout1.json
    │   ├── workout2.json
    │   └── ...
    ├── exercises/
    │   ├── exercise1.json
    │   ├── exercise2.json
    │   └── ...
    └── videos/
        ├── video1.mp4
        ├── video2.mp4
        └── ...
```

**Important**: The folder name MUST exactly match your brand variable (case-sensitive).

### 3. Update GitHub Repository Settings

In `AppConfig.swift`, update these if using a different repository:

```swift
static let githubOwner = "yourusername"     // GitHub username
static let githubRepo = "fit-files"         // Repository name
static let githubBranch = "main"            // Branch name
static let contentFolder = "yourbrand"      // Folder in repo (should match brand)
```

### 4. Configure Your Xcode Project

#### A. Update Bundle Identifier
1. Open the project in Xcode
2. Select the project in the navigator
3. Select your target
4. Under "General" → "Identity", change the Bundle Identifier:
   - From: `com.skatefit.app`
   - To: `com.yourbrand.app`

#### B. Update Display Name
In the same section, change the "Display Name" to your app's name:
   - From: `skatefit`
   - To: `Your App Name`

#### C. Add Your App Icon
1. Select `Assets.xcassets` in the project navigator
2. Click on `AppIcon`
3. Drag and drop your app icon images for all required sizes:
   - 1024x1024 (App Store)
   - 180x180 (iPhone)
   - 167x167 (iPad Pro)
   - 152x152 (iPad)
   - And other required sizes

**The app will automatically use your app icon throughout the interface**, so you don't need to create a separate brand icon.

### 5. Test Your App

1. Build and run in the iOS Simulator
2. The app will:
   - Load onboarding content from `fit-files/yourbrand/onboarding.json`
   - Display workouts from `fit-files/yourbrand/workouts/`
   - Show exercises from `fit-files/yourbrand/exercises/`
   - Stream videos from `fit-files/yourbrand/videos/`

## Content Format

### Onboarding JSON Structure
See the reference `skatefit/onboarding.json` in the fit-files repository for the complete structure.

### Workout JSON Structure
```json
{
  "name": "Full Body Workout",
  "icon": "figure.strengthtraining.traditional",
  "color": "blue",
  "exercises": [
    {
      "exerciseId": "exercise_file_name",
      "section": "Warm-Up",
      "beginner": "10 reps",
      "intermediate": "15 reps",
      "advanced": "20 reps"
    }
  ]
}
```

### Exercise JSON Structure
```json
{
  "id": "exercise_name",
  "move": "Exercise Name",
  "description": "Brief description",
  "detailedDescription": "Detailed instructions",
  "videoFile": "video_filename",
  "section": "Main",
  "beginner": "10 reps",
  "intermediate": "15 reps",
  "advanced": "20 reps",
  "equipment": ["dumbbells"],
  "targetMuscles": ["legs", "core"],
  "benefit": "What this exercise helps improve",
  "exerciseType": ["strength", "cardio"],
  "durationPerRep": "3-5 seconds"
}
```

## Features

- **100% Dynamic Content**: All workouts, exercises, and videos load from GitHub
- **Multi-Brand Ready**: Change one variable to rebrand
- **Offline Caching**: Content is cached locally for offline use
- **Auto-Updates**: Checks for content updates from GitHub
- **Three Difficulty Levels**: Beginner, Intermediate, Advanced
- **Video Integration**: Full-screen video playback with looping
- **Custom Onboarding**: Fully customizable onboarding flow
- **Exercise Details**: Long-press on exercises to see detailed information

## Customization Options

### Colors
The app uses iOS system colors by default. Workout colors are defined in your workout JSON files using standard color names:
- `blue`, `purple`, `orange`, `teal`, `indigo`, `red`, `green`, `yellow`, `pink`, `mint`

### SF Symbols Icons
Use any SF Symbol name for workout icons. Browse available symbols at: https://developer.apple.com/sf-symbols/

## Building for Production

1. Update version and build number in Xcode
2. Archive the app (Product → Archive)
3. Distribute to App Store or TestFlight
4. Make sure your GitHub repository is public or configure authentication

## Troubleshooting

### Content Not Loading
- Check that the brand folder name matches exactly (case-sensitive)
- Verify the GitHub repository is public
- Check the Xcode console for error messages
- Try clearing the cache in the app settings

### Videos Not Playing
- Ensure videos are in MP4 format
- Check that video files are properly uploaded to GitHub
- For large files, make sure you're using Git LFS

### App Icon Not Showing
- Ensure all required icon sizes are provided in Assets.xcassets
- Clean build folder (Product → Clean Build Folder)
- Restart Xcode

## Requirements

- iOS 15.0 or later
- Xcode 14.0 or later
- Swift 5.0 or later

## Support

For issues or questions, please create an issue in the GitHub repository.
