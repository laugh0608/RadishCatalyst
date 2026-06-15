# Daily Start

更新时间：2026-06-15

## 用途

当提示是“根据项目规划和开发进度，今天要来做什么以推进开发”时，优先阅读本文。

本文只提供日常入口和读取顺序；阶段方向以当前活跃专题为准，每日代码范围以当前执行子专题为准。

## 阶段

当前为「首版 Demo 体验主干建设：角色成长与战斗第一版」。

首版 Demo 完成规格：[Demo Definition V1](../features/demo-definition-v1.md)。

当前活跃专题：[Demo Combat Progression V1](../features/demo-combat-progression-v1.md)。

当前执行细专题：[Ruin Outer Ring Module Pressure V1](../features/ruin-outer-ring-module-pressure-v1.md)。

最近完成细专题：[Pollution Edge Maintenance Pressure V1](../features/pollution-edge-maintenance-pressure-v1.md)，2026-06-15 已落地。

重点是让基地制造和出发整备带来明确战斗 / 成长差异，不再继续给既有回访链追加同类内容包，也不把基线复核写成下一步主线。

## 最近收尾

- 早期复测、资源循环、基地行动、窗口复盘、装备与战斗反哺基地原型均已通过检查或局部复测。
- 首版 Demo 已完成范围冻结、12 区域封顶、UI baseline、核心稳定站终点链路和早期链路审计。
- 首小时引导、Demo 中段衔接、基地后勤、晶体侧路、污染边界、核心稳定站复测和整段原型呈现已完成第一轮建设。
- 2026-06-14 阶段口径复核结论：继续加厚同一条核心站归档后回访链收益递减，阶段转入角色成长与战斗第一版。

## 下一步读取顺序

1. 读 `docs/planning/current.md` 确认阶段和冻结边界。
2. 读 `docs/features/demo-definition-v1.md` 确认首版 Demo 完成规格和当前缺口。
3. 读当前活跃专题 `docs/features/demo-combat-progression-v1.md`，确认阶段方向和冻结边界。
4. 读当前执行细专题 `docs/features/ruin-outer-ring-module-pressure-v1.md`，确认本轮玩家路径、状态边界和验收条件。
5. 只在需要确认已落地边界时，读最近完成细专题 `docs/features/pollution-edge-maintenance-pressure-v1.md`。
6. 只在需要历史风险时，读取最新周志中的“风险与未完成项”和“下周建议”。
7. 按改动范围选读设计、架构和复测基线文档。

## 当前开发重点

- 只推进当前活跃专题中的首版 demo 级角色成长 / 战斗差异。
- 本轮执行遗迹外圈模块承压差异，让基础过滤模块、模块校准或后勤维护状态影响遗迹外圈压力读法。
- 不继续加厚污染边界后勤维护口袋；若后续扩到主动技能或装备槽位，先建立角色技能 / 装备模块细专题。
- 必须覆盖真实玩家操作路径、HUD / 对象反馈、战斗结果、存档状态和自动检查。
- 首版 Demo 未完成初步阶段的完整玩法、场景和美术前，不切到试玩准备或修 bug 阶段；真实页面 smoke 只用于对比开发效果。
- 工程上注意 `vertical_slice_flow_check.gd`、`vertical_slice_map.gd`、`prototype_hud.gd`、`interaction_prompt_formatter.gd` 和相关系统职责边界。

## 当前不做

- 不继续扩前线行动台、候选、窗口复盘、高压窗口或 `base_action_state`，除非出现 `P0` / `P1`。
- 不继续横向新增区域；首版 Demo 到 12 个区域封顶。
- 不再默认给核心站完成态追加同构回访口袋。
- 不新增随机成功率、新货币、队员、完整装备栏、完整 `loadout`、完整背包重构、联机入口或大规模美术替换。
- 不把试玩准备、修 bug 阶段、完整发布准备、大规模 polish、基线复核、静态审计或纯提示修补作为当前阶段目标。

## 阻塞标准

只让这些问题阻塞阶段：

- 崩溃
- 主线卡死
- 坏档
- 任务无法完成
- 关键资源断档
- UI 完全无法判断下一步

其他问题进入 backlog 或后续 polish。

## 必读与选读

日常推进必读：

- `docs/planning/current.md`
- `docs/features/demo-definition-v1.md`
- `docs/features/demo-combat-progression-v1.md`
- `docs/features/ruin-outer-ring-module-pressure-v1.md`
- `docs/features/pollution-edge-maintenance-pressure-v1.md`

按任务选读：

- Demo 范围与 UI baseline：`docs/planning/demo-scope-and-playable-slice.md`
- 区域和首小时体验：`docs/design/onboarding-and-first-hour.md`
- 开发复测基线：`docs/design/development-retest-baselines.md`
- 代码结构和重构：`docs/architecture/code-style-and-language-practices.md`
- 存档、联机或边界：`docs/architecture/multiplayer-and-save-architecture.md`

## 验证入口

客户端改动优先执行默认检查：Windows 用 `pwsh ./scripts/check-client.ps1`，macOS / Linux / Git Bash 用 `sh ./scripts/check-client.sh`；该入口不启动 Godot。需要导入工程或运行项目自定义 GDScript 检查时，确认本机 Godot 可启动后加 `-WithGodot` / `--with-godot`。

提交前：Windows 用 `pwsh ./scripts/check-text-files.ps1`、`pwsh ./scripts/check-docs.ps1`；macOS / Linux / Git Bash 用 `./scripts/check-text-files.sh`、`./scripts/check-docs.sh`；最后执行 `git diff --check`。
