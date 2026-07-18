# Daily Start

更新时间：2026-07-18

## 用途

当提示是“根据项目规划和开发进度，今天要来做什么以推进开发”时，优先阅读本文。本文只提供日常入口和读取顺序；阶段方向与边界以 `docs/planning/current.md` 为准。

## 阶段

当前为「呈现修正：高机位视角修正轮」。

- 当前唯一活跃功能专题：[Slice Viewpoint Correction V1](../features/slice-viewpoint-correction-v1.md)。
- 美术介质机械口径：[Pixel Art And Grid Standard](../reference/pixel-art-and-grid-standard.md)（32px 网格、960x540 相机、宏块归一均已定稿）。
- 章程与复盘结论存档：[Project Purpose And Solo AI Development Review](project-purpose-and-solo-ai-development-review.md)。

## 最近收尾

- 2026-07-17 至 07-18 存档持久化专题收口：`SliceSaveService` 隔离存档、`载入存档` 改指切片、纯自动存档；双进程闭环验证，萝卜SAMA实机复核通过。
- 2026-07-18 采集与建造专题收口：整备台建造采集器（携带态 + 放置预览 + 仅晶体地校验）、每 10 秒自动产出、进存档续产；三包运行时断言全过，萝卜SAMA实机复核通过。
- 2026-07-18 萝卜SAMA实机提出两项呈现口径问题并定档修正：素材视角走高机位近正俯视修正轮（投影口径已改写像素标准 + 提示词库）；画面填充 `scale_mode` 改 `fractional` 已止血。

## 下一步事项

按视角修正轮三包串行，每包收口做最小验证并记入当周周志：

1. 包 1 新机位锚点验证（已收口 2026-07-18）：S1'' 高度增强版 `v2` 定稿为新锚点并入库。
2. 包 2 设备重出与换装（已收口 2026-07-18）：S3'' 三张一次过，6 张设备同名换装，采集器足印提 2x2；萝卜SAMA实机确认（小瑕疵记打磨清单不阻塞）。
3. 包 3 角色重出、换装与收口（当前）：交接副本 S4''（静态 + 侧向）与 S7''（背 + 正）两段已备妥，生成会话由萝卜SAMA分两次执行；审阅 / 归一 / 换装 / 实机复核由执行会话承接。

## 防跑偏规则

- 只做视角修正三包；不改系统逻辑（循环 / 存档 / 建造 / 产出），素材为同名替换。
- 视角修正轮收口前不生成敌人 / 新设备等其他素材；地面 tile 与立绘不动，晶体簇留实机对比定夺。
- 素材生成是萝卜SAMA的显式决策，执行会话不自行启动生成；图像会话稳定性约束不变。
- 采集器足印 1x1 → 2x2 是本专题唯一代码改动；冻结保留旧场景、旧视觉层与旧检查，不删除、不修改。
- 玩家可见目标以正式入口实机截图与运行时路径复核为主证据，自动检查只兜底。
- 投影口径两轮不成立复盘、专题切换属架构级升级点，执行会话停手上报萝卜SAMA。

## 当前不做

- 敌人 / 战斗 / 新设备素材（视角定档收口后另起）；配方加工、立绘对话、任务链。
- viewport 整数重构（留后续 HUD 换皮专题）；旧代码与旧素材清理、联机、多星球、试玩准备与发布。

## 必读与选读

日常必读：

- `docs/planning/current.md`
- `docs/features/slice-viewpoint-correction-v1.md`
- `docs/reference/pixel-art-and-grid-standard.md`（投影口径 2026-07-18 修订）
- `docs/reference/ai-art-prompts.md`（全局风格块 2026-07-18 视角修订）

按任务选读：

- 归一与提示词口径：`docs/reference/ai-art-prompts.md`
- 流程闸门：`docs/process/development-decision-gates.md`
- 章程与完成定义：`docs/planning/project-purpose-and-solo-ai-development-review.md`
- 视觉气质与 UI 原则：`docs/product/visual-and-ui-direction.md`
- 旧路线历史证据：`docs/archive/features-demo-v1/README.md`、`docs/archive/planning-demo-v1/README.md`

## 验证入口

- 代码与素材接入：`sh ./scripts/check-client.sh`（默认不启动 Godot）；场景与脚本改动按需 `--with-godot` 单项验证。
- 文档改动：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`。
