# Demo Core Approach Handoff Playability V1

更新时间：2026-06-19

## 用途

本文定义首版 Demo 核心稳定站入口承接可玩路径第一版。它承接已通过退出判断的风蚀管廊过渡路径，不继续给风蚀管廊、锁相框架或锚定桥内部小循环追加同类内容，而是把玩家从锁相框架 -> 锚定桥 -> 核心稳定站入口的终点前承接、对象落点、HUD / 对象反馈和回基地理由落到既有 12 区路线中。

本专题覆盖 [Demo Definition V1](demo-definition-v1.md) 的「区域 / 场景」「功能 / 过渡场景」「UI / HUD」「存档 / 状态」和「自动检查」规格。

## 玩家价值

玩家完成风蚀管廊和锁相框架后，应能看出锚定桥不是另一个孤立小循环，而是把锁相收益、锚场回稳窗、前线行动读数和核心稳定站入口接成 Demo 终点前准备。

## 与整体规划的关系

- 延续“基地服务冒险，冒险反哺基地”：锚定桥获得的稳场锚核、稳窗余响片和前线读数必须回到基地解析、归档或整备，再支撑核心稳定站入口。
- 承接 [Demo Wind Corridor Transition Playability V1](demo-wind-corridor-transition-playability-v1.md)：继续选择新的真实玩家路径，不重复加厚风蚀管廊或中段路线。
- 避免重做 [Demo Functional Scene Gameplay Density V1](demo-functional-scene-gameplay-density-v1.md) 已覆盖的锁相框架 / 锚定桥小循环；本包只补终点入口承接。

## 当前已有基础

- `region.phase_well_frame`、`region.phase_well_tether` 和 `region.demo_stabilization_core` 已存在区域、对象、任务和资源链。
- 既有对象包括锁相侧路障、边缕残条、锁相框架断面、锚定桥结点、锚索残股、锚定桥断面、回传锚点、锚场回稳窗、压力钉、稳窗校准点、前线读数标记和核心稳定设备。
- `DemoFunctionalSceneGameplayDensityFormatter` 已覆盖锁相框架 / 锚定桥代表小循环。
- `DemoEndpointReadinessFormatter` 已覆盖进入核心稳定站后的终点前准备；本专题只补进入前的承接读法。

## 本轮范围

- 第一包覆盖 `region.phase_well_frame`、`region.phase_well_tether` 和 `region.demo_stabilization_core` 的入口承接读法。
- 新增核心入口承接 formatter，覆盖 HUD、地图提示、对象提示和交互结果中的路径读法。
- 在既有地图场景上标出锁相出口、锚定桥承接、锚场稳窗、核心站入口阈值和核心设备承接。
- 新增静态检查和 Godot runtime 检查，覆盖 formatter、场景层、HUD / 对象提示、交互结果和行数预算。

## 当前不做

- 不新增第 13 区域，不新增资源、配方、设备、敌人、任务链、存档字段或 UI 面板。
- 不重做锁相框架、锚定桥、前线行动台、高压窗口、核心阶段守卫或核心写入逻辑。
- 不重绘整张地图，不平均扩厚 12 个区域。
- 不把 Demo 终点完成态、结算页、试玩准备或发布准备纳入本包。

## 玩家操作路径

1. 玩家完成风蚀管廊后进入锁相框架，清理侧路、回收边缕残条并勘验框架断面。
2. 玩家回基地解析锚定结核后进入锚定桥，确认结点、回收锚索残股并勘验桥体断面。
3. 玩家回基地解析稳场锚核并整备校锚桩，回到锚场回稳窗处理压力钉、稳场守脉体和稳窗余响片。
4. 玩家解析稳窗读数、校准稳窗节点并处理既有前线行动读数后，从锚定桥进入核心稳定站入口。

## 运行时、存档与数据边界

- 不新增长期真相源；承接路径由既有区域 ID、对象 definition、对象状态、任务状态和世界当前区域推导。
- 不新增存档字段；对象状态继续使用既有 `is_gathered`、`is_cleared`、`is_inspected`、`anchor_field_*` 和 `stability_node_calibrated`。
- 新 formatter 只负责读法和检查侧断言，不成为任务推进、前线行动调度、战斗结算或核心写入入口。

## HUD / 场景 / 对象反馈

- HUD / 地图：显示锁相框架、锚定桥、锚场回稳窗、前线读数和核心稳定站入口的承接关系。
- 场景：在 `VerticalSliceMap.tscn` 增加 `CoreApproachHandoffLayer`，标出锁相出口、锚定桥承接、锚场稳窗、核心站入口阈值和核心设备承接。
- 对象提示：侧路、材料、断面、回传锚点、回稳窗、压力钉、稳窗校准点、前线读数标记和核心稳定设备都能读出承接职责。
- 交互结果：处理对象后说明下一段和回基地处理价值。

## 第一包完成状态

- 2026-06-19 第一包已落地：新增核心入口承接 formatter、`CoreApproachHandoffLayer` 和专项检查，把锁相框架 -> 锚定桥 -> 核心稳定站入口接入 HUD、地图、对象提示和交互结果，不新增区域、资源、配方、敌人、任务链、存档字段或 UI 面板。
- 2026-06-19 通过退出判断：核心入口前的实际移动关系已能在 HUD、地图、对象提示、交互结果和场景层中读出；后续切到核心稳定站内可玩路径。

## 验收条件

- 核心入口承接路径能在 HUD、地图、对象提示和交互结果中读出锁相出口、锚定桥、锚场稳窗、前线读数、核心入口和回基地理由。
- 场景层能标出代表落点，并保持在既有 12 区区域边界内。
- 自动检查覆盖 formatter、场景层、HUD / 对象提示、交互结果和脚本行数预算。
- `vertical_slice_map.gd` 保持明显低于 1500 行，且本专题不把新逻辑塞回地图主脚本。

## 验证计划

- `python scripts/check-client-demo-core-approach-handoff-playability.py .`
- `sh ./scripts/check-client.sh`
- 涉及场景和 Godot runtime 路径时执行 `sh ./scripts/check-client.sh --with-godot`
- `sh ./scripts/check-docs.sh`
- `sh ./scripts/check-text-files.sh`
- `git diff --check`

## 风险与后续决策

- 若锁相框架 -> 锚定桥 -> 核心稳定站入口已能读出实际移动关系，后续应切到下一个未形成执行专题的玩家可见缺口。
- 若出现主线卡死、任务无法完成、关键资源断档或 UI 完全无法判断下一步，按阶段 `P0` / `P1` 处理。
- 若只是局部文本密度、色块粗糙或对象摆位微调，记录到后续 polish，不阻塞本专题退出。
