# Daily Start

更新时间：2026-07-28

## 用途

当提示是“根据项目规划和开发进度，今天要来做什么以推进开发”时，优先阅读本文。本文只提供日常入口和读取顺序；阶段方向与边界以 `docs/planning/current.md` 为准。

## 阶段

阶段：第一可玩切片全链串通，生产节奏、HUD 与包 2B 空间反馈均已人工通过；下一包为完整验收。

- [第一可玩切片全链串通](../features/slice-first-playable-journey-v1.md) 已证明机械全链和包 2 体验修正成立；当前进入包 3。
- [首次外勤战斗与关键样本回收](../features/slice-first-field-combat-and-sample-recovery-v1.md) 三包、保留世界与人工证据闭环，已于 2026-07-27 收口。
- 最新收口专题 [多世界存档列表](../features/slice-multi-world-save-list-v1.md)：目录、列表、暂停返回、动作互斥与人工路径全部通过。
- 美术介质机械口径：[Pixel Art And Grid Standard](../reference/pixel-art-and-grid-standard.md)（32px 网格、960x540 相机、宏块归一均已定稿）。
- 章程与复盘结论存档：[Project Purpose And Solo AI Development Review](project-purpose-and-solo-ai-development-review.md)。

## 最近收尾

- 2026-07-21 L1 手持合成与 L2 核心直供 / 中央仓库经正式入口人工复核收口，schema 3 存读兼容成立。
- 2026-07-25 L3 六类建筑、工业地板、扩展供电、schema 4 和自然资源自举收口；人工视觉失败推动包 5 修正采集器方向、供电树与统一接地 / 底边排序。
- 2026-07-25 L4 直线、转角、合流、公平轮询、回压和 schema 5 收口，人工复核确认三源物流与满箱回压。
- 2026-07-26 L5 反应器、催化剂货物、自然完整产线与 schema 6 收口；真实新档无注入完成有限资源自举、可再生采集、加工和双状态重启。
- 2026-07-26 多世界存档列表收口：30 世界上限、三份备份、损坏隔离、回收恢复、启动列表、暂停返回与动作互斥均通过人工复核。
- 2026-07-27 C1 / C2 从三稿选定晶腺样本 V2，归一为 `31×30`、7 色透明 RGBA；九档机械检查和两张联系表通过。
- 2026-07-27 D / 包 1 自动证据完成：四张素材入库，2 催化剂显式充能、鼠标瞄准 / 左键续攻、`Space` 闪避、前台输入互斥与紧凑 HUD 接入；专项 52 项、完整回归、真实 `Boot → 载入 L5 产线副本` 30 项和三态视觉复核通过。
- 2026-07-27 包 1、包 2 人工通过；唯一敌人、撤离与样本成立，复核发现的缺字和阴影偏移已修正。专项 53 项、`Boot` 56 项、修正 10 项通过。
- 2026-07-27 包 3 完成样本交付、`120` 生命收益和 schema 7 五态持久化；专项 54 项、schema 144 项、目录 91 项、`Boot` 52 项及三态视觉通过。
- 2026-07-27 萝卜SAMA确认包 3 的世界摘要、交付收益与重启完成态无问题；首次外勤战斗专题正式收口，并授权切换到第一可玩切片全链串通。
- 2026-07-27 全链包 1 以 253 项断言从真实新档完成核心、自然产线、重启、充能、战斗与交付；六图联系表和 `delivered / 120` 保留世界通过。无 `P0`，两项 `P1` 为产线短目标缺失和主要 HUD 浅地对比不足。
- 2026-07-27 全链包 2 从权威状态派生七段旅程目标，补当前规则行与统一高对比 HUD 承载；专项 40 项、完整 Godot 回归和真实新档 267 项通过，九图确认浅地可读且无截断。
- 2026-07-27 萝卜SAMA人工全链落在 20 到 40 分钟且总体可完成；反馈确认产晶等待、HUD 挡视野、鼠标放置、电网范围和地板需求属于进入盲测前的主要体验阻力，纯文字面板与整体 3/4 体积感另行分级。
- 2026-07-28 反馈拆为包 2A“生产节奏与紧凑 HUD”和包 2B“鼠标放置与空间反馈”；2A 把采集周期从 `10s` 降到 `6s`，理论最低生产等待从 `390.7s` 降到 `242.7s`，常驻 HUD 左侧高度从 `192px` 降到 `114px`。完整 Godot 回归、真实新档 267 项及九图视觉复核通过，保留旧进度兼容、主档和三份备份。
- 2026-07-28 萝卜SAMA人工反馈确认紧凑 HUD 仍像纯文字草稿，不具备游戏 UI 质感；停止继续做同类矩形 / 字号调参。生产节奏另备通电采集阶段存档，不要求从新档复核。
- 2026-07-28 萝卜SAMA从阶段档确认 `6s/个` 仍慢，当前改为 `1s/个`；37 个可再生晶体与反应器的理论最低生产等待约 `57.7s`，完整 Godot 回归通过，原阶段档可直接复用。
- 2026-07-28 萝卜SAMA确认 `1s/个` 的生产速度可以接受；HUD 路线改由 [Slice HUD Gameplay Shell V1](../features/slice-hud-gameplay-shell-v1.md) 承载，不再继续同类文字底板调参。
- 2026-07-28 HUD 五类组件、三态自动 / 截图证据和双世界人工复核档完成；AI 复核修正底部操作条与角色模块重叠，等待萝卜SAMA实机判断游戏 UI 质感。
- 2026-07-28 萝卜SAMA确认 HUD 可以通过，提交为 `badc20ca`；包 2A 与 HUD 阻断解除。
- 2026-07-28 包 2B 接入鼠标单放、地板拖铺、UI 点击互斥、足印 / 缺地板格和两级电力范围；放置 74 项、旅程 55 项、完整 Godot 回归和真实 `Boot` 23 项通过。萝卜SAMA人工确认无问题，提交为 `59c33950`。
- 遗留登记：八方向动画（候选专题）、viewport 整数重构（并入 HUD 换皮）、打磨清单观察项。

## 当前下一事项

主目标是建立包 3 的当前完整内部基线，不直接进入朋友盲测。

1. 从干净世界重跑当前 `1s` 节奏、游戏化 HUD 与鼠标放置后的正式入口全链。
2. 保留主档和三份备份，记录总时长、关键交互、重启续跑、最终状态与节点截图。
3. 萝卜SAMA复核内部基线通过后，才组织陌生玩家无人指导盲测。

## 明日事项（2026-07-29）

1. 先复用现有全链脚本建立包 3 干净内部基线，不新增玩法、资源、建筑或教程。
2. 从真实 `Boot → 新建世界` 覆盖核心修复、产线、重启、充能、战斗、样本交付与 `delivered / 120`，记录 20–40 分钟口径所需证据。
3. 生成关键节点截图联系表并保留复核世界；萝卜SAMA确认后再准备朋友盲测记录表，3/4 世界视觉仍保持冻结。

## 防跑偏规则

- 多世界与 schema 7 已收口；新专题只按明确迁移策略扩展当前切片状态，不复活旧 `SaveService`、旧 `GameRoot` 或旧三槽存档。
- 包 3 首轮只做当前能力的完整验收取证，不新增玩法内容，也不在路径运行中即时调规则。
- 玩家可见目标以正式入口实机截图与运行时路径复核为主证据，自动检查只兜底。
- 自动化可生成多张截图，但单个 Codex 会话默认最多读取 3 张图片；多图先用 `scripts/create-screenshot-contact-sheet.sh` 合成一张带编号联系表，达到默认上限后先报告，萝卜SAMA明确要求时可继续。
- 图像生成默认每轮至多 3 次、每次 1 张；每轮结束必须先落盘、更新 manifest 并报告，只有经萝卜SAMA明确授权才能在同素材会话追加下一轮。
- 介质口径变更、两轮失败复盘、专题切换属架构级升级点，执行会话停手上报萝卜SAMA。

## 当前不做

- 敌潮、复杂 Boss、技能树、联机；旧地图、旧 `GameRoot`、旧三槽存档复活；无关重构。
- 新敌人、配方、建筑或地图；立绘对话、八方向动画、viewport 重构与 HUD 换皮。
- 包 3 内部正式入口与萝卜SAMA复核通过前的朋友盲测、试玩分发准备与发布。

## 必读与选读

日常必读：

- `docs/planning/current.md`（当前阶段与包 3 退出条件）
- `docs/features/slice-first-playable-journey-v1.md`（当前专题、完整路径、三包边界与失败判据）
- `docs/features/slice-first-field-combat-and-sample-recovery-v1.md`（最新收口战斗、schema 7 与人工证据）
- `docs/features/slice-multi-world-save-list-v1.md`（最新收口存档与菜单边界）
- `docs/features/slice-reactor-automation-v1.md`（L5 当前玩家路径、状态机、双端口、schema 6、素材闸门与实现包）
- `docs/features/slice-conveyor-logistics-v1.md`（L4 已收口物流模型与验收基线）
- `docs/features/slice-building-placement-and-power-grid-v1.md`（L3 已收口范围、素材与验收）
- `docs/features/slice-recipe-processing-v1.md`（配方加工 arc 总览与层状态）
- `docs/reference/pixel-art-and-grid-standard.md`（投影口径 2026-07-18 修订）
- `docs/reference/ai-art-prompts.md`（全局风格块 2026-07-18 视角修订）

按任务选读：

- L5-A 素材与归一口径：`docs/reference/ai-art-prompts.md`、`docs/reference/pixel-art-and-grid-standard.md`
- 反应器端口与主体不变量：`docs/reference/l3-building-art-prompts.md`
- 流程闸门：`docs/process/development-decision-gates.md`
- 章程与完成定义：`docs/planning/project-purpose-and-solo-ai-development-review.md`
- 视觉气质与 UI 原则：`docs/product/visual-and-ui-direction.md`
- 旧路线历史证据：`docs/archive/features-demo-v1/README.md`、`docs/archive/planning-demo-v1/README.md`

## 验证入口

- 代码与素材接入：`sh ./scripts/check-client.sh`（默认不启动 Godot）；场景与脚本改动按需 `--with-godot` 单项验证。
- 玩家可见玩法 / UI / 场景 / 交互 / 存读结果：强制按 [Godot Runtime Verification Guide](../reference/godot-runtime-verification-guide.md) 从真实 `Boot` 自动运行输入链；有渲染目标必须有窗口抓图到 `assets/art-intake/` 并实际审阅，headless 断言不能替代截图。
- 文档改动：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`。
