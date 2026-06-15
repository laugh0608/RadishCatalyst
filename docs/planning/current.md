# Current Plan

更新时间：2026-06-15

## 入口约束

本文是新会话的阶段入口，只保留当前阶段、当前活跃专题、边界、验证入口和退出条件。首版 Demo 完成规格以 [Demo Definition V1](../features/demo-definition-v1.md) 为准，具体开发范围以当前活跃专题、当前执行细专题和最近完成边界为准：

- [Demo Combat Progression V1](../features/demo-combat-progression-v1.md)
- [Ruin Outer Ring Module Pressure V1](../features/ruin-outer-ring-module-pressure-v1.md)

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

当前阶段：

```text
首版 Demo 体验主干建设：角色成长与战斗第一版
```

当前推进口径从路线可读性与同类内容追加，转向补足玩家继续玩的体验主干：基地制造和出发整备必须带来明确战斗 / 成长差异。

## 当前主线

当前只推进 [Demo Combat Progression V1](../features/demo-combat-progression-v1.md)，它覆盖 [Demo Definition V1](../features/demo-definition-v1.md) 中的角色成长、装备 / 模块和战斗压力规格。当前执行细专题是 [Ruin Outer Ring Module Pressure V1](../features/ruin-outer-ring-module-pressure-v1.md)，用于让模块状态在遗迹外圈读出承压差异。最近完成细专题 [Pollution Edge Maintenance Pressure V1](../features/pollution-edge-maintenance-pressure-v1.md) 已在 2026-06-15 落地，后续不继续加厚污染边界口袋。

下一次代码开发应从 Demo 完成规格、阶段专题和执行子专题的“本轮范围”“验收条件”选择一个可验证开发包，不再直接从周志条目、历史复盘或局部提示问题派生主线任务。

首版 Demo 未完成初步阶段的完整玩法、场景和美术前，不进入试玩准备或修 bug 阶段。真实页面 smoke 可以用于对比开发效果，但不能替代功能、场景和玩法专题推进。

## 区域策略

- 首版 Demo 继续按 12 区域封顶。
- 4 个核心区域、4 个功能区域、4 个过渡区域不再平均加厚。
- 只修阻塞理解、主线连续性、功能闭合或场景表达的断点。

## UI 策略

UI 和场景表现已完成第一轮原型呈现支撑。当前 UI 改动只服务当前活跃专题：制造 / 整备前后状态、模块收益、战斗承压变化和回基地价值要自然出现在 HUD、对象反馈和战斗日志里。

不做完整菜单、设置页、背包大重构、完整装备栏、动画过场或大规模美术替换。

## 冻结与放宽

继续冻结：

- 前线行动台、候选、窗口复盘、高压窗口和 `base_action_state` 保持冻结，只修 `P0` / `P1`。
- 不新增第 13 区域，不平均扩 12 个区域，不继续给核心站完成态追加同构回访口袋。
- 不新增随机成功率、新货币、队员、完整装备栏、完整 `loadout`、联机入口或完整长期成长系统。
- 不把试玩准备、修 bug 阶段、发布准备或大规模 polish 作为当前阶段目标。
- 不迁移稳定数据 ID；旧 ID 先作为存档、任务和数据兼容层保留。

允许推进：

- 当前活跃专题内的首版 demo 级角色成长与战斗差异。
- 新建或切换到当前阶段内的基建设备、装备 / 模块、功能玩法或场景压力细专题。
- 为该差异调整 UI、场景提示、承压计算、路线节奏和自动检查。
- 为维护工程边界拆分检查脚本、地图脚本、HUD 脚本、提示 formatter 或系统职责。

## 节奏规则

个人开发阶段只做足以判断方向的完成度。一个阶段达到退出条件后，必须及时进入下一阶段；不允许因为 `P2` / `P3` 细节、局部读法、文案密度或状态字段洁癖无限打磨。

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

- [Demo Combat Progression V1](../features/demo-combat-progression-v1.md) 下至少 1 个成长或战斗差异通过真实玩家操作获得，并能改变污染、遗迹或核心守卫中的承压 / 输出 / 防护读法。
- 该差异覆盖 HUD / 对象反馈、战斗结果、存档状态和自动检查；玩家能读懂回基地整备为什么有价值。
- 未引入完整装备栏、完整 `loadout`、新资源、新任务链、第 13 区域、行动台或高压窗口扩展。
- 接近 1500 行硬上限的检查 / 地图 / HUD / 提示脚本已有拆分方案或已完成必要拆分。
