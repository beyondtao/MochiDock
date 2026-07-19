# MochiDock 素材目录

素材按角色、用途和版本组织，避免探索稿、生产母版与运行时尺寸混放。

## 目录结构

- `character/red-panda/exploration/`：概念探索稿与候选排版图，只用于方向评审。
- `character/red-panda/master/<version>/`：选定造型的高分辨率母版及生成源图。
- `character/red-panda/previews/<version>/`：从同版本透明母版确定性缩放的桌面尺寸验证图。
- `workbench/`：本地抠图、边缘诊断和评审候选；只有用户确认的结果才会升格到正式版本目录。

## 使用规则

- 不直接把探索排版稿接入产品。
- 小尺寸素材必须从已确认的透明母版缩放，不能分别重新生成。
- 新一轮造型或花纹发生变化时创建新版本目录，不覆盖旧版本。
- `workbench/` 中的试验结果不能直接接入产品。
- Xcode 运行时素材后续从已确认版本复制到 `Assets.xcassets`，这里保留设计源与评审记录。
