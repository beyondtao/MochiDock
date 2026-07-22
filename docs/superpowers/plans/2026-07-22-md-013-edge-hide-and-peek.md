# MD-013 Edge Hide and Peek Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task, and use superpowers:test-driven-development for every product change. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a pet deliberately placed near the left or right outer screen edge retreat partially off-screen, remain discoverable, and return safely on pointer approach or click.

**Architecture:** Add a pure `PetEdgePlacement` geometry policy and a focused `PetEdgeBehaviorCoordinator` state machine. `PetPanelController` remains the AppKit integration owner and forwards drag, pointer, visibility, size, and screen events; the coordinator owns the cancellable wait and reports frame transitions without persisting temporary peek frames. Existing `PetInteractionModel` continues to own visual/animation state, with a minimal explicit edge-peek visual entry/exit instead of a second animation loop.

**Tech Stack:** Swift, AppKit, SwiftUI Observation, Swift Testing, existing animation scheduler abstraction, xcodebuild.

## Global Constraints

- Preserve one `NSPanel`, one `PetInteractionModel`, and one normal playback scheduling boundary.
- Trigger only after a user drag ends within a left/right outer-edge trigger band; never cross the screen from the center.
- Support left and right outer edges only; top, bottom, and internal display seams are excluded.
- Persist only fully visible resting frames. Never persist a temporary peek frame or new edge state.
- Add no permissions, global event monitor, network, AI, dependency, database, preference key, setting, or asset.
- Keep existing identifiers, localization, signing, deployment target, Space behavior, and safe ordinary restoration unchanged.
- Do not add MD-013 tests to the existing 646-line `PetPanelControllerTests.swift`.

---

### Task 1: Pure outer-edge geometry policy

**Files:**
- Create: `MochiDock/MochiDock/PetEdgePlacement.swift`
- Create: `MochiDock/MochiDockTests/PetEdgePlacementTests.swift`

**Interfaces:**
- Produce `enum PetScreenEdge { case left, right }`.
- Produce `struct PetEdgePlacement` with methods to resolve an eligible outer edge from a fully visible panel frame and `[CGRect]`, and to calculate the temporary peek frame from the full frame, edge, and display-size length.
- Expose centralized trigger-band and visible-width policy values to deterministic tests without reading `NSScreen`.

- [ ] Write failing geometry tests covering left/right eligibility, center and top/bottom rejection, internal display-seam rejection, negative-coordinate displays, five display sizes, a visible width of `max(length * 0.35, 32)`, and exact restoration to the original full frame.
- [ ] Run `PetEdgePlacementTests` with signing disabled and confirm RED because the policy types do not exist.
- [ ] Implement the minimum pure geometry policy. Select a screen only when it completely contains the full frame; treat an edge as external only when no other visible frame continues immediately beyond that side across the panel's vertical span.
- [ ] Re-run `PetEdgePlacementTests` and confirm GREEN.

### Task 2: Cancellable edge behavior state machine

**Files:**
- Create: `MochiDock/MochiDock/PetEdgeBehaviorCoordinator.swift`
- Create: `MochiDock/MochiDockTests/PetEdgeBehaviorCoordinatorTests.swift`

**Interfaces:**
- Produce states equivalent to `inactive`, `waiting(edge:fullFrame:)`, `peeking(edge:fullFrame:peekFrame:)`, and `returning` without exposing mutable state to views.
- Consume the existing `PetAnimationScheduling` abstraction for one six-second wait task.
- Produce callbacks for `moveToPeek(frame:)`, `moveToFull(frame:completion:)`, `setPeekVisual(Bool)`, and `requestClickResponse()`; the AppKit owner supplies actual movement.

- [ ] Write failing tests for drag-end arming, wait expiry, cancellation by pointer/click/new drag/Hide/size/screen changes, stale scheduled callbacks after cancellation, pointer return, click return followed by one click response, repeated input idempotence, and no persistence responsibility.
- [ ] Run the focused coordinator tests and confirm RED because the coordinator does not exist.
- [ ] Implement a single cancellable wait, explicit state transitions, and completion-gated click response. Keep AppKit, preferences, and real screen reads outside this type.
- [ ] Re-run the focused tests and confirm GREEN.

### Task 3: Explicit peek visual lifecycle

**Files:**
- Modify: `MochiDock/MochiDock/PetInteractionModel.swift`
- Modify: `MochiDock/MochiDockTests/PetInteractionModelTests.swift`

**Interfaces:**
- Add explicit methods that enter the existing `attentionBase` visual while pausing ordinary breathing/blinking and leave it by resuming the normal idle schedule.
- Preserve `handleClick()` and `handleProximityEntry()` behavior outside an active edge transition.

- [ ] Add failing tests proving peek entry cancels the pending automatic action, holds `attentionBase` without a new loop, exit resumes idle once, click after exit uses the existing response, and stop playback clears peek visual.
- [ ] Run the focused model tests and confirm RED on missing peek lifecycle methods.
- [ ] Implement the smallest explicit enter/leave methods using the existing single `scheduledTask`; do not add a second scheduler or new visual asset mapping.
- [ ] Re-run the focused tests and confirm GREEN.

### Task 4: Single-panel AppKit integration

**Files:**
- Modify: `MochiDock/MochiDock/PetPanelController.swift`
- Create: `MochiDock/MochiDockTests/PetPanelEdgeBehaviorTests.swift`

**Interfaces:**
- `PetPanelController` injects or constructs the geometry policy and coordinator, forwards pointer contact and relevant lifecycle events, and remains the only owner of `NSPanel` frame changes and `pet.windowPosition` writes.
- Use a short `NSAnimationContext` frame animation for retreat/return; coordinator completion must be called exactly once even when AppKit animation duration is zero in tests.

- [ ] Add failing controller tests for left/right arm and retreat, pointer return independent of the decorative proximity preference, click return then one happy response, drag cancellation/re-arm, Hide/Show, size/screen change safety, central and seam rejection, panel identity, and no preference write for peek frames.
- [ ] Run the new controller test file with existing model/panel suites and confirm RED because integration is missing.
- [ ] Wire the coordinator into the existing panel lifecycle. Preserve the last fully visible frame as the only persistence candidate; when returning, set that exact safe frame before resuming ordinary playback or forwarding the click.
- [ ] Re-run the focused controller, interaction, proximity, placement, and preference suites and confirm GREEN.
- [ ] Check `PetPanelController.swift` responsibility and line count. If it reaches the 400-line responsibility review range, extract frame animation behind a focused protocol/type rather than mechanically splitting methods.

### Task 5: Full verification and real desktop calibration

**Files:**
- No product changes expected unless a verified defect is found.

- [ ] Run all effective `MochiDockTests` serially with code signing disabled.
- [ ] Run the MD-005 and MD-008 asset stability tests and confirm all 11 remain green.
- [ ] Run a clean unsigned Debug build and `git diff --check`.
- [ ] Launch the clean Debug app and verify left and right cycles at 120, 240, and 320 pt; verify central/top/bottom/non-outer seam rejection where the local display layout permits.
- [ ] Verify wait cancellation, pointer return, click return plus one happy response, Hide/Show, size change, relaunch from the last full position, and no unrecoverable off-screen state.
- [ ] Inspect changed-file responsibilities and line counts, protected identifiers, absence of new permissions/dependencies/preferences/assets, and task-book coverage.
- [ ] Deliver the required report and end with `MD-013 已交付，请验收` without marking the task accepted or starting another task.
