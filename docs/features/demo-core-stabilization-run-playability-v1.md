# Demo Core Stabilization Run Playability V1

更新时间：2026-06-19

## 用途

本文定义首版 Demo 核心稳定站内可玩路径第一版。它承接已通过退出判断的核心稳定站入口承接专题，不继续给锁相框架、锚定桥或终点前准备总览加厚，而是把玩家进入核心稳定站后的实际操作顺序落到 HUD、地图、对象提示、结果反馈、场景层和自动检查。

本专题覆盖 [Demo Definition V1](demo-definition-v1.md) 的「主线结构」「核心场景完成度」「战斗压力」「UI / HUD」「存档 / 状态」和「自动检查」规格。

## 玩家价值

玩家进入核心稳定站后，应能看出这里不是一个只等按键写入的终点房间，而是一段短路径：

```text
入口确认 -> 侧边补给 -> 稳压缓冲包 -> 阶段守卫 -> 回写缓存 -> 核心写入
```

这段路径必须读出准备为何有用、守卫为何要处理、缓存为何要回收、核心设备何时可写入，以及完成后为什么回前哨整理。

## 与整体规划的关系

- 承接 [Demo Core Approach Handoff Playability V1](demo-core-approach-handoff-playability-v1.md)：入口前承接已完成，本专题只处理进入核心稳定站后的站内路径。
- 不重复 [Demo Endpoint Readiness V1](demo-endpoint-readiness-v1.md)：终点前准备总览已存在，本专题强调站内操作顺序和对象落点。
- 不重复 [Demo Completion Outcome Readout V1](demo-completion-outcome-readout-v1.md)：核心写入后的成果整理已存在，本专题只补写入前后的路径衔接。

## 当前已有基础

- 核心稳定站区域、阶段守卫、核心稳定设备、侧边补给缓存、守卫回写缓存、核心写入校验片和核心稳压缓冲包已存在。
- `CoreStabilizationPressureFormatter` 已覆盖承压和准备项读法。
- `DemoEndpointReadinessFormatter` 已覆盖前哨、出发口和核心设备的终点前总览。
- `DemoMainPathContinuityCheck` 已能从 `S21` 跑到核心写入完成。

## 本轮范围

- 新增核心稳定站内路径 formatter，覆盖入口确认、侧边补给、缓冲包、阶段守卫、回写缓存和核心写入。
- HUD / 地图显示站内路径、当前段、站内状态和下一步。
- 对象提示覆盖核心站补给缓存、守卫回写缓存和核心稳定设备的职责、状态和下一步。
- 结果反馈覆盖侧边补给回收、阶段守卫击败、守卫缓存回收和核心写入完成后的站内后续。
- `VerticalSliceMap.tscn` 增加 `CoreStabilizationRunLayer`，只标出既有核心稳定站内部落点。
- 新增便携静态检查和 Godot runtime 专项检查。

## 当前不做

- 不新增第 13 区域，不新增资源、配方、设备、敌人、任务链、存档字段或 UI 面板。
- 不修改阶段守卫血量、反击公式、核心写入承压公式、掉落表或任务完成条件。
- 不重做前线行动台、高压窗口、终点前准备总览、完成态成果整理或核心站复测链路。
- 不新增终局菜单、结算页、死亡系统、发布准备或试玩准备流程。

## 玩家操作路径

1. 玩家从锚定桥进入核心稳定站，确认入口场、侧边补给和核心设备。
2. 若尚未整备核心稳压缓冲包，玩家回污染边界补料并回基地加工，再带缓冲包回站内。
3. 玩家先回收核心站侧边补给缓存，获得守卫战和写入前补给。
4. 玩家处理核心阶段守卫，缓冲包、侧边补给和抗污染药剂会降低承压。
5. 玩家回收守卫回写缓存，取得核心写入校验片、基础零件和终点补给。
6. 玩家在核心稳定设备写入核心稳定数据，随后回前哨整理 Demo 成果。

## 运行时、存档与数据边界

- 不新增长期状态字段；站内路径由既有任务状态、对象状态、敌人状态、库存和当前区域推导。
- 不改变任务推进；formatter 只负责玩家可见读法和自动检查断言。
- 对象状态继续使用既有 `is_gathered`、`is_sampled`、敌人 `is_defeated`、`core_buffer_used`、`core_side_supply_used` 和 `pressure_vial_used`。

## HUD / 场景 / 对象反馈

- HUD：显示站内路径、当前段、站内状态和下一步，和既有承压读法并列。
- 地图：在核心稳定站目标或当前位置显示站内路径提示，不再把核心站只读成终点标签。
- 场景：`CoreStabilizationRunLayer` 标出入口确认、侧边补给、缓冲包回站、守卫场、守卫缓存和写入平台。
- 对象提示：补给缓存、守卫缓存和核心设备分别读出职责、状态和下一步。
- 结果反馈：回收缓存、击败守卫和写入核心后都能读出下一段行动。

## 第一包完成状态

- 2026-06-19 第一包已落地：新增核心稳定站内路径 formatter、`CoreStabilizationRunLayer`、静态检查和 Godot runtime 检查，并接入 HUD、地图、对象提示、缓存 / 守卫 / 核心写入结果。

## 验收条件

- 入口确认 -> 侧边补给 -> 稳压缓冲包 -> 阶段守卫 -> 回写缓存 -> 核心写入的顺序在 HUD、地图、对象提示、结果反馈和场景层中可读。
- 自动检查覆盖 formatter、场景层、HUD / 地图、对象提示、结果反馈和主要源码行数预算。
- 不新增区域、资源、配方、设备、敌人、任务链、存档字段或 UI 面板。
- `vertical_slice_map.gd`、`interaction_prompt_formatter.gd` 和 `gather_system.gd` 均保持低于 1500 行。

## 验证计划

- `python scripts/check-client-demo-core-stabilization-run-playability.py .`
- `sh ./scripts/check-client.sh`
- 涉及场景和 Godot runtime 路径时执行 `sh ./scripts/check-client.sh --with-godot`
- `sh ./scripts/check-docs.sh`
- `sh ./scripts/check-text-files.sh`
- `git diff --check`

## 风险与后续决策

- 若站内路径已经能读出真实操作顺序，后续应继续按 Demo Definition 选择新的非重复玩家可见缺口。
- 若出现主线卡死、任务无法完成、关键资源断档或 UI 完全无法判断下一步，按阶段 `P0` / `P1` 处理。
- 若只是局部文本密度、色块粗糙或对象摆位微调，记录到后续 polish，不阻塞本专题退出。
