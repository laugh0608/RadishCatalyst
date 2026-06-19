# Demo Midfield Route Playability V1

更新时间：2026-06-19

## 用途

本文定义首版 Demo 中段异常地貌可玩路径第一版。它承接已通过退出判断的地图承载面拆分，不继续做工程拆分同层包，而是把玩家从回声台地 -> 盐壳浅滩 -> 碎晶沟谷的实际移动、对象落点、HUD / 对象反馈和回基地理由落到既有 12 区路线中。

本专题覆盖 [Demo Definition V1](demo-definition-v1.md) 的「区域 / 场景」「功能 / 过渡场景」「UI / HUD」「存档 / 状态」和「自动检查」规格。

## 玩家价值

玩家进入 Demo 中段后，不能只靠区域名推断下一步。第一包必须让玩家能读出：

1. 回声台地、盐壳浅滩、碎晶沟谷三段如何连续推进。
2. 每段的入口边界、危险、资源、设施和回基地处理理由。
3. 当前对象处理后会打开哪段后续路线，而不是停留在孤立采集点。

## 与整体规划的关系

- 延续“基地服务冒险，冒险反哺基地”：中段资源和样本必须回到基地稳定、解析或整备，再支撑下一段外勤。
- 承接 [Demo Map Surface Decomposition V1](demo-map-surface-decomposition-v1.md)：地图承载面已降出硬上限，本轮可以推进玩家可感知路线。
- 避免重复加厚已通过退出判断的封锁遗迹 -> 裂相脊、锁相框架、锚定桥、补给、交互提示或地图 helper。

## 当前已有基础

- `region.inner_phase_well`、`region.phase_well_sink`、`region.phase_well_chamber` 已存在区域、对象、任务和资源链。
- 既有对象包括回声泄压阀、回声碎屑、回声台地探点、盐壳硬壳、盐壳余烬、盐壳裂口、碎晶分流读数点、心棘残片和碎晶沟谷断面。
- `FunctionalSceneGameplayFormatter` 已提供基础现场玩法；本专题只新增中段路径读法。
- `VerticalSliceMap.tscn` 已有区域底色和非核心区域身份层，可补窄职责路线层。

## 本轮范围

- 第一包只覆盖 `region.inner_phase_well`、`region.phase_well_sink`、`region.phase_well_chamber`。
- 新增中段路线 formatter，覆盖 HUD、地图提示、对象提示和交互结果中的路径读法。
- 在既有地图场景上标出入口边界、资源口袋、设施落点和回基地衔接。
- 新增静态检查和 Godot runtime 检查，覆盖三段路线、场景层、HUD / 对象提示和交互结果。

## 当前不做

- 不新增第 13 区域，不新增资源、配方、设备、敌人、任务链、存档字段或 UI 面板。
- 不重绘整张地图，不平均扩厚 12 个区域。
- 不改战斗、采集、任务推进、前线行动台、窗口复盘或存档 schema。
- 不继续围绕封锁遗迹、裂相脊、锁相框架、锚定桥或工程拆分同一批结论加厚。

## 玩家操作路径

1. 玩家从裂相锁位或回投路线进入回声台地，先读出泄压阀、回声碎屑和台地探点的关系。
2. 玩家把回声碎屑 / 回声芯样本带回基地处理后，HUD 和地图指向盐壳浅滩。
3. 玩家进入盐壳浅滩，清开盐壳硬壳，回收盐壳余烬，并把碎晶心核带回基地解析。
4. 玩家进入碎晶沟谷，写入分流读数，回收心棘残片，勘验断面并把风蚀张力核带回基地。

## 运行时、存档与数据边界

- 不新增长期真相源；中段路径由既有区域 ID、对象 definition、对象状态和世界当前区域推导。
- 不新增存档字段；对象状态继续使用既有 `is_gathered`、`is_cleared`、`is_sampled`、`is_inspected`。
- 新 formatter 只负责读法和检查侧断言，不成为任务推进或战斗结算入口。

## HUD / 场景 / 对象反馈

- HUD / 地图：显示当前中段路径、入口边界、危险、资源、设施、下一段和回基地理由。
- 场景：在 `VerticalSliceMap.tscn` 增加 `MidfieldRoutePlayabilityLayer`，标出三段代表落点。
- 对象提示：普通采集、读数、清障和终端对象都能读出中段路径职责。
- 交互结果：处理对象后说明下一段和回基地处理价值。

## 第一包完成状态

- 2026-06-19 第一包已落地：新增 `DemoMidfieldRoutePlayabilityFormatter`、`MidfieldRoutePlayabilityLayer`、静态接线检查和 Godot runtime 检查，HUD、地图、对象提示和交互结果已接入回声台地 -> 盐壳浅滩 -> 碎晶沟谷读法。
- 2026-06-19 退出判断通过：验收条件已有实现与自动检查证据，未发现阻塞阶段的 `P0` / `P1`，后续不继续围绕同一批中段对象加厚。

## 验收条件

- 三段中段路径能在 HUD、地图、对象提示和交互结果中读出入口、边界、资源、设施、下一段与回基地理由。
- 场景层能标出三段代表落点，并保持在既有 12 区区域边界内。
- 自动检查覆盖三段 formatter、场景层、HUD / 对象提示、交互结果和脚本行数预算。
- `vertical_slice_map.gd` 保持明显低于 1500 行，且本专题不把新逻辑塞回地图主脚本。

## 验证计划

- `python scripts/check-client-demo-midfield-route-playability.py .`
- `sh ./scripts/check-client.sh`
- 涉及场景和 Godot runtime 路径时执行 `sh ./scripts/check-client.sh --with-godot`
- `sh ./scripts/check-docs.sh`
- `sh ./scripts/check-text-files.sh`
- `git diff --check`

## 风险与后续决策

- 若三段路径已能读出实际移动关系，后续应切到下一个未形成执行专题的玩家可见缺口。
- 若出现主线卡死、任务无法完成、关键资源断档或 UI 完全无法判断下一步，按阶段 `P0` / `P1` 处理。
- 若只是局部文本密度、色块粗糙或对象摆位微调，记录到后续 polish，不阻塞本专题退出。
