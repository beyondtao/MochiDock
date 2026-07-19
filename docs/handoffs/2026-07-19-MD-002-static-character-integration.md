# MochiDock Handoff：MD-002 正式角色静态接入与桌面尺寸验证

## Metadata

- 日期：2026-07-19
- 来源任务：`MD-002 正式角色静态接入与桌面尺寸验证`
- 仓库绝对路径：`/Users/tao/Projects/Working/MochiDock`
- 当前分支：`main`
- 当前 worktree 情况：主工作区，dirty；`origin/main` 已不存在。
- 当前 HEAD commit：`1c92bd7ad2941e8614263d2a62e5573b3e58d184`（`docs: add project planning and MD-001 delivery records`）
- 完成开发后的 `git status --short --branch` 摘要：5 个已跟踪产品/测试文件被 MD-002 修改；2 个 MD-002 Swift 文件、3 个 image set 和本 Handoff 未跟踪；根 `task_plan.md`、`findings.md`、`progress.md` 以及 `asset/`、`docs/design/` 是开发前已经存在的 dirty 内容。
- 工作区在开发前已经存在的改动：`findings.md`、`progress.md`、`task_plan.md` 已修改；`asset/` 与 `docs/design/` 未跟踪。
- 本次 MD-002 新增或修改的内容：正式角色三档运行时资源、`PetDisplaySize`、尺寸状态和菜单连接、静态角色视图、面板居中缩放、尺寸/资源/面板测试，以及本 Handoff。
- 是否创建 Git commit：否。

## 1. Goal and allowed scope

**Documented agreement:** 用用户确认的小熊猫 v0.3 三张透明静态预览替换 SwiftUI 临时占位形象，并提供不持久化的 80、120、160 point 体验切换，同时保持 MD-001 的单面板、透明无边框、拖动、点击状态、恢复和退出闭环。

**Documented agreement:** 本任务不包含动画帧、新表情、自动移动、位置或尺寸持久化、设置页、Retina 多倍率体系、角色重生成、绿边修复、AI、网络、第三方依赖、签名或发布变更，也不替用户验收 MD-001/MD-002。

## 2. Completed work

**Verified fact:** `PetView` 已删除圆角矩形、眼睛与 `PetMouth` 占位绘图，改为按当前尺寸加载透明 PNG；使用 `resizable` + `scaledToFit`，没有新增底色、阴影、边框或裁切逻辑。

**Verified fact:** 默认尺寸是 Medium 120；菜单栏使用系统 `Picker` 提供 `Small — 80`、`Medium — 120`、`Large — 160` 和系统选中标记。状态仅在内存中，重启会重新建立默认 120。

**Verified fact:** 点击仍在 `Resting` / `Happy` 间往返。Happy 仅使用 1.03 倍缩放、向上 2 point、亮度 +0.025 和 0.16 秒 ease-out，不伪造第二张表情图，也没有循环动画。

**Verified fact:** 辅助功能 label 仍为 `MochiDock pet`，value 仍按模型报告 `Resting` 或 `Happy`。

**Verified fact:** 切换尺寸时控制器修改同一 `NSPanel` 的 frame，保存 frame 中心并用新边长重算原点；不创建新面板，不重置 mood，重复选择同档直接返回。

## 3. Verified project state

**Verified fact:** 开始实施时当前产品源码为 MD-001 单面板实现，既有 6 个测试；HEAD 和工作区状态与 MD-001 Handoff 基本一致，没有发现要求暂停的重大冲突。

**Verified fact:** `MochiDock/MochiDock.xcodeproj/project.pbxproj` 无差异。项目继续使用文件系统同步分组，因此新增 Swift 文件和 asset catalog 内容无需手改工程文件。

**Verified fact:** deployment target 仍为 macOS 26.4；应用 Bundle Identifier 仍为 `com.taotao.MochiDock`；签名设置仍为 Automatic；没有第三方依赖。

**Verified fact:** 开发前的根项目记录、`asset/` 与 `docs/design/` dirty 内容未被本任务覆盖、撤销、暂存或提交。

## 4. Confirmed product and business rules

- **Documented agreement:** 用户是产品经理、产品负责人和最终验收者。
- **Documented agreement:** 80/120/160 是本轮桌面体验评估的 point 档位，不是最终 Retina 1x/2x/3x 密度设计。
- **Documented agreement:** 三个 PNG 是独立评估素材，不能放进同一 image set 的倍率槽位。
- **Documented agreement:** 绿色细毛边是已知观察项，本任务只记录，不重新生成或复杂抠图。
- **Documented agreement:** 人工体验验收完成前，不把 MD-001 或 MD-002 标记为已完成。

## 5. Technical decisions

- **Verified fact:** `PetDisplaySize: CaseIterable, Identifiable` 集中定义资源名、point 边长和菜单标题，避免尺寸逻辑散落在入口、视图和控制器。
- **Verified fact:** `PetInteractionModel` 持有 `displaySize`，使尺寸选择与 mood 同属可观察的临时展示状态；尺寸选择不会修改 mood。
- **Verified fact:** `PetPanelController.selectDisplaySize(_:)` 只管理 AppKit frame 和单实例面板，入口只转发菜单事件。
- **Verified fact:** 每个 image set 只填写 universal 1x 槽位，分别保存其源像素文件；这是体验评估资源组织，不代表正式 Retina 方案。

## 6. Changed files and interfaces

创建：

- `MochiDock/MochiDock/PetDisplaySize.swift`
  - 新增 `PetDisplaySize.small/.medium/.large`
  - 新增 `resourceName`、`pointLength`、`menuTitle`
- `MochiDock/MochiDockTests/PetDisplaySizeTests.swift`
- `MochiDock/MochiDock/Assets.xcassets/RedPandaMaster80.imageset/Contents.json`
- `MochiDock/MochiDock/Assets.xcassets/RedPandaMaster80.imageset/RedPandaMaster80.png`
- `MochiDock/MochiDock/Assets.xcassets/RedPandaMaster120.imageset/Contents.json`
- `MochiDock/MochiDock/Assets.xcassets/RedPandaMaster120.imageset/RedPandaMaster120.png`
- `MochiDock/MochiDock/Assets.xcassets/RedPandaMaster160.imageset/Contents.json`
- `MochiDock/MochiDock/Assets.xcassets/RedPandaMaster160.imageset/RedPandaMaster160.png`
- `docs/handoffs/2026-07-19-MD-002-static-character-integration.md`

修改：

- `MochiDock/MochiDock/MochiDockApp.swift`
  - 新增 `Pet Size` Picker、`displaySize` 读取和 `selectDisplaySize(_:)` 事件转发。
- `MochiDock/MochiDock/PetInteractionModel.swift`
  - 新增 `private(set) var displaySize = .medium` 和 `selectDisplaySize(_:)`。
- `MochiDock/MochiDock/PetPanelController.swift`
  - 默认面板边长改由模型尺寸提供；新增 `selectDisplaySize(_:)`，保持中心并复用面板。
- `MochiDock/MochiDock/PetView.swift`
  - 正式图片替换临时绘图，保留手势和辅助功能，增加克制的 mood 动效。
- `MochiDock/MochiDockTests/PetPanelControllerTests.swift`
  - 新增三档 frame、中心保持、面板身份和重复选择测试。

复制来源（未修改或移动）：

- `asset/character/red-panda/previews/v0.3/mochidock-red-panda-master-v0.3-80px.png`
- `asset/character/red-panda/previews/v0.3/mochidock-red-panda-master-v0.3-120px.png`
- `asset/character/red-panda/previews/v0.3/mochidock-red-panda-master-v0.3-160px.png`

删除：无。

## 7. Verification

### TDD RED

**Verified fact:** 在实现 `PetDisplaySize` 和相关接口前先新增尺寸与面板测试，然后执行：

```bash
xcodebuild test -quiet \
  -project MochiDock/MochiDock.xcodeproj \
  -scheme MochiDock \
  -destination 'platform=macOS' \
  -only-testing:MochiDockTests/PetDisplaySizeTests \
  -only-testing:MochiDockTests/PetPanelControllerTests \
  -derivedDataPath /private/tmp/MochiDock-derived-md002-red \
  CODE_SIGNING_ALLOWED=NO
```

结果：`** TEST FAILED **`，xcodebuild 非零退出（标准构建失败码 65）；编译器明确报告多处 `cannot find 'PetDisplaySize' in scope` / `cannot find type 'PetDisplaySize' in scope`。失败原因正是被测功能尚未实现，不是测试拼写或环境错误。

### 最终目标测试

**Verified fact:** 最后一次实际执行：

```bash
xcodebuild test -quiet \
  -project MochiDock/MochiDock.xcodeproj \
  -scheme MochiDock \
  -destination 'platform=macOS' \
  -only-testing:MochiDockTests \
  -derivedDataPath /private/tmp/MochiDock-derived-md002 \
  CODE_SIGNING_ALLOWED=NO
```

结果：退出码 0；22 个测试实例通过，0 失败。范围包括原 3 个 mood 测试、原面板配置/显示复用/关闭恢复测试，以及默认 120、三档映射、三档状态选择、mood 保持、Bundle 资源加载、三档面板尺寸、中心保持、面板身份和重复选择。

说明：首次在受限沙箱内跑基线测试时，Swift 宏插件被 `sandbox-exec` 阻止而失败；在沙箱外重跑相同基线命令退出码 0。这是执行环境限制，不是代码 RED。

### 干净 Debug 构建

**Verified fact:** 最后一次实际执行：

```bash
xcodebuild clean build -quiet \
  -project MochiDock/MochiDock.xcodeproj \
  -scheme MochiDock \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath /private/tmp/MochiDock-derived-md002 \
  CODE_SIGNING_ALLOWED=NO
```

结果：退出码 0。输出只有 macOS arm64/x86_64 destination 二选一警告，没有编译或链接错误。

### PNG 与构建资源

**Verified fact:** `file` 与 `sips -g pixelWidth -g pixelHeight -g hasAlpha` 在接入前确认三张源图依次为 80×80、120×120、160×160，均为 8-bit RGBA 且 `hasAlpha: yes`。

**Verified fact:** 接入后源图与 Assets.xcassets 副本的 SHA-256 成对完全一致：80 为 `8cea8237…85268`，120 为 `cb55c613…12bbe`，160 为 `b8201246…76ed`。

**Verified fact:** 单元测试中的 `NSImage(named:)` 对三档资源均加载成功。`xcrun assetutil --info .../Assets.car` 显示三个独立 rendition：`RedPandaMaster80` 80×80、`RedPandaMaster120` 120×120、`RedPandaMaster160` 160×160，scale 均为 1；没有 chroma 资源。

**Verified fact:** SwiftUI 使用 `scaledToFit`，代码上不裁切、不拉伸；窗口和视图没有新增不透明底色。

### 运行检查

**Verified fact:** 使用最终 Debug 产物 `/private/tmp/MochiDock-derived-md002/Build/Products/Debug/MochiDock.app` 启动成功；观察到单一正式小熊猫窗口。辅助功能树报告 `MochiDock pet`、`Resting`，与默认模型状态一致。验证结束后已请求退出应用。

**Verified fact:** `git diff --check` 最终退出码 0。

**Coverage limitation:** 自动测试和代码检查证明窗口属性、状态、资源映射和复用关系，但不能替代真实拖动、点击手势与背景拖动组合、菜单栏实际点选、三档长期遮挡感、透明毛边观感或连续运行稳定性。

## 8. Incomplete work, risks, and blockers

- **User decision needed:** 人工比较 80/120/160 在真实桌面中的辨识度、占用和遮挡感。
- **User decision needed:** 人工判断透明边缘及已知轻微绿色毛边是否可接受。
- **User decision needed:** 人工验证菜单三档逐项切换及系统选中标记、点击两次的肉眼反馈、实际拖动、`Show Pet`、`Quit MochiDock` 和长时间稳定性。
- **Verified fact:** 当前桌面自动化能启动并读取默认可访问性状态，但一次辅助功能点击未触发状态变化，且未可靠访问 MenuBarExtra；因此这些项目没有被写成通过。
- **Known risk:** Happy 的 1.03 倍缩放可能在素材透明留白不足时接近面板边界；当前 PNG 有透明留白，仍应由人工观察是否出现视觉裁边。
- **Known risk:** 1x image set 与 point 尺寸直接映射只服务本轮体验评估，不是正式 Retina 密度体系。
- **Known risk:** 缩放素材可能保留轻微绿色细毛边，本任务没有处理。
- **Verified fact:** 没有发现当前实现与 MD-002 Prompt 的功能性偏差；人工体验验收尚未完成。
- **Verified fact:** 当前无开发阻塞。
- **Verified fact:** 除本 Handoff 外未修改项目管理文档；未修改 `project.pbxproj`、deployment target、Bundle Identifier、签名设置或第三方依赖。

## 9. Decisions still required from the user

- **User decision needed:** 三档中哪一档更适合作为后续默认体验方向；本任务仍按要求默认 120。
- **User decision needed:** 当前绿色细毛边在真实桌面是否可接受，或是否应在未来单独安排素材优化任务。
- **User decision needed:** 完成人工验收后，由用户/高级项目经理决定 MD-002 状态；本 Handoff 不代表验收通过。

## 10. Takeover procedure

1. 先读取项目规则、MD-001 任务书、MD-001 Handoff、MD-002 Prompt 和本 Handoff。
2. 执行 `git status --short --branch`，确认 HEAD 与 dirty worktree。
3. 区分开发前已有的 `task_plan.md`、`findings.md`、`progress.md`、`asset/`、`docs/design/` 与本次 MD-002 改动。
4. 检查三个 image set、`PetDisplaySize.swift`、`PetInteractionModel.swift`、`PetView.swift`、`PetPanelController.swift`、菜单连接和测试。
5. 重新运行本 Handoff 中的目标测试与干净 Debug 构建。
6. 启动 Debug 应用，人工完成三档尺寸、选中标记、点击、拖动、Show Pet、Quit、透明边缘、绿边、遮挡感和稳定性验收。
7. 在验收前不得把 MD-001 或 MD-002 标记为“已完成”。
8. 只有项目经理验收后，才更新 `task_plan.md`、`progress.md`、`findings.md` 和任务状态；是否提交 Git 由用户决定。

## 11. Post-delivery commit record

- **Verified fact:** 第一批本地提交为 `3d511c90245951ace8b853a878b8a5d19f8d5d45 assets: add red panda character master`。
- **Verified fact:** 第二批本地提交为 `907ca176e4c7ccc3ee6b85856da86f5c9441d49e feat: integrate red panda display sizes`。
- **Verified fact:** 第二批提交后重新执行：

```bash
xcodebuild test -quiet \
  -project MochiDock/MochiDock.xcodeproj \
  -scheme MochiDock \
  -destination 'platform=macOS' \
  -only-testing:MochiDockTests \
  -derivedDataPath /private/tmp/MochiDock-derived-md002-postcommit \
  CODE_SIGNING_ALLOWED=NO
```

结果：22 个测试实例通过、0 失败、退出码 0。

- **Verified fact:** 第二批提交后重新执行：

```bash
xcodebuild clean build -quiet \
  -project MochiDock/MochiDock.xcodeproj \
  -scheme MochiDock \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath /private/tmp/MochiDock-derived-md002-postcommit \
  CODE_SIGNING_ALLOWED=NO
```

结果：退出码 0。

- **Verified fact:** 本轮没有 push、PR、merge、分支切换或 remote 修改。
- **Verified fact:** 第三批项目记录提交将在本 Handoff 与项目记录暂存后创建，因此该提交的 hash 以最终 `git log` 为准。
- **Documented agreement:** MD-001 和 MD-002 仍为“待验收”；本地提交不代表人工验收通过。
