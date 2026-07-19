# Daily Start

更新时间：2026-07-19

## 用途

当提示是“根据项目规划和开发进度，今天要来做什么以推进开发”时，优先阅读本文。本文只提供日常入口和读取顺序；阶段方向与边界以 `docs/planning/current.md` 为准。

## 阶段

当前为「切片实现：配方加工 arc（首条化工链的空间工厂自动化）——方向修订，设计先行」。

- 活跃专题 [配方加工](../features/slice-recipe-processing-v1.md)：2026-07-19 实机复核判定抽象实现（包 1+2）层级过抽象，重写为空间工厂自动化 arc 总览（L0 资源模型 → L1 合成 → L2 电力 → L3 建造放置 → L4 传送带 → L5 反应器接入）；抽象实现保留为过渡参照。待萝卜SAMA确认 L0 起步与美术授权后另建可执行细专题。
- 美术介质机械口径：[Pixel Art And Grid Standard](../reference/pixel-art-and-grid-standard.md)（32px 网格、960x540 相机、宏块归一均已定稿）。
- 章程与复盘结论存档：[Project Purpose And Solo AI Development Review](project-purpose-and-solo-ai-development-review.md)。

## 最近收尾

- 2026-07-18 存档持久化与采集建造两专题收口：`SliceSaveService` 存读闭环；整备台建造采集器、晶体地放置、每 10 秒自动产出。
- 2026-07-18 至 07-19 视角修正轮收口：投影口径两次校准定为高斜角俯视，22 张世界层素材重出换装（锚点 + 6 设备 + 13 角色帧 + 3 站立帧），画面填充 fractional、采集器足印 2x2、方向性 idle；萝卜SAMA实机确认。
- 遗留登记：八方向动画（候选专题）、viewport 整数重构（并入 HUD 换皮）、打磨清单观察项。

## 下一步事项

1. 配方加工 arc 待萝卜SAMA确认 L0（资源模型改造：全局计数 → 空间物品 + 机器进出料库存 + 储物箱）起步与美术授权（传送带 / 电线杆·中继 / 地板 / 储物箱新素材）后，另建 L0 可执行细专题实施。
2. 敌人素材生成会话可由萝卜SAMA择时并行启动（按高斜角口径与提示词库执行）。

## 防跑偏规则

- 配方加工 arc 需新素材（传送带 / 电线杆·中继 / 地板 / 储物箱），属硬闸门——须萝卜SAMA授权美术会话按高斜角口径产出，执行会话不自铺全量；抽象实现（包 1+2）保留为过渡参照。
- 不做敌人 / 战斗、任务链、立绘对话、八方向动画、viewport 重构；冻结旧系统与旧检查不动。
- 玩家可见目标以正式入口实机截图与运行时路径复核为主证据，自动检查只兜底。
- 介质口径变更、两轮失败复盘、专题切换属架构级升级点，执行会话停手上报萝卜SAMA。

## 当前不做

- 敌人、战斗、污染伤害；任务链、立绘对话；八方向动画；viewport 重构与 HUD 换皮。
- 旧代码与旧素材清理（清单专题收口后另定）、联机、多星球、试玩准备与发布。

## 必读与选读

日常必读：

- `docs/planning/current.md`（配方加工阶段边界与退出条件）
- `docs/features/slice-recipe-processing-v1.md`（配方加工活跃专题范围与验收）
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
