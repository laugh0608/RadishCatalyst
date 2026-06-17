# Daily Start

更新时间：2026-06-17

## 用途

当提示是“根据项目规划和开发进度，今天要来做什么以推进开发”时，优先阅读本文。

本文只提供日常入口和读取顺序；阶段方向以当前活跃专题为准，每日代码范围以当前执行或下一次新建细专题为准。

## 阶段

当前为「首版 Demo 体验主干建设：动作反馈可读性第一版」。

首版 Demo 完成规格：[Demo Definition V1](../features/demo-definition-v1.md)。

当前活跃细专题：[Demo Action Feedback Readability V1](../features/demo-action-feedback-readability-v1.md)，检查并补齐玩家执行采集、清障、建造、加工、整备、战斗和核心写入后的结果文本、HUD / 地图和对象状态一致性。

最近完成细专题：[Demo Interaction Affordance V1](../features/demo-interaction-affordance-v1.md)、[Demo Combat Evacuation Recovery V1](../features/demo-combat-evacuation-recovery-v1.md)、[Demo Playable Scene Composition V1](../features/demo-playable-scene-composition-v1.md)、[Demo Playable Experience Coherence V1](../features/demo-playable-experience-coherence-v1.md) 与 [Demo Completion Outcome Readout V1](../features/demo-completion-outcome-readout-v1.md)，2026-06-17 第一包已落地。

最近完成细专题：[Demo Non-Core Scene Identity V1](../features/demo-non-core-scene-identity-v1.md) 与 [Demo Functional Transition Route Support V1](../features/demo-functional-transition-route-support-v1.md)，2026-06-16 第一包已落地。

更早完成专题按 [Feature Development Docs](../features/README.md) 索引选读；不继续给既有路线、场景、资源链、存档、主路径、工程拆分或现场阶段读法追加同类内容包。

## 最近收尾

- 早期复测、资源循环、基地行动、窗口复盘、装备与战斗反哺基地原型均已通过检查或局部复测。
- 首版 Demo 已完成范围冻结、12 区域封顶、UI baseline、核心稳定站终点链路和早期链路审计。
- 首小时引导、Demo 中段衔接、基地后勤、晶体侧路、污染边界、核心稳定站复测和整段原型呈现已完成第一轮建设。
- 2026-06-14 阶段口径复核结论：继续加厚同一条核心站归档后回访链收益递减，阶段转入角色成长与战斗第一版。

## 下一步读取顺序

1. 读 `docs/planning/current.md` 确认阶段和冻结边界。
2. 读 `docs/features/demo-definition-v1.md` 确认首版 Demo 完成规格和当前缺口。
3. 读当前活跃细专题 `docs/features/demo-action-feedback-readability-v1.md`，确认动作结果、HUD / 地图、对象状态和验收条件。
4. 只在需要确认上一个阶段边界时，读 `docs/features/demo-interaction-affordance-v1.md`。
5. 读 `docs/planning/demo-scope-and-playable-slice.md`，确认 12 区域职责表和功能 / 过渡分组。
6. 只在需要历史风险时，读取最新周志中的“风险与未完成项”和“后续事项”。
7. 按改动范围选读设计、架构和复测基线文档。

## 当前开发重点

- 当前推进动作反馈可读性第一包；检查并补齐关键动作结果、消耗 / 获得、状态写入、HUD / 地图和对象状态一致性。
- 交互可辨识度、战斗撤离恢复、可玩场景构成、整段体验连贯性和 Demo 完成成果整理第一包已落地；不继续围绕对象可交互状态、撤离恢复、区域构成、断点清单或核心稳定站写入后完成态加厚。
- 外勤回基地收益兑现、功能场景玩法、运行时承载面拆分、主路径连续性和存档状态契约第一包已落地；不继续围绕同一切面加厚。
- 非核心区域场景识别和功能 / 过渡路线支撑第一包已落地；不继续围绕同一批区域标签、路线职责、当前危险和回基地理由加厚。
- 角色成长与战斗第一版已满足退出条件；不继续围绕战术扫描、防护响应、工具校准、污染边界、遗迹外圈或核心守卫同一压力点加厚。
- 主线完成感、工业主干、核心场景识别第一版已落地；不继续围绕这些同一读法点加厚。
- 新增检查必须优先走专项文件，避免继续推高 `vertical_slice_flow_check.gd`；路线读法优先走窄职责 formatter，避免继续堆 `vertical_slice_map.gd`。
- 不继续加厚战术扫描、工业主干、污染边界后勤维护口袋或遗迹外圈同一压力点；若后续扩到第二个主动技能或装备槽位，先明确新的细专题边界。
- 不继续加厚工具打击校准或防护响应同一状态；若后续扩到新战斗收益，先明确新的细专题边界。
- 必须覆盖真实玩家路线、场景节点、HUD / 地图 / 对象反馈和自动检查；不因本轮新增存档 schema。
- 首版 Demo 未完成初步阶段的完整玩法、场景和美术前，不切到试玩准备或修 bug 阶段；真实页面 smoke 只用于对比开发效果。
- 工程上注意 `vertical_slice_flow_check.gd`、`vertical_slice_map.gd`、`prototype_hud.gd`、`interaction_prompt_formatter.gd` 和相关系统职责边界。

## 当前不做

- 不继续扩前线行动台、候选、窗口复盘、高压窗口或 `base_action_state`，除非出现 `P0` / `P1`。
- 不继续横向新增区域；首版 Demo 到 12 个区域封顶。
- 不再默认给核心站完成态追加同构回访口袋。
- 不新增随机成功率、新货币、队员、完整装备栏、完整 `loadout`、完整背包重构、联机入口或大规模美术替换。
- 不把试玩准备、修 bug 阶段、完整发布准备、大规模 polish、死亡系统、结算页、基线复核、静态审计或纯提示修补作为当前阶段目标。

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
- `docs/features/demo-action-feedback-readability-v1.md`
- `docs/features/demo-interaction-affordance-v1.md`
- 最近完成细专题按 `docs/features/README.md` 选读
- `docs/planning/demo-scope-and-playable-slice.md`

按任务选读：

- 最近完成战斗 / 工业 / 场景细专题：按 `docs/features/README.md` 选读
- 区域和首小时体验：`docs/design/onboarding-and-first-hour.md`
- 开发复测基线：`docs/design/development-retest-baselines.md`
- 代码结构和重构：`docs/architecture/code-style-and-language-practices.md`
- 存档、联机或边界：`docs/architecture/multiplayer-and-save-architecture.md`

## 验证入口

客户端改动优先执行默认检查：Windows 用 `pwsh ./scripts/check-client.ps1`，macOS / Linux / Git Bash 用 `sh ./scripts/check-client.sh`；该入口不启动 Godot。需要导入工程或运行项目自定义 GDScript 检查时，确认本机 Godot 可启动后加 `-WithGodot` / `--with-godot`。

提交前：Windows 用 `pwsh ./scripts/check-text-files.ps1`、`pwsh ./scripts/check-docs.ps1`；macOS / Linux / Git Bash 用 `./scripts/check-text-files.sh`、`./scripts/check-docs.sh`；最后执行 `git diff --check`。
