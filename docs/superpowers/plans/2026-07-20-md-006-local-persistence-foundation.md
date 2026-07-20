# MD-006 Local Persistence Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist the selected `PetDisplaySize` immediately and restore it before the first pet panel is created.

**Architecture:** Add a small injectable preference-store protocol backed in production by `UserDefaults`. `PetInteractionModel` restores one stable enum raw value during initialization and writes it on selection; `PetPanelController` continues to derive its first frame from that already-restored model, keeping the panel, image resource, and menu selection on one source of truth.

**Tech Stack:** Swift, SwiftUI Observation, AppKit, Foundation `UserDefaults`, Swift Testing, Xcode/macOS.

## Global Constraints

- Persist only the stable `PetDisplaySize.rawValue`; default and invalid values resolve to `.medium` (120).
- Tests must use isolated in-memory storage and never `UserDefaults.standard`.
- Do not add SwiftData, Core Data, cloud sync, third-party dependencies, or unrelated persisted state.
- Do not change MD-004 animation timing or start MD-005.
- Do not modify signing, bundle identifier, deployment target, or release configuration.
- Do not commit or push.

---

### Task 1: Preference boundary and model persistence

**Files:**
- Create: `MochiDock/MochiDock/PetPreferences.swift`
- Create: `MochiDock/MochiDockTests/PetPreferencesTests.swift`
- Modify: `MochiDock/MochiDock/PetInteractionModel.swift`

**Interfaces:**
- Produces: `PetPreferencesStoring.string(forKey:)`, `set(_:forKey:)`, `UserDefaultsPetPreferences`, and model initializers accepting an isolated store.
- Persists: key `pet.displaySize`, value `PetDisplaySize.rawValue`.

- [x] Write tests for missing value, all five round trips through a new model instance, invalid value fallback, and immediate writes.
- [x] Run only the new persistence tests and confirm RED because the injectable preference API does not exist.
- [x] Implement the smallest protocol, production adapter, centralized key, initialization restore, and selection write needed to pass.
- [x] Run only the new persistence tests and confirm GREEN.

### Task 2: Startup consistency and animation regression

**Files:**
- Modify: `MochiDock/MochiDockTests/PetPanelControllerTests.swift`
- Modify only if a failing test requires it: `MochiDock/MochiDock/PetPanelController.swift`

**Interfaces:**
- Consumes: a `PetInteractionModel` whose display size is restored synchronously at initialization.
- Verifies: first panel frame, model/menu selection source, image resource mapping, and the one-scheduled-task animation contract.

- [x] Write tests that construct a fresh restored model and first panel, then verify frame size and selected size agree before display.
- [x] Add persistence-backed repeated selection and Show/Hide/size-switch regression coverage for one pending animation schedule.
- [x] Run the focused tests and confirm RED because the persistence dependency was absent.
- [x] Make only the minimal wiring adjustment required and rerun focused tests to GREEN.

### Task 3: Production UserDefaults assembly

**Files:**
- Modify: `MochiDock/MochiDock/PetInteractionModel.swift`
- Verify: `MochiDock/MochiDock/MochiDockApp.swift`

**Interfaces:**
- Production `PetInteractionModel()` uses `UserDefaults.standard` through `UserDefaultsPetPreferences`.
- Test initializers continue to accept both scheduler and isolated preference dependencies without touching real preferences.

- [x] Add a failing test proving dependency combinations preserve restored size and animation scheduling.
- [x] Confirm RED, implement minimal initializer assembly, and rerun to GREEN.
- [x] Confirm app delegate builds the restored model before constructing `PetPanelController`.

### Task 4: Full verification and project records

**Files:**
- Modify: `docs/tasks/active/MD-006-local-persistence-foundation.md`
- Modify: `task_plan.md`
- Modify: `findings.md`
- Modify: `progress.md`

- [x] Run all `MochiDockTests` with the exact required derived-data path.
- [x] Run the exact required clean Debug build.
- [x] Run `git diff --check`, inspect changed file responsibilities/line counts, and verify no dependency or release-setting changes.
- [x] Launch the production build with MochiDock's non-default `jumbo` preference, quit, relaunch, and inspect restored size; menu Picker and startup time-series observation were not available through Computer Use and are recorded as unverified.
- [x] Record RED/GREEN evidence, verification results, unverified manual observations, risks, deviations, and current Git state while keeping MD-006 “开发中”.
