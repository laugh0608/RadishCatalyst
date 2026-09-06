# Current Plan

更新时间：2026-09-06

## 当前阶段

```text
小型化工厂视觉目标探索与 3D / Web 隔离对照
```

本轮方向以 [Production-Centered Direction](../product/production-centered-direction.md) 为优先真相源：化工生产经营成为核心，探索为生产提供资源、空间和长期目的；战斗体量、美术介质、Web 迁移和随机工业投入的具体系统均未决定。

既有[第一可玩切片全链](../features/slice-first-playable-journey-v1.md)、[试玩反馈整改](../features/slice-playtest-remediation-v1.md)包 0—4、`delivered / 120`、schema 10 及其自动和人工证据全部保留为实现与回归基线；`91f52869` 所含的工厂反馈收口事实不因本轮视觉探索而改写。原整改 S0 继续暂缓，功能与系统路径通过不等于视觉方向通过。

## 当前边界

- 小区域工厂片段的玩家反馈实现与系统验证已经完成：真实端口接缝按物流方向刷新，建造态允许 `WASD`、近身 `E` 与无预览时鼠标选中已有设备进入既有调整流程。
- 常态画面采用固定高斜角，建造模式以 `1.5` 档位拉远并显示网格、足印、接口和流向，同时弱化遮挡；继续复用现有素材与实现。
- 工厂整图按 [Small Chemical Factory Visual Target V1](../design/small-chemical-factory-visual-target-v1.md) 保留 v1 / v2 候选。透明管段、金属接头及管壁动态流向标识已获用户认可；已授权 [Transparent Pipe Module Visual Validation V1](../design/transparent-pipe-module-visual-validation-v1.md) 的有限模块制作、机械归一和 Godot 隔离视觉验证。
- 管道模块被反馈缺少 2.5D 体积感；[Industrial Volume Visual Study V1](../design/industrial-volume-visual-study-v1.md) 的 v2 获得“有点那种感觉了”的方向反馈。按用户后续授权，已完成少量独立像素素材与正常游戏比例隔离验证，等待实机体积评价。
- 体积样板与建造分层已在 `e4f63d5d` / `6264e17d` 保存。[Raised Pipe Module Visual Validation V1](../design/raised-pipe-module-visual-validation-v1.md) 已按用户授权完成有限可拼接模块、动态内容与隔离验证，等待连续装配的实机体积评价。
- 目标图是概念候选，不是游戏截图或可直接接入的正式资产；萝卜SAMA对整改后完整操作手感的复评继续保留为待办，但不是本轮首要动作。
- 工业研发、试制、勘探和传统抽卡都只是随机投入的候选表达，不进入本轮实现。
- 已授权 [Topdown 3D Comparison Demo V1](../design/topdown-3d-comparison-demo-v1.md)：独立工程与实机对照已完成，等待路线选择；不代表正式客户端切换 3D。

- 已授权 [Web Style Comparison Demo V1](../design/web-style-comparison-demo-v1.md)：同场景比较手绘 2.5D 与现有像素素材，限本机独立 Demo；不代表正式 Web 迁移。
- 已授权并完成 [Web Topdown 3D Demo V1](../design/web-topdown-3d-demo-v1.md)：使用局部 Three.js 依赖建立七台设备的真实三维样场，比较三档俯角、光照与遮挡；等待用户评价。

## 当前不做

- 不删除既有功能、战斗或历史证据，不改写旧专题和旧周志。
- 不新增玩法系统，不解冻新地图、新敌人、剧情、多人、完整 ARPG 或长期多星球实现。
- 只制作本包有限视觉样板，不批量生产或接入正式设备系统；不把工厂目标图裁切后冒充网格合格素材。
- 不决定像素转 3D、双角度、Web 迁移或整仓重写。
- 不恢复陌生玩家盲测、试玩分发、打包、发布或上传。

## 下一步

查看 [Web Topdown 3D Demo V1](../design/web-topdown-3d-demo-v1.md) 的真实三维工厂样场，比较 40° / 55° / 70°、光照与透明遮挡。保留 [Web Style Comparison Demo V1](../design/web-style-comparison-demo-v1.md)、[Topdown 3D Comparison Demo V1](../design/topdown-3d-comparison-demo-v1.md) 与二维 Godot 样板作为参照，由萝卜SAMA选择后续路线；不自行验收或迁移。

上一轮 [管道模块验证](../design/transparent-pipe-module-visual-validation-v1.md) 已在 `280abdde` 保存，保留为未验收试验；本次只新增隔离体积样板。工厂 v2 整体评价及既有操作手感复评继续保留，局部样板不替代它们。既有物流 / 建造专项 `180` / `152` 项与正式窗口 `59` 项断言继续保留；不新增液气玩法系统、不迁移 Web、不切换 3D、不做全仓重构。

## 退出条件

- 一张目标图能支持上述四项评审，且与稀疏单排箱体现状形成清楚差异。
- 连续厂坪、两排设备、贯通通道和三层物流 / 管线关系可读，不依赖口头补图。
- 高斜角、矩形网格、设备足印、角色比例、调色板和左上光能作为后续模块化美术的目标约束。
- 候选的生成缺陷、未归一、未接入和未验证边界记录清楚；用户评审后再决定有限修订或停止。
- 管道模块局部包按其合同单独验收；不把示例动画写成真实输送或整体工厂通过。

## 默认验证

- 文档：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`、`./scripts/check-repo.sh`。
- 本次独立 3D 工程的入口、验证结果和未覆盖项见其专题；不替换正式 Boot。
- 管道模块包另执行客户端静态检查、独立 Godot 导入 / 定向检查与正式 `Boot` 隔离视觉验证；开窗前先告知。
- 管道模块包客户端静态检查及正式窗口定向检查通过，实际证据与未验证项见该包合同；旧完整 `check-client --with-godot`、焦点 probe 及 `67 + 6` 等工厂检查保留为各自历史证据。后续玩家可见实现仍须遵循 [Godot Runtime Verification Guide](../reference/godot-runtime-verification-guide.md)。
