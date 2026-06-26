# Demo Initial Art Identity V1

更新时间：2026-06-19

## 用途

本文定义首版 Demo 初步美术识别与设备现场表现第一包。它承接 `Demo Playable Content Substance V1`，把已补强的核心设备职责、任务节奏和核心场景空间进一步落到现场可见外观。

## 玩家价值

玩家应能在场景里直接区分设备、资源、危险和核心目标，而不是只靠 HUD、对象名或日志解释当前物体的意义。

## 与整体规划的关系

- 映射 `Demo Definition V1` 的核心场景完成度、工业基建模块、UI / HUD 和初步美术规格。
- 承接 `Demo Core Scene Playable Space V1` 与 `Demo Industrial Module Task Rhythm V1`：前者提供核心区空间角色，后者提供设备职责，本专题把它们转成现场轮廓、状态条和材质身份。
- 仍归属首版 Demo 可玩内容实质补强，不切到验收、试玩准备或最终美术阶段。

## 当前已有基础

- `SceneArtFoundationLayer` 已提供核心区底色和区域识别。
- `PrototypeVisualPriorityLayer` 已提供区域级路线 / 对象 / 危险 cue。
- `DemoCoreSceneSpaceLayer` 已给四个核心区地表、路线和对象落点打上空间角色。
- 当前缺口是设备、资源、危险和核心目标本身还缺少稳定的现场身份层。

## 本轮范围

- 新增 `DemoInitialArtIdentityProfile`，定义 5 个核心设备、2 类关键资源、1 个污染危险和 1 个核心目标的视觉身份。
- 新增 `DemoInitialArtIdentityLayer`，在 `VerticalSliceMap` 中生成现场轮廓和状态条，并给锚点写入 `initial_art_identity_id`、`initial_art_role` 和 `initial_art_material`。
- 覆盖前哨核心、基础反应器、基础储存箱、出发整备台、污染过滤器、晶体矿物、污染沉积物、污染压力和核心稳定站。
- 新增 `demo_initial_art_identity_check.gd` 与默认检查入口，验证身份 profile、场景层、锚点元数据和 12 区域封顶。

## 当前不做

- 不新增第 13 区域。
- 不做最终美术包、大规模换皮、过场动画或完整地图重绘。
- 不新增设备、资源、敌人类型、配方、任务链或长期存档字段。
- 不做完整 UI 组件库、背包、装备栏、死亡系统、结算页、联机入口或发布流程。

## 玩家操作路径

```text
进入场景 -> 识别设备 / 资源 / 危险 / 核心目标 -> 按现场身份决定采集、处理、整备或推进 -> HUD 和设备面板只补充状态细节
```

## 运行时、存档与数据边界

- 运行时只新增场景表现层和 profile，不修改世界状态、角色状态或存档结构。
- 轮廓 / 状态条由既有地图节点和锚点生成，作为原型美术身份，不进入数据表。
- 检查必须验证真实地图节点和生成形状，不只验证文档文本。

## HUD / 场景 / 对象反馈

- 现场轮廓表示对象类别和可识别占位。
- 状态条表示该对象的主材质或职责色。
- 设备、资源、危险和核心目标使用不同 role 与 material 元数据，供后续表现迭代继续复用。

## 验收条件

- 5 个核心工业设备均有现场身份。
- 晶体资源、污染沉积物、污染压力和核心稳定站均有现场身份。
- `VerticalSliceMap` 加载后生成 body + accent 两类形状。
- 不新增区域，不修改长期状态字段。

## 验证计划

- `sh ./scripts/check-client.sh`
- `sh ./scripts/check-client.sh --with-godot`
- `sh ./scripts/check-docs.sh`
- `sh ./scripts/check-text-files.sh`
- `git diff --check`

## 风险与后续决策

- 本包仍是原型美术身份，不等于最终美术质量。
- 若玩家仍读不出设备和危险，应优先调整对象尺寸、色块层级、动效或实际交互落点，不继续堆文字提示。
