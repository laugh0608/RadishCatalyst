# Current Plan

更新时间：2026-09-05

## 当前阶段

```text
小型化工厂视觉目标探索与评审
```

本轮方向以 [Production-Centered Direction](../product/production-centered-direction.md) 为优先真相源：化工生产经营成为核心，探索为生产提供资源、空间和长期目的；战斗体量、美术介质、Web 迁移和随机工业投入的具体系统均未决定。

既有[第一可玩切片全链](../features/slice-first-playable-journey-v1.md)、[试玩反馈整改](../features/slice-playtest-remediation-v1.md)包 0—4、`delivered / 120`、schema 10 及其自动和人工证据全部保留为实现与回归基线；`91f52869` 所含的工厂反馈收口事实不因本轮视觉探索而改写。原整改 S0 继续暂缓，功能与系统路径通过不等于视觉方向通过。

## 当前边界

- 小区域工厂片段的玩家反馈实现与系统验证已经完成：真实端口接缝按物流方向刷新，建造态允许 `WASD`、近身 `E` 与无预览时鼠标选中已有设备进入既有调整流程。
- 常态画面采用固定高斜角，建造模式以 `1.5` 档位拉远并显示网格、足印、接口和流向，同时弱化遮挡；继续复用现有素材与实现。
- 当前只允许按 [Small Chemical Factory Visual Target V1](../design/small-chemical-factory-visual-target-v1.md) 生成一张 16:9 小型化工厂目标图及有限修订，用于评审规模密度、生产可读性、投影模块感和材质气质。
- 目标图是概念候选，不是游戏截图或可直接接入的正式资产；萝卜SAMA对整改后完整操作手感的复评继续保留为待办，但不是本轮首要动作。
- 工业研发、试制、勘探和传统抽卡都只是随机投入的候选表达，不进入本轮实现。

## 当前不做

- 不删除既有功能、战斗或历史证据，不改写旧专题和旧周志。
- 不新增玩法系统，不解冻新地图、新敌人、剧情、多人、完整 ARPG 或长期多星球实现。
- 用户评审前不批量生产或接入正式资产，不把目标图裁切后冒充网格合格素材。
- 不决定像素转 3D、双角度、Web 迁移或整仓重写。
- 不恢复陌生玩家盲测、试玩分发、打包、发布或上传。

## 下一步

优先评审 [Small Chemical Factory Visual Target V1](../design/small-chemical-factory-visual-target-v1.md) 推荐的 v2，保留 v1 作为比例修订对照；判断规模与密度、生产可读性、投影与模块感、材质与气质。用户评审前不新增玩法系统，不批量生产或接入正式资产，不迁移 Web、不切换 3D、不做全仓重构。既有物流 / 建造专项 `180` / `152` 项与正式窗口 `59` 项断言继续保留，操作手感复评留作后续待办。

## 退出条件

- 一张目标图能支持上述四项评审，且与稀疏单排箱体现状形成清楚差异。
- 连续厂坪、两排设备、贯通通道和三层物流 / 管线关系可读，不依赖口头补图。
- 高斜角、矩形网格、设备足印、角色比例、调色板和左上光能作为后续模块化美术的目标约束。
- 候选的生成缺陷、未归一、未接入和未验证边界记录清楚；用户评审后再决定有限修订或停止。

## 默认验证

- 文档：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`、`./scripts/check-repo.sh`。
- 本轮 `./scripts/check-client.sh` 静态检查通过；旧完整 `check-client --with-godot` 在最后的焦点 / 缩放小修前通过，焦点专门 probe 通过，修后的正式 `Boot` 路径以 `67 + 6` 项断言通过。后续玩家可见实现仍须遵循 [Godot Runtime Verification Guide](../reference/godot-runtime-verification-guide.md)。
