# Feature Development Docs

更新时间：2026-06-19

## 用途

本目录存放玩家可感知功能目标的设计与开发文档。阶段入口只决定当前主线，具体范围、边界、玩家路径、验收和检查放在这里。

当一次开发会同时影响玩法、场景、HUD、任务、存档、运行时状态或自动检查时，应优先建立或更新对应专题文档，再开始实现。

## 使用规则

- `docs/planning/current.md` 只保留当前阶段、当前活跃专题、阶段边界和退出条件。
- `docs/planning/daily-start.md` 只保留日常推进入口和读取顺序。
- `docs/devlogs/` 只记录已经发生的推进、决策、验证和风险，不作为具体功能范围的真相源。
- 专题文档必须说明玩家价值、整体规划关系、已有基础、本轮范围、当前不做、真实操作路径、状态 / 存档 / HUD / 检查要求和验收条件。
- 不为单个文案调整、局部修错或一次性讨论创建专题文档；专题应对应一个玩家可感知功能目标或阶段开发包。
- 活跃专题接近 220 行时，优先拆成总览与子专题，或把历史过程移入周志 / 参考 / 归档。

## 专题层级

- 阶段级专题用于说明能力域方向、冻结边界和跨包验收，例如角色成长与战斗第一版。
- 可执行细专题用于定义一个基建设备、装备 / 模块、功能玩法、场景压力或工程边界包，是每日代码开发的直接范围来源。
- 当前或最近执行细专题应由阶段入口或阶段级专题显式链接；完成后再切换到下一个细专题。

## 当前与最近专题

- [Demo Definition V1](demo-definition-v1.md)：首版 Demo 完成规格表，后续专题必须映射到其中的未完成规格项。
- [Demo Playable Content Substance V1](demo-playable-content-substance-v1.md)：当前活跃专题，覆盖首版 Demo 场景、角色 / 怪物 UI、初步美术、工业基建和任务节奏的玩家可见实质补强。
- [Demo Core Scene Playable Space V1](demo-core-scene-playable-space-v1.md)：最近完成细专题，覆盖四个核心区的地表、路线、对象锚点、承压区和回收口袋。
- [Demo First Playable Acceptance V1](demo-first-playable-acceptance-v1.md)：阶段验收专题暂缓，自动检查通过不足以证明首版 Demo 已达到可试玩候选质量。
- [Demo Device Panel Operation Readability V1](demo-device-panel-operation-readability-v1.md)：最近完成细专题，覆盖前哨核心、基础反应器、污染过滤器和出发整备台的操作意图、缺料方向、产出去向和完成后路线。
- [Demo Core Approach Handoff Playability V1](demo-core-approach-handoff-playability-v1.md)：最近完成细专题，覆盖锁相框架 -> 锚定桥 -> 核心稳定站入口的终点前承接、对象落点、回基地理由和自动检查。
- [Demo Wind Corridor Transition Playability V1](demo-wind-corridor-transition-playability-v1.md)：最近完成细专题，覆盖碎晶沟谷 -> 风蚀管廊 -> 锁相框架入口的过渡路径、资源 / 设施落点、回基地理由和自动检查。
- [Demo Midfield Route Playability V1](demo-midfield-route-playability-v1.md)：最近完成细专题，覆盖回声台地 -> 盐壳浅滩 -> 碎晶沟谷的入口边界、资源 / 设施落点、回基地理由和自动检查。
- [Demo Map Surface Decomposition V1](demo-map-surface-decomposition-v1.md)：最近完成细专题，已拆分接近硬上限的地图区域 / gate 承载面，支撑后续场景和路线推进。
- [Demo Interaction Prompt Surface Decomposition V1](demo-interaction-prompt-surface-decomposition-v1.md)：最近完成细专题，已拆分加工设备交互提示承载面，降低大文件行数风险并承接基地再进入读法。
- [Demo Route Return And Base Reentry Readability V1](demo-route-return-and-base-reentry-readability-v1.md)：最近完成细专题，覆盖外勤结果回基地后的处理设备、收益变化、下一次出发入口和自动检查。
- [Demo Functional Transition Spatial Playability V1](demo-functional-transition-spatial-playability-v1.md)：最近完成细专题，覆盖封锁遗迹到裂相脊代表路径的入口、可走边界、危险 / 资源 / 设施落点、回基地理由和自动检查。
- [Demo Functional Scene Gameplay Density V1](demo-functional-scene-gameplay-density-v1.md)：最近完成细专题，覆盖锁相框架和锚定桥代表小循环的操作密度、HUD / 对象反馈和自动检查。
- [Demo Supply Pressure Pacing V1](demo-supply-pressure-pacing-v1.md)：最近完成细专题，覆盖现有修复凝胶 / 抗污染药剂在制作、消耗、补回和关键压力节点中的真实价值。
- [Demo Quick Slot Supply Readability V1](demo-quick-slot-supply-readability-v1.md)：最近完成细专题，已覆盖现有修复凝胶 / 抗污染药剂在 HUD 快捷栏、补给反馈和失败恢复路线中的可用、暂存和缺补给读法。
- [Demo Prototype Visual Pass V1](demo-prototype-visual-pass-v1.md)：最近完成细专题，已推进原型视觉优先级、核心区场地尺度和首小时目标链场景导引，覆盖现有 12 区原型画面的色彩层级、前后景分离、危险 / 资源 / 设施视觉权重和 HUD / 地图 / 对象状态互证。
- [Demo Action Blocker Recovery V1](demo-action-blocker-recovery-v1.md)：最近完成细专题，2026-06-17 第一包已落地并通过退出判断，覆盖关键动作被前置、缺料、缺补给、敌人或设备状态拦住时的失败反馈、HUD / 地图、对象状态和恢复路线。
- [Demo Action Feedback Readability V1](demo-action-feedback-readability-v1.md)：最近完成细专题，覆盖关键动作执行后的结果文本、HUD / 地图、对象状态和下一步读法。
- [Demo Interaction Affordance V1](demo-interaction-affordance-v1.md)：最近完成细专题，覆盖对象可交互、已处理、缺条件、被阻挡或危险仍在时的画面、焦点标签、HUD / 地图和对象提示一致性。
- [Demo Combat Evacuation Recovery V1](demo-combat-evacuation-recovery-v1.md)：最近完成细专题，覆盖外勤承压后的自动撤回前哨、恢复补给、HUD / 地图 / 对象反馈、状态 / 存档和自动检查断点。
- [Demo Playable Scene Composition V1](demo-playable-scene-composition-v1.md)：最近完成细专题，覆盖 12 个既有区域的画面构成、关键对象落点、HUD / 地图读法和自动检查断点。
- [Demo Playable Experience Coherence V1](demo-playable-experience-coherence-v1.md)：最近完成细专题，覆盖从新档到 Demo 完成后回前哨整理的场景、HUD、地图、对象反馈、状态 / 存档和自动检查断点。
- [Demo Completion Outcome Readout V1](demo-completion-outcome-readout-v1.md)：最近完成细专题，覆盖核心稳定站写入后的主线完成、补给收益、整备收益、守卫战记录和复测方向读法。
- [Demo Endpoint Readiness V1](demo-endpoint-readiness-v1.md)：最近完成细专题，覆盖核心稳定站写入前的主线、补给、整备、守卫战准备和写入准备读法。
- [Demo Field Loop Payoff V1](demo-field-loop-payoff-v1.md)：最近完成细专题，覆盖外勤对象处理结果回到基地加工、整备状态和下一趟外勤准备。
- [Demo Functional Scene Gameplay V1](demo-functional-scene-gameplay-v1.md)：最近完成细专题，2026-06-16 第一包已落地，覆盖功能 / 过渡区代表性对象处理后的现场阶段、状态反馈和回基地处理理由。
- [Demo Runtime Surface Decomposition V1](demo-runtime-surface-decomposition-v1.md)：最近完成细专题，覆盖主路径连续性第一包落地后的运行时检查承载面拆分。
- [Demo Main Path Continuity V1](demo-main-path-continuity-v1.md)：最近完成细专题，覆盖 `S0` 到 `S21` 和核心稳定站终点完成反馈之间的主路径连续性。
- [Demo Save State Contract V1](demo-save-state-contract-v1.md)：最近完成细专题，覆盖 Demo 主路径世界、角色、库存、建筑、任务、区域、敌人和关键整备 / 资源链状态保存读取与校验。
- [Demo Resource Chain State V1](demo-resource-chain-state-v1.md)：最近完成细专题，2026-06-16 第一包已落地，覆盖核心资源 / 产物的链路状态、HUD / 设备 / 加工反馈和状态序列化检查。
- [Demo Non-Core Scene Identity V1](demo-non-core-scene-identity-v1.md)：最近完成细专题，2026-06-16 第一包已落地，覆盖 4 个功能区和 4 个过渡区的场景身份、视觉标识、HUD / 对象反馈和专项检查。
- [Demo Functional Transition Route Support V1](demo-functional-transition-route-support-v1.md)：最近完成细专题，已覆盖 4 个功能区和 4 个过渡区的路线支撑、当前危险、回基地理由和专项检查。
- [Demo Combat Progression V1](demo-combat-progression-v1.md)：最近完成阶段级专题，已完成首版 Demo 角色成长与战斗第一版。
- [Demo Tool Strike Calibration V1](demo-tool-strike-calibration-v1.md)：最近完成细专题，已把基础多用工具、基础零件和出发整备台收束成一次可读战斗输出整备。
- [Demo Protective Response V1](demo-protective-response-v1.md)：最近完成细专题，已把基础防护服、基础过滤模块和前哨补给收束成一次可读防护响应。
- [Demo Scene Art Foundation V1](demo-scene-art-foundation-v1.md)：最近完成细专题，已建立核心区场景与初步美术识别第一包。
- [Demo Mainline Completion V1](demo-mainline-completion-v1.md)：最近完成细专题，已收束核心稳定站写入后的 Demo 主线完成读法。
- [Demo Industrial Tech Spine V1](demo-industrial-tech-spine-v1.md)：最近完成细专题，已收束基础反应器、污染过滤器和出发整备台之间的轻量工艺主干读法。
- [Demo Character Kit V1](demo-character-kit-v1.md)：最近完成细专题，已验证 `C` 战术扫描主动工具动作。
- [Ruin Outer Ring Module Pressure V1](ruin-outer-ring-module-pressure-v1.md)：最近完成细专题，已验证模块状态在遗迹外圈形成承压差异。
- [Pollution Edge Maintenance Pressure V1](pollution-edge-maintenance-pressure-v1.md)：最近完成细专题，已验证后勤维护在污染边界形成第二个承压差异。

## 专题文档推荐结构

1. 用途
2. 玩家价值
3. 与整体规划的关系
4. 当前已有基础
5. 本轮范围
6. 当前不做
7. 玩家操作路径
8. 运行时、存档与数据边界
9. HUD / 场景 / 对象反馈
10. 验收条件
11. 验证计划
12. 风险与后续决策
