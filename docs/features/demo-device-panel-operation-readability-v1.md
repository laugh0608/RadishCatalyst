# Demo Device Panel Operation Readability V1

更新时间：2026-06-19

## 用途

本文定义首版 Demo 设备面板操作读法第一版。它不新增设备或 UI 面板，而是让玩家在既有前哨核心、基础反应器、污染过滤器和出发整备台上读懂当前目标为什么要用这个设备、缺什么、产出去哪、完成后回哪条已有路线。

本专题覆盖 [Demo Definition V1](demo-definition-v1.md) 的「UI / HUD」「工业基建模块」「资源 / 生产链」「自动检查」规格。

## 玩家价值

玩家回基地时不应只看到一串库存和配方名，而应能判断：

- 当前设备的职责是什么。
- 当前配方服务哪段主线或整备目标。
- 缺料时该回污染过滤器、基础反应器、前哨核心还是外勤路线。
- 启动或完成加工后，下一站是出发整备台、前哨核心还是核心稳定站。

## 与整体规划的关系

- 承接 [Demo Core Stabilization Run Playability V1](demo-core-stabilization-run-playability-v1.md)：核心稳定站内路径已落地后，玩家回基地整备缓冲包时需要设备层读法。
- 不重复 [Demo Industrial Tech Spine V1](demo-industrial-tech-spine-v1.md)：工业主干已说明设备链路，本专题只把操作意图落到当前面板和结果日志。
- 不重复 [Demo Resource Chain State V1](demo-resource-chain-state-v1.md)：资源链状态已说明库存价值，本专题强调设备操作、缺料方向和完成后去向。
- 不重复交互提示承载面拆分专题；本专题可使用新 formatter，但不继续做承载面迁移。

## 当前已有基础

- `HudDevicePanelPresenter` 已显示加工设备面板标题、配方、输入、产出、副产、缺料、推荐配方和操作键。
- `ProcessingInteractionPromptFormatter` 已承接加工设备交互提示和 Q 详情日志。
- `InteractionPromptFormatter` 已承接前哨核心和出发整备台提示。
- `ProcessingRecipeHintFormatter`、`RecipePurposeHints` 和资源链 / 工业主干 formatter 已提供配方用途与完成下一步。

## 本轮范围

- 新增窄职责设备操作读法 formatter，覆盖前哨核心、基础反应器、污染过滤器和出发整备台。
- 加工设备面板显示“操作读法”和“缺料读法”，并复用 `ProcessingSystem` 已计算出的 `status`。
- 加工交互提示与 Q 详情日志共享同一设备操作读法。
- 核心缓冲包加工启动 / 完成结果日志新增设备操作反馈，说明完成后接哪条既有路线。
- 前哨核心和出发整备台提示显示当前设备职责与回补 / 整备去向。
- 新增静态检查和 Godot runtime 专项检查。

## 当前不做

- 不新增第 13 区域，不新增资源、配方、设备、敌人、任务链、存档字段或 UI 面板。
- 不修改配方选择、配方消耗、加工时长、任务推进、补给数值、战斗逻辑或整备状态字段。
- 不重做完整背包、装备栏、科技树、电网、物流、管线、菜单或结算页。
- 不继续给工业主干、资源链状态、动作失败反馈或核心站路径追加同类内容包。

## 玩家操作路径

1. 玩家回前哨核心补生命、防护和快捷补给，看到当前目标应去哪个已有设备。
2. 玩家靠近污染过滤器，看到沉积物会变成抗污染药剂和污染浆液，且核心缓冲目标应回基础反应器。
3. 玩家靠近基础反应器，看到核心稳压缓冲包需要修复凝胶、抗污染药剂、污染浆液和基础零件；缺料时读出补给方向。
4. 玩家启动或完成核心缓冲包加工，结果日志说明产物去向和下一站。
5. 玩家到出发整备台确认过滤模块、维护或校准状态后，再回前哨核心补给并出发。

## 运行时、存档与数据边界

- 不新增长期状态字段；所有读法来自既有任务、库存、建筑、整备和加工状态。
- 不复制 `ProcessingSystem` 的配方选择或缺料判断；formatter 只读取已计算的 `status`。
- 不新增静态数据 ID；所有设备、配方和资源沿用现有定义。

## HUD / 面板 / 对象反馈

- 设备面板：在状态区追加操作意图、缺料方向和完成后去向。
- 加工交互提示：在既有输入 -> 输出行补充同一操作读法。
- Q 详情日志：把配方用途和设备操作读法并列显示。
- 前哨核心 / 出发整备台提示：显示当前设备职责和回补 / 整备路径。
- 结果日志：启动和完成核心缓冲包加工时显示设备操作完成后的下一站。

## 第一包完成状态

- 2026-06-19 第一包已落地并通过退出判断：新增 `DemoDevicePanelOperationFormatter`、静态检查和 Godot runtime 检查，并接入设备面板、加工提示、Q 详情、前哨核心 / 出发整备台提示和核心缓冲包加工结果日志。

## 验收条件

- 四个既有设备都能读出操作职责，不需要新增面板。
- 基础反应器和污染过滤器能在当前核心缓冲目标下读出投入、产出、缺料和完成后去向。
- 加工启动 / 完成日志能读出设备操作结果。
- 自动检查覆盖静态接线、Godot runtime 路径和主要源码行数预算。
- `interaction_prompt_formatter.gd`、`processing_system.gd`、`vertical_slice_map.gd` 均保持低于既有行数预算。

## 验证计划

- `python scripts/check-client-demo-device-panel-operation-readability.py .`
- `sh ./scripts/check-client.sh`
- 涉及 Godot runtime 路径时执行 `sh ./scripts/check-client.sh --with-godot`
- `sh ./scripts/check-docs.sh`
- `sh ./scripts/check-text-files.sh`
- `git diff --check`

## 风险与后续决策

- 若设备读法仍不足，优先修真实流程断点或当前面板缺口，不继续堆重复文案。
- 若出现主线卡死、任务无法完成、关键资源断档或 UI 完全无法判断下一步，按阶段 `P0` / `P1` 处理。
- 若只是局部文案密度、排序或样式 polish，记录到后续，不阻塞本专题退出。
