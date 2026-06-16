# Daily Start

更新时间：2026-06-16

## 用途

当提示是“根据项目规划和开发进度，今天要来做什么以推进开发”时，优先阅读本文。

本文只提供日常入口和读取顺序；阶段方向以当前活跃专题为准，每日代码范围以当前执行或下一次新建细专题为准。

## 阶段

当前为「首版 Demo 体验主干建设：功能场景玩法第一版」。

首版 Demo 完成规格：[Demo Definition V1](../features/demo-definition-v1.md)。

最近完成细专题：[Demo Functional Scene Gameplay V1](../features/demo-functional-scene-gameplay-v1.md)，2026-06-16 第一包已落地；明天先做阶段退出判断，再按最新周志决定是否切新专题。

最近完成细专题：[Demo Runtime Surface Decomposition V1](../features/demo-runtime-surface-decomposition-v1.md)、[Demo Main Path Continuity V1](../features/demo-main-path-continuity-v1.md)、[Demo Save State Contract V1](../features/demo-save-state-contract-v1.md) 与 [Demo Resource Chain State V1](../features/demo-resource-chain-state-v1.md)，2026-06-16 第一包已落地。

最近完成细专题：[Demo Non-Core Scene Identity V1](../features/demo-non-core-scene-identity-v1.md) 与 [Demo Functional Transition Route Support V1](../features/demo-functional-transition-route-support-v1.md)，2026-06-16 第一包已落地。

最近完成阶段级专题：[Demo Combat Progression V1](../features/demo-combat-progression-v1.md)，2026-06-16 判定达到阶段退出条件。

最近完成细专题：[Demo Tool Strike Calibration V1](../features/demo-tool-strike-calibration-v1.md)、[Demo Protective Response V1](../features/demo-protective-response-v1.md)、[Demo Mainline Completion V1](../features/demo-mainline-completion-v1.md)、[Demo Scene Art Foundation V1](../features/demo-scene-art-foundation-v1.md)，2026-06-15 已落地。

上一批完成细专题：[Demo Industrial Tech Spine V1](../features/demo-industrial-tech-spine-v1.md)、[Demo Character Kit V1](../features/demo-character-kit-v1.md)、[Ruin Outer Ring Module Pressure V1](../features/ruin-outer-ring-module-pressure-v1.md)、[Pollution Edge Maintenance Pressure V1](../features/pollution-edge-maintenance-pressure-v1.md)，2026-06-15 已落地。

明天先复核功能场景玩法第一包是否达到退出条件；若没有更高优先级缺口，建议建立 `Demo Field Loop Payoff V1`，把外勤对象处理结果兑现到基地加工、整备状态和下一趟外勤准备；不继续给既有路线、场景、资源链、存档、主路径、工程拆分或现场阶段读法追加同类内容包。

## 最近收尾

- 早期复测、资源循环、基地行动、窗口复盘、装备与战斗反哺基地原型均已通过检查或局部复测。
- 首版 Demo 已完成范围冻结、12 区域封顶、UI baseline、核心稳定站终点链路和早期链路审计。
- 首小时引导、Demo 中段衔接、基地后勤、晶体侧路、污染边界、核心稳定站复测和整段原型呈现已完成第一轮建设。
- 2026-06-14 阶段口径复核结论：继续加厚同一条核心站归档后回访链收益递减，阶段转入角色成长与战斗第一版。

## 下一步读取顺序

1. 读 `docs/planning/current.md` 确认阶段和冻结边界。
2. 读 `docs/features/demo-definition-v1.md` 确认首版 Demo 完成规格和当前缺口。
3. 读最近完成细专题 `docs/features/demo-functional-scene-gameplay-v1.md`，确认第一包退出条件和后续不再加厚的边界。
4. 读最近完成细专题 `docs/features/demo-runtime-surface-decomposition-v1.md`，确认不要继续加厚工程拆分同一检查包。
5. 读 `docs/planning/demo-scope-and-playable-slice.md`，确认 12 区域职责表和功能 / 过渡分组。
6. 只在需要确认完成边界时，读最近完成的战斗、工业、场景和主线细专题。
7. 只在需要历史风险时，读取最新周志中的“风险与未完成项”和“后续事项”。
8. 按改动范围选读设计、架构和复测基线文档。

## 当前开发重点

- 当前先做 Demo 功能场景玩法阶段退出判断；若通过，下一步建议切到外勤回基地收益兑现，而不是继续追加同类现场阶段提示。
- 运行时承载面拆分第一包已落地；后续不继续围绕同一检查承载面加厚。
- 主路径连续性第一包已落地：`S0` 到 `S21` 的代表性基线、核心稳定站终点运行路径、HUD / 地图读法和 `slice_01_complete` 已有专项覆盖。
- 存档状态契约第一包已落地；不继续围绕同一保存读取切面加厚。
- 资源链状态第一包已落地：核心资源 / 产物已能在 HUD、设备面板、加工结果和状态序列化中读出链路位置。
- 非核心区域场景识别第一包已落地，不继续围绕同一批区域标签和地貌 / 设施身份加厚。
- 功能 / 过渡路线支撑第一包已落地，不继续围绕同一套路线职责、当前危险和回基地理由加厚。
- 角色成长与战斗第一版已满足退出条件；不继续围绕战术扫描、防护响应、工具校准、污染边界、遗迹外圈或核心守卫同一压力点加厚。
- 主线完成感、工业主干、核心场景识别第一版已落地；不继续围绕这些同一读法点加厚。
- 新增检查必须优先走专项文件，避免继续推高 `vertical_slice_flow_check.gd`；路线读法优先走窄职责 formatter，避免继续堆 `vertical_slice_map.gd`。
- 不继续加厚战术扫描、工业主干、污染边界后勤维护口袋或遗迹外圈同一压力点；若后续扩到第二个主动技能或装备槽位，先明确新的细专题边界。
- 不继续加厚工具打击校准或防护响应同一状态；若后续扩到新战斗收益，先明确新的细专题边界。
- 必须覆盖真实玩家路线、场景节点、HUD / 地图 / 对象反馈、关键状态或存档边界和自动检查。
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
- `docs/features/demo-functional-scene-gameplay-v1.md`
- `docs/features/demo-runtime-surface-decomposition-v1.md`
- `docs/features/demo-main-path-continuity-v1.md`
- `docs/features/demo-save-state-contract-v1.md`
- `docs/features/demo-resource-chain-state-v1.md`
- `docs/features/demo-non-core-scene-identity-v1.md`
- `docs/features/demo-functional-transition-route-support-v1.md`
- `docs/features/demo-combat-progression-v1.md`
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
