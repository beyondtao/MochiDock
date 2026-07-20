# MochiDock Handoff：MD-008 有限鼠标接近回应

## Metadata

- 日期：2026-07-20
- 来源任务：`MD-008 有限鼠标接近回应`
- 仓库路径：`/Users/tao/Projects/Working/MochiDock`
- 分支：`main`
- HEAD commit：`948b20b`
- 开发前状态：工作区已有项目经理完成的 MD-001/002/003/005 归档移动、MD-008 项目记录、正式素材、素材脚本和 workbench 内容；本轮全部保留，没有回退、覆盖、暂存或提交。

## 1. 已实现范围与实际交互序列

- 指针检测只在宠物可见时运行，使用 `NSEvent.mouseLocation` 定时读取当前位置；没有安装全局或本地事件监视器，没有申请辅助功能、录屏或输入监控权限。
- 检测器只判断二元的外部/进入/滞回离开状态，不保存轨迹，不判断方向。
- 有效外→内转换触发一次 `attention-tail → attention-base → idle`：尾巴强调帧 0.22 秒，注意基础帧 0.55 秒，随后恢复原待机调度。
- 指针停留时不会重复播放；必须先越过更大的离开区域，并且 4 秒冷却已结束，才能再次触发。
- Show 时若指针已经在区域内，检测器保持未武装状态；只有真实离开离开区域后再次进入才触发。

## 2. 参数

| 参数 | 数值 | 五档实际值 |
|---|---:|---|
| 采样间隔 | 0.15 秒 | 约 6.67 Hz |
| 进入外扩 | 面板边长 × 0.30 | 24 / 36 / 48 / 72 / 96 pt |
| 离开外扩 | 面板边长 × 0.45 | 36 / 54 / 72 / 108 / 144 pt |
| 尾巴强调帧 | 0.22 秒 | 全尺寸一致 |
| 注意基础帧 | 0.55 秒 | 全尺寸一致 |
| 冷却 | 4.0 秒 | 从成功触发时计时 |
| 程序化抬起 | 面板边长 × 0.01 | 向上偏移；尾巴/基础纵向缩放 1.01 / 1.005 |

所有数值集中在 `PointerProximityTiming.standard` 与 `PetAnimationTiming.standard`。

## 3. 最终优先级行为

- 点击 > 接近 > 呼吸/眨眼。
- 点击可取消正在播放的接近序列并立即进入既有开心弹起；点击回应期间的接近请求返回拒绝，不改变开心视觉或调度。
- 接近可取消尚未开始或正在进行的呼吸/眨眼；接近结束后回到原有单一待机循环。
- `PetPanel` 只通过自身 `sendEvent` 上报左键按下/抬起，不使用事件监听器。按下期间检测器暂停；抬起时按当前位置重建内外状态，因此不会在拖动松手后立即误触发。
- Hide 先停止并取消接近采样，再取消当前动画并恢复 idle；Show 复用同一面板和模型，重新启动待机与接近检测。
- 尺寸切换继续复用同一面板、模型和 hosting view；注意帧资源切换继续使用现有禁用隐式动画策略。

## 4. 修改和新增文件

产品代码：

- `MochiDock/MochiDock/PointerProximityDetector.swift`：集中参数、缩放阈值、滞回、冷却、可见生命周期、拖动抑制及可注入采样职责。
- `MochiDock/MochiDock/PetAnimation.swift`：增加注意视觉/动画状态和两段时长。
- `MochiDock/MochiDock/PetInteractionModel.swift`：在现有单一可取消动画任务中实现注意序列与点击抢占。
- `MochiDock/MochiDock/PetDisplaySize.swift`：映射五档 AttentionBase/AttentionTail 资源。
- `MochiDock/MochiDock/PetRenderPolicy.swift`：为轻微注意几何变化提供时长，同时保留离散切图禁动画边界。
- `MochiDock/MochiDock/PetPanelController.swift`：负责检测器装配、Show/Hide 生命周期和面板自身鼠标按下/抬起桥接。

测试和记录：

- `MochiDock/MochiDockTests/PointerProximityDetectorTests.swift`：覆盖阈值缩放、初始内区、首次进入、停留、离开、冷却、拖动与单一采样任务。
- `MochiDock/MochiDockTests/PetAnimationTests.swift`：覆盖注意序列、自动动作替换、点击抢占和点击期间拒绝接近。
- `MochiDock/MochiDockTests/PetDisplaySizeTests.swift`：覆盖两种注意状态的五档资源名和可加载像素/Alpha 契约。
- `MochiDock/MochiDockTests/PetPanelControllerTests.swift`：覆盖检测器 Show/Hide 生命周期、面板复用和鼠标接触抑制桥接。
- `asset/tests/test_md008_frame_stability.py`：把 JSON 点数组显式转换为 Pillow 9.4 可接受的坐标元组；没有修改蒙版或图片数据。
- `docs/superpowers/plans/2026-07-20-md-008-limited-pointer-proximity-response.md`：本轮测试先行实施计划。
- `docs/handoffs/2026-07-20-MD-008-limited-pointer-proximity-response.md`：本交付记录。

## 5. TDD RED 与 GREEN

- 第一轮 RED：目标测试退出码 65；在修正测试夹具自身的 actor 默认参数错误后，稳定失败为缺少 `PointerProximityDetector`、`PointerProximityTiming`、注意视觉状态、资源映射和 `handleProximityEntry()`。
- 第一轮 GREEN：检测器、动画与资源目标测试退出码 0。
- 第二轮 RED：面板目标测试退出码 65，稳定失败为缺少 `PointerProximityDetecting` 生命周期接口和面板鼠标接触桥接。
- 第二轮 GREEN：串行面板目标测试退出码 0。
- AppKit 测试并行启动曾两次在测试断言前由 LaunchServices 返回 `No such process`；同一构建使用 `-parallel-testing-enabled NO` 后稳定通过，确认是测试宿主并行启动竞争，不是产品断言或编译失败。

## 6. 规定验证结果

### 素材稳定测试

```bash
python3 -m unittest \
  asset.tests.test_md005_frame_stability \
  asset.tests.test_md008_frame_stability
```

结果：11 项通过，0 失败，退出码 0。首次运行有 3 项因 Pillow 9.4 不接受 JSON 的列表坐标而报错；测试辅助器显式转换为元组后，同一 11 项全部通过。正式素材、蒙版和生成结果未修改。

### 全部有效应用测试

```bash
xcodebuild test -quiet \
  -project MochiDock/MochiDock.xcodeproj \
  -scheme MochiDock \
  -destination 'platform=macOS' \
  -derivedDataPath .derivedData-md008-final \
  CODE_SIGNING_ALLOWED=NO \
  -parallel-testing-enabled NO \
  -only-testing:MochiDockTests
```

结果：退出码 0。测试日志只有 macOS arm64/x86_64 多匹配目标警告。`xcresulttool` 附加汇总仍因本机 `TestReport` 写权限失败，未作为正式证据；完整 `xcodebuild test` 的退出码 0 是正式结果。

### 无签名干净 Debug 构建

```bash
xcodebuild clean build -quiet \
  -project MochiDock/MochiDock.xcodeproj \
  -scheme MochiDock \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath .derivedData-md008-build \
  CODE_SIGNING_ALLOWED=NO
```

结果：退出码 0；只有多匹配目标警告。

### 静态检查和职责规模

- `git diff --check`：退出码 0。
- 产品 Swift 文件最大 264 行；新增检测器 153 行；测试文件最大 352 行，均未进入 500–600 行警戒范围。
- 未修改偏好键、本地化键、签名、Bundle Identifier、deployment target 或 `project.pbxproj`；未增加依赖、网络、AI、权限或持久化。

## 7. 本地可观察冒烟

- 启动本轮干净 Debug 应用成功。
- 本机可访问性树显示一个 MochiDock 窗口、一个描述为“MochiDock 宠物”的元素，状态为“休息中”；屏幕图像显示 120 pt 小熊猫面板。
- 未出现系统权限提示；检查后只终止了该构建路径对应的测试实例。

## 8. 尚需人工验收

- 在 120、240、320 三个代表尺寸观察头部注意和尾巴一次抬起是否清楚、自然且低打扰。
- 实际测试进入边缘、滞回带、快速反复进出及 4 秒冷却的体感频率。
- 实际拖动中确认不触发，松手后不立即误触发；实际点击接近序列时确认开心动作立即抢占。
- 实际 Hide/Show 时确认已在区域内不会无真实外→内转换而触发。
- 长时间使用确认约 6.67 Hz 的可见期采样没有可感知能耗或干扰问题。

## 9. 已知风险与偏离

- 自动测试可以确定状态、调度和资源映射，但不能替代真实桌面上的尾巴辨识度、边缘触发手感与长期低打扰判断。
- AppKit 测试需串行运行以避开当前机器的测试宿主并行启动竞争。
- 除为兼容本机 Pillow 9.4 修正素材测试坐标类型外，无任务书范围偏离。
- MD-008 仍保留在 `active/` 且未标记“已完成”；最终验收和归档由用户/高级项目经理决定。

## 10. Git 操作确认

- 本轮没有执行 `git add`、`git commit`、`git push`、PR、merge、reset、restore、分支创建、分支切换或 remote 修改。
- 本轮验证生成的临时 DerivedData 和覆盖率文件已删除；未删除任何产品、素材或用户文件。

MD-008 已交付，请验收
