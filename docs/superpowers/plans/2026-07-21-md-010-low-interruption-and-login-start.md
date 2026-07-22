# MD-010 Low Interruption and Login Start Implementation Plan

> **For agentic workers:** Execute inline in this task. Do not dispatch subagents, create a follow-on task, or mark MD-010 accepted. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a persistent pointer-proximity response toggle and a truthful macOS login-item toggle without changing unrelated desktop-pet behavior.

**Architecture:** `PetInteractionModel` owns the persisted proximity preference and cancellation of an active attention sequence; `PetPanelController` owns detector sampling lifecycle. A new injectable login-item boundary wraps `SMAppService.mainApp`, maps every native status, and lets `MochiDockAppDelegate` expose actual status and localized outcomes to the menu.

**Tech Stack:** Swift 6, SwiftUI, AppKit, ServiceManagement, Swift Testing, Xcode/macOS 26.4.

## Global Constraints

- Test first and observe each new test fail for the expected missing behavior before production edits.
- Reuse `PetPreferencesStoring`; centralize the new key and never touch real user preferences in tests.
- Use Apple `SMAppService`; add no dependency, helper process, entitlement, signing, installer, or release change.
- Preserve one `NSPanel`, existing click/drag/idle/blink/Hide/Show, size and position behavior.
- Unsigned builds do not prove real login-item activation; report system-level checks as manual acceptance.
- Do not archive the task, mark it accepted, commit, push, or begin another task.

---

### Task 1: Persistent proximity-response preference and attention cancellation

**Files:**
- Modify: `MochiDock/MochiDock/PetPreferences.swift`
- Modify: `MochiDock/MochiDock/PetInteractionModel.swift`
- Test: `MochiDock/MochiDockTests/PetPreferencesTests.swift`
- Test: `MochiDock/MochiDockTests/PetAnimationTests.swift`

**Interfaces:**
- Produces: `PetPreferenceKey.proximityResponseEnabled`, `PetInteractionModel.isProximityResponseEnabled`, and `setProximityResponseEnabled(_:)`.

- [x] Add tests proving the missing value defaults to enabled, both values persist and restore, disabled blocks attention, and disabling during attention cancels it while ordinary idle scheduling remains active.
- [x] Run only those tests and confirm RED is caused by the missing key/API.
- [x] Implement stable `"true"`/`"false"` storage, default-on restoration, eligibility guarding, and attention-only cancellation followed by ordinary idle scheduling.
- [x] Re-run the focused tests and confirm GREEN.

### Task 2: Sampling lifecycle and app/menu connection

**Files:**
- Modify: `MochiDock/MochiDock/PetPanelController.swift`
- Modify: `MochiDock/MochiDock/MochiDockApp.swift`
- Test: `MochiDock/MochiDockTests/PetPanelControllerTests.swift`
- Test: `MochiDock/MochiDockTests/MochiDockAppDelegateTests.swift`

**Interfaces:**
- Produces: `PetPanelController.setProximityResponseEnabled(_:)` and app-delegate menu state/action.

- [x] Add tests proving disabled launch/show does not start sampling, disabling stops it immediately, re-enabling while visible starts once, enabling while hidden waits for Show, and menu state restores through a new model.
- [x] Run focused tests and confirm expected RED.
- [x] Implement minimal controller/app-delegate connection and a SwiftUI toggle labelled `Pointer Proximity Response`.
- [x] Re-run focused tests and confirm GREEN, including existing Hide/Show lifecycle tests.

### Task 3: Native login-item boundary and truthful menu state

**Files:**
- Create: `MochiDock/MochiDock/LoginItemService.swift`
- Create: `MochiDock/MochiDockTests/LoginItemServiceTests.swift`
- Modify: `MochiDock/MochiDock/MochiDockApp.swift`
- Modify: `MochiDock/MochiDockTests/MochiDockAppDelegateTests.swift`

**Interfaces:**
- Produces: `LoginItemServicing`, mapped status (`notRegistered`, `enabled`, `requiresApproval`, `notFound`), idempotent `setEnabled(_:)`, and menu outcome text.

- [x] Add injected-boundary tests for status mapping, enable/disable calls, idempotence, thrown errors, and `requiresApproval` never appearing enabled.
- [x] Run focused tests and confirm RED for the missing boundary.
- [x] Wrap `SMAppService.mainApp`; after every request re-read native status, publish actual enabled state, and expose a localized approval/error outcome instead of claiming success.
- [x] Add a `Start at Login` toggle and status/outcome text; refresh actual status when the menu appears.
- [x] Re-run focused tests and confirm GREEN.

### Task 4: Localization and regression verification

**Files:**
- Modify: `MochiDock/MochiDock/Localizable.xcstrings`
- Modify: `MochiDock/MochiDockTests/LocalizationTests.swift`
- Update: `findings.md`
- Update: `progress.md`

- [x] Add localization expectations first for `Pointer Proximity Response`, `Start at Login`, approval-needed text, not-found text, and failure text; confirm RED.
- [x] Add English and Simplified Chinese catalog entries; confirm localization GREEN.
- [x] Run all valid `MochiDockTests` unsigned and confirm zero failures.
- [x] Run the existing MD-005/MD-008 asset-stability tests explicitly.
- [x] Run an unsigned clean Debug build and `git diff --check`.
- [x] Perform a local smoke check for disable/re-enable proximity behavior where tooling permits; do not describe it as user acceptance.
- [x] Inspect centralized keys, menu truth source, detector lifecycle, login status handling, single-panel boundary, changed-file responsibilities, final line counts, and Git diff.
- [x] Record RED/GREEN evidence, verification results, unverified system login/logout checks, risks, and deviations in project records.

## Self-review

- Spec coverage: preference default/restore, detector stop/restart, active attention cancellation, native login status/error/idempotence, localization, regression, build, assets, smoke, and manual-only signing checks are mapped above.
- Scope: no settings window, schedules, global monitoring, helper process, dependency, signing change, publishing, new animation, telemetry, or next task.
- Type consistency: menu consumes the model boolean and the login service's mapped actual status; no login preference is introduced.
