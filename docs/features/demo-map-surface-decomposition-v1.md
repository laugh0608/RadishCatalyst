# Demo Map Surface Decomposition V1

更新时间：2026-06-19

## 用途

本文定义首版 Demo 地图承载面拆分第一版。它不是地图扩建、玩法加厚或场景重绘；目标是在不改变玩家路线和场景节点的前提下，把已接近硬上限的 `vertical_slice_map.gd` 拆出窄职责地图 helper，为后续场景、路线和对象交互开发保留空间。

本专题覆盖 [Demo Definition V1](demo-definition-v1.md) 的「区域 / 场景」「自动检查」和「工程承载面」规格。

## 玩家价值

地图脚本承载玩家移动、区域识别、门槛回退、对象交互和战斗入口。文件逼近硬上限时，后续任何场景或路线修正都会被迫挤进同一大文件；拆分后，玩家可见的区域边界、门槛提示和回投位置可以继续迭代，而不牺牲主路径稳定性。

## 与整体规划的关系

- 承接 [Demo Interaction Prompt Surface Decomposition V1](demo-interaction-prompt-surface-decomposition-v1.md)：交互提示承载面已通过退出判断，下一处明确工程风险转到地图脚本。
- 延续 [Demo Runtime Surface Decomposition V1](demo-runtime-surface-decomposition-v1.md)：当后续开发必须触碰 `vertical_slice_map.gd` 时，优先拆地图区域 / gate helper。
- 保持 12 区域封顶和当前主线不变；拆分服务后续真实场景与路线推进。

## 当前已有基础

- `vertical_slice_map.gd` 拆分前约 1480 行，第一包落地后降至 1383 行，重新低于源码硬上限并留出后续余量。
- 区域 X 边界、门槛回退、回投坐标、区域判断、交互对象区域归属和 gate 状态混在同一地图脚本中。
- `check-client` 与 Godot runtime 已覆盖主路径、区域路线、地图提示和多项专题检查，可用于拆分后的行为回归。

## 本轮范围

- 第一包只拆地图区域 / gate 承载面：区域边界判断、门槛回退位置、回投坐标和区域归属查询迁出到窄职责 helper。
- 保留 `VerticalSliceMap` 对外方法和信号，调用方不改。
- 拆分后 `vertical_slice_map.gd` 必须明显低于 1500 行硬上限。
- 新增专项检查，覆盖拆分接线、行数预算、代表区域判断和门槛回退。

## 当前状态

- 2026-06-19 建立专题：`Demo Interaction Prompt Surface Decomposition V1` 已通过退出判断，地图承载面拆分第一包进入落地。
- 2026-06-19 第一包已落地：新增 `VerticalSliceMapSurface`，`VerticalSliceMap` 保留原方法、信号和玩家路线，区域判断、gate 回退、回投坐标和对象区域归属查询改由窄职责 helper 承载。

## 当前不做

- 不新增第 13 区域，不重排 12 区域路线，不改玩家可走边界。
- 不新增资源、配方、敌人、任务链、存档字段或 UI 面板。
- 不重绘 `VerticalSliceMap.tscn`，不做完整地图工具或导航系统。
- 不把战斗、采集、任务推进或前线行动逻辑一并迁出；本轮只处理地图区域 / gate helper。

## 玩家操作路径

玩家路径不变化。玩家仍从基地出发，沿晶体、污染、遗迹、裂相脊、相位井和核心稳定站推进；拆分后的地图 helper 只保证区域识别、门槛拦截、回退位置和回投位置保持一致。

## 运行时、存档与数据边界

- 不新增存档字段，不改变世界状态真相源。
- 地图 helper 只读取地图位置、对象实例 ID、世界状态和既有区域常量。
- `VerticalSliceMap` 继续负责节点连接、玩家交互、战斗入口和对外信号。

## HUD / 场景 / 对象反馈

- HUD / 地图提示文本不因本轮拆分改变。
- 场景节点、对象实例 ID 和区域 ID 保持稳定。
- 自动检查新增静态接线和 Godot runtime 代表路径，确保区域判断、gate 回退、回投坐标与对象区域归属不回归。

## 验收条件

- `vertical_slice_map.gd` 明显低于 1500 行硬上限。
- 区域判断、gate 回退、回投坐标和对象区域归属由窄职责 helper 承载。
- 主路径、区域路线、地图提示和代表 gate 运行时检查保持通过。
- 不新增玩法内容、存档字段、区域或 UI 面板。

## 验证计划

- `python scripts/check-client-demo-map-surface-decomposition.py .`
- `sh ./scripts/check-client.sh`
- 需要运行时证据时执行 `sh ./scripts/check-client.sh --with-godot`
- `sh ./scripts/check-docs.sh`
- `sh ./scripts/check-text-files.sh`
- `git diff --check`

## 风险与后续决策

- 若拆分后仍需要频繁改 `VerticalSliceMap`，再按交互、战斗或对象状态职责建立后续专题；不要一次性做大重构。
- 若只发现低优先级场景微调，记录到后续 polish，不阻塞本专题退出。
