# Content Authoring Guide

更新时间：2026-05-09

## 目的

这份文档说明当前 Godot 原型里新增或修改一包内容时，通常需要改哪些文件、哪些地方仍是硬编码、最小验证应怎么跑。

它不是长期最终工具链设计，而是**按仓库当前实际实现**整理的工作手册。

## 适用范围

当前适用于这些改动：

- 新增或修改任务链
- 新增配方、物品、流体、装备、敌人、区域
- 新增地图交互点、建造点、加工点、敌人实例
- 扩一段新的“外出 -> 回基地 -> 再外出”闭环

不适用于：

- 规划层讨论
- 玩家 Wiki 编写
- 正式大规模数据编辑器设计

## 先判断这包内容落在哪些层

当前内容改动通常会同时落在 6 层：

1. `client/data/*.json`
2. `client/data/localization/zh_cn.json`
3. `client/scenes/maps/VerticalSliceMap.tscn`
4. `client/scripts/` 里的运行时胶水或特殊规则
5. `scripts/check-client-*.ps1`
6. `docs/` 与本周周志

如果只改了其中一层，很多时候会留下“数据有了，但场景没放”“任务写了，但区域索引没同步”“逻辑可跑，但存档校验不认”的分叉。

## 通用流程

建议按这个顺序推进：

1. 先定义这包内容要改变哪一次外勤结果。
2. 先补静态数据和本地化。
3. 再把场景实例放进 `VerticalSliceMap.tscn`。
4. 再补运行时特殊口径和存档来源表。
5. 跑匹配的最小验证。
6. 同步正式说明文档和本周周志。

不要反过来先堆 UI 提示或验证兜底，再回头想内容本身。

## 按内容类型操作

### 新增物品或流体

至少检查这些文件：

- `client/data/items.json` 或 `client/data/fluids.json`
- `client/data/localization/zh_cn.json`
- 相关 `recipes.json`、`map_objects.json`、`enemies.json`、`quests.json`

当前要点：

- 新增 `item.*` / `fluid.*` 后，只写定义还不够，还要给出真实来源。
- 任务 `gather_item` 目标的来源要能被静态检查从地图对象掉落、采样结果、敌人掉落、配方产物 / 副产、任务奖励中反推出。
- `source_refs` / `used_by_refs` 建议保持更新，但它们当前不是运行时真相源。

### 新增配方

至少检查这些文件：

- `client/data/recipes.json`
- `client/data/items.json` / `fluids.json` / `equipment.json`
- `client/data/quests.json`
- `client/data/localization/zh_cn.json`

当前要点：

- `required_building_id` 才是当前设备归属真相源。
- 如果配方是任务解锁，必须同时：
  - 在 `recipes.json` 的 `unlock_conditions` 中写任务 ID。
  - 在对应任务的 `unlock_effects` 中写同一个 `recipe.*`。
- 如果配方产物会成为任务目标，`quests.objectives` 里的 `craft_item` 必须直接指向该产物 ID。
- 如果要让设备靠近时自动切到该配方，还要改 `client/scripts/systems/processing_system.gd` 的 `get_recommended_recipe_id()`。
- 如果要让完成加工后的“下一步提示”更准确，还要改 `ProcessingSystem._get_completion_next_step()`。

### 新增任务

至少检查这些文件：

- `client/data/quests.json`
- `client/data/regions.json`
- `client/data/localization/zh_cn.json`
- 可能涉及的 `recipes.json`、`map_objects.json`、`enemies.json`

当前要点：

- 主线任务要保证 `stage` 递增。
- 前置链要双向对齐：
  - 前任务 `next_quest_ids`
  - 后任务 `prerequisites`
- `unlock_effects` 和 `next_quest_ids` 不要重复写同一个后续任务。
- 任务目标落在哪个区域，就要把该任务写进对应区域的 `quest_refs`。
- 如果目标类型是新类型，还要同步扩：
  - `QuestEventRules`
  - `QuestProgressRules`
  - `scripts/check-client-data.ps1`
  - `SaveContentValidator`

当前任务恢复 / 兼容的特殊点：

- `client/scripts/quests/quest_runtime.gd` 的 `reconcile_active_objectives()` 里已经有少量旧进度补救逻辑。
- 如果你改的是已上线原型链路，可能还需要在这里补一次兼容迁移，而不是只改静态数据。

### 新增地图对象

至少检查这些文件：

- `client/data/map_objects.json`
- `client/data/localization/zh_cn.json`
- `client/scenes/maps/VerticalSliceMap.tscn`
- `client/scripts/save/save_content_validator.gd`

当前要点：

- 对象定义只在 `map_objects.json` 出现还不够，必须把实例放进 `VerticalSliceMap.tscn`。
- 当前第一切片的存档校验是固定来源白名单，所以新增固定对象实例后，要同步更新：
  - `SaveContentValidator.PROTOTYPE_MAP_OBJECT_SOURCES`
- 场景检查会按节点名推导实例 ID：
  - `CrystalClusterEast` -> `map_object_instance.crystal_cluster_east`
- 这意味着改节点名会影响存档来源和场景检查口径。

如果对象是特殊门禁 / 终端 / 锁扣：

- 只写 `interaction_types = ["inspect"]` 不够。
- 还要改 `client/scripts/map/vertical_slice_map.gd` 的 `try_interact()` 和对应 `_inspect_*()` 分支。
- 还可能要补交互提示格式化和区域挡门逻辑。

### 新增敌人或新敌人实例

至少检查这些文件：

- `client/data/enemies.json`
- `client/data/localization/zh_cn.json`
- `client/scenes/maps/VerticalSliceMap.tscn`
- `client/scripts/save/save_content_validator.gd`

当前要点：

- 新增敌人定义后，如果它会成为任务 `defeat_enemy` 目标，场景里必须有实例。
- 固定第一切片里的敌人实例还要同步更新：
  - `SaveContentValidator.PROTOTYPE_ENEMY_SOURCES`
- 如果敌人只在某个任务阶段出现，还要改：
  - `VerticalSliceMap._should_enemy_spawn()`

### 新增建筑、建造点或加工点

至少检查这些文件：

- `client/data/buildings.json`
- `client/data/recipes.json`
- `client/data/localization/zh_cn.json`
- `client/scenes/maps/VerticalSliceMap.tscn`
- `client/scripts/systems/build_system.gd`
- `client/scripts/save/save_content_validator.gd`

当前要点：

- 新建筑定义不会自动出现建造点；建造点实例要进场景。
- 第一切片的固定建造结果同样受存档来源白名单约束，需要同步更新：
  - `SaveContentValidator.PROTOTYPE_BASE_STRUCTURE_SOURCES`
- 当前建造前置规则是脚本硬编码，不是完全数据驱动：
  - `BuildSystem._get_requirement_error()`
  - `BuildSystem._get_requirement_hint()`

如果新增加工设备：

- `VerticalSliceMap._get_recipes_for_building()` 会按 `required_building_id` 把配方挂到这个设备上。
- 设备面板、提示、保存中的运行时状态也要能识别这台设备。

### 新增区域或扩地图边界

至少检查这些文件：

- `client/data/regions.json`
- `client/scenes/maps/VerticalSliceMap.tscn`
- `client/scripts/map/vertical_slice_map.gd`
- 相关任务、敌人、地图对象、区域 `quest_refs`

当前要点：

- 当前区域划分是 `VerticalSliceMap` 里的坐标阈值硬编码，不是导航网格或区域体积数据驱动。
- 新区域通常要同步改：
  - `CRYSTAL_REGION_X`
  - `POLLUTION_REGION_X`
  - `RUIN_OUTER_RING_X`
  - `DEEP_RUIN_REGION_X`
  - `_get_region_id_for_position()`
  - `apply_region_gate_bounds()`
- `scripts/check-client-scenes.ps1` 也会按这些常量反推场景实例所属区域，所以区域口径改了后，检查脚本会一起受影响。

## 当前最需要警惕的硬编码点

这些地方是当前原型最典型的“内容扩了就容易忘”的点：

### 1. `VerticalSliceMap`

文件：

- `client/scripts/map/vertical_slice_map.gd`

当前承载：

- 区域划分
- 区域挡门
- 特殊 inspect 交互
- 敌人阶段生成
- 固定场景对象实例命名

只改数据，不改这里，很多新内容不会真正接上。

### 2. `ProcessingSystem`

文件：

- `client/scripts/systems/processing_system.gd`

当前承载：

- 任务相关配方自动推荐
- 加工完成后的下一步提示

如果新增的是“回基地加工后继续推进”的闭环，而你想让原型保持当前的引导体验，通常要补这里。

### 3. `QuestRuntime`

文件：

- `client/scripts/quests/quest_runtime.gd`

当前承载：

- 旧进度补救
- 特定任务恢复推进

如果你修改了已存在任务的中段结构，旧存档是否还能平滑读进来，需要看这里。

### 4. `SaveContentValidator`

文件：

- `client/scripts/save/save_content_validator.gd`

当前承载：

- 固定原型地图对象来源
- 固定敌人来源
- 固定建筑来源
- 设备运行时状态白名单
- 任务链 / 区域 / 配方解锁来源校验

新增第一切片固定实例而不改这里，最常见的结果是“运行时能玩，但保存后不可读”。

## 最小验证建议

### 只改静态数据

至少执行：

```powershell
pwsh ./scripts/check-client-data.ps1
pwsh ./scripts/check-text-files.ps1
git diff --check
```

### 改了场景实例、区域或 HUD 布局

至少执行：

```powershell
pwsh ./scripts/check-client-scenes.ps1
pwsh ./scripts/check-text-files.ps1
git diff --check
```

### 改了任务链、运行时系统、存档或内容闭环

默认直接执行：

```powershell
pwsh ./scripts/check-client.ps1
pwsh ./scripts/check-text-files.ps1
git diff --check
```

`check-client.ps1` 当前会串行执行：

- `check-client-data.ps1`
- `check-client-scenes.ps1`
- `check-client-save.ps1`
- `check-client-quests.ps1`
- `check-client-flow.ps1`
- `check-godot-client.ps1`

## 文档同步要求

涉及以下变化时，除了改代码和数据，还应同步正式文档：

- 新增或重排一段首小时闭环：更新 `docs/design/onboarding-and-first-hour.md`
- 运行时职责边界变化：更新 `docs/architecture/runtime-systems-overview.md`
- 数据字段或内容制作口径变化：更新 `docs/reference/client-data-dictionary.md`
- 改变常用制作流程：更新本文
- 阶段性重要推进：追加到本周周志 `docs/devlogs/2026-W19.md`

入口文档仍应保持简约，不要把制作细节堆回 `docs/planning/current.md` 或 `docs/README.md`。

## 当前推荐工作方式

如果只是补一个“最小可玩内容包”，推荐优先级是：

1. 先保证新收益和新门槛真的改变下一次外勤结果。
2. 再保证任务链、区域索引、存档来源和场景实例同步。
3. 最后再补额外 HUD 文案、日志润色和更多兜底提示。

当前仓库最缺的不是再多一层兜底，而是把“内容、数据、场景、运行时、校验、文档”六层统一起来。

## 相关文档

- [Client Data Dictionary](client-data-dictionary.md)
- [Runtime Systems Overview](../architecture/runtime-systems-overview.md)
- [Static Data Schema](../architecture/static-data-schema.md)
- [Save Data Model](../architecture/save-data-model.md)
