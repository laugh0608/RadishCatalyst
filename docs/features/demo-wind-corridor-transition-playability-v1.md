# Demo Wind Corridor Transition Playability V1

更新时间：2026-06-19

## 用途

本文定义首版 Demo 风蚀管廊过渡可玩路径第一版。它承接已通过退出判断的中段异常地貌可玩路径，不继续给回声台地、盐壳浅滩或碎晶沟谷加同类内容，而是把玩家从碎晶沟谷 -> 风蚀管廊 -> 锁相框架入口的实际移动、对象落点、HUD / 对象反馈和回基地理由落到既有 12 区路线中。

本专题覆盖 [Demo Definition V1](demo-definition-v1.md) 的「区域 / 场景」「功能 / 过渡场景」「UI / HUD」「存档 / 状态」和「自动检查」规格。

## 玩家价值

玩家完成碎晶沟谷后，应能看出风蚀管廊不是一段空白过道，而是把旧前哨管廊、纬束残团、风蚀张力和锁相框架入口连接起来的过渡段。

## 与整体规划的关系

- 延续“基地服务冒险，冒险反哺基地”：纬束残团和锁相织构核必须回到基地稳定、解析或整备，再支撑锁相框架入口。
- 承接 [Demo Midfield Route Playability V1](demo-midfield-route-playability-v1.md)：继续选择新的真实玩家路径，不重复加厚同一批中段对象。
- 避免重做 [Demo Functional Scene Gameplay Density V1](demo-functional-scene-gameplay-density-v1.md) 已覆盖的锁相框架小循环；本包只承接锁相入口。

## 当前已有基础

- `region.phase_well_loom` 已存在区域、对象、任务和资源链。
- 既有对象包括风蚀张力绕轮、纬束残团、风蚀管廊断面和锁相框架侧路障。
- `FunctionalSceneGameplayFormatter` 已提供风蚀管廊现场玩法；本专题只新增过渡路径读法。
- `VerticalSliceMap.tscn` 已有区域底色、非核心区域身份层和中段路线层，可继续补窄职责过渡层。

## 本轮范围

- 第一包只覆盖 `region.phase_well_loom`，并把 `map_object.phase_well_frame_route_blocker` 作为锁相入口承接点。
- 新增风蚀过渡 formatter，覆盖 HUD、地图提示、对象提示和交互结果中的路径读法。
- 在既有地图场景上标出入口、张力边界、纬束资源、管廊断面和锁相入口承接。
- 新增静态检查和 Godot runtime 检查，覆盖 formatter、场景层、HUD / 对象提示和交互结果。

## 当前不做

- 不新增第 13 区域，不新增资源、配方、设备、敌人、任务链、存档字段或 UI 面板。
- 不重绘整张地图，不平均扩厚 12 个区域。
- 不改战斗、采集、任务推进、前线行动台、窗口复盘或存档 schema。
- 不重做锁相框架的清障 / 回收 / 勘验小循环，不扩锚定桥或核心稳定站完成态。

## 玩家操作路径

1. 玩家从碎晶沟谷带回风蚀张力核，在基地解析后进入风蚀管廊。
2. 玩家在管廊入口写入两处张力绕轮读数，确认入口边界和资源线。
3. 玩家回收纬束残团并带回基地稳定，组装风蚀梭栓。
4. 玩家勘验风蚀管廊断面，把锁相织构核带回基地解析，并读出锁相框架入口承接。

## 运行时、存档与数据边界

- 不新增长期真相源；过渡路径由既有区域 ID、对象 definition、对象状态和世界当前区域推导。
- 不新增存档字段；对象状态继续使用既有 `is_gathered`、`is_cleared`、`is_sampled`、`is_inspected`。
- 新 formatter 只负责读法和检查侧断言，不成为任务推进或战斗结算入口。

## HUD / 场景 / 对象反馈

- HUD / 地图：显示风蚀过渡、入口边界、危险、资源、设施、锁相入口和回基地理由。
- 场景：在 `VerticalSliceMap.tscn` 增加 `WindCorridorTransitionPlayabilityLayer`，标出风蚀管廊代表落点和锁相入口。
- 对象提示：普通采集、读数、风蚀断面和锁相侧路清障都能读出过渡职责。
- 交互结果：处理对象后说明下一段和回基地处理价值。

## 第一包完成状态

- 2026-06-19 第一包已落地：新增风蚀过渡 formatter、`WindCorridorTransitionPlayabilityLayer` 和专项检查，把碎晶沟谷 -> 风蚀管廊 -> 锁相框架入口接入 HUD、地图、对象提示和交互结果，不新增区域、资源、配方、敌人、任务链、存档字段或 UI 面板。
- 2026-06-19 退出判断通过：验收条件已有实现与自动检查证据，未发现阻塞阶段的 `P0` / `P1`，后续不继续围绕风蚀管廊入口承接加厚。

## 验收条件

- 风蚀管廊过渡路径能在 HUD、地图、对象提示和交互结果中读出入口、边界、资源、设施、锁相入口和回基地理由。
- 场景层能标出风蚀代表落点和锁相入口承接，并保持在既有 12 区区域边界内。
- 自动检查覆盖 formatter、场景层、HUD / 对象提示、交互结果和脚本行数预算。
- `vertical_slice_map.gd` 保持明显低于 1500 行，且本专题不把新逻辑塞回地图主脚本。

## 验证计划

- `python scripts/check-client-demo-wind-corridor-transition-playability.py .`
- `sh ./scripts/check-client.sh`
- 涉及场景和 Godot runtime 路径时执行 `sh ./scripts/check-client.sh --with-godot`
- `sh ./scripts/check-docs.sh`
- `sh ./scripts/check-text-files.sh`
- `git diff --check`

## 风险与后续决策

- 若风蚀管廊已能读出实际移动关系，后续应切到下一个未形成执行专题的玩家可见缺口。
- 若出现主线卡死、任务无法完成、关键资源断档或 UI 完全无法判断下一步，按阶段 `P0` / `P1` 处理。
- 若只是局部文本密度、色块粗糙或对象摆位微调，记录到后续 polish，不阻塞本专题退出。
