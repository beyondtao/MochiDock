# MD-007 Localization Foundation Implementation Plan

> **For agentic workers:** Execute this plan inline in the current task. Steps use checkbox (`- [ ]`) syntax for tracking; no commits are permitted before user acceptance.

**Goal:** Add native English and Simplified Chinese localization for all current runtime menu and pet accessibility text without changing stable size, preference, resource, panel, or animation behavior.

**Architecture:** `Localizable.xcstrings` is the single translation source with English as source/fallback and `zh-Hans` translations. SwiftUI views consume localized keys directly; small domain enums expose `LocalizedStringResource` presentation values while stable raw values and resources remain untouched. Tests resolve the real application catalog through locale-specific bundles and exercise dynamic visibility and persistence using the existing single state sources.

**Tech Stack:** Swift 5, SwiftUI, Foundation, AppKit, Xcode String Catalog, Swift Testing, xcodebuild.

## Global Constraints

- English is the development and missing-translation fallback language; Simplified Chinese is the only added language.
- Use Apple-native localization and Xcode String Catalog; follow macOS system or per-app language settings with no in-app switcher.
- Do not translate `MochiDock` or change `pet.displaySize`, `PetDisplaySize.rawValue`, `small`, `medium`, `large`, `extraLarge`, `jumbo`, character resource names, Bundle Identifier, deployment target, signing, or release configuration.
- Do not localize Preview names, tests, logs, or comments; do not modify animation, panel behavior, persistence mechanics, or MD-005.
- Do not commit or push; task status remains `开发中` at delivery.

---

### Task 1: Prove the localization gap and add the catalog

**Files:**
- Create: `MochiDock/MochiDock/Localizable.xcstrings`
- Create: `MochiDock/MochiDockTests/LocalizationTests.swift`
- Modify only if required: `MochiDock/MochiDock.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: application bundle and the current English keys.
- Produces: locale-aware translations for menu, five size labels, accessibility label, and two mood values.

- [x] Add a test that requires `en.lproj` and `zh-Hans.lproj`, checks every expected English/Chinese value, checks an unknown key falls back to its English key, and verifies bundle localizations.
- [x] Run the localization test before creating the catalog; expect failure because locale resources/translations do not exist.
- [x] Add the minimal `Localizable.xcstrings` with English source entries and `zh-Hans` translations; add `zh-Hans` to project known regions only if Xcode does not derive it automatically.
- [x] Run the focused localization test; expect all catalog and fallback assertions to pass.

### Task 2: Route runtime presentation through native localized values

**Files:**
- Modify: `MochiDock/MochiDock/MochiDockApp.swift`
- Modify: `MochiDock/MochiDock/PetDisplaySize.swift`
- Modify: `MochiDock/MochiDock/PetInteractionModel.swift`
- Modify: `MochiDock/MochiDock/PetView.swift`
- Modify: `MochiDock/MochiDockTests/MochiDockAppDelegateTests.swift`
- Modify: `MochiDock/MochiDockTests/PetDisplaySizeTests.swift`
- Modify: `MochiDock/MochiDockTests/PetInteractionModelTests.swift`

**Interfaces:**
- Consumes: catalog keys as `LocalizedStringResource` / SwiftUI localizable string inputs.
- Produces: dynamic visibility title from actual panel state, localized size presentation separated from raw values, and localized accessibility label/value.

- [x] Add focused tests for localized dynamic Show/Hide titles, all five localized size titles with unchanged point lengths/raw values/resources, and localized Resting/Happy values.
- [x] Run focused tests and confirm failure because the runtime APIs still return hard-coded `String` values.
- [x] Change only presentation properties and SwiftUI string inputs to native localized types; retain actual panel visibility and model size/mood as sole state sources.
- [x] Run focused tests and then all `MochiDockTests`; expect zero failures.

### Task 3: Verify artifacts, behavior, contracts, and project scope

**Files:**
- Modify: `task_plan.md`
- Modify: `findings.md`
- Modify: `progress.md`
- Modify: `docs/tasks/active/MD-007-localization-foundation.md` only to preserve `开发中` and record delivery evidence if appropriate.

**Interfaces:**
- Consumes: built app, test results, git diff, catalog, current persisted size behavior.
- Produces: evidence-backed delivery report and persistent project record.

- [x] Clean-test all `MochiDockTests` and perform a clean Debug build in fresh derived-data directories.
- [x] Inspect the built app for `en` and `zh-Hans` resources and declared localizations; verify all catalog keys and English fallback.
- [x] Run bilingual executable checks where tooling permits: launch with Apple language overrides, inspect menu Show/Hide, five sizes, persistence/selection across restart, and accessibility text; clearly mark anything not visually observable.
- [x] Run `git diff --check`, search for user-visible hard-coded runtime English, compare protected constants/configuration to `51aa976`, inspect dependencies/signing/Bundle ID/deployment/release changes, and report file line counts/responsibilities.
- [x] Request read-only code review against MD-007; fix Critical/Important findings with RED/GREEN evidence, then rerun affected and final verification.
- [x] Update persistent records without changing MD-007 from `开发中`; deliver without commit or push.
