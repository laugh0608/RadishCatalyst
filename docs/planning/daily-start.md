# Daily Start

更新时间：2026-07-29

## 用途

当提示是“根据项目规划和开发进度，今天要来做什么以推进开发”时，优先阅读本文。本文只提供日常入口和读取顺序；阶段方向与边界以 `docs/planning/current.md` 为准。

## 阶段

阶段：第一可玩切片玩家可见完成度补强；自动与人工完整全链已经通过，但表现仍有大量草稿层，陌生玩家盲测延期。

- [第一可玩切片全链串通](../features/slice-first-playable-journey-v1.md) 的自动、正式入口和萝卜SAMA人工内部验收均已通过；当前返回玩家可见完成度开发，不进入盲测。
- [首次外勤战斗与关键样本回收](../features/slice-first-field-combat-and-sample-recovery-v1.md) 三包、保留世界与人工证据闭环，已于 2026-07-27 收口。
- 最新收口专题 [多世界存档列表](../features/slice-multi-world-save-list-v1.md)：目录、列表、暂停返回、动作互斥与人工路径全部通过。
- 美术介质机械口径：[Pixel Art And Grid Standard](../reference/pixel-art-and-grid-standard.md)（32px 网格、960x540 相机、宏块归一均已定稿）。
- 章程与复盘结论存档：[Project Purpose And Solo AI Development Review](project-purpose-and-solo-ai-development-review.md)。

## 最近收尾

- 2026-07-21 至 07-26 L1–L5 依次收口手持合成、中央仓库、六类建筑、电网、传送物流、反应器与自然产线，schema 演进至 6。
- 2026-07-26 多世界目录、三份备份、损坏隔离、回收恢复、启动列表与暂停返回通过人工复核。
- 2026-07-27 首次战斗、撤离、样本交付、`120` 生命收益与 schema 7 五态持久化收口。
- 2026-07-27 全链包 1 / 2 从真实新档串通基地、生产、重启、充能、战斗与交付，并从权威状态派生七段旅程目标；人工计时前无 `P0`。
- 2026-07-27 萝卜SAMA人工全链落在 20 到 40 分钟且总体可完成；反馈确认产晶等待、HUD 挡视野、鼠标放置、电网范围和地板需求属于进入盲测前的主要体验阻力，纯文字面板与整体 3/4 体积感另行分级。
- 2026-07-28 反馈拆为包 2A“生产节奏与紧凑 HUD”和包 2B“鼠标放置与空间反馈”；2A 把采集周期从 `10s` 降到 `6s`，理论最低生产等待从 `390.7s` 降到 `242.7s`，常驻 HUD 左侧高度从 `192px` 降到 `114px`。完整 Godot 回归、真实新档 267 项及九图视觉复核通过，保留旧进度兼容、主档和三份备份。
- 2026-07-28 萝卜SAMA人工反馈确认紧凑 HUD 仍像纯文字草稿，不具备游戏 UI 质感；停止继续做同类矩形 / 字号调参。生产节奏另备通电采集阶段存档，不要求从新档复核。
- 2026-07-28 萝卜SAMA从阶段档确认 `6s/个` 仍慢，当前改为 `1s/个`；37 个可再生晶体与反应器的理论最低生产等待约 `57.7s`，完整 Godot 回归通过，原阶段档可直接复用。
- 2026-07-28 萝卜SAMA确认 `1s/个` 的生产速度可以接受；HUD 路线改由 [Slice HUD Gameplay Shell V1](../features/slice-hud-gameplay-shell-v1.md) 承载，不再继续同类文字底板调参。
- 2026-07-28 HUD 五类组件、三态自动 / 截图证据和双世界人工复核档完成；AI 复核修正底部操作条与角色模块重叠，等待萝卜SAMA实机判断游戏 UI 质感。
- 2026-07-28 萝卜SAMA确认 HUD 可以通过，提交为 `badc20ca`；包 2A 与 HUD 阻断解除。
- 2026-07-28 包 2B 接入鼠标单放、地板拖铺、UI 点击互斥、足印 / 缺地板格和两级电力范围；放置 74 项、旅程 55 项、完整 Godot 回归和真实 `Boot` 23 项通过。萝卜SAMA人工确认无问题，提交为 `59c33950`。
- 2026-07-29 包 3A 修正人工复核前段三项 `P1`：设备可按背包材料自动补地板，储物箱 / 反应器显示权威物流端口，采集器改为先开面板再显式取料；数字键固定制作、`Shift + 数字键`选中已有套件，制作地板后恢复原设备预览。
- 2026-07-29 包 3A 正式新档全链以 308 项断言、9 次设备确认和 22 格自动补地板通过；`delivered / 120` 主档、三份备份、13 张原图与联系表均保留在项目内忽略目录。
- 2026-07-29 实机保留档定位到左侧储物箱端口朝上、传送带只贴近箱体而未接网；传送带放置态现持续显示附近 `IO / IN / OUT`、连接格、箭头和 `✓ / ×`，设备面板显示未接 / 方向错误 / 有效流向。物流专项 97 项、完整 Godot 回归与真实新档 313 项全链通过。
- 2026-07-29 萝卜SAMA从保留世界确认传送带端口、左侧储物箱断链诊断、调整后实际出货和设备面板均无问题；包 3A 前段修正人工通过。
- 2026-07-29 萝卜SAMA继续跑完反应器、催化剂、核心充能、外勤、交付和最终完成态；保留主档为 `delivered / 120`，三份备份同步更新，包 3 内部完整人工验收收口。
- 2026-07-29 萝卜SAMA判定当前仍有大量草稿层，开发者理解不能作为陌生玩家可读性的替代证据；明确跳过当前盲测，下一阶段恢复表现层开发。
- 遗留登记：八方向动画（候选专题）、viewport 整数重构（并入 HUD 换皮）、打磨清单观察项。

## 当前下一事项

主目标是先建立“设备操作面板统一 V1”可执行专题，不立即写代码。

1. 盘点采集器、储物箱、反应器和核心现有面板的共同结构与设备特有操作。
2. 定义名称 / 状态、输入输出、库存容量、供电 / 物流诊断、操作按钮和异常原因的统一组件契约。
3. 第一实现包只替换设备面板表现与鼠标路径，不改生产、物流、库存或存档规则。
4. 世界 3/4 体积感继续作为独立架构级专题，不与设备 UI 混改。

## 今日进度（2026-07-29）

1. 已完成包 3A 三项 `P1` 修正及大足印地板备料闭环；一次性驱动、隔离存档和人工复核数据迁到 `tools/runtime-intake/`。
2. 完整 Godot 回归与真实 `Boot → 新建世界` 313 项全链通过，最终仍为 `delivered / 120`。
3. 14 张原图和联系表已生成；文件级核对通过，但按本会话图片读取护栏未加载新图，新画面与手感仍需萝卜SAMA人工确认。
4. 萝卜SAMA人工确认端口提示、断链诊断、储物箱调整和实际出货无问题；包 3A 前段修正完成。
5. 萝卜SAMA继续完成全部后段路径；保留档核对为 `delivered / 120`，内部完整人工验收完成，下一步切入陌生玩家盲测。
6. 萝卜SAMA明确跳过当前盲测：当前仍有大量草稿层，下一步先补建造 / 背包图形化，再评估设备面板和世界表现。
7. 已建立并实现 [图形化建造 / 合成 / 背包 UI V1](../features/slice-graphical-crafting-and-inventory-v1.md) 包 1；七张配方卡、九个背包格、鼠标制作 / 选中和权威阻塞反馈均已接入。
8. 建造操作 118 项、正式 `Boot` 43 项与完整 Godot 回归通过；三张截图和联系表已生成，受本会话图片读取护栏限制，当时转交萝卜SAMA视觉 / 手感复核。
9. 萝卜SAMA实机确认图形化制造 / 背包整体感觉可以；专题人工通过并收口，下一步转入设备操作面板统一专题设计。

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
- 陌生玩家盲测、多人试玩、试玩分发准备、打包与发布；只有表现层达到萝卜SAMA认可门槛后才重新解冻。

## 必读与选读

日常必读：

- `docs/planning/current.md`（当前阶段与包 3 退出条件）
- `docs/features/slice-first-playable-journey-v1.md`（当前专题、完整路径、三包边界与失败判据）
- `docs/features/slice-graphical-crafting-and-inventory-v1.md`（当前图形化整备专题、组件契约与包 1 验收）
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
