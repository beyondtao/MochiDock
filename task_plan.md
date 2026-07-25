# MochiDock 项目总览

> 本文档只维护项目方向、当前范围和任务索引。具体开发内容放在 `docs/tasks/` 的独立任务书中。

## 产品目标

MochiDock 首先是一款自然、有趣、低打扰的 macOS 桌面宠物；后续从真实使用体验中逐步探索工具能力，并保留接入 AI 的可能性。

项目采用“小步验证、实际体验、持续调整”的方式推进，不要求探索期先完成完整 PRD。

## 职责与决策权

- 用户是项目经理、产品负责人和最终决策者，决定是否安排开发任务。
- 高级项目经理 Agent 负责阶段规划、范围与优先级、验收标准、风险、项目记录及开发任务书，不直接编写产品代码。
- Codex 开发部门负责产品代码实现、技术自测和开发结果说明。
- 高级项目经理 Agent 可只读检查代码、测试和 Git 状态，用于验收与项目判断。
- 产品方向、核心功能类别、隐私、持续付费服务、重要依赖、数据保存、发布和大规模重写必须由用户确认。

## 产品路线

| 阶段 | 目标 | 状态 |
|---|---|---|
| 阶段 0 | 建立 Xcode、Git 和项目记忆基础 | 已完成 |
| 阶段 1 | 验证最小可体验桌面宠物 | 已完成 |
| 阶段 2 | 根据体验完善互动与基础设置 | 已完成 |
| 阶段 3 | 从真实需求选择一个小型工具场景 | 开发中 |
| 阶段 4 | 在明确隐私、成本和降级方案后探索一个 AI 场景 | 未开始 |

## 当前范围

### 当前正在做

- MD-010、MD-011 与 MD-012 已由用户验收并归档；阶段 2 完成。
- MD-013“屏幕边缘躲藏与偷看”已通过最终人工验收并归档。
- MD-014“宠物循环间隔提醒”已关闭首轮三个 Important、一个 Minor 及第二轮 Hide/Show 陈旧 blocker；完整自动验证通过，当前等待用户人工验收。

### 下一步可能做

- 由用户完成 MD-014 的真实计时、桌面边缘、多尺寸、重启、睡眠唤醒及半天低打扰体验验收。
- 根据 MD-013 的实际使用体验，仍可由用户决定是否安排“情境化休息/睡眠小实验”，但目前不作为优先开发承诺。
- 若后续真实使用出现明确摩擦，先复核并形成小范围修订任务。
- 详细提案见 [阶段 2 开发计划](docs/stage-2-development-plan.md)。

### 想法池，暂不承诺

- 屏幕顶部/底部躲藏、从屏幕中央自主走到边缘、随机巡游和多屏穿越。
- 固定时间提醒、一次性提醒、日历或系统提醒事项同步、提醒统计与成长奖励。
- AI、聊天、知识库和复杂智能体。

## 任务索引

| 编号 | 任务 | 状态 | 任务书 |
|---|---|---|---|
| MD-001 | 阶段 1A：最小桌面宠物 | 已完成 | [打开任务书](docs/tasks/completed/MD-001-stage-1a-minimum-desktop-pet.md) |
| MD-002 | 正式角色静态接入与桌面尺寸验证 | 已完成 | [打开任务书](docs/tasks/completed/MD-002-static-character-integration.md) |
| MD-003 | 隐藏与恢复菜单闭环 | 已完成 | [打开任务书](docs/tasks/completed/MD-003-hide-show-menu-loop.md) |
| MD-004 | 动画播放与状态基础 | 已完成 | [打开任务书](docs/tasks/completed/MD-004-animation-playback-foundation.md) |
| MD-005 | 趴姿待机与点击回应接入 | 已完成 | [打开任务书](docs/tasks/completed/MD-005-prone-idle-and-click-response.md) |
| MD-006 | 本地偏好持久化基础 | 已完成 | [打开任务书](docs/tasks/completed/MD-006-local-persistence-foundation.md) |
| MD-007 | 英文与简体中文本地化基础 | 已完成 | [打开任务书](docs/tasks/completed/MD-007-localization-foundation.md) |
| MD-008 | 有限鼠标接近回应 | 已完成 | [打开任务书](docs/tasks/completed/MD-008-limited-pointer-proximity-response.md) |
| MD-009 | 宠物位置保存与安全恢复 | 已完成 | [打开任务书](docs/tasks/completed/MD-009-pet-position-persistence-and-safe-restoration.md) |
| MD-010 | 低打扰控制与登录时启动 | 已完成 | [打开任务书](docs/tasks/completed/MD-010-low-interruption-and-login-start.md) |
| MD-011 | 独立设置窗口 | 已完成 | [打开任务书](docs/tasks/completed/MD-011-settings-window.md) |
| MD-012 | 阶段 2 稳定试用与体验收口 | 已完成 | [打开任务书](docs/tasks/completed/MD-012-stage-2-stability-trial-and-closure.md) |
| MD-013 | 屏幕边缘躲藏与偷看 | 已完成 | [打开任务书](docs/tasks/completed/MD-013-edge-hide-and-peek.md) |
| MD-014 | 宠物循环间隔提醒 | 待验收 | [打开任务书](docs/tasks/active/MD-014-pet-interval-reminder.md) |

任务状态统一使用：`草拟中`、`待用户安排`、`开发中`、`待验收`、`已完成`、`已取消`、`已阻塞`。

## 项目级工程约束

- 入口文件只负责启动、装配和依赖连接。
- 文件达到约 400 行时检查职责；500–600 行进入警戒范围；超过 600 行优先按职责评估拆分。
- 超过 1000 行属于例外，必须说明原因并获得用户确认。
- 不创建万能 `Utils`，不为缩短行数进行机械拆分。
- 新增重要依赖、数据保存方式或大规模重写前必须获得用户确认。

## 项目记忆索引

- [已确认结论与发现](findings.md)
- [阶段进度记录](progress.md)
- [小熊猫角色母版 v0.2](docs/design/character/character_master_v0.2.md)
- [角色设计计划](docs/design/character/task_plan.md)
- [角色设计决定](docs/design/character/findings.md)
- [角色设计进展](docs/design/character/progress.md)
- [任务文档规则](docs/tasks/README.md)
- [AI 开发连续性总结](sources/ai-development-mode-summary.md)
- [MochiDock PM Skill 蓝图](skill-blueprints/mochidock-pm.md)
- [阶段 2 开发计划（提案）](docs/stage-2-development-plan.md)

## 错误与恢复记录

| 问题 | 处理方式 |
|---|---|
| MD-014 第二轮完整 scheme 运行中空 UI 测试 Runner 在连接前被系统终止（退出码 65） | 结果包确认全部 203 个有效 `MochiDockTests` 已通过；按项目既有正式口径使用 `-only-testing:MochiDockTests` 新鲜重跑，203/203 通过、参数化展开 291 次、退出码 0。该空 UI Runner 事件不计为产品测试失败。 |
| MD-014 定向修订的结果汇总命令因 `TestReport` 临时目录写权限失败（退出码 64） | 不把附加汇总视为测试失败；使用 `xcresulttool get object --legacy` 只读结果包，确认状态 `succeeded` 且参数化展开 287 次 |
| MD-014 独立素材专项在受限沙箱中遇到 Swift 宏服务 malformed response，未进入测试 | 按既有规则在获批的沙箱外环境用同一无签名命令重跑，`PetDisplaySizeTests` 全部通过、退出码 0 |
| MD-014 首次领域 RED 测试文件误落到 Xcode 工程外层，`only-testing` 未匹配任何测试却返回成功 | 该次不计为 RED；使用补丁把测试移入真实 `MochiDock/MochiDockTests` target 后重跑，要求看到缺少目标类型的编译失败 |
| MD-014 几何 GREEN 首跑的屏幕变化断言同时要求气泡居中和不越过新屏幕左边界，两者在给定矩形下矛盾 | 保留产品的可见区夹取规则，将断言修正为 `minX == visibleFrame.minX` 后重跑；`xcresulttool` 额外摘要因 TestReport 权限失败，不作为正式证据 |
| MD-014 窗口装配 GREEN 首编译在默认参数中创建 `@MainActor` 调度器而失败 | 沿用项目既有修复模式：改为主线程隔离方法内创建调度器的无参数重载，显式调度器重载继续服务测试注入 |
| MD-014 首次全量回归在可选上下文的无标签 tuple fallback 上编译失败 | 移除会丢失 tuple 标签的 `?? (false, false)`，对可选命名字段分别提供默认值后重跑全量测试 |
| `G_MochiDock` 隐藏项目目录中曾生成的规划文件未保留在当前磁盘视图 | 从对应历史任务的已确认讨论中恢复规划，并写入当前本地仓库 |
| MD-004 首次源码盘点按仓库根目录猜测测试与 Assets 路径，因 Xcode 工程实际位于 `MochiDock/` 子目录而失败 | 使用 `rg --files MochiDock` 确认真实路径，后续改用 `MochiDock/MochiDock` 与 `MochiDock/MochiDockTests` |
| MD-004 首次 GREEN 构建中，默认参数表达式在非隔离上下文创建 `@MainActor` 调度器而编译失败 | 移除调度器默认参数；以无参数初始化器在模型主线程上下文组装生产调度器，显式初始化器继续服务测试注入 |
| MD-004 第二次 GREEN 构建中测试辅助器无法解析 `TimeInterval`，并保留 timing 默认参数隔离警告 | 测试显式导入 `Foundation`；将 timing 默认值移入主线程隔离的重载初始化器 |
| MD-004 第三次 GREEN 构建中测试直接比较 `UnitPoint.bottom` 但未导入定义模块 | 测试显式导入 `SwiftUI`；产品模块已在该次构建中通过编译 |
| MD-004 资源像素测试读取资产目录 `NSImage.representations.first`，三档均失败；结果附件提取又因工具写入权限被沙箱拒绝 | 改为请求实际运行时 `CGImage` 并验证宽、高和 Alpha 信息，避免依赖资产代理 representation；源 PNG 已另由 `sips` 验证 |
| MD-004 大尺寸复验时 `xcresulttool` 汇总尝试因 TestReport 写入权限失败 | 不依赖该附加汇总；以完整 `xcodebuild test` 的退出码 0、`TEST SUCCEEDED` 和逐项通过输出作为正式验证证据 |
| MD-004 收口复核首次新鲜测试因当前终端缺少开发签名证书而在构建阶段取消 | 该次没有进入测试，不作为产品失败；改用 `CODE_SIGNING_ALLOWED=NO` 的本地无签名验证重新执行完整测试和干净 Debug 构建 |
| MD-004 收口复核无签名整套 scheme 测试加载空 `MochiDockUITests` bundle 时找不到可执行文件 | `MochiDockTests` 在该次输出中逐项通过，但整体退出码 65，不视为完整成功；按项目既有正式口径指定 `-only-testing:MochiDockTests` 重跑全部有效单元测试，并另跑干净 Debug 构建 |
| MD-005 首次 RED 在受限沙箱中被 Swift 宏插件服务的 malformed response 阻断 | 该次未编译到新增测试，不作为功能 RED；在非沙箱环境用同一无签名命令重跑，取得缺少新视觉映射与状态接口的预期失败证据 |
| MD-005 第二轮 GREEN 初版尝试调用 `disableScreenUpdatesUntilFlush()` | 编译器确认该 API 自 macOS 15 起已弃用且无作用；立即移除，改为 `setFrame(display: false)`、禁用 SwiftUI/AppKit 动画、完成布局后单次 `displayIfNeeded()` 提交最终缓冲区 |
| MD-005 快速尺寸面板测试的窗口动画断言失败 | `NSWindow.animationBehavior` 是可选属性，裸 `.none` 被解析为 `Optional.none` 而非动画枚举的 none；从 xcresult 确认实际值后改为显式 `NSWindow.AnimationBehavior.none`，撤销未经证实的套件串行化假设 |
