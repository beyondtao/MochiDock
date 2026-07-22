# MD-011 Settings Window Implementation Plan

> **For agentic workers:** Execute inline in this task. Do not dispatch subagents, accept or archive MD-011, or start later work. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace growing status-menu preferences with one reusable independent settings window while preserving every MD-010 behavior and state source.

**Architecture:** Keep `MochiDockAppDelegate` as the existing action/state bridge and add one retained `SettingsWindowController` that hosts a focused SwiftUI `SettingsView`. The status menu opens that controller and contains only visibility, settings, and quit actions. Settings bindings continue to call the existing display-size persistence, proximity persistence/lifecycle, and native login-item service paths.

**Tech Stack:** Swift, SwiftUI, AppKit `NSWindowController`, Swift Testing, Xcode/xcodebuild.

## Global Constraints

- Preserve the dirty, unaccepted MD-010 implementation and all of its behavior.
- The status menu contains only Hide/Show Pet, Settings…, and Quit MochiDock.
- Repeated Settings… actions reuse one window; closing it does not quit, hide the pet, or create another window.
- Settings contain only Pet Size, Pointer Proximity Response, and Start at Login, including truthful native login status outcomes.
- Add English and Simplified Chinese only; add no dependencies, permissions, persistence keys, generic settings framework, or unrelated features.
- Do not accept, archive, commit, push, publish, or begin a later task.
- Use the confirmed two-column Pet/Application layout without adding placeholder categories.
- Render Pet Size as a thin discrete slider with exactly five visible stops mapped to the existing 80/120/160/240/320 cases; never introduce continuous sizes or another persisted value.

---

### Task 1: Single reusable settings window lifecycle

**Files:**
- Create: `MochiDock/MochiDock/SettingsWindowController.swift`
- Modify: `MochiDock/MochiDock/MochiDockApp.swift`
- Test: `MochiDock/MochiDockTests/MochiDockAppDelegateTests.swift`

**Interfaces:**
- Produces: `MochiDockAppDelegate.openSettings()`, retained `SettingsWindowController`, and one reusable non-releasing `NSWindow`.

- [x] Add tests that open settings twice, compare window identity, close and reopen it, and assert the pet remains visible and application last-window closure does not terminate.
- [x] Run the focused tests and confirm RED for the missing settings action/controller.
- [x] Add the minimal retained controller and app-delegate action.
- [x] Re-run the focused tests and confirm GREEN.

### Task 2: Move the three existing controls into settings

**Files:**
- Create: `MochiDock/MochiDock/SettingsView.swift`
- Modify: `MochiDock/MochiDock/MochiDockApp.swift`
- Test: `MochiDock/MochiDockTests/MochiDockAppDelegateTests.swift`

**Interfaces:**
- Consumes: existing `displaySize`, `selectDisplaySize(_:)`, proximity state/action, login state/action/outcome.
- Produces: `SettingsView` and the three-item status-menu policy.

- [x] Add tests identifying the exact three menu actions and proving settings bindings still route through existing persisted and native state.
- [x] Run the focused tests and confirm RED for missing menu policy/settings surface.
- [x] Reduce `MochiDockMenuContent` to visibility, Settings…, and quit; build the focused settings form with the existing bindings.
- [x] Refresh native login-item status whenever settings is shown.
- [x] Re-run focused MD-011 and existing MD-010 app-delegate tests and confirm GREEN.

### Task 3: English and Simplified Chinese coverage

**Files:**
- Modify: `MochiDock/MochiDock/Localizable.xcstrings`
- Modify: `MochiDock/MochiDockTests/LocalizationTests.swift`

- [x] Add expectations for Settings…, the window title, and the existing settings labels; confirm localization RED.
- [x] Add only English and Simplified Chinese catalog values; confirm localization GREEN.

### Task 4: Records and full regression verification

**Files:**
- Add: `docs/tasks/active/MD-011-settings-window.md`
- Modify: `task_plan.md`
- Modify: `findings.md`
- Modify: `progress.md`

- [x] Record MD-011 as delivered for user acceptance without accepting or archiving it and without changing MD-010 acceptance state.
- [x] Run all valid `MochiDockTests` unsigned, including the MD-010 interaction/login suites.
- [x] Run an unsigned clean Debug build and `git diff --check`.
- [x] Inspect changed-file responsibilities, line counts, persistence keys, permissions/dependencies, window ownership, exact menu scope, and final diff.
- [x] Report changed files, tests, build, manual gaps, and risks; end with the exact MD-011 delivery signal.

### Task 5: Confirmed two-column revision and discrete size slider

**Files:**
- Modify: `MochiDock/MochiDock/SettingsView.swift`
- Modify if required for window sizing only: `MochiDock/MochiDock/SettingsWindowController.swift`
- Test: an existing focused settings test file under `MochiDock/MochiDockTests/`
- Modify: `MochiDock/MochiDockTests/LocalizationTests.swift` only if visible labels change

**Interfaces:**
- Consumes: existing `PetDisplaySize.allCases`, current selected size, and `MochiDockAppDelegate.selectDisplaySize(_:)`.
- Produces: one accessible five-stop slider UI; no new preference key, size case, or state owner.

- [x] Add focused failing tests proving the control model exposes exactly the existing five ordered sizes and maps each stop back to the matching `PetDisplaySize`.
- [x] Add focused failing tests for nearest-stop snapping, direct stop selection, and one-step keyboard movement without any intermediate persisted value.
- [x] Replace the segmented size picker with a thin horizontal track, five fixed dots, a clearly distinguished current stop, and readable size labels.
- [x] Route every committed selection through the existing size action and preserve immediate panel update and persistence behavior.
- [x] Verify English and Simplified Chinese labels remain covered by the localization suite; final spacing and selected-stop appearance remain manual acceptance items.
- [x] Fix and test the already-recorded application activation/frontmost-window gap before presenting the window for acceptance.
- [x] Run all valid `MochiDockTests`, the asset stability suite, an unsigned clean Debug build, and `git diff --check`; then return MD-011 for independent review.

### Task 6: Repair real pointer dragging and focus presentation

**Files:**
- Modify: `MochiDock/MochiDock/PetSizeSlider.swift`
- Test: `MochiDock/MochiDockTests/PetSizeSliderTests.swift` or an appropriate UI-level settings test

**Verified root causes:**
- The drag gesture is attached only to the track behind stop buttons, so a drag beginning on a dot is consumed by the overlaid `Button` rather than the track gesture.
- Existing “drag” tests cover only numeric snapping helpers and do not exercise pointer events against the rendered SwiftUI control.
- Applying `.focusable()` with the default focus effect to the root `VStack` produces the oversized blue rectangular focus ring.

- [x] Add a failing interaction-level regression that begins the pointer drag on the selected dot, crosses at least two stops, and observes the expected legal selections.
- [x] Add coverage for dragging from an unselected dot and from the track, without removing direct dot clicking.
- [x] Give the control one coherent pointer hit region so the drag gesture receives events regardless of whether the press begins on the track or any dot.
- [x] Preserve five-stop snapping and the existing `selectDisplaySize(_:)` path; do not add continuous state or another persistence route.
- [x] Preserve keyboard focus and left/right movement while removing the default focus effect around the entire slider container.
- [x] If a custom focus indication is retained, constrain it to the selected thumb or track and keep it visually distinct from the persistent selected-size indication.
- [x] Manually verify real mouse dragging from the selected dot, every other dot, and between dots; model-only tests are not sufficient evidence.
- [x] Manually verify the active window contains no oversized rectangular focus border; inactive-window appearance remains a user-side visual check.
- [x] Run focused RED/GREEN evidence, all valid tests, the asset stability suite, unsigned clean Debug build, and `git diff --check` before returning for review.

### Task 7: Reopen settings on the current macOS Space

**Files:**
- Modify: `MochiDock/MochiDock/SettingsWindowController.swift`
- Test: `MochiDock/MochiDockTests/MochiDockAppDelegateTests.swift` or a focused settings-window test file

**Confirmed product decision:**
- Reopening the one retained settings window must bring it to the currently active Space instead of switching the user back to the Space where settings was last shown.
- This policy applies only to settings. The pet panel keeps its existing all-Spaces behavior.

- [x] Add a failing test proving the settings window uses the AppKit collection behavior that moves a shown window to the active Space.
- [x] Prove the settings window does not use `canJoinAllSpaces` and still reuses one `NSWindow` across close/reopen cycles.
- [x] Apply the minimal settings-window collection behavior; do not modify `PetPanelController` or its all-Spaces policy.
- [x] Manually verify: open and close settings on Space 2, switch to Space 1, reopen settings, and confirm macOS remains on Space 1.
- [x] Re-run focused window tests, all valid tests, unsigned clean Debug build, and `git diff --check` before returning for review.

### Task 8: Remove the activation-injection isolation warning

**Files:**
- Modify: `MochiDock/MochiDock/MochiDockApp.swift`
- Test: `MochiDock/MochiDockTests/MochiDockAppDelegateTests.swift`

**Verified warning:**
- `MochiDockApp.swift:97`: the default argument `NSApplication.shared` is evaluated from a nonisolated default-argument context even though the delegate class is main-actor isolated.

- [x] Add or preserve focused tests proving production construction uses the native application activator and test construction can inject a fake activator.
- [x] Remove the default argument reference to `NSApplication.shared`; resolve the production activator only inside an explicitly main-actor-isolated initializer or assembly path.
- [x] Do not use `nonisolated(unsafe)`, warning suppression, weaker concurrency settings, or project configuration changes.
- [x] Run the focused AppDelegate tests and a fresh unsigned Debug build; inspect output and confirm the specific isolation warning is absent.
- [x] Re-run all valid tests and `git diff --check` before returning for review.

## Self-review

- Spec coverage: exact menu, reusable window, three moved controls, persistence/native truth, close behavior, localization, MD-010 regression, and delivery boundary are all mapped.
- Scope: no extra settings, dependency, permission, generic framework, acceptance, archival, or follow-on work.
- Type consistency: settings consumes the already-existing app-delegate state/actions; no second preference store or login truth source is introduced.
