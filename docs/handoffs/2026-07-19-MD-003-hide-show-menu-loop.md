# MochiDock Handoff：MD-003 隐藏与恢复菜单闭环

## Metadata

- 日期：2026-07-19
- 来源任务：`MD-003 隐藏与恢复菜单闭环`
- 仓库路径：`/Users/tao/Projects/Working/MochiDock`
- 分支：`main`
- HEAD commit：`3c0e15369cd24ce5933183abfcd7a54703c42e86`（`docs: record MD-002 delivery and verification`）
- 开发前 Git 状态：`main` 与 `origin/main` 同步；工作区有高级项目经理的 5 个已跟踪文档改动和 1 个未跟踪 MD-003 任务书，暂存区为空。
- 开发后 Git 状态：保留上述项目经理改动；另有 MD-003 的 1 个产品源码修改、1 个测试文件修改、1 个新增测试文件和本 Handoff。
- 原有项目经理改动：`task_plan.md`、`findings.md`、`progress.md`、`docs/tasks/active/MD-001-stage-1a-minimum-desktop-pet.md`、`docs/tasks/active/MD-002-static-character-integration.md`、`docs/tasks/active/MD-003-hide-show-menu-loop.md`。

## 1. Goal and allowed scope

**Documented agreement:** 在现有 MenuBarExtra 中增加明确的 `Hide Pet`，由 AppDelegate 转发到已有 `PetPanelController.hidePet()`，形成可达的 Hide → Show 单面板恢复闭环。

**Documented agreement:** 本任务不修改持久化、角色素材、尺寸逻辑、点击反馈、拖动、动画、设置、签名、工程配置、依赖或发布行为，也不更新 MD-001、MD-002 或 MD-003 的验收状态。

## 2. Completed work

**Verified fact:** 菜单顺序现在为 `Show Pet`、`Hide Pet`、`Pet Size`、分隔线、`Quit MochiDock`。

**Verified fact:** `MochiDockAppDelegate.hidePet()` 只调用 `panelController.hidePet()`；面板生命周期逻辑仍在 `PetPanelController`。

**Verified fact:** 生产控制器原有的 `hidePet()` 继续使用 `panel?.orderOut(nil)`，没有释放面板、清空引用或创建新实例。

**Verified fact:** 新增回归测试覆盖隐藏后的不可见状态、面板身份保持、隐藏后恢复、尺寸与 mood 保持、重复 Hide/Show 幂等行为，以及 AppDelegate 可调用的隐藏入口。

## 3. Verified project state

**Verified fact:** 开发前 `main` 与 `origin/main` 均位于 `3c0e153`，暂存区为空，Git 状态与任务书列出的项目经理文档现场一致，没有未知改动。

**Verified fact:** 基线完整测试为 22 通过、0 失败、退出码 0。

**Verified fact:** 没有修改 `PetPanelController.swift`、`PetInteractionModel.swift`、`PetView.swift` 或 `PetDisplaySize.swift`；现有单面板、尺寸和互动状态职责保持不变。

**Verified fact:** 没有 Assets.xcassets、PNG、`project.pbxproj`、deployment target、Bundle Identifier、签名或第三方依赖差异。

## 4. Technical choices

- **Verified fact:** 使用两个始终可见的独立系统菜单按钮，而不是含义不清的切换按钮。
- **Verified fact:** AppDelegate 仅增加事件转发，避免为一个菜单入口引入依赖注入或架构重写。
- **Verified fact:** AppDelegate 测试直接编译并调用公开给模块内部使用的 `hidePet()`，不暴露私有面板控制器。
- **Verified fact:** 控制器闭环测试使用真实 `NSPanel`，并用 `defer { controller.panel?.close() }` 清理本任务新增测试创建的窗口。

## 5. Changed files

修改：

- `MochiDock/MochiDock/MochiDockApp.swift`
  - 增加 `Hide Pet` 菜单按钮。
  - 增加 `MochiDockAppDelegate.hidePet()` 转发。
- `MochiDock/MochiDockTests/PetPanelControllerTests.swift`
  - 增加 4 个 Hide/Show 行为与状态保持测试。

新增：

- `MochiDock/MochiDockTests/MochiDockAppDelegateTests.swift`
  - 验证 AppDelegate 提供可调用的 `hidePet()` 入口。
- `docs/handoffs/2026-07-19-MD-003-hide-show-menu-loop.md`

**Verified fact:** 未删除任何文件。

## 6. TDD RED

**Verified fact:** 在生产代码增加隐藏入口前执行：

```bash
xcodebuild test -quiet \
  -project MochiDock/MochiDock.xcodeproj \
  -scheme MochiDock \
  -destination 'platform=macOS' \
  -only-testing:MochiDockTests/MochiDockAppDelegateTests \
  -derivedDataPath /private/tmp/MochiDock-derived-md003-red \
  CODE_SIGNING_ALLOWED=NO
```

结果：退出码 65，`** TEST FAILED **`。准确失败原因为：

```text
value of type 'MochiDockAppDelegate' has no member 'hidePet'
```

**Verified fact:** RED 针对当前真正缺失的 AppDelegate 入口，不是针对原本已经存在的 `PetPanelController.hidePet()`，也不是拼写、沙箱或无关编译错误。

## 7. GREEN and complete tests

**Verified fact:** 添加最小生产入口后，AppDelegate 与控制器目标测试退出码 0。随后执行完整命令：

```bash
xcodebuild test -quiet \
  -project MochiDock/MochiDock.xcodeproj \
  -scheme MochiDock \
  -destination 'platform=macOS' \
  -only-testing:MochiDockTests \
  -derivedDataPath /private/tmp/MochiDock-derived-md003 \
  CODE_SIGNING_ALLOWED=NO
```

结果：27 个测试实例通过、0 失败、退出码 0。相较基线新增 1 个 AppDelegate 入口测试和 4 个面板闭环测试；MD-001 与 MD-002 的既有测试继续通过。

## 8. Clean Debug build

**Verified fact:** 执行：

```bash
xcodebuild clean build -quiet \
  -project MochiDock/MochiDock.xcodeproj \
  -scheme MochiDock \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath /private/tmp/MochiDock-derived-md003 \
  CODE_SIGNING_ALLOWED=NO
```

结果：退出码 0。仅出现 macOS arm64/x86_64 多匹配目标警告，没有编译或链接错误。

## 9. Runtime check

**Verified fact:** 最终 Debug 应用 `/private/tmp/MochiDock-derived-md003/Build/Products/Debug/MochiDock.app` 启动成功，显示单一宠物窗口；辅助功能树报告 `MochiDock pet`、`Resting`。验证结束后通过 Quit 请求正常结束应用。

**Coverage limitation:** 当前桌面自动化无法可靠访问 MenuBarExtra 的弹出内容，因此没有把真实菜单中看到 `Hide Pet`、点击隐藏、菜单栏继续存在和点击恢复写成已人工验证。

## 10. Incomplete work, risks, and blockers

- **User decision needed:** 在真实菜单中确认 `Hide Pet` 文案和顺序清楚。
- **User decision needed:** 点击 Hide 后确认宠物消失但菜单栏图标仍存在，再用 Show 恢复。
- **User decision needed:** 人工确认恢复后的尺寸、mood、拖动、点击与尺寸切换仍正常。
- **User decision needed:** 人工重复 Hide/Show，确认没有多窗口或异常。
- **Verified fact:** 自动测试已覆盖底层单实例和状态保持，但不能替代 MenuBarExtra 的实际点击路径。
- **Verified fact:** 当前无开发阻塞；剩余内容是人工体验验收。

## 11. Preserved project-manager work

**Verified fact:** 开发部门没有编辑、覆盖、撤销、暂存或提交高级项目经理已有的 6 个任务与验收记录文件。它们在开发后仍保持各自原有 working-tree 状态。

**Verified fact:** 本任务唯一新增的项目管理文件是本 Handoff。

## 12. User acceptance still required

**Documented agreement:** MD-001、MD-002 和 MD-003 都没有因本次开发交付被标记为“已完成”。用户或高级项目经理仍需完成任务书中的人工体验项目并独立决定是否验收。

## 13. Takeover procedure

1. 只读查看 `git status --short --branch`、MD-003 任务书和本 Handoff。
2. 区分项目经理原有 6 个文档现场与 MD-003 产品/测试/Handoff 改动。
3. 检查 `MochiDockApp.swift` 的菜单顺序和 `hidePet()` 转发。
4. 检查新增 AppDelegate 测试与 4 个面板闭环测试。
5. 重新运行完整目标测试和干净 Debug 构建。
6. 启动应用并人工完成 MenuBarExtra 的 Hide → Show 闭环、状态保持和重复操作验收。
7. 验收前不要修改 MD-001、MD-002 或 MD-003 状态。

## 14. Git operation confirmation

**Verified fact:** 本轮没有执行 `git add`、`git commit`、`git push`、PR、merge、分支切换、分支创建或 remote 修改。

## 15. Dynamic visibility menu revision

**Documented agreement:** 首轮实现同时显示 `Show Pet` 和 `Hide Pet` 两个固定按钮，没有满足用户后来明确的“任何时刻只有一个宠物显示操作”要求，因此未被用户接受。

**Verified fact:** 收到同一份旧任务书后的第二次报告只重新运行了已有 27 项测试并判断“无需修改”，没有识别并实施动态单菜单修订，也没有补充新的动态行为 RED；该报告不满足修订要求。

**Verified fact:** 最终菜单使用单一动态按钮：

```swift
Button(appDelegate.petVisibilityActionTitle) {
    appDelegate.togglePetVisibility()
}
```

`MochiDockAppDelegate.petVisibilityActionTitle` 根据控制器真实可见性返回 `Hide Pet` 或 `Show Pet`，`togglePetVisibility()` 只转发到控制器。菜单重新打开并重新求值内容时，会再次读取该计算属性。

**Verified fact:** 当前可见性的事实来源是 `PetPanelController.isPetVisible`：

```swift
var isPetVisible: Bool {
    panel?.isVisible == true
}
```

控制器的 `togglePetVisibility()` 在真实面板可见时调用 `hidePet()`，不可见时调用 `showPet()`；仍使用同一个长期持有的 `NSPanel`，不释放实例，不重置尺寸或 mood。

**Verified fact:** 本轮新的首个 TDD RED 命令为：

```bash
xcodebuild test -quiet \
  -project MochiDock/MochiDock.xcodeproj \
  -scheme MochiDock \
  -destination 'platform=macOS' \
  -only-testing:MochiDockTests/MochiDockAppDelegateTests \
  -only-testing:MochiDockTests/PetPanelControllerTests \
  -derivedDataPath /private/tmp/MochiDock-derived-md003-dynamic-red \
  CODE_SIGNING_ALLOWED=NO
```

结果：退出码 65；失败原因是缺少新的 `MochiDockAppDelegate.togglePetVisibility` 和 `petVisibilityActionTitle`，与旧的“缺少 hidePet”RED 无关。

**Verified fact:** 为直接测试 AppDelegate 在真实面板状态下的标题和转发，又执行了第二个小型 TDD 循环。修正测试所需的 AppKit 导入后，RED 退出码 65，唯一失败是缺少接收现有模型和控制器的最小构造入口。加入该入口后，测试直接验证 `Show Pet → Hide Pet → Show Pet → Hide Pet` 标题变化与 toggle 转发，并主动关闭面板。

**Verified fact:** 最终完整测试命令为：

```bash
xcodebuild test -quiet \
  -project MochiDock/MochiDock.xcodeproj \
  -scheme MochiDock \
  -destination 'platform=macOS' \
  -only-testing:MochiDockTests \
  -derivedDataPath /private/tmp/MochiDock-derived-md003-dynamic \
  CODE_SIGNING_ALLOWED=NO
```

结果：30 个测试实例通过、0 失败、退出码 0。

**Verified fact:** 最终干净 Debug 构建命令使用同一 `MochiDock-derived-md003-dynamic` 派生目录，退出码 0；仅有 macOS arm64/x86_64 多匹配目标警告。

**Verified fact:** 固定双按钮静态检查：

```bash
rg -n 'Button\("Show Pet"\)|Button\("Hide Pet"\)' \
  MochiDock/MochiDock/MochiDockApp.swift
```

结果：零匹配，`rg` 退出码 1（未找到模式）。动态接口搜索退出码 0，在 `MochiDockApp.swift`、`PetPanelController.swift`、`MochiDockAppDelegateTests.swift` 和 `PetPanelControllerTests.swift` 中均有匹配。

**User decision needed:** 当前自动化测试证明标题计算和切换行为会随真实面板状态变化，但仍需在实际 MenuBarExtra 中人工确认：启动后显示 `Hide Pet`；隐藏后重新打开菜单显示 `Show Pet`；恢复后重新打开菜单再次显示 `Hide Pet`。

**Verified fact:** 为避免只依赖 MenuBarExtra 可能重新构建内容的推断，最终 AppDelegate 还明确遵循 `ObservableObject`，并在 `showPet()` 与 `togglePetVisibility()` 改变真实面板可见性后发送 `objectWillChange`。该通知只触发 SwiftUI 重新求值；标题仍实时读取 `panelController.isPetVisible`，没有复制或持久化第二份可见状态。此补强也遵循独立 TDD：测试先因 AppDelegate 不符合 `ObservableObject` 而以退出码 65 RED，最小实现后 GREEN。

**Verified fact:** 动态修订期间没有执行 commit、push、PR、merge、reset、restore、分支操作或 remote 修改。

### Startup and MenuBarExtra runtime correction

**Verified fact:** 产品方向复核时，系统中同时运行了三个拥有同一 Bundle Identifier 的 MochiDock Debug 实例：两个来自 Xcode DerivedData，一个来自本轮 `/private/tmp` 构建。不同进程分别持有状态栏项目和宠物面板，会造成肉眼看到的菜单状态与窗口状态互相矛盾。关闭全部旧实例并只启动本轮 Debug 包后，确认 `applicationDidFinishLaunching(_:)`、`MochiDockAppDelegate.showPet()`、`PetPanelController.makePanel()` 和 `orderFrontRegardless()` 均真实执行；辅助功能树包含 `MochiDock pet`，控制器测试也确认 `panel.isVisible == true`。

**Verified fact:** 干净启动后的面板虽然 `isVisible == true`、frame 为有效的 120 × 120、alpha 未被修改、contentView 为 `NSHostingView<PetView>`，但首次全桌面截图中肉眼不可见。原因是面板只设置 `.moveToActiveSpace`；菜单栏应用启动时不会激活自身，面板可能停留在非当前 Space。新的 Space RED 命令使用 `/private/tmp/MochiDock-derived-md003-space-red`，运行 `PetPanelControllerTests` 后退出码 65，唯一失败用例是 `showPetConfiguresTransparentMovablePanel()` 缺少 `.canJoinAllSpaces`。最小修正将 collection behavior 改为 `.canJoinAllSpaces`，仍不创建第二面板，也不改变尺寸、mood、素材、动画或拖动。修正后的真实桌面截图确认宠物在当前 Space 自动出现。

**Verified fact:** Space 修正后，真实宠物已可见，但首次 MenuBarExtra 仍显示 `Show Pet`。这把第二个故障独立定位到 SwiftUI 刷新链路：`MochiDockAppDelegate.objectWillChange.send()` 已执行，但原 `MochiDockApp` 场景没有以观察对象方式订阅 AppDelegate，因此缓存了启动前标题。新的观察链路 RED 命令使用 `/private/tmp/MochiDock-derived-md003-observation-red`，运行 `MochiDockAppDelegateTests` 后退出码 65，准确失败为 `cannot find 'MochiDockMenuContent' in scope`。最小修正新增 `MochiDockMenuContent`，以 `@ObservedObject var appDelegate` 构建原菜单内容；标题仍只读取 `panelController.isPetVisible`，没有引入第二份可见状态。目标测试随后通过。

**Verified fact:** 在单一最新 Debug 应用中通过真实 MenuBarExtra 完成以下闭环：启动后宠物自动出现在当前桌面；首次菜单为 `Hide Pet, Pet Size, separator, Quit MochiDock`；点击 `Hide Pet` 后宠物隐藏，再开菜单为 `Show Pet`；点击 `Show Pet` 后宠物恢复，再开菜单重新为 `Hide Pet`。因此本轮不再把 MenuBarExtra 标题刷新列为未验证项。

**Verified fact:** 最终完整测试共 31 个测试实例通过、0 失败、退出码 0。最终干净 Debug 构建退出码 0，仅有 macOS arm64/x86_64 多匹配目标警告。固定双按钮搜索仍为零匹配（`rg` 退出码 1）；动态接口、`MochiDockMenuContent` 和 `.canJoinAllSpaces` 搜索在产品代码及测试中均有匹配（退出码 0）；`git diff --check` 退出码 0。

**Verified fact:** 此次启动与真实菜单修正仍未执行 commit、push、PR、merge、reset、restore、分支创建或分支切换；除本 Handoff 外，没有修改项目经理文档现场，也没有把 MD-003 标记为已完成。

## 16. Post-delivery commit record

**Verified fact:** 用户授权本地提交后，MD-003 产品代码与测试已提交为 `98a746e fix: complete pet visibility toggle`。该提交只包含 `MochiDockApp.swift`、`PetPanelController.swift`、`MochiDockAppDelegateTests.swift` 和 `PetPanelControllerTests.swift`。

**Verified fact:** 提交前，高级项目经理使用新的独立派生目录复跑完整测试，31 个测试通过、0 失败、退出码 0；另以独立派生目录执行干净 Debug 构建，退出码 0；`git diff --check` 通过。

**Verified fact:** 项目管理文档与本 Handoff 作为第二批独立提交处理。此次授权不包含 push、PR、merge 或将 MD-003 标记为“已完成”；用户仍保留最终人工验收决定权。
