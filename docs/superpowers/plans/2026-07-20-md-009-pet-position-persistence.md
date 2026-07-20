# MD-009 Pet Position Persistence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:test-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist the pet panel's final position and safely restore or correct it against current macOS screen visible frames.

**Architecture:** A versioned `PetWindowPosition` owns serialization and finite-number validation. A pure `PetWindowPlacement` service selects the nearest visible frame and clamps the complete current-size panel. `PetPanelController` injects preferences, visible frames, and screen notifications, then commits only at startup correction, drag end, size change, or runtime screen correction.

**Tech Stack:** Swift, AppKit, Foundation, Swift Testing, UserDefaults, xcodebuild.

## Global Constraints

- Preserve the single `NSPanel`, single `PetInteractionModel`, and single animation scheduling boundary.
- Use `visibleFrame`, support negative global coordinates, and keep the complete panel visible.
- Do not add permissions, global event monitors, databases, cloud services, telemetry, or dependencies.
- Do not modify asset names, display-size raw values, localization keys, bundle identity, deployment target, or signing settings.
- Do not commit or push.

---

### Task 1: Versioned position persistence contract

**Files:**
- Modify: `MochiDock/MochiDock/PetPreferences.swift`
- Test: `MochiDock/MochiDockTests/PetPreferencesTests.swift`

- [ ] Add tests for stable key/JSON, positive and negative coordinates, missing/corrupt/unknown/non-finite values.
- [ ] Run focused tests and confirm RED due to missing position contract.
- [ ] Implement minimal encode/decode and finite-value validation.
- [ ] Run focused tests and confirm GREEN.

### Task 2: Deterministic visible-frame correction

**Files:**
- Create: `MochiDock/MochiDock/PetWindowPlacement.swift`
- Create: `MochiDock/MochiDockTests/PetWindowPlacementTests.swift`

- [ ] Add tests for contained frames, off-screen/partial frames, negative coordinates, nearest-screen selection, empty screens, visible-area changes, and all five sizes.
- [ ] Run focused tests and confirm RED due to missing placement service.
- [ ] Implement nearest-rectangle selection and whole-frame clamping.
- [ ] Run focused tests and confirm GREEN.

### Task 3: Panel lifecycle integration

**Files:**
- Modify: `MochiDock/MochiDock/PetPanelController.swift`
- Modify: `MochiDock/MochiDock/MochiDockApp.swift`
- Modify: `MochiDock/MochiDockTests/PetPanelControllerTests.swift`
- Modify: `MochiDock/MochiDockTests/MochiDockAppDelegateTests.swift`

- [ ] Add tests for pre-show restoration, drag-end-only commits, size center/correction, Hide/Show identity and position, and screen-notification corrections without redundant writes.
- [ ] Run focused tests and confirm RED due to missing controller integration.
- [ ] Inject shared preferences/current visible frames/notification center; restore before showing and commit only final positions.
- [ ] Run focused tests and confirm GREEN.

### Task 4: Full verification

**Files:**
- No product changes expected.

- [ ] Run all `MochiDockTests` serially with signing disabled.
- [ ] Run MD-005 and MD-008 asset stability tests.
- [ ] Run a clean unsigned Debug build and `git diff --check`.
- [ ] Launch the clean Debug app, perform an observable drag/relaunch smoke where tooling permits, and stop only the launched process.
- [ ] Review preference contract, notification lifecycle, protected identifiers, changed-file responsibilities, line counts, and task-book coverage.
