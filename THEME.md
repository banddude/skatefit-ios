# SkateFit iOS App Theme Guide

## Overview
This document outlines the design system and styling patterns for the SkateFit iOS app, using **WorkoutsView** as our gold standard for design excellence. The WorkoutsView demonstrates proper use of Apple's design principles with adaptive colors, consistent typography, and well-structured visual hierarchy.

## Design Philosophy
- **Apple Human Interface Guidelines Compliance**: Use system colors and fonts for accessibility and consistency
- **Adaptive Design**: Colors and typography that work in both light and dark modes
- **Skateboarding Brand Identity**: Bold, energetic, but clean and modern
- **Functional Beauty**: Every design element serves the user's workout experience

## Color System

### Primary Color Hierarchy
```swift
// Background System (Apple Semantic Colors)
Color(.systemGroupedBackground)           // Main app background
Color(.secondarySystemGroupedBackground)  // Card and container backgrounds
Color(.tertiarySystemGroupedBackground)   // Button and interactive element backgrounds

// Text Colors
.primary                                  // Main text content
.secondary                               // Supporting text and labels
.accentColor                            // Primary brand actions and highlights
```

### Custom Brand Colors

#### Difficulty Level Colors
```swift
WorkoutDifficulty Color System:
- Beginner: .mint      // Approachable, fresh
- Intermediate: .blue  // Trustworthy, progressive  
- Advanced: .purple    // Premium, intense
```

#### Section-Based Colors
```swift
Workout Section Colors:
- Warm-up: .orange     // Energy, preparation
- Main: .purple        // Intensity, focus
- Cool-down: .teal     // Calm, recovery
```

### Color Usage Guidelines
- **Always use semantic colors** (`.primary`, `.secondary`) instead of hardcoded colors
- **Use adaptive colors** that work in light/dark mode
- **Brand colors for specific contexts only**: Difficulty badges, section indicators
- **Avoid hardcoded values** like `Color.blue` - use `.accentColor` or custom semantic colors

## Typography System

### Font Hierarchy
```swift
// Primary Headings
.largeTitle + .bold        // Main screen titles ("Workouts")
.title + .bold            // Important section headers
.title2 + .bold           // Secondary section headers
.title3 + .bold           // Subsection headers

// Content Typography  
.headline + .semibold     // Important labels and card titles
.subheadline + .bold      // Card titles and exercise names
.body                     // Primary content text
.callout                  // Secondary content

// Supporting Text
.caption + .medium        // Supporting information
.caption2 + .semibold     // Small badges and labels
```

### Typography Guidelines
- **Consistent weight hierarchy**: Bold for headers, medium for emphasis, regular for body
- **Semantic sizing**: Use Apple's text styles rather than custom point sizes
- **Weight pairing**: Pair font sizes with appropriate weights (large titles with bold, captions with medium)

## Spacing & Layout

### Standard Measurements
```swift
// Card and Container Padding
Internal padding: 14-16px     // Inside cards and containers
Section spacing: 20px         // Between major sections
Element spacing: 12px         // Between related elements
Tight spacing: 8px           // Between closely related items

// Corner Radius
Primary cards: 16px          // Main content cards
Secondary elements: 8px      // Buttons, small containers
Badges: 8px                 // Small labels and tags
Pills: Full height/2        // Rounded pill buttons
```

### Layout Patterns
- **Card-based design**: Primary content in rounded rectangles with consistent padding
- **Generous whitespace**: Don't overcrowd elements
- **Consistent alignment**: Use HStack/VStack with proper spacing
- **Strategic use of Spacer()**: For flexible layouts and alignment

## Component Styling Standards

### Card Components
```swift
Standard Card Styling:
- Background: Color(.secondarySystemGroupedBackground)
- Corner radius: 16px
- Padding: 14px
- Shadow: .black.opacity(0.05), radius: 3, x: 0, y: 2
- Border: Optional, .color.opacity(0.2), 1px width
```

### Button Components  
```swift
Primary Button:
- Background: .accentColor
- Text: .white
- Corner radius: 8px
- Padding: 12px horizontal, 8px vertical

Secondary Button:
- Background: Color(.tertiarySystemGroupedBackground)  
- Text: .primary
- Corner radius: 8px
- Same padding as primary

Difficulty Buttons:
- Background: WorkoutDifficulty.color.opacity(0.2)
- Border: WorkoutDifficulty.color.opacity(0.3)
- Text: .primary
- Corner radius: 8px
```

### Badge Components
```swift
Standard Badge:
- Background: .accentColor.opacity(0.2) or custom color
- Text: .caption2 + .semibold
- Padding: 6px horizontal, 3px vertical  
- Corner radius: 8px
- Foreground: Matching solid color of background
```

## View-Specific Guidelines

### WorkoutsView (Reference Standard)
✅ **Perfect implementation** - use as template for all other views
- Proper background hierarchy
- Consistent card styling
- Excellent typography hierarchy  
- Proper use of semantic colors

### WorkoutDetailView & WorkoutPlayerView
⚠️ **Mostly consistent** with minor adjustments needed:
- Maintain dark overlay theme for video contexts
- Ensure typography weights match reference hierarchy
- Standardize spacing values with WorkoutsView

### OnboardingView & SplashView  
❌ **Needs major updates**:
- Replace hardcoded `.blue` with `.accentColor`
- Implement proper typography hierarchy
- Use semantic background colors
- Add card-based styling patterns

## Implementation Priorities

### Phase 1: Critical Fixes (High Priority)
1. **Color system standardization**: Replace all hardcoded colors with semantic colors
2. **OnboardingView redesign**: Match WorkoutsView quality and patterns  
3. **SplashView update**: Use proper brand colors and typography

### Phase 2: Consistency Improvements (Medium Priority)
1. **Component standardization**: Create reusable view modifiers for cards, buttons, badges
2. **Spacing normalization**: Ensure all views use consistent padding/spacing values
3. **Typography audit**: Verify all views follow the established hierarchy

### Phase 3: Enhancement (Low Priority)  
1. **Fine-tune player view styling**: Maintain functionality while improving consistency
2. **Advanced animations**: Consistent transition and animation patterns
3. **Accessibility improvements**: Ensure all custom colors meet contrast requirements

## Design System Extensions

### Recommended SwiftUI Extensions
```swift
extension Color {
    // Brand semantic colors
    static let skatefitBackground = Color(.systemGroupedBackground)
    static let skatefitCard = Color(.secondarySystemGroupedBackground)
    static let skatefitButton = Color(.tertiarySystemGroupedBackground)
}

extension Font {
    // Brand typography
    static let skatefitTitle = Font.largeTitle.bold()
    static let skatefitCardTitle = Font.subheadline.bold() 
    static let skatefitSectionHeader = Font.title3.bold()
    static let skatefitBadge = Font.caption2.weight(.semibold)
}

extension View {
    // Reusable modifiers
    func skatefitCard() -> some View {
        self
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    func skatefitButton(style: ButtonStyle = .primary) -> some View {
        // Implementation for consistent button styling
    }
}
```

## Success Metrics

The styling is successful when:
- ✅ All views feel part of the same app family
- ✅ Dark/light mode transitions are seamless
- ✅ Typography creates clear visual hierarchy
- ✅ Colors reinforce brand identity while remaining accessible
- ✅ Layout patterns are predictable and familiar to users
- ✅ Component styling is consistent across all contexts

**WorkoutsView is our north star** - every other view should achieve this level of design consistency and polish.