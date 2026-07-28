# Current Plan

更新时间：2026-07-28

## 入口约束

本文是新会话的阶段入口，只保留当前阶段、当前活跃专题、边界、验证入口和退出条件。

- 当前活跃专题：[第一可玩切片全链串通](../features/slice-first-playable-journey-v1.md) 包 3；生产节奏、[Slice HUD Gameplay Shell V1](../features/slice-hud-gameplay-shell-v1.md)与包 2B 空间反馈均已人工通过。
- 最新收口专题：[首次外勤战斗与关键样本回收](../features/slice-first-field-combat-and-sample-recovery-v1.md)、[多世界存档列表](../features/slice-multi-world-save-list-v1.md)、[L5 反应器接入自动化](../features/slice-reactor-automation-v1.md)与[配方加工 arc](../features/slice-recipe-processing-v1.md)；更早专题见 `docs/features/README.md`。
- 美术口径：[Pixel Art And Grid Standard](../reference/pixel-art-and-grid-standard.md)（32px 网格、960x540 相机、宏块归一）。
- 章程结论：[Project Purpose And Solo AI Development Review](project-purpose-and-solo-ai-development-review.md)（决策存档）。
- 旧 Demo V1 路线（12 区纵切 + 写实 2.5D）已废止归档：`docs/archive/features-demo-v1/`、`docs/archive/planning-demo-v1/`。

## 阶段状态

已通过：

- 2026-07-12 至 07-21：介质章程、960×540 像素口径、基地 / 晶体无缝地图、采集修核心、独立切片存档、采集自动化、视角修正和核心直供 / 中央仓库依次收口。
- 2026-07-25：L3 六类建筑、工业地板、扩展供电、schema 4、自举资源与空间视觉修正收口；L4 传送带、转角 / 合流、公平轮询、回压和 schema 5 收口。
- 2026-07-26：L5 双端口反应器、催化剂、完整自然产线与 schema 6 收口；多世界目录、三份备份、损坏隔离、回收恢复和暂停返回收口。
- 2026-07-27：首次外勤战斗、样本交付、`120` 生命收益与 schema 7 收口；真实新档全链成立，人工计时落在 20 到 40 分钟。
- 2026-07-28：采集器调整为 `1s/个`；游戏化 HUD 和包 2B 鼠标放置 / 空间反馈经自动、正式入口与人工复核通过，提交分别为 `badc20ca`、`59c33950`。

当前阶段：

```text
第一可玩切片全链串通——包 3 完整验收
```

## 当前主线

1. 先从干净世界重跑当前 `1s` 节奏、游戏化 HUD、鼠标放置后的正式入口全链，保留主档与三份备份。
2. 记录总时长、关键交互、读档续跑、最终 `delivered / 120` 和节点截图；萝卜SAMA先复核内部基线。
3. 内部基线通过后才组织一位陌生玩家无人指导盲测；盲测过程中只记录，不即时改规则。

## 边界与冻结

- 多世界目录与 schema 7 现状作为当前基线；不复活旧 `SaveService`、旧 `GameRoot`、旧三槽存档或旧地图。
- 视角修正轮遗留项在案：八方向动画（候选专题）、viewport 整数重构（并入 HUD 换皮）、打磨清单（核心区底板叠加等观察项）。
- 新专题不做敌潮、复杂 Boss、技能树、联机或无关重构；立绘对话、八方向动画、viewport 重构、HUD 换皮与发布继续冻结。
- 不复活旧通用任务链；若包 1 证明存在引导阻断，优先从现有权威状态派生固定阶段目标。
- 包 3 内部正式入口与萝卜SAMA复核通过前，不进入朋友盲测或试玩分发准备。
- `SliceWorld` 当前 1406 行；指针、预览和放置校验已拆分，包 3 不新增业务分支。

## 当前默认验证

- 代码与素材接入：`sh ./scripts/check-client.sh`（默认不启动 Godot）；场景与脚本改动按需 `--with-godot` 单项验证。
- 文档改动：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`。
- 玩家可见目标以正式入口实机截图与运行时路径复核为主证据；自动检查只兜底。

## 当前实现包退出条件

- 修复核心后，玩家不用口头说明即可从 HUD 与当前面板读出通电采集、反应器供电、双端物流和 2 催化剂的顺序与必要规则。
- 阶段目标只由既有世界、建筑、库存和遭遇状态派生，不新增存档字段或通用任务图。
- 资源、目标、生命、战斗状态和交互提示在基地浅地与晶体区均保持稳定对比，无截断或遮挡。
- 37 个可再生晶体与反应器的最低生产等待不高于 `60s`，旧档采集进度可继续结算；常驻 HUD 不恢复完整套件长行。
- 放置预览跟随鼠标网格，工业地板可连续铺设，设备足印、缺地板格和电力范围在确认前可见，且不破坏 `E` 兼容路径。
- 真实新档全链回归继续通过；萝卜SAMA确认内部路径后，一位陌生玩家能无人指导在 20 到 40 分钟内完成并说明为何出门、返回与继续。

切片整体完成定义为陌生玩家无人指导 20 到 40 分钟完整体验，五条标准见复盘文档章程节。
