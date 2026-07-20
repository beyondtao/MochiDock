# MD-008 Limited Pointer Proximity Response Implementation Plan

> **For agentic workers:** Implement inline in this session. Follow each checkbox in order and preserve the user's existing uncommitted asset and documentation work.

**Goal:** Add a low-distraction, permission-free pointer proximity response that plays one `attention-tail -> attention-base -> idle` sequence per eligible outside-to-inside transition.

**Architecture:** A focused proximity detector owns pointer sampling, scaled enter/exit geometry, hysteresis, cooldown, visibility, and drag suppression. `PetPanelController` supplies AppKit's current mouse location and panel frame without global event monitors, while `PetInteractionModel` remains the single cancellable visual scheduling boundary and arbitrates automatic, proximity, and click responses.

**Tech Stack:** Swift 6, AppKit, SwiftUI Observation, Swift Testing, existing Xcode project and asset catalog.

## Global Constraints

- Do not add permissions, global event monitors, network access, AI calls, third-party dependencies, settings, persistence keys, localization keys, or a general behavior tree.
- Do not modify or regenerate accepted MD-008 image assets.
- Keep one `NSPanel`, one `PetInteractionModel`, and one cancellable animation transition.
- Keep discrete image changes inside the existing non-animated render policy.
- Preserve all unrelated worktree changes.

---

### Task 1: Proximity geometry and detector state machine

**Files:**
- Create: `MochiDock/MochiDock/PointerProximityDetector.swift`
- Create: `MochiDock/MochiDockTests/PointerProximityDetectorTests.swift`

**Interfaces:**
- Consumes a sampled pointer position, current panel frame, visibility, drag state, monotonic time, and a callback for an eligible entry.
- Produces `start(panelFrame:)`, `stop()`, `setDragging(_:panelFrame:)`, and deterministic `sample(pointerLocation:panelFrame:now:)` behavior.

- [x] Write tests for scaled enter/exit insets, initial-inside arming behavior, first outside-to-inside entry, stationary-inside suppression, exit reset, cooldown, drag suppression/resynchronization, visibility stop/start, and one cancellable sampling schedule.
- [x] Run only `PointerProximityDetectorTests` and confirm failures are caused by missing detector APIs.
- [x] Implement the minimum detector and centralized `PointerProximityTiming.standard` constants using injected scheduler/time/pointer sources.
- [x] Run only `PointerProximityDetectorTests` and keep it green.

### Task 2: Visual sequence, resource mapping, and priority arbitration

**Files:**
- Modify: `MochiDock/MochiDock/PetAnimation.swift`
- Modify: `MochiDock/MochiDock/PetInteractionModel.swift`
- Modify: `MochiDock/MochiDock/PetDisplaySize.swift`
- Modify: `MochiDock/MochiDock/PetRenderPolicy.swift`
- Modify: `MochiDock/MochiDockTests/PetAnimationTests.swift`
- Modify: `MochiDock/MochiDockTests/PetDisplaySizeTests.swift`
- Modify: `MochiDock/MochiDockTests/PetRenderingPolicyTests.swift`

**Interfaces:**
- Add `.attentionTail` and `.attentionBase` visual states and bounded attention animation states.
- Add `handleProximityEntry()` returning whether the sequence started, with click cancellation and click-response protection.

- [x] Write tests for all five attention resource mappings, one tail/base/idle sequence, automatic-action replacement, click preemption, and proximity rejection during a click response.
- [x] Run focused tests and confirm the expected RED failures.
- [x] Add minimal visual states, centralized timing, state transitions, and non-animated discrete resource switching.
- [x] Run focused tests and keep them green.

### Task 3: Panel lifecycle and drag integration

**Files:**
- Modify: `MochiDock/MochiDock/PetPanelController.swift`
- Modify: `MochiDock/MochiDock/PetView.swift`
- Modify: `MochiDock/MochiDockTests/PetPanelControllerTests.swift`

**Interfaces:**
- The controller owns the detector lifecycle and passes drag start/end notifications from `PetView`.
- Show starts detection after the panel is visible; hide stops detection and animation; drag prevents proximity triggers and resynchronizes at the end.

- [x] Write controller tests for detector start/stop, hide cancellation, show-inside arming, drag suppression, and panel reuse.
- [x] Run focused tests and confirm RED.
- [x] Wire detector lifecycle through the panel's own mouse events without changing panel identity or click priority.
- [x] Run focused tests and keep them green.

### Task 4: Required verification and delivery record

**Files:**
- Create: `docs/handoffs/2026-07-20-MD-008-limited-pointer-proximity-response.md`
- Modify only the existing root records needed to log implementation evidence; do not move MD-008 or mark it complete.

- [x] Run `python3 -m unittest asset.tests.test_md005_frame_stability asset.tests.test_md008_frame_stability`.
- [x] Run all effective `MochiDockTests` with code signing disabled.
- [x] Run a clean unsigned Debug build.
- [x] Run `git diff --check`, inspect changed-file responsibilities and line counts, and perform an observable local smoke check.
- [x] Record exact constants, priority behavior, commands/results, manual acceptance items, risks, and deviations in the handoff.
- [x] Re-read the MD-008 acceptance and delivery sections line by line, then report only MD-008 without starting another task.
