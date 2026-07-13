# Demo Action Blocker Recovery V1

更新时间：2026-06-17

## 用途

本文定义首版 Demo 受阻动作恢复读法第一版的范围。它不是试玩准备、修 bug 阶段、终局菜单、结算页或发布准备；它用于检查玩家尝试关键动作但被前置、缺料、缺补给、敌人、设备忙碌或已处理状态拦住时，能否从失败反馈、HUD、地图和对象状态读懂原因与恢复路线。

## 玩家价值

玩家在动作没有完成时，需要立刻知道：

1. 哪个条件挡住了动作。
2. 当前资源、任务、敌人、设备或对象状态差在哪里。
3. 应该去哪补材料、处理敌人、恢复补给、切换目标或等待加工完成。

## 与整体规划的关系

本专题覆盖 [Demo Definition V1](demo-definition-v1.md) 的「UI / HUD」「自动检查」「资源 / 生产链」「工艺 / 科技解锁」和「战斗压力」规格。

它承接已完成的 [Demo Interaction Affordance V1](demo-interaction-affordance-v1.md) 与 [Demo Action Feedback Readability V1](demo-action-feedback-readability-v1.md)：前者解决动作前能否判断对象状态，后者解决动作成功后能否读懂结果，本专题转向动作被拦住后的原因和恢复路径。

## 当前已有基础

- `GatherSystem`、`BuildSystem`、`ProcessingSystem`、`CharacterState` 和核心写入前置已返回 `failure_feedback` 或失败 message。
- HUD、地图、对象提示和专项检查已覆盖动作前可辨识度与动作成功后结果读法。
- 代表性开发断点已能构造缺料、缺补给、守卫未击败、设备加工中和已处理对象状态。

## 本轮范围

- 覆盖采集 / 采样前置不足、清障已处理、建造缺前置 / 缺材料、加工缺原料 / 设备忙碌、补给无法使用、核心写入缺守卫或校验片等代表性受阻动作。
- 检查失败反馈是否包含阻挡原因、状态差距和恢复路线。
- 检查 HUD / 地图 / 对象状态是否继续指向真实恢复路径，不新增 UI 面板。
- 新增检查优先放在独立专项文件，不继续推高 `vertical_slice_flow_check.gd`、`vertical_slice_map.gd`、`prototype_hud.gd` 或 `interaction_prompt_formatter.gd`。

## 第一包实施范围

- 新增窄职责 `DemoActionBlockerRecoveryFormatter`，统一代表性失败反馈的原因、缺口和恢复路线字段。
- 接入采集 / 采样前置不足、已处理对象、建造缺前置 / 缺材料、加工缺原料 / 设备忙碌、补给无法使用和核心写入缺守卫 / 校验片路径。
- 新增 `demo_action_blocker_recovery_check.gd` 专项检查，覆盖失败反馈、HUD 日志 / 目标 / 地图提示、对象 / 设备 / 敌人状态和恢复路线一致性。
- 不新增 UI 面板、存档 schema、资源、配方、区域、任务链、敌人类型、完整背包或完整装备栏。

## 第一包完成状态

- 2026-06-17 已落地：`DemoActionBlockerRecoveryFormatter` 接入采集 / 采样、已处理对象、建造、加工、补给和核心写入失败路径。
- `demo_action_blocker_recovery_check.gd` 与默认静态接线检查已覆盖代表性受阻动作、HUD 日志 / 目标 / 地图提示、对象 / 设备 / 敌人状态和恢复路线。
- 已通过 `sh ./scripts/check-client.sh` 与 `sh ./scripts/check-client.sh --with-godot`，满足当前阶段第一包退出判断。

## 阶段退出判断

- 2026-06-17 结论：通过。第一包已覆盖本专题要求的代表性受阻路径、恢复路线和专项检查。
- 退出证据：失败反馈、HUD / 地图、对象状态、设备状态和敌人状态已能互相印证；验证记录包含 `check-client`、`check-client --with-godot`、`check-docs`、`check-text-files` 和 `git diff --check`。
- 后续不继续围绕同一批失败文案加厚；若发现崩溃、主线卡死、坏档、任务无法完成、关键资源断档或 UI 完全无法判断下一步，再按 `P0` / `P1` 处理。

## 当前不做

- 不新增资源、配方、区域、任务链、敌人类型、完整背包或完整装备栏。
- 不做试玩准备、修 bug 阶段、终局菜单、结算页、发布准备或完整失败日志系统。
- 不重做 HUD 布局，不新增失败弹窗，不扩展长期成就、评分或统计。
- 不继续加厚交互可辨识度、动作成功反馈、撤离恢复、完成成果整理或整段断点检查同类内容。

## 玩家操作路径

1. 基地：材料不足、设备忙碌或补给无法使用时，失败反馈说明缺口和应回哪台设备处理。
2. 外勤：对象已处理、前置任务未满足或危险仍在时，失败反馈说明当前状态和下一步目标。
3. 核心站：守卫未击败、回写缓存未回收或校验片不足时，失败反馈说明终点写入被什么挡住。

## 运行时、存档与数据边界

- 不新增存档 schema，不迁移稳定 ID。
- 只读取既有 `WorldState`、`CharacterState`、库存、任务、敌人、对象和基础设施状态。
- 若失败反馈与真实状态不一致，优先修失败来源和状态判断，不用额外提示掩盖错误。

## HUD / 场景 / 对象反馈

- 失败反馈：关键受阻动作必须说明原因、缺口和恢复路线。
- HUD / 地图：受阻后目标应继续指向当前真实路线或恢复点。
- 场景对象：已处理、危险压制、设备忙碌和缺条件状态应继续被对象提示读出。

## 验收条件

- `Demo Action Blocker Recovery V1` 已建立并完成第一包。
- 代表性受阻动作能和 HUD / 地图、对象状态或场景视觉互相印证。
- 已通过阶段退出判断，未引入当前不做事项，新增检查走独立专项文件。

## 验证计划

- `sh ./scripts/check-client.sh`
- `sh ./scripts/check-client.sh --with-godot`
- `sh ./scripts/check-docs.sh`
- `sh ./scripts/check-text-files.sh`
- `git diff --check`

## 风险与后续决策

- 若只发现低优先级措辞问题，记录到后续 polish，不阻塞阶段推进。
- 若失败反馈暴露主线卡死、关键资源断档、坏档或 UI 完全无法判断下一步，优先按当前阶段阻塞标准处理。
