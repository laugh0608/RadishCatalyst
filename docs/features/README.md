# Feature Development Docs

更新时间：2026-06-30

## 用途

本目录存放玩家功能目标文档。阶段入口定主线，具体范围、路径、验收和检查放在这里。

当一次开发会同时影响玩法、场景、HUD、任务、存档、运行时状态或自动检查时，先建立或更新对应专题。

## 使用规则

- `docs/planning/current.md` 只保留当前阶段、当前活跃专题、阶段边界和退出条件。
- `docs/planning/daily-start.md` 只保留日常推进入口和读取顺序。
- `docs/devlogs/` 只记录已经发生的推进、决策、验证和风险，不作为具体功能范围的真相源。
- 专题文档必须说明玩家价值、范围、当前不做、真实操作路径、状态 / 存档 / HUD / 检查和验收。
- 不为单个文案调整、局部修错或一次性讨论创建专题文档；专题应对应一个玩家可感知功能目标或阶段开发包。
- 活跃专题接近 220 行时，优先拆成总览与子专题，或把历史过程移入周志 / 参考 / 归档。

## 专题层级

- 阶段级专题用于说明能力域方向、冻结边界和跨包验收，例如角色成长与战斗第一版。
- 可执行细专题用于定义一个基建设备、装备 / 模块、功能玩法、场景压力或工程边界包，是每日代码开发的直接范围来源。
- 当前或最近细专题应由阶段入口链接；完成后再切换。

## 当前与最近专题

- [Demo Definition V1](demo-definition-v1.md)：Demo 规格表。
- [Demo First Playable Slice Assembly V1](demo-first-playable-slice-assembly-v1.md)：当前活跃专题，覆盖纵切装配。
- [Demo Playable UI And Art Pass V1](demo-playable-ui-and-art-pass-v1.md)：当前执行线，覆盖画面 / HUD。
- [Demo Base First Screen Scene V2](demo-base-first-screen-scene-v2.md)：当前 UI / Art 细专题，独立基地首屏。
- [Demo Playable Scene Rebuild V1](demo-playable-scene-rebuild-v1.md)：最近暂停，停止截图微调。
- [Demo First Screen Assetized Scene V1](demo-first-screen-assetized-scene-v1.md)：UI / Art 细专题，覆盖首屏资产化。
- [Demo Crystal Workface Assetized Scene V1](demo-crystal-workface-assetized-scene-v1.md)：UI / Art 细专题，晶体资产化。
- [Demo Base Handoff Assetized Scene V1](demo-base-handoff-assetized-scene-v1.md)：最近暂停，基地交接小工作面。
- [Demo Core Loop Playable V1](demo-core-loop-playable-v1.md)：当前执行线，覆盖核心循环接力。
- [Demo Narrative Beats V1](demo-narrative-beats-v1.md)：当前执行线，覆盖 Demo 叙事节拍。
- [Demo Industrial Base Visual And Scene V1](demo-industrial-base-visual-and-scene-v1.md)：最近活跃视觉专题，未完成项并入 UI / Art pass。
- [Demo Playable Content Substance V1](demo-playable-content-substance-v1.md)：最近完成口径修正，确认自动检查不能替代可试玩画面。
- [Demo Scene Device Pressure Staging V1](demo-scene-device-pressure-staging-v1.md)：暂缓，后续若启用须服务工业基地视觉。
- [Demo Field Task Differentiation V1](demo-field-task-differentiation-v1.md)：最近完成，覆盖任务差异。
- [Demo Initial Art Identity V1](demo-initial-art-identity-v1.md)：最近完成，覆盖现场身份。
- [Demo Industrial Module Task Rhythm V1](demo-industrial-module-task-rhythm-v1.md)：最近完成，覆盖 5 个核心模块职责。
- [Demo Core Scene Playable Space V1](demo-core-scene-playable-space-v1.md)：最近完成，覆盖核心区空间角色。
- [Demo First Playable Acceptance V1](demo-first-playable-acceptance-v1.md)：阶段验收专题暂缓。
- [Demo Device Panel Operation Readability V1](demo-device-panel-operation-readability-v1.md)：最近完成，覆盖设备面板读法。
- [Demo Core Approach Handoff Playability V1](demo-core-approach-handoff-playability-v1.md)：最近完成，覆盖终点前承接。
- [Demo Wind Corridor Transition Playability V1](demo-wind-corridor-transition-playability-v1.md)：最近完成，覆盖风蚀过渡路径。
- [Demo Midfield Route Playability V1](demo-midfield-route-playability-v1.md)：最近完成，覆盖中段入口边界。
- [Demo Map Surface Decomposition V1](demo-map-surface-decomposition-v1.md)：最近完成，拆分地图区域 / gate 承载面。
- [Demo Interaction Prompt Surface Decomposition V1](demo-interaction-prompt-surface-decomposition-v1.md)：最近完成，拆分加工设备交互提示承载面。
- [Demo Route Return And Base Reentry Readability V1](demo-route-return-and-base-reentry-readability-v1.md)：最近完成，覆盖外勤回基地处理入口。
- [Demo Functional Transition Spatial Playability V1](demo-functional-transition-spatial-playability-v1.md)：最近完成，覆盖功能 / 过渡代表路径空间。
- [Demo Functional Scene Gameplay Density V1](demo-functional-scene-gameplay-density-v1.md)：最近完成，覆盖代表小循环操作密度。
- [Demo Supply Pressure Pacing V1](demo-supply-pressure-pacing-v1.md)：最近完成，覆盖补给制作、消耗和补回价值。
- [Demo Quick Slot Supply Readability V1](demo-quick-slot-supply-readability-v1.md)：最近完成，覆盖快捷补给 HUD 读法。
- [Demo Prototype Visual Pass V1](demo-prototype-visual-pass-v1.md)：最近完成，覆盖原型视觉优先级和场地尺度。
- [Demo Action Blocker Recovery V1](demo-action-blocker-recovery-v1.md)：最近完成，覆盖关键动作受阻后的恢复路线。
- [Demo Action Feedback Readability V1](demo-action-feedback-readability-v1.md)：最近完成，覆盖关键动作结果读法。
- [Demo Interaction Affordance V1](demo-interaction-affordance-v1.md)：最近完成，覆盖对象交互状态一致性。
- [Demo Combat Evacuation Recovery V1](demo-combat-evacuation-recovery-v1.md)：最近完成，覆盖外勤承压撤回与恢复。
- [Demo Playable Scene Composition V1](demo-playable-scene-composition-v1.md)：最近完成，覆盖 12 区画面构成。
- [Demo Playable Experience Coherence V1](demo-playable-experience-coherence-v1.md)：最近完成，覆盖整段体验断点检查。
- [Demo Completion Outcome Readout V1](demo-completion-outcome-readout-v1.md)：最近完成，覆盖核心写入后成果读法。
- [Demo Endpoint Readiness V1](demo-endpoint-readiness-v1.md)：最近完成，覆盖终点前综合准备。
- [Demo Field Loop Payoff V1](demo-field-loop-payoff-v1.md)：最近完成，覆盖外勤结果回基地兑现。
- [Demo Functional Scene Gameplay V1](demo-functional-scene-gameplay-v1.md)：最近完成，覆盖功能 / 过渡区对象处理。
- [Demo Runtime Surface Decomposition V1](demo-runtime-surface-decomposition-v1.md)：最近完成，拆分运行时检查承载面。
- [Demo Main Path Continuity V1](demo-main-path-continuity-v1.md)：最近完成，覆盖 `S0` 到 `S21` 主路径连续性。
- [Demo Save State Contract V1](demo-save-state-contract-v1.md)：最近完成，覆盖 Demo 主路径状态保存读取。
- [Demo Resource Chain State V1](demo-resource-chain-state-v1.md)：最近完成，覆盖资源链状态与序列化检查。
- [Demo Non-Core Scene Identity V1](demo-non-core-scene-identity-v1.md)：最近完成，覆盖功能 / 过渡区场景身份。
- [Demo Functional Transition Route Support V1](demo-functional-transition-route-support-v1.md)：最近完成，覆盖功能 / 过渡区路线支撑。
- [Demo Combat Progression V1](demo-combat-progression-v1.md)：最近完成阶段级专题，已完成首版 Demo 角色成长与战斗第一版。
- [Demo Tool Strike Calibration V1](demo-tool-strike-calibration-v1.md)：最近完成细专题，已把基础多用工具、基础零件和出发整备台收束成一次可读战斗输出整备。
- [Demo Protective Response V1](demo-protective-response-v1.md)：最近完成细专题，已把基础防护服、基础过滤模块和前哨补给收束成一次可读防护响应。
- [Demo Scene Art Foundation V1](demo-scene-art-foundation-v1.md)：最近完成细专题，已建立核心区场景与初步美术识别第一包。
- [Demo Mainline Completion V1](demo-mainline-completion-v1.md)：最近完成细专题，已收束核心稳定站写入后的 Demo 主线完成读法。
- [Demo Industrial Tech Spine V1](demo-industrial-tech-spine-v1.md)：最近完成细专题，已收束基础反应器、污染过滤器和出发整备台之间的轻量工艺主干读法。
- [Demo Character Kit V1](demo-character-kit-v1.md)：最近完成细专题，已验证 `C` 战术扫描主动工具动作。
- [Ruin Outer Ring Module Pressure V1](ruin-outer-ring-module-pressure-v1.md)：最近完成细专题，已验证模块状态在遗迹外圈形成承压差异。
- [Pollution Edge Maintenance Pressure V1](pollution-edge-maintenance-pressure-v1.md)：最近完成细专题，已验证后勤维护在污染边界形成第二个承压差异。
