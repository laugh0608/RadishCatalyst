# Demo Runtime Surface Decomposition V1

更新时间：2026-06-16

## 用途

本文定义主路径连续性第一包落地后的运行时承载面拆分范围。它不是玩法加厚包，而是为后续继续推进首版 Demo 规格时，先把接近硬上限的检查脚本拆出清晰边界。

## 玩家价值

玩家价值来自开发可持续性：主路径、HUD、地图和状态检查可以继续覆盖真实路线，而不是因为单个运行时检查文件过大，后续只能继续堆同一文件或降低检查密度。

## 与整体规划的关系

- 覆盖 `Demo Definition V1` 的「自动检查」和工程专题类型。
- 承接已落地的 `Demo Main Path Continuity V1`，不改变主线、区域、任务或资源规格。
- 为后续真实玩法、场景或状态专题保留检查扩展空间。

## 当前已有基础

- `vertical_slice_flow_check.gd` 已覆盖从新档到 Demo 终点的大量主路径断言，并接近源码硬上限。
- 开局引导提示检查依赖 `HudHintPresenter` 和 `VerticalSliceMap.tscn`，但与主线任务推进断言耦合较浅。
- `check-client` 已有默认静态检查和可选 Godot 运行时检查入口。

## 本轮范围

- 新增 `onboarding_hint_runtime_check.gd`，专门覆盖开局、污染边界、遗迹、深层遗迹、相位回投和相位井相关的引导提示 / 方向提示断言。
- 从 `vertical_slice_flow_check.gd` 移除开局引导提示检查和只为该检查服务的 `VerticalSliceMapScene` 依赖。
- 新增 `check-client-demo-runtime-surface-decomposition`，校验专题文档、脚本拆分边界和检查接线。
- 将新运行时检查接入 `sh ./scripts/check-client.sh --with-godot` 与 PowerShell 运行时入口。

## 当前不做

- 不新增资源、配方、区域、任务链、完整背包、完整装备栏或自动化物流。
- 不改变主路径连续性断言、不扩写新的玩家内容包、不切到试玩准备或集中修 bug。
- 不在本包拆 `vertical_slice_map.gd`、`prototype_hud.gd` 或 `interaction_prompt_formatter.gd`；只有后续功能必须触碰时再按职责拆。

## 玩家操作路径

玩家路径不变化。新脚本只把既有 HUD / 地图引导提示检查从主流程检查中移出，仍覆盖新档恢复前哨、采集晶体、准备补给、推进污染边界、进入遗迹、回投相位前线和相位井后续提示。

## 运行时、存档与数据边界

- 运行时检查继续使用 `DataRegistry`、`WorldState.create_default()`、`CharacterState.create_default()` 和 `VerticalSliceMap.tscn`。
- 不新增存档字段、数据 ID、地图区域或任务状态。
- `vertical_slice_flow_check.gd` 继续负责主路径任务推进、代表性基线和终点运行路径。

## HUD / 场景 / 对象反馈

- `onboarding_hint_runtime_check.gd` 只验证 `HudHintPresenter` 输出和地图上下文组合。
- 不新增 HUD 面板、场景节点、对象提示或美术层。
- 如果未来继续拆分 HUD / 地图检查，应按玩家可读职责建独立脚本，而不是把所有提示断言塞回主流程检查。

## 验收条件

- `vertical_slice_flow_check.gd` 不再包含 `_check_onboarding_hints` 和 `VerticalSliceMapScene`。
- `onboarding_hint_runtime_check.gd` 能独立运行并输出 `Onboarding hint runtime checks passed.`。
- 默认 `check-client` 能检查拆分边界；`--with-godot` 能运行新脚本。
- 入口文档和本周周志同步说明当前阶段和后续边界。

## 验证计划

- `sh ./scripts/check-client.sh`
- `sh ./scripts/check-client.sh --with-godot`
- `./scripts/check-docs.sh`
- `./scripts/check-text-files.sh`
- `git diff --check`

## 风险与后续决策

- 本包只处理影响后续开发节奏的运行时检查承载面，不应扩成纯重构长线。
- 若下一步仍需触碰 `vertical_slice_map.gd`，优先拆地图区域 / gate helper 后再推进功能。
- 本包完成后应重新做阶段退出判断，优先选择真实玩家路径、场景玩法或状态规格缺口。
