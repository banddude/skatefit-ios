# SkateFit App Store Update Readiness Review

Date: April 26, 2026

Scope: This review is for an update to the existing SkateFit app already in the App Store, not a new listing.

## Current Verdict

The app is closer, but it is still not fully ready for App Store submission.

## Live App Metadata

1. App Store Apple ID: `6751483195`
2. SKU: `skatefit-ios-2025`
3. Bundle identifier: `com.mikeshaffer.skatefit`
4. Live minimum OS version: iOS 16.6

## Fixes Completed In This Working Session

1. The local project bundle identifier now matches the live App Store app, `com.mikeshaffer.skatefit`.
2. The visible app name is now `SkateFit`.
3. A `PrivacyInfo.xcprivacy` manifest was added for `UserDefaults`.
4. The broad `NSAllowsArbitraryLoads` ATS override was removed.
5. The onboarding flow now loads from GitHub once at the container level, instead of each onboarding page creating its own loader and request.
6. The `Strength` workout accent color was fixed at the source in the live content repo, not by hardcoded Swift logic.
7. Missing or still loading videos now show the app icon placeholder instead of a black frame.

## Verified Checks

1. Simulator builds succeeded on April 26, 2026, after the branding, privacy manifest, ATS, onboarding fallback, and content color fixes.
2. The stale bundled `onboarding.json` file is no longer copied into the built app bundle.
3. The live workout source now reports `strength.json` color as `red`.
4. The strength content fix landed in the live content repo at commit `09eabaa4284e536096b4f99ed80c4384a9e48448`.
5. The app is building against the iOS 26.4 SDK on this machine, which satisfies Apple’s SDK requirement for uploads after April 28, 2026.

## Remaining Submission Blocker

1. Release signing is still not ready on this machine.
   The Release build for a real iOS target failed because there is no usable local signing certificate for team `6D4T7VB2AF`.

   Until signing is corrected, the app cannot be archived and uploaded from this machine.

## High Priority Risks

1. First launch still depends heavily on GitHub for workout, exercise, and onboarding payloads.
   That is now intentional for onboarding as well, but the app still loads primary content from cache or network in [FitnessApp/ContentManager.swift](/Users/mikeshaffer/AIVA/apps/skatefit/ios-mixed/skatefit/FitnessApp/ContentManager.swift:29) and [FitnessApp/GitHubContentService.swift](/Users/mikeshaffer/AIVA/apps/skatefit/ios-mixed/skatefit/FitnessApp/GitHubContentService.swift:52).

   A clean install with poor connectivity can still fall into an incomplete or error state.

2. First run video fallback is still incomplete.
   The black frame issue is fixed, the UI now shows the app icon while remote videos are still loading.

   The remaining risk is network timing, first run still depends on GitHub video download completion before the real loops appear.

3. There is still no obvious in app privacy policy or support surface.
   Apple requires a privacy policy URL in App Store Connect, and review is smoother when users can also access privacy and support information inside the app.

4. Deployment target compatibility changed from the live app.
   The live listing supports iOS 16.6, but the local project is currently building with `IPHONEOS_DEPLOYMENT_TARGET = 17.0`.

   That may be intentional, but if not, the update will drop some currently supported devices.

## Medium Priority Gaps

1. The scheme is not configured for tests, so `xcodebuild test` is still not available as a release check.
2. There is still no visible About or Settings surface for support, privacy, version info, or maintenance actions like cache reset.
3. The project targets both iPhone and iPad. That may be fine, but it should be intentional and tested before submission.

## Name Status

If the desired visible app name is `SkateFit`, the app side rename is in good shape now. The important continuity rule is unchanged, the bundle identifier must remain exactly `com.mikeshaffer.skatefit` for this to ship as an update.

## Recommended Next Fix Order

1. Fix signing so a real Release archive can be produced.
2. Add a small in app About or Settings surface with Privacy Policy and Support links.
3. Decide whether remote only onboarding and content loading is acceptable for first launch, or whether you want a smarter offline-safe startup path without bundling business content.
4. Keep the new app icon placeholder path for videos, and decide whether you also want a retry or timeout indicator for very slow downloads.
5. Decide whether the move from iOS 16.6 to iOS 17.0 is intentional.
6. Run a clean install pass again after those changes, then archive and validate.

## Good News

1. The update continuity issue is fixed.
2. The privacy manifest issue is fixed.
3. The ATS issue is fixed.
4. The workout color issue is now owned by content, which is the correct long term model.
5. The video loading state now degrades to branded UI instead of a black box.
