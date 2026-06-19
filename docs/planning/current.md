# Current Plan

更新时间：2026-06-19

## 入口约束

本文是新会话的阶段入口，只保留当前阶段、当前活跃专题、边界、验证入口和退出条件。首版 Demo 完成规格以 [Demo Definition V1](../features/demo-definition-v1.md) 为准，具体开发范围以当前活跃专题和最近完成细专题为准：

- 当前活跃专题：[Demo Playable Content Substance V1](../features/demo-playable-content-substance-v1.md)，覆盖首版 Demo 场景、角色 / 怪物 UI、初步美术、工业基建和任务节奏的玩家可见实质补强。
- 最近完成：[Demo Core Scene Playable Space V1](../features/demo-core-scene-playable-space-v1.md)、[Demo Device Panel Operation Readability V1](../features/demo-device-panel-operation-readability-v1.md)、[Demo Core Stabilization Run Playability V1](../features/demo-core-stabilization-run-playability-v1.md)、[Demo Core Approach Handoff Playability V1](../features/demo-core-approach-handoff-playability-v1.md)
- 更早完成专题按 [Feature Development Docs](../features/README.md) 索引选读。

历史过程、长完成清单和详细复盘优先查看：

- `docs/planning/daily-start.md`
- `docs/devlogs/README.md` 中列出的最新一期周志
- `docs/planning/demo-scope-and-playable-slice.md`
- `docs/design/onboarding-and-first-hour.md`
- `docs/design/development-retest-baselines.md`

`AGENTS.md` 和 `CLAUDE.md` 只保留长期协作约束与稳定入口引用；当前阶段、当前不做、当前验证重点和退出条件统一以本文和当前活跃专题为准。

## 阶段状态

已通过：

- `S0` 早期复测、资源循环、基地行动、窗口复盘、装备与战斗反哺基地原型。
- 首版 Demo 范围冻结、12 区域封顶、UI baseline、核心稳定站终点链路和早期链路审计。
- 首小时引导、首小时到 Demo 中段节奏衔接、基地后勤、出发口、污染边界、晶体侧路和核心稳定站复测内容。
- 2026-06-14：「首版 Demo 可玩内容建设推进」达到收束条件；现有路线已有可操作场景对象、运行逻辑、玩家反馈、存档来源和自动检查证据。
- 2026-06-16：「角色成长与战斗第一版」「功能 / 过渡路线支撑第一版」「非核心区域场景识别第一版」「资源链状态第一版」「存档状态契约第一版」「主路径连续性第一版」「运行时承载面拆分第一版」与「功能场景玩法第一版」第一包已落地。
- 2026-06-17：外勤回基地收益兑现、终点前综合准备读法、Demo 完成成果整理、整段体验连贯性、可玩场景构成、战斗撤离恢复、交互可辨识度、动作反馈可读性、受阻动作恢复读法与原型视觉呈现第一包均已落地。
- 2026-06-18：原型视觉呈现、快捷补给读法和补给节奏与承压价值第一版均通过退出判断。
- 2026-06-19：功能 / 过渡场景玩法密度、可达空间、基地再进入读法、交互提示承载面、地图承载面、中段 / 风蚀 / 核心入口承接、核心稳定站内路径和设备面板操作读法均已完成第一包；随后撤回“自动检查通过即可进入验收”的判断，切回首版 Demo 可玩内容实质补强，并完成角色 / 怪物 UI 与核心场景空间第一包。

当前阶段：

```text
首版 Demo 可玩内容实质补强第一版
```

当前推进口径是首版 Demo 可玩内容实质补强：继续开发玩家实际能看到和操作的场景、角色 / 怪物 UI、初步美术、设备 / 生产链和任务节奏，不再把自动检查通过等同于可试玩候选。

## 当前主线

当前活跃专题是 [Demo Playable Content Substance V1](../features/demo-playable-content-substance-v1.md)。它承接已完成的第一包建设，回到 [Demo Definition V1](../features/demo-definition-v1.md) 中尚未被真实体验证明的场景、角色 / 怪物 UI、初步美术、工业基建、资源 / 生产链、战斗压力和任务节奏。

角色成长与战斗第一版只证明了第一轮能力和压力点存在；角色 / 怪物 UI 第一包已补战斗现场面板、敌人威胁 / 状态标签和命中承压反馈，核心场景空间第一包已补四个核心区的地表、路线、对象锚点、承压区和回基地 / 回收口袋，后续仍必须落到玩家可见实现。

体验主干建设尚未达到试玩准备判断标准；真实页面 smoke、自动检查和人工实机复测只能提供证据，不能替代场景、美术、设备、任务和战斗 UI 的实质开发。

## 区域策略

- 首版 Demo 继续按 12 区域封顶。
- 4 个核心区域、4 个功能区域、4 个过渡区域不再平均加厚。
- 原型视觉呈现和核心场景空间第一包已完成基础检查；后续允许继续补对象尺寸、设备造型、危险边界和任务节奏，但不继续堆同类场景提示。
- 不继续堆视觉 cue、目标箭头或地图提示来替代场景建设。

## UI 策略

UI 和场景表现只完成第一轮原型支撑。当前允许补强 HUD、战斗现场、敌人状态和对象反馈中的玩家判断信息，但不做完整菜单或高保真组件库。

不做完整菜单、设置页、背包大重构、完整装备栏、结算页、动画过场或大规模美术替换。

## 冻结与放宽

继续冻结：

- 前线行动台、候选、窗口复盘、高压窗口和 `base_action_state` 保持冻结，只修 `P0` / `P1`。
- 不新增第 13 区域，不平均扩 12 个区域，不继续给核心站完成态追加同构回访口袋。
- 不新增随机成功率、新货币、队员、完整装备栏、完整 `loadout`、联机入口或完整长期成长系统。
- 不把试玩准备、修 bug 阶段、发布准备或大规模 polish 作为当前阶段目标；当前仍是首版 Demo 内容开发。
- 不迁移稳定数据 ID；旧 ID 先作为存档、任务和数据兼容层保留。

允许推进：

- 可玩内容实质补强：开发场景空间、角色 / 怪物 UI、初步美术识别、计划内设备职责和任务节奏差异。
- 必要时新增窄职责 formatter、presenter helper 或专项 check，避免继续推高接近硬上限的大文件。
- 可以修阻塞主线连续性、功能闭合、区域表达或玩法密度判断的断点，也可以补齐首版 Demo 必达规格内的玩家可见缺口。

## 节奏规则

个人开发阶段只做足以判断方向的完成度，但不能把“有检查、有提示、有第一包”误判成首版 Demo 已可试玩。一个阶段真正达到退出条件后，必须及时进入下一阶段；不允许因为 `P2` / `P3` 细节、局部读法、文案密度或状态字段洁癖无限打磨。

只让这些问题阻塞阶段：

- 崩溃
- 主线卡死
- 坏档
- 任务无法完成
- 关键资源断档
- UI 完全无法判断下一步

其他问题进入 backlog 或后续 polish。

## 当前默认验证

客户端相关改动优先执行默认检查：Windows 用 `pwsh ./scripts/check-client.ps1`，macOS / Linux / Git Bash 用 `sh ./scripts/check-client.sh`；该入口不启动 Godot。需要导入工程或运行项目自定义 GDScript 检查时，确认本机 Godot 可启动后加 `-WithGodot` / `--with-godot`。

涉及文档、规划、协作规则或仓库入口时额外执行：

Windows 用 `pwsh ./scripts/check-docs.ps1`、`pwsh ./scripts/check-text-files.ps1`；macOS / Linux / Git Bash 用 `./scripts/check-docs.sh`、`./scripts/check-text-files.sh`；最后执行 `git diff --check`。

## 阶段退出条件

- [Demo Playable Content Substance V1](../features/demo-playable-content-substance-v1.md) 第一轮玩家可见补强落地，不能只停在规划或检查。
- [Demo Definition V1](../features/demo-definition-v1.md) 的场景、角色 / 怪物 UI、初步美术、工业模块和任务节奏缺口被重新标注并至少完成一个实质补强包。
- 未引入规格外资源、配方、设备、区域、任务链、敌人类型、完整背包、完整装备栏、死亡系统、终局菜单、结算页或发布准备流程。
- 后续再重新启动 [Demo First Playable Acceptance V1](../features/demo-first-playable-acceptance-v1.md)，由人工实机体验和自动检查共同判断是否进入试玩准备。
