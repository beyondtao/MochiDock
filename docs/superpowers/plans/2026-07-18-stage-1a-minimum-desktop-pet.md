# MochiDock Stage 1A Minimum Desktop Pet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a minimal macOS desktop pet that appears in a transparent borderless window, can be dragged, visibly reacts to a click, and can be exited from a menu.

**Architecture:** Keep `MochiDockApp` focused on application assembly. An AppKit window controller owns and configures the transparent floating panel, while a small observable interaction model owns testable pet state and a SwiftUI view renders a temporary vector placeholder. No persistence or external dependency is introduced in Stage 1A.

**Tech Stack:** Swift 5, SwiftUI, AppKit, Swift Testing, Xcode 26.4.1, macOS 26.4 deployment target.

## Global Constraints

- The user remains product manager, product owner, and final decision-maker.
- Stage 1A includes only stable display, dragging, click feedback, a clear menu, and quit behavior.
- Use a temporary code-drawn placeholder; do not select or generate final character artwork.
- Do not add SwiftData, settings persistence, AI, chat, networking, third-party packages, autonomous movement, or complex animation.
- The pet window must be transparent and borderless, remain movable by dragging its background, and must not activate an ordinary document window.
- Closing or hiding the pet must not leave the user without an obvious way to quit; the menu-bar menu remains available.
- Keep each file focused on one responsibility and do not introduce a general-purpose utility file.

---

## Stage 1A Acceptance Evidence

1. Launching the app shows exactly one visible pet placeholder without an ordinary title bar or opaque window background.
2. Dragging the pet moves the window and releasing the pointer leaves it at the new position.
3. A single click changes the pet's visible expression immediately; a second click returns it to the resting expression.
4. The menu-bar menu contains `Show Pet` and `Quit MochiDock`; `Show Pet` restores a hidden/closed pet panel and `Quit MochiDock` terminates the app.
5. The panel remains above normal app windows but does not appear on every Space or over full-screen apps in Stage 1A.
6. Unit tests cover the click-state transition and idempotent panel presentation; a clean Debug build and test run pass.
7. Manual observation confirms the pet can remain visible for 30 minutes without multiplying windows, losing click response, or preventing normal pointer use outside its bounds.

## File Structure

- `MochiDock/MochiDock/MochiDockApp.swift`: app entry point, dependency assembly, and menu-bar commands only.
- `MochiDock/MochiDock/PetInteractionModel.swift`: testable resting/happy interaction state and click transition.
- `MochiDock/MochiDock/PetView.swift`: temporary vector pet rendering and click gesture.
- `MochiDock/MochiDock/PetPanelController.swift`: creates, configures, presents, and reuses one transparent AppKit panel.
- `MochiDock/MochiDockTests/PetInteractionModelTests.swift`: state-transition tests.
- `MochiDock/MochiDockTests/PetPanelControllerTests.swift`: panel configuration and single-instance presentation tests.
- Delete template-only `ContentView.swift`, `Item.swift`, and the empty `MochiDockTests.swift` after their replacements compile.

### Task 1: Replace the template data model with a testable pet interaction model

**Files:**
- Create: `MochiDock/MochiDock/PetInteractionModel.swift`
- Create: `MochiDock/MochiDockTests/PetInteractionModelTests.swift`
- Delete after tests pass: `MochiDock/MochiDock/Item.swift`

**Interfaces:**
- Produces: `@MainActor @Observable final class PetInteractionModel`
- Produces: `enum PetMood { case resting, happy }`
- Produces: `private(set) var mood: PetMood` and `func handleClick()`

- [ ] **Step 1: Write the failing state-transition tests**

```swift
import Testing
@testable import MochiDock

@MainActor
struct PetInteractionModelTests {
    @Test func startsResting() {
        let model = PetInteractionModel()
        #expect(model.mood == .resting)
    }

    @Test func clickTogglesBetweenRestingAndHappy() {
        let model = PetInteractionModel()
        model.handleClick()
        #expect(model.mood == .happy)
        model.handleClick()
        #expect(model.mood == .resting)
    }
}
```

- [ ] **Step 2: Run the focused tests and verify they fail**

Run:

```bash
xcodebuild test -project MochiDock/MochiDock.xcodeproj -scheme MochiDock -destination 'platform=macOS' -only-testing:MochiDockTests/PetInteractionModelTests -derivedDataPath .derivedData-stage1a CODE_SIGNING_ALLOWED=NO
```

Expected: test compilation fails because `PetInteractionModel` and `PetMood` do not exist.

- [ ] **Step 3: Add the minimal interaction model**

```swift
import Observation

enum PetMood: Equatable {
    case resting
    case happy
}

@MainActor
@Observable
final class PetInteractionModel {
    private(set) var mood: PetMood = .resting

    func handleClick() {
        mood = mood == .resting ? .happy : .resting
    }
}
```

- [ ] **Step 4: Re-run the focused tests**

Expected: both `PetInteractionModelTests` tests pass.

- [ ] **Step 5: Remove the unused SwiftData template model and commit**

```bash
git add MochiDock/MochiDock/PetInteractionModel.swift MochiDock/MochiDockTests/PetInteractionModelTests.swift MochiDock/MochiDock/Item.swift
git commit -m "feat: add desktop pet interaction state"
```

### Task 2: Render a temporary clickable pet

**Files:**
- Create: `MochiDock/MochiDock/PetView.swift`
- Delete after replacement compiles: `MochiDock/MochiDock/ContentView.swift`

**Interfaces:**
- Consumes: `PetInteractionModel.mood` and `PetInteractionModel.handleClick()`
- Produces: `struct PetView: View` initialized with `PetInteractionModel`

- [ ] **Step 1: Add a compile-time view test through a Debug build**

Create `PetView.swift` first with a deliberately unresolved `PetFace` reference, then run the Debug build command below to prove the new file is compiled by the synchronized Xcode group.

```swift
import SwiftUI

struct PetView: View {
    let model: PetInteractionModel

    var body: some View {
        PetFace(mood: model.mood)
    }
}
```

- [ ] **Step 2: Run a Debug build and verify it fails on `PetFace`**

Run:

```bash
xcodebuild build -project MochiDock/MochiDock.xcodeproj -scheme MochiDock -configuration Debug -destination 'platform=macOS' -derivedDataPath .derivedData-stage1a CODE_SIGNING_ALLOWED=NO
```

Expected: compilation fails with `cannot find 'PetFace' in scope`.

- [ ] **Step 3: Implement the complete temporary vector view**

Replace the deliberately incomplete body with a 128×128 SwiftUI composition: a rounded mochi-colored body, two eyes, and a mouth whose curve/color changes for `.happy`. Apply `.contentShape(Rectangle())`, `.onTapGesture { model.handleClick() }`, and accessibility label/value strings `MochiDock pet` and `Resting`/`Happy`. Do not add timers, image assets, or continuous animation.

- [ ] **Step 4: Build and visually preview both states**

Run the Debug build command from Step 2. Expected: `** BUILD SUCCEEDED **`. In Xcode previews, instantiate two models, toggle one once, and confirm both expressions fit inside 128×128 without clipping.

- [ ] **Step 5: Remove `ContentView.swift` and commit**

```bash
git add MochiDock/MochiDock/PetView.swift MochiDock/MochiDock/ContentView.swift
git commit -m "feat: render clickable placeholder pet"
```

### Task 3: Present one transparent draggable pet panel

**Files:**
- Create: `MochiDock/MochiDock/PetPanelController.swift`
- Create: `MochiDock/MochiDockTests/PetPanelControllerTests.swift`

**Interfaces:**
- Consumes: `PetInteractionModel` and `PetView`
- Produces: `@MainActor final class PetPanelController`
- Produces: `func showPet()` and `func hidePet()`
- Produces for tests: read-only `var panel: NSPanel?`

- [ ] **Step 1: Write failing panel tests**

```swift
import AppKit
import Testing
@testable import MochiDock

@MainActor
struct PetPanelControllerTests {
    @Test func showPetConfiguresTransparentMovablePanel() {
        let controller = PetPanelController(model: PetInteractionModel())
        controller.showPet()
        let panel = controller.panel
        #expect(panel != nil)
        #expect(panel?.isOpaque == false)
        #expect(panel?.backgroundColor == .clear)
        #expect(panel?.styleMask.contains(.borderless) == true)
        #expect(panel?.isMovableByWindowBackground == true)
        #expect(panel?.level == .floating)
    }

    @Test func repeatedShowReusesTheSamePanel() {
        let controller = PetPanelController(model: PetInteractionModel())
        controller.showPet()
        let firstPanel = controller.panel
        controller.showPet()
        #expect(controller.panel === firstPanel)
    }
}
```

- [ ] **Step 2: Run the focused panel tests and verify they fail**

Expected: test compilation fails because `PetPanelController` does not exist.

- [ ] **Step 3: Implement minimal panel ownership**

Create a borderless `NSPanel` with a 128×128 content rect and `NSHostingView(rootView: PetView(model: model))`. Configure `isOpaque = false`, `backgroundColor = .clear`, `hasShadow = true`, `isMovableByWindowBackground = true`, `level = .floating`, `collectionBehavior = [.moveToActiveSpace]`, and `hidesOnDeactivate = false`. Center it on first creation, retain it, and use `orderFrontRegardless()` on every `showPet()` call. `hidePet()` calls `orderOut(nil)` without destroying the panel.

- [ ] **Step 4: Run both focused test suites**

Expected: all interaction and panel tests pass, and repeated presentation retains exactly one `NSPanel` instance.

- [ ] **Step 5: Commit the panel boundary**

```bash
git add MochiDock/MochiDock/PetPanelController.swift MochiDock/MochiDockTests/PetPanelControllerTests.swift
git commit -m "feat: present pet in transparent draggable panel"
```

### Task 4: Assemble launch and menu-bar lifecycle

**Files:**
- Modify: `MochiDock/MochiDock/MochiDockApp.swift`
- Delete after replacement tests compile: `MochiDock/MochiDockTests/MochiDockTests.swift`

**Interfaces:**
- Consumes: one shared `PetInteractionModel` and one shared `PetPanelController`
- Produces: menu actions `Show Pet` and `Quit MochiDock`

- [ ] **Step 1: Replace the SwiftData app entry with explicit assembly**

Use an `NSApplicationDelegateAdaptor` whose delegate constructs one model and controller, calls `showPet()` from `applicationDidFinishLaunching`, and returns `false` from `applicationShouldTerminateAfterLastWindowClosed`. The SwiftUI `App` body contains a `MenuBarExtra("MochiDock", systemImage: "pawprint.fill")` with buttons that call `showPet()` and `NSApplication.shared.terminate(nil)`. Do not retain a `WindowGroup` or `ModelContainer`.

- [ ] **Step 2: Run all unit tests**

Run:

```bash
xcodebuild test -project MochiDock/MochiDock.xcodeproj -scheme MochiDock -destination 'platform=macOS' -derivedDataPath .derivedData-stage1a CODE_SIGNING_ALLOWED=NO
```

Expected: all unit and UI target tests selected by the scheme pass; no SwiftData or template-symbol errors remain.

- [ ] **Step 3: Run a clean Debug build**

Run:

```bash
xcodebuild clean build -project MochiDock/MochiDock.xcodeproj -scheme MochiDock -configuration Debug -destination 'platform=macOS' -derivedDataPath .derivedData-stage1a CODE_SIGNING_ALLOWED=NO
```

Expected: `** CLEAN SUCCEEDED **` followed by `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Remove the empty template test and commit**

```bash
git add MochiDock/MochiDock/MochiDockApp.swift MochiDock/MochiDockTests/MochiDockTests.swift
git commit -m "feat: add desktop pet launch and quit lifecycle"
```

### Task 5: Perform Stage 1A experiential verification and update project memory

**Files:**
- Modify: `task_plan.md`
- Modify: `findings.md`
- Modify: `progress.md`

**Interfaces:**
- Consumes: the complete Stage 1A application
- Produces: dated verification evidence and any observed usability risks

- [ ] **Step 1: Launch the built Debug application manually**

Open `.derivedData-stage1a/Build/Products/Debug/MochiDock.app`. Confirm a single pet appears and no ordinary document window opens.

- [ ] **Step 2: Exercise the observable interaction checklist**

Drag the pet to four screen positions, click twice, switch to another normal app, use `Show Pet`, and quit from `Quit MochiDock`. Record pass/fail against acceptance items 1–5; include the exact failure and reproduction steps for any failed item.

- [ ] **Step 3: Run the 30-minute low-interruption observation**

Leave the pet visible during normal work. Record whether it multiplied, intercepted clicks outside its 128×128 bounds, disappeared unexpectedly, or became unresponsive. This is experience evidence, not an automated test.

- [ ] **Step 4: Update persistent project records**

Mark only verified items complete in `task_plan.md`, append technical or experiential discoveries to `findings.md`, and add build/test/manual results to `progress.md`. Keep animation refinements, settings, final artwork, tools, and AI in possible-next-work or the idea pool.

- [ ] **Step 5: Commit verified Stage 1A records**

```bash
git add task_plan.md findings.md progress.md
git commit -m "docs: record stage 1a verification"
```

## Self-Review Result

- Spec coverage: every Stage 1A capability has an implementation task and observable acceptance evidence.
- Scope control: persistence, final artwork, autonomous animation, tools, and AI are explicitly excluded.
- Type consistency: `PetInteractionModel`, `PetMood`, `PetView`, and `PetPanelController` names and ownership are consistent across tasks.
- Test boundary: deterministic state and panel configuration are automated; subjective dragging and low-interruption behavior remain explicit manual checks.
- Placeholder scan: implementation steps contain concrete behavior and commands; there are no unresolved `TBD` or `TODO` markers.
