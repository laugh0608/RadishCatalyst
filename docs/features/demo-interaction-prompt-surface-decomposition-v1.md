# Demo Interaction Prompt Surface Decomposition V1

更新时间：2026-06-19

## 用途

本文定义首版 Demo 交互提示承载面拆分第一版。它不是新 UI 面板，也不是大规模重构；目标是在不改变玩家操作路径的前提下，把已经接近硬上限的 `interaction_prompt_formatter.gd` 拆出窄职责 formatter，让后续对象提示、设备读法和基地再进入读法能继续安全推进。

本专题覆盖 [Demo Definition V1](demo-definition-v1.md) 的「UI / HUD」「自动检查」和「工程承载面」规格。

## 玩家价值

交互提示是玩家判断“能不能按 E、为什么不能、按完后去哪”的第一入口。文件逼近硬上限时，后续只能绕开对象提示或继续堆风险；拆分后，设备、基地对象和外勤对象可以按职责扩展，玩家读法不再受单文件行数挤压。

## 与整体规划的关系

- 承接 [Demo Route Return And Base Reentry Readability V1](demo-route-return-and-base-reentry-readability-v1.md)：基地再进入读法已接入设备面板，但通用交互提示因大文件接近硬上限暂未继续加厚。
- 延续运行时承载面拆分原则：只有当工程边界影响继续开发时才拆分，本轮正好命中 `interaction_prompt_formatter.gd` 1494 行风险。
- 保持当前阶段不进入试玩准备或集中修 bug；拆分服务后续玩家可见提示推进。

## 当前已有基础

- `InteractionPromptFormatter` 已覆盖通用对象、加工设备、建造点、出发口、前哨核心和深段对象提示。
- `HudDevicePanelPresenter`、结果日志和多个专题 formatter 已具备窄职责接入点。
- `check-client` 已有大量对象提示与加工提示运行时检查，可以守住拆分后的行为一致性。

## 本轮范围

- 第一包只拆加工设备交互提示：`format_processing_prompt`、`format_processing_log` 和相关小 helper 迁出到独立 formatter。
- 保留 `InteractionPromptFormatter.format_processing_prompt` 和 `format_processing_log` 对外接口，调用方不改。
- 拆出的加工提示接入基地再进入读法，让基础反应器 / 污染过滤器对象提示能显示返回基地处理方向。
- 新增专项检查，覆盖拆分接线、行数预算、代表性加工提示和基地再进入提示。

## 当前状态

- 2026-06-19 第一包已落地：新增 `ProcessingInteractionPromptFormatter`，`InteractionPromptFormatter` 保留原入口并委托加工提示 / 加工日志。
- `interaction_prompt_formatter.gd` 已从 1494 行降到 1373 行；加工设备提示已接入基地再进入读法。
- 新增 `demo_interaction_prompt_surface_decomposition_check.gd` 与静态接线检查，并接入默认 `check-client` 和 Godot runtime 检查。

## 当前不做

- 不新增 UI 面板、菜单、背包、装备栏、结算页或设置页。
- 不重写全部交互提示，不移动通用对象、深段对象、建造点或出发口逻辑。
- 不新增资源、配方、设备、区域、任务链、敌人类型或存档字段。
- 不为了“整齐”做大范围重命名或目录重排。

## 玩家操作路径

1. 玩家靠近加工设备，仍通过原入口看到设备、配方、输入 / 产出、状态、下一步和操作提示。
2. 当玩家带着外勤结果回基地，设备提示可补充“返回基地读法”，说明该设备处理什么和处理后去哪。
3. 玩家按 `Q` 打开设备面板或按 `E` 启动加工时，原行为保持不变。

## 运行时、存档与数据边界

- 不新增运行时状态或存档字段。
- 拆分后的 formatter 只读取 `DataRegistry`、`ProcessingSystem`、`CharacterState` 和 `WorldState`。
- 原 `InteractionPromptFormatter` 继续作为对外门面，避免调用方和场景节点连锁修改。

## HUD / 场景 / 对象反馈

- 对象提示：加工设备提示保持原信息密度，并补充基地再进入读法。
- 设备面板：不改变既有面板职责，只与对象提示保持口径一致。
- 结果反馈：不改变现有日志结构。
- 自动检查：新增静态接线和运行时代表提示检查。

## 验收条件

- `interaction_prompt_formatter.gd` 明显低于 1500 行硬上限。
- 加工设备交互提示、加工日志和既有运行时检查保持通过。
- 基地再进入代表状态能在加工设备对象提示中读出处理方向。
- 不新增玩法内容、存档字段或 UI 面板。

## 验证计划

- `sh ./scripts/check-client.sh`
- 需要运行时证据时执行 `sh ./scripts/check-client.sh --with-godot`
- `sh ./scripts/check-docs.sh`
- `sh ./scripts/check-text-files.sh`
- `git diff --check`

## 风险与后续决策

- 若后续仍需要扩前哨核心、出发口或深段对象提示，应继续按职责拆分，而不是把逻辑塞回 `interaction_prompt_formatter.gd`。
- 若只发现局部文案顺序或低优先级提示密度问题，记录到后续 polish，不阻塞本专题。
