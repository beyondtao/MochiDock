# MD-014 Pet Interval Reminder Implementation Plan

> **For agentic workers:** Execute inline, task by task. Every production change requires a focused failing test first, followed by the smallest passing implementation and a fresh focused test run.

**Goal:** Deliver one complete local recurring reminder loop expressed by the existing desktop pet, with one active reminder, completion/snooze handling, restoration, low-interruption presentation, and settings management.

**Architecture:** `ReminderCenter` owns reminder definitions and business transitions; `ReminderPersistence` owns the exact local payload; `ReminderClock` and `ReminderScheduling` make wall-clock behavior deterministic. `ReminderPresentationCoordinator` owns presentation priority and bubble lifetime, while `ReminderBubbleLayout` is pure geometry. `PetPanelController` remains the single panel lifecycle adapter and delegates reminder behavior instead of owning reminder data or scheduling; settings bind to `ReminderCenter` through the app delegate.

**Tech Stack:** Swift 6, SwiftUI, AppKit, Observation/Combine, Swift Testing, UserDefaults; no new dependency, permission, network capability, notification API, sound, or image asset.

## Global Constraints

- Only recurring 5–240 minute intervals in 5-minute steps; presets are 20, 30, 45, and 60 minutes.
- Reminder name is required and at most 30 characters; a new draft is empty and 45 minutes.
- Multiple definitions are allowed, but at most one is enabled or pending.
- Persist only name, interval, enabled state, paused remaining time, next trigger time, and pending state needed to restore the same lifecycle; never persist history or statistics.
- Due presentation is once per cycle, bubble text is `该{提醒名称}啦～`, actions are `完成` and `10 分钟后提醒`, bubble auto-collapses after 8 seconds while pending remains.
- Sleep does not accumulate cycles; wake presents at most once when overdue.
- Hide never forces the pet visible; peek restores the full frame; drag and happy response finish before presentation.
- Pending disables automatic edge retreat and decorative proximity response.
- Reuse attention visuals for one approximately 1.5-second lift/two-nod animation; no new image asset and no sound.
- Bubble gap is 12 pt, maximum width 280 pt, flips below when needed, and clamps to a supplied visible screen rectangle without changing pet position.
- Do not commit, push, publish, create a PR, accept/archive MD-014, or start MD-015.

---

### Task 1: Reminder domain, scheduling, and persistence

**Files:**
- Create: `MochiDock/MochiDock/Reminder.swift`
- Create: `MochiDock/MochiDock/ReminderPersistence.swift`
- Create: `MochiDock/MochiDock/ReminderCenter.swift`
- Test: `MochiDock/MochiDockTests/ReminderCenterTests.swift`
- Test: `MochiDock/MochiDockTests/ReminderPersistenceTests.swift`

**Interfaces:** `ReminderCenter` publishes reminders/current status and implements add, edit, enable, pause, delete, due, complete, snooze, wake, and restoration. `ReminderClock.now` and `ReminderScheduling.schedule(at:)` are injected.

- [ ] Write focused tests for validation, one-active invariant, pause/resume, edit reset, delete confirmation classification, due/complete/snooze, no duplicate due, sleep/wake, and restoration.
- [ ] Run the focused suite and record missing-type/behavior RED output.
- [ ] Implement only the domain, persistence adapter, and deterministic scheduling required by those tests.
- [ ] Run the focused suite and record GREEN output.

### Task 2: Bubble geometry

**Files:**
- Create: `MochiDock/MochiDock/ReminderBubbleLayout.swift`
- Test: `MochiDock/MochiDockTests/ReminderBubbleLayoutTests.swift`

**Interfaces:** Pure `layout(petFrame:bubbleSize:visibleFrame:)` returns frame and above/below placement from synthetic rectangles.

- [ ] Write synthetic geometry tests for above, below, left/right clamps, maximum width, pet movement, size changes, and screen changes.
- [ ] Run the focused suite and record RED.
- [ ] Implement 12 pt spacing, 280 pt width cap, vertical flip, and visible-frame clamp without mutating the pet frame.
- [ ] Run the focused suite and record GREEN.

### Task 3: Reminder presentation and interaction priority

**Files:**
- Create: `MochiDock/MochiDock/ReminderPresentationCoordinator.swift`
- Modify: `MochiDock/MochiDock/PetInteractionModel.swift`
- Modify: `MochiDock/MochiDock/PetAnimation.swift`
- Test: `MochiDock/MochiDockTests/ReminderPresentationCoordinatorTests.swift`
- Test: `MochiDock/MochiDockTests/PetInteractionModelTests.swift`

**Interfaces:** Coordinator accepts visibility, drag, ordinary-response, peek, and pending events and emits restore/show/hide/relayout actions. The model exposes a one-shot reminder animation and completion callback while suppressing decorative attention.

- [ ] Write tests for 8-second collapse/reopen, drag delay, happy-response delay, peek restoration, Hide/Show, pending suppression, one-shot animation, and stale callback cancellation.
- [ ] Run focused RED.
- [ ] Implement the presentation state machine and 1.5-second attention-based lift/two-nod sequence.
- [ ] Run focused GREEN and the existing interaction tests.

### Task 4: Panel bubble and lifecycle integration

**Files:**
- Create: `MochiDock/MochiDock/ReminderBubbleView.swift`
- Create: `MochiDock/MochiDock/ReminderPanelController.swift`
- Modify: `MochiDock/MochiDock/PetPanelController.swift`
- Modify: `MochiDock/MochiDock/PetView.swift`
- Test: `MochiDock/MochiDockTests/PetReminderIntegrationTests.swift`

**Interfaces:** A separate bubble panel follows the existing pet panel. The panel controller exposes narrow visibility, drag, click, peek-restoration, size, and screen callbacks to the reminder presentation coordinator.

- [ ] Write integration tests proving one bubble, follow-on-drag, relayout, click priority, Hide/Show, edge suppression, and no pet-position writes.
- [ ] Run focused RED.
- [ ] Add the smallest adapter calls and dedicated bubble controller; keep reminder data/scheduling/geometry out of `PetPanelController`.
- [ ] Run focused GREEN plus existing panel/edge/proximity suites.

### Task 5: Settings management and application assembly

**Files:**
- Create: `MochiDock/MochiDock/ReminderSettingsView.swift`
- Modify: `MochiDock/MochiDock/SettingsView.swift`
- Modify: `MochiDock/MochiDock/MochiDockApp.swift`
- Modify: `MochiDock/MochiDock/Localizable.xcstrings`
- Test: `MochiDock/MochiDockTests/ReminderSettingsTests.swift`
- Modify: `MochiDock/MochiDockTests/MochiDockAppDelegateTests.swift`
- Modify: `MochiDock/MochiDockTests/LocalizationTests.swift`

**Interfaces:** App assembly creates one `ReminderCenter`; app delegate publishes it to settings and forwards due/presentation actions. Reminder settings contain current remaining time, list controls, edit/add sheets, and deletion confirmation only for enabled/pending reminders.

- [ ] Write tests for sidebar order, no menu entry, draft defaults/validation/presets, management actions, status explanation, and settings reuse.
- [ ] Run focused RED.
- [ ] Implement settings UI and dependency wiring without adding a menu action.
- [ ] Run focused GREEN and all settings/localization tests.

### Task 6: Full verification and delivery records

**Files:**
- Modify: `task_plan.md`
- Modify: `findings.md`
- Modify: `progress.md`
- Modify: `docs/tasks/active/MD-014-pet-interval-reminder.md`

- [ ] Run all effective `MochiDockTests` with signing disabled.
- [ ] Run a clean unsigned Debug build.
- [ ] Run `git diff --check`, existing character asset stability tests, asset diff inspection, and changed-file line counts.
- [ ] Perform every reliable short manual check; explicitly record unavailable five-minute, ten-minute, real sleep/wake, edge/size, restart, and half-day checks as unverified rather than substituting automation.
- [ ] Re-read the task spec and map every requirement to code/test evidence; correct gaps through another RED/GREEN cycle.
- [ ] Update MD-014 to `待验收` only after fresh verification; do not accept, archive, commit, push, publish, create a PR, or start MD-015.

## Plan Self-Review

- Spec coverage: domain lifecycle, persistence, controlled time, sleep/wake, bubble geometry, interaction priority, pet animation, panel lifecycle, settings, localization, regression, asset stability, and delivery records each have an explicit task.
- Placeholder scan: no deferred implementation placeholder is used; unavailable real-time/manual checks are intentionally reported rather than treated as implementation omissions.
- Type consistency: `ReminderCenter` is the sole business state owner; `ReminderPresentationCoordinator` consumes pending events; `ReminderPanelController` consumes presentation/layout commands; app delegate only assembles and forwards.

---

## Independent Review Revision (2026-07-22)

This is a focused continuation of MD-014. Preserve the first implementation and its evidence; change only the four reviewed gaps below.

### Revision 1: Restored-pending edge suppression

- [ ] Add a controller-sequence test that restores a persisted pending reminder at an eligible edge, calls `showPet()` in production order, fires the previously armed edge task, and observes no retreat.
- [ ] Cover pending resolution/deletion rearming and Hide/Show retaining suppression.
- [ ] Record focused RED before changing production code.
- [ ] Make pending-state synchronization explicit at the panel/controller boundary, then record focused GREEN.

### Revision 2: Independent interaction blockers

- [ ] Add both drag-first and ordinary-response-first completion tests, including duplicate end events and no new reminder cycle while waiting.
- [ ] Record focused RED against the single waiting Boolean.
- [ ] Track blockers independently or refresh the complete interaction context on every transition; present exactly once after the last blocker clears.
- [ ] Record focused GREEN plus existing presentation and pet-interaction suites.

### Revision 3: Parameterized reminder localization

- [ ] Add English and Simplified Chinese tests for bubble text, running, pending, remaining, interval, and switched-reminder status using long/special-character names.
- [ ] Record focused RED against current Chinese literals.
- [ ] Introduce responsibility-scoped localized reminder text generation backed by String Catalog format keys; remove user-visible Chinese literals from business and views.
- [ ] Record focused GREEN and verify English output contains no fixed Chinese fragments.

### Revision 4: Narrow visible-frame geometry

- [ ] Add synthetic above/below, left/right, narrower-than-requested, narrower-than-280, and degenerate-frame tests.
- [ ] Record focused RED against the current width calculation.
- [ ] Bound width to the usable visible-frame width with a predictable safety-margin rule and nonnegative finite output.
- [ ] Record focused GREEN while preserving 12 pt gap, flip behavior, and pet-frame immutability.

### Revision 5: Full re-verification and records

- [ ] Run every focused revision suite, all effective `MochiDockTests`, clean unsigned Debug build, `git diff --check`, asset stability/diff checks, and line/responsibility inspection.
- [ ] Append RED/GREEN evidence and remaining manual checks to `task_plan.md`, `findings.md`, `progress.md`, and the active MD-014 task document.
- [ ] Move MD-014 to `待验收` only after fresh evidence; do not accept, archive, commit, push, publish, create a PR, merge, or start MD-015.

### Revision completion evidence

- All Revision 1–4 RED cases were observed with exit code 65 before product changes; focused combined GREEN exited 0.
- All 201 logical test definitions expanded to 287 executions and passed with 0 failures, exit code 0.
- Clean unsigned Debug build and independently rerun asset stability suite exited 0; asset diff and `git diff --check` were clean.
- MD-014 moved to `待验收`; real-time, real-desktop, restart, sleep/wake, and half-day experience checks remain with the user.

---

## Second Independent Review Revision (2026-07-22)

The prior four review findings remain closed. This revision addresses only stale presentation blockers when Hide cancels active interactions.

- [x] Add focused coordinator RED cases for drag-only, ordinary-response-only, and combined blockers followed by Hide/Show.
- [x] Add a real `PetPanelController` production-order RED covering due while drag and happy are active, Hide cancellation, Show presentation, repeated lifecycle events, and edge rearming after resolution.
- [x] Clear cancelled interaction blockers at the Hide lifecycle boundary without presenting while hidden or replaying a previously played reminder animation.
- [x] Run focused GREEN, all effective tests, clean unsigned Debug build, asset stability/diff checks, `git diff --check`, and line/responsibility inspection.
- [x] Append evidence to project records and move MD-014 to `待验收` only after fresh verification; do not accept, archive, commit, push, publish, merge, or start MD-015.

### Second revision completion evidence

- Focused RED failed in all three blocker combinations and the real controller production-order case, exit code 65; focused GREEN passed, exit code 0.
- All 203 effective logical tests passed with 0 failures, expanding to 291 parameterized executions, exit code 0.
- Clean unsigned Debug build, independent asset stability tests, asset/project diff inspection, and `git diff --check` passed. No product file exceeds 600 lines.
- Real-time and real-desktop acceptance remains with the user; no acceptance, archive, commit, push, publish, merge, PR, or MD-015 work occurred.
