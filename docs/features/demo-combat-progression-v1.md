# Demo Combat Progression V1

更新时间：2026-06-15

## 用途

本文是当前阶段「首版 Demo 体验主干建设：角色成长与战斗第一版」的阶段级专题文档，负责说明方向、边界和验收口径。

每日代码开发应从本文下挂的可执行细专题派生，不再只从本文件的大方向描述直接开工。最近完成细专题包括 [Demo Mainline Completion V1](demo-mainline-completion-v1.md)、[Demo Scene Art Foundation V1](demo-scene-art-foundation-v1.md)、[Demo Industrial Tech Spine V1](demo-industrial-tech-spine-v1.md)、[Demo Character Kit V1](demo-character-kit-v1.md)、[Ruin Outer Ring Module Pressure V1](ruin-outer-ring-module-pressure-v1.md) 和 [Pollution Edge Maintenance Pressure V1](pollution-edge-maintenance-pressure-v1.md)。

## 玩家价值

玩家从外勤带回材料、回基地制造或整备后，下一趟外勤应能感到承压、输出或防护读法发生变化。目标不是建立完整长期成长系统，而是在首版 demo 内证明“基地整备会改变外勤处理危险的方式”。

## 与整体规划的关系

- 服务长期核心：“基地服务冒险，冒险反哺基地”。
- 覆盖 `docs/features/demo-definition-v1.md` 中的角色成长、装备 / 模块、战斗压力和 UI / 存档 / 检查规格。
- 承接已完成的基地后勤、出发整备台、污染边界、晶体侧路和核心稳定站复测内容。
- 不横向扩 12 区域外的新空间，不把 Demo 主线改成装备收集或长期养成。
- 和 `docs/design/character-progression-and-equipment.md`、`docs/design/combat-and-interaction-prototype.md` 保持方向一致，但只取首版 demo 可验证的第一层。

## 当前已有基础

- 资源与加工：`item.crystal_ore`、`item.salvage_scrap`、`recipe.process_crystal_ore`、`building.basic_reactor`。
- 整备与状态：`building.field_outfitting_station`、`FieldOutfittingRuntime`、基础过滤模块、模块校准状态、核心归档维护状态。
- 战斗与反馈：`EnemyCounterattackRuntime`、`DepartureReadinessFormatter`、`CoreGuardAftermathFormatter`。
- 场景与读法：基地后勤区、外勤出发口、污染边界、遗迹外圈和核心稳定站已有对象反馈、HUD / 地图目标和自动检查基础。

## 专题层级

本文只管理角色成长与战斗差异的阶段口径。下挂细专题负责单个设备、模块、场景或玩法包的真实开发范围。

- 最近完成：[Ruin Outer Ring Module Pressure V1](ruin-outer-ring-module-pressure-v1.md)，已让基础过滤模块、模块校准或后勤维护状态在遗迹外圈读出承压差异。
- 最近完成：[Pollution Edge Maintenance Pressure V1](pollution-edge-maintenance-pressure-v1.md)，已让后勤维护在污染边界读出第二个承压差异。
- 最近完成：[Demo Character Kit V1](demo-character-kit-v1.md)，已让基础多用工具接入 `C` 战术扫描，主动标记敌人或污染采集点并降低下一次承压。
- 最近完成：[Demo Industrial Tech Spine V1](demo-industrial-tech-spine-v1.md)，已收束基础反应器、污染过滤器和出发整备台之间的工艺主干读法。
- 最近完成：[Demo Mainline Completion V1](demo-mainline-completion-v1.md)，已收束核心稳定站写入完成后的 Demo 主线完成读法。
- 已完成第一包：核心站后勤维护复测承压差异，记录在本文“已落地第一包”。
- 后续若扩到技能、装备模块或单独场景，应先建立对应细专题，再写代码。

## 本轮范围

优先落地 1 到 2 个首版 demo 级可感知差异：

- 一个由基地制造或出发整备台触发的角色成长 / 防护 / 战斗收益。
- 一个能在污染、遗迹或核心守卫压力中读出的结果差异。
- HUD、对象反馈、战斗反馈、存档状态和自动检查必须同步覆盖。

第一轮建议从“基础过滤模块 / 后勤维护状态改变污染或核心守卫承压读法”开始，因为它复用现有材料、整备台、运行时和战斗承压路径。

## 已落地第一包

- 2026-06-14 已完成“后勤维护复测承压差异”：玩家回收晶体侧路补料后，用 `recipe.process_crystal_ore` 在 `building.basic_reactor` 加工基础零件，再到 `building.field_outfitting_station` 确认后勤维护。
- `FieldOutfittingRuntime` 将后勤维护状态持久写在整备台对象上；HUD、整备台、出发口和地图目标会读出“模块归档 / 后勤维护”和下一趟核心站复测方向。
- 后勤维护会降低核心站后勤复测污染采集和反击承压，`EnemyCounterattackRuntime` 的战斗反馈会说明本次损耗来自整备台维护收益；自动检查覆盖状态往返、HUD / 对象反馈和确认前后损耗差异。

## 下一包建议

- 角色工具动作、工业主干读法、核心场景识别和主线完成感第一包均已落地。
- 后续优先从第二个清晰角色套件动作、装备状态或仍未覆盖的 Demo 完成规格缺口中选择，不继续堆同一战术扫描倍率或同一完成态提示。

## 当前不做

- 不新增第 13 区域。
- 不扩前线行动台、候选、窗口复盘、高压窗口或 `base_action_state`。
- 不新增随机成功率、新货币、队员、完整装备栏、完整 `loadout` 或完整长期成长系统。
- 不新增同类资源、同类敌人或新任务链来支撑本轮成长。
- 不把基线复核、静态清单、纯提示修补或画面微调当作本专题主线。

## 玩家操作路径

本专题的开发包必须覆盖完整玩家路径：

1. 玩家在既有外勤区域回收材料、残骸、缓存或稳定数据。
2. 玩家回到基地，基础反应器或出发整备台明确显示可加工 / 可维护 / 可确认的内容。
3. 玩家执行制造、模块整备或维护确认，运行时写入可持久判断的状态。
4. HUD、基地对象、外勤出发口和地图目标读出“已经整备，下一趟外勤会有什么变化”。
5. 玩家进入污染、遗迹或核心稳定站后，战斗承压、输出、防护或采集压力读出前后差异。
6. 战斗或采集结束后，反馈回指基地补给、后续整备或下一项功能开发观察点。

## 运行时、存档与数据边界

- 优先复用既有物品、配方、建筑、敌人和地图对象。
- 成长状态优先绑定现有整备台、角色状态、任务完成态或地图对象实例；确需新增字段时必须说明存档兼容方式。
- 战斗差异优先在 `EnemyCounterattackRuntime` 或已有承压 formatter 中表达，不把判断散落到 HUD、地图和交互脚本。
- 新增提示 formatter 或检查 helper 应有清晰职责，避免继续推高接近行数边界的大文件。

## HUD / 场景 / 对象反馈

至少覆盖：

- 出发整备台：显示当前模块 / 维护状态、可执行动作、收益和缺料。
- 基础反应器：显示材料能否加工成基础零件，以及加工后服务哪项整备。
- 前哨核心与外勤出发口：显示出发前准备状态和下一趟外勤观察点。
- 主 HUD / 地图目标：在基地与前线分别给出当前整备状态和下一个目标。
- 战斗反馈：明确读出本次承压差异来自哪项整备或维护。

## 验收条件

- 至少 1 个成长 / 战斗差异可通过真实玩家操作获得，不靠调试状态或纯文案假设。
- 差异能在污染、遗迹或核心守卫压力中体现，并能被 HUD、对象反馈或战斗日志读懂。
- 存档 / 状态判断能支持离开区域、回基地、再次出发后的持续读法。
- 自动检查覆盖材料来源、整备动作、状态写入、战斗差异和反馈文本关键点。
- 未引入本专题“当前不做”中的系统扩张。

## 验证计划

- 客户端相关改动：`sh ./scripts/check-client.sh`。
- 涉及文档：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`。
- 需要项目自定义 GDScript 运行时检查时，在确认本机 Godot 可启动后执行 `sh ./scripts/check-client.sh --with-godot`。

## 风险与后续决策

- 首个差异只说明方向成立；首版 Demo 未完成初步阶段的完整玩法、场景和美术前，不进入试玩准备或修 bug 阶段。
- 后续继续按功能、场景和玩法专题推进第二个战斗 / 成长差异或工程边界拆分；真实页面 smoke 只用于对比开发效果。
- 若玩家仍读不懂回基地整备价值，应补真实操作路径中的断点，不能只改提示。
- 若实现触及 `vertical_slice_flow_check.gd`、`vertical_slice_map.gd`、`prototype_hud.gd` 或 `interaction_prompt_formatter.gd` 的继续膨胀，应同步拆分职责。
