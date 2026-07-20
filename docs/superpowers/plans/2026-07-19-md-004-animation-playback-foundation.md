# MD-004 Animation Playback Foundation Implementation Plan

> **For agentic workers:** Execute inline in this task. Follow test-driven development for every product-code behavior and do not dispatch subagents.

**Goal:** Replace the standing runtime art with the approved v0.4 prone assets and add a bottom-anchored, low-frequency breathing cycle backed by a minimal testable animation state machine.

**Architecture:** `PetInteractionModel` owns the stage-1B state and exactly one cancellable scheduled transition. A small injected scheduler makes transitions deterministic in tests; `PetPanelController` starts and stops playback with visibility, while `PetView` only renders model-derived scale, anchor, and short response presentation.

**Tech Stack:** Swift 6, SwiftUI, AppKit, Observation, Swift Testing, Xcode asset catalogs.

## Global Constraints

- Keep the existing 80/120/160 point panel definitions and 120 default.
- Use only the three approved files under `asset/character/red-panda/previews/v0.4/`; do not modify either excluded experiment directory.
- Reuse one image per selected size; vertical scale starts at 1.0 and peaks at no more than 1.024, horizontal scale stays 1.0, anchor stays at the bottom.
- Keep timing and scale parameters centralized; keep a visible idle pause between breaths.
- Keep at most one scheduled transition per model; repeated show and size changes must not start another loop, hide must cancel playback, and rapid clicks must not queue responses.
- Do not add dependencies, persistence, new action art, or MD-005 behavior.

---

### Task 1: Runtime asset mapping

**Files:**
- Modify: `MochiDock/MochiDock/PetDisplaySize.swift`
- Modify: `MochiDock/MochiDock/Assets.xcassets/RedPandaMaster80.imageset/`
- Modify: `MochiDock/MochiDock/Assets.xcassets/RedPandaMaster120.imageset/`
- Modify: `MochiDock/MochiDock/Assets.xcassets/RedPandaMaster160.imageset/`
- Test: `MochiDock/MochiDockTests/PetDisplaySizeTests.swift`

- [x] Change the resource expectations to prone v0.4 names and add bundle image pixel/alpha checks.
- [x] Run the focused test and confirm it fails against the standing names/assets.
- [x] Copy the three approved PNGs into their corresponding image sets and update the mapping.
- [x] Run the focused test and confirm it passes.

### Task 2: Testable playback state and scheduling

**Files:**
- Create: `MochiDock/MochiDock/PetAnimation.swift`
- Modify: `MochiDock/MochiDock/PetInteractionModel.swift`
- Test: `MochiDock/MochiDockTests/PetAnimationTests.swift`
- Modify: `MochiDock/MochiDockTests/PetInteractionModelTests.swift`

- [x] Add failing tests for idle-to-peak-to-idle progression, pause scheduling, stable recovery, one pending transition, stop/restart, and bounded rapid click handling.
- [x] Run the focused tests and confirm failures are caused by missing playback behavior.
- [x] Add centralized timing/presentation parameters, scheduler protocol plus production implementation, and the minimal state transitions needed by the tests.
- [x] Run the focused tests and confirm they pass; refactor only while green.

### Task 3: Panel lifecycle and bottom-anchored rendering

**Files:**
- Modify: `MochiDock/MochiDock/PetPanelController.swift`
- Modify: `MochiDock/MochiDock/PetView.swift`
- Modify: `MochiDock/MochiDockTests/PetPanelControllerTests.swift`
- Create: `MochiDock/MochiDockTests/PetViewPresentationTests.swift`

- [x] Add failing tests that show repeated display and size changes keep one playback schedule, hide cancels it, show restarts it, and rendering presentation has x-scale 1.0 with a bottom anchor.
- [x] Run the focused tests and confirm they fail for missing lifecycle/presentation behavior.
- [x] Wire visibility to playback start/stop and render model presentation with bottom-anchored vertical scale.
- [x] Run the focused tests and confirm they pass; then run all existing panel, menu, size, and interaction tests.

### Task 4: Verification and project records

**Files:**
- Modify: `progress.md`
- Modify: `findings.md`
- Keep `task_plan.md` and `docs/tasks/active/MD-004-animation-playback-foundation.md` at `开发中`.

- [x] Run all effective tests and record the exact count/result.
- [x] Run a clean Debug build in a fresh derived-data directory.
- [x] Launch the built app and inspect the visible posture, all sizes, breathing, bottom stability, click, drag, Hide/Show, and Quit where the environment permits.
- [x] Run `git diff --check`, inspect file line counts/responsibilities, verify excluded directories remain untouched, and report current Git status.
