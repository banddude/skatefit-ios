//
//  skatefitTests.swift
//  skatefitTests
//
//  Created by Mike Shaffer on 4/23/25.
//

import Testing
@testable import skatefit

struct skatefitTests {
    @Test func detailedGuideSplitsExistingProseWithoutInventingContent() {
        let source = "Start in a stable stance. Keep your core engaged throughout the movement. Finish under control."
        let segments = ExerciseGuideFormatter.segments(from: source)

        #expect(segments == [
            "Start in a stable stance.",
            "Keep your core engaged throughout the movement.",
            "Finish under control."
        ])
        #expect(segments.joined(separator: " ") == source)
    }

    @Test func detailedGuidePreservesExplicitParagraphs() {
        let source = "First cue.\n\nSecond cue."
        let segments = ExerciseGuideFormatter.segments(from: source)

        #expect(segments == ["First cue.", "Second cue."])
    }

    @Test func liveWorkoutCategoryPaletteDoesNotReuseDifficultyColors() {
        let difficultyColorNames = Set(WorkoutDifficulty.allCases.map(\.colorName))

        let fullBody = WorkoutContainer(name: "Full Body", icon: nil, color: "blue", exercises: [])
        let strength = WorkoutContainer(name: "Strength", icon: nil, color: "purple", exercises: [])
        let mobility = WorkoutContainer(name: "Mobility", icon: nil, color: "orange", exercises: [])
        let core = WorkoutContainer(name: "Core", icon: nil, color: "teal", exercises: [])

        #expect(fullBody.categoryColorName == "cyan")
        #expect(strength.categoryColorName == "pink")
        #expect(!difficultyColorNames.contains(fullBody.categoryColorName))
        #expect(!difficultyColorNames.contains(strength.categoryColorName))
        #expect(!difficultyColorNames.contains(mobility.categoryColorName))
        #expect(!difficultyColorNames.contains(core.categoryColorName))
    }

    @Test func mainSectionNoLongerSharesAdvancedPurple() {
        #expect(WorkoutSectionVisuals.colorName(for: "Main") == "pink")
        #expect(WorkoutSectionVisuals.colorName(for: "Main") != WorkoutDifficulty.advanced.colorName)
        #expect(WorkoutSectionVisuals.iconName(for: "Main") == "figure.strengthtraining.traditional")
    }

    @Test func difficultyUsesStableIconAndColorSemantics() {
        #expect(WorkoutDifficulty.beginner.iconName == "1.circle.fill")
        #expect(WorkoutDifficulty.intermediate.iconName == "2.circle.fill")
        #expect(WorkoutDifficulty.advanced.iconName == "3.circle.fill")
        #expect(WorkoutDifficulty.beginner.colorName == "mint")
        #expect(WorkoutDifficulty.intermediate.colorName == "blue")
        #expect(WorkoutDifficulty.advanced.colorName == "purple")
    }
}
