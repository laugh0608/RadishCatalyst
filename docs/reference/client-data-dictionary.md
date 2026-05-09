# Client Data Dictionary

更新时间：2026-05-09

## 目的

这份文档用于说明当前 `client/data/` 下静态数据表的实际字段、运行时用途和跨表约束。

它面向两类工作：

- 内容编写：新增任务、配方、区域、敌人和交互对象时，先确认字段和约束。
- 工程维护：判断某个字段目前只是说明性信息，还是已经被脚本、场景检查或存档校验当成真相源。

它描述的是**当前 Godot 原型的已接入口径**，不是最终数据 schema 承诺。

## 真相源

当前客户端数据字典的直接真相源是：

- `client/data/*.json`
- `client/scripts/core/data_registry.gd`
- `scripts/check-client-data.ps1`
- `scripts/check-client-scenes.ps1`
- `client/scripts/save/save_content_validator.gd`

如果本文与代码不一致，以代码和检查脚本为准，然后回头修本文。

## 通用装载约定

所有静态数据文件当前都采用：

```json
{
  "schema_version": 1,
  "entries": []
}
```

通用约束：

- 每条 `entry` 必须有唯一 `id`。
- `id` 必须符合 `category.name_variant` 风格，例如 `item.crystal_ore`。
- `display_name_key` 和 `description_key` 必须存在，并能在 `client/data/localization/zh_cn.json` 中找到。
- `public_level` 当前用于区分玩家可公开程度，已有值主要是 `public` 和 `spoiler`。

`DataRegistry` 当前对所有表统一要求的字段只有：

- `id`
- `display_name_key`
- `description_key`
- `public_level`

这意味着很多更细字段是由后续运行时、检查脚本或约定共同约束的，而不是由 `DataRegistry` 单独校验。

## 表级字典

### `items.json`

用途：定义可进入背包的固体引用。

当前字段：

| 字段 | 类型 | 当前作用 |
| --- | --- | --- |
| `id` | `string` | 稳定物品 ID。 |
| `display_name_key` | `string` | 名称本地化键。 |
| `description_key` | `string` | 描述本地化键。 |
| `category` | `string` | 物品分类，当前主要用于说明和后续扩展。 |
| `tags` | `string[]` | 标签，当前主要用于说明。 |
| `stack_size` | `number` | 堆叠上限，当前未由背包容量逻辑严格执行。 |
| `mass` | `number` | 单位质量，当前主要用于说明。 |
| `rarity` | `string` | 稀有度，当前主要用于说明。 |
| `source_refs` | `string[]` | 来源反查，当前主要用于文档和人工理解。 |
| `used_by_refs` | `string[]` | 用途反查，当前主要用于文档和人工理解。 |
| `public_level` | `string` | 公开等级。 |

当前运行时真正依赖物品 ID 的地方：

- `InventoryState`
- 配方输入输出
- 任务目标 `gather_item` / `craft_item`
- 快捷栏消耗品使用
- 敌人掉落、地图对象掉落、任务奖励

注意：

- `source_refs` / `used_by_refs` 目前不会自动驱动运行时。
- `scripts/check-client-data.ps1` 当前不会反查 `source_refs` 是否完整；它会直接从地图对象、敌人、配方和任务奖励推导来源。

### `fluids.json`

用途：定义可进入库存流体槽的流体引用。

当前字段：

| 字段 | 类型 | 当前作用 |
| --- | --- | --- |
| `id` | `string` | 稳定流体 ID。 |
| `display_name_key` | `string` | 名称本地化键。 |
| `description_key` | `string` | 描述本地化键。 |
| `category` | `string` | 分类，当前主要用于说明。 |
| `tags` | `string[]` | 标签，当前主要用于说明。 |
| `storage_unit` | `string` | 存储单位说明。 |
| `default_color` | `string` | 默认颜色。 |
| `hazard_type` | `string` | 危害类型，当前主要用于说明。 |
| `public_level` | `string` | 公开等级。 |

当前运行时：

- 流体和物品共用 `InventoryState.has_ref()` / `consume_ref()` / `add_ref()`。
- 配方输入输出里只要 `id` 以 `fluid.` 开头，就会走流体库存分支。

### `recipes.json`

用途：定义基础反应器、污染过滤器等加工配方。

当前字段：

| 字段 | 类型 | 当前作用 |
| --- | --- | --- |
| `id` | `string` | 配方 ID。 |
| `display_name_key` | `string` | 名称本地化键。 |
| `description_key` | `string` | 描述本地化键。 |
| `category` | `string` | 分类；当前更多用于说明，不是实际分发真相源。 |
| `required_building_id` | `string` | 真正决定该配方属于哪台设备。 |
| `inputs` | `[{id, amount}]` | 输入引用。 |
| `outputs` | `[{id, amount}]` | 产物引用。 |
| `byproducts` | `[{id, amount}]` | 副产引用。 |
| `duration` | `number` | 加工时长秒数。 |
| `energy_cost` | `number` | 能耗说明，当前主要用于说明。 |
| `pollution_delta` | `number` | 污染变化说明，当前主要用于说明。 |
| `unlock_conditions` | `string[]` | 任务解锁来源说明，且会被静态检查严格校验。 |
| `public_level` | `string` | 公开等级。 |

当前运行时真相：

- `ProcessingSystem` 用 `required_building_id` 找设备。
- `VerticalSliceMap._get_recipes_for_building()` 也是按 `required_building_id` 过滤，不看 `recipe_categories`。
- `unlock_conditions` 当前不直接驱动解锁逻辑；真正的运行态解锁状态保存在 `quest_state.unlocked_effects`。
- 但 `unlock_conditions` 会被 `scripts/check-client-data.ps1` 校验，要求与任务里的 `unlock_effects` 双向一致。

### `buildings.json`

用途：定义固定设备、建造物和地基。

当前字段：

| 字段 | 类型 | 当前作用 |
| --- | --- | --- |
| `id` | `string` | 建筑 / 设备 ID。 |
| `display_name_key` | `string` | 名称本地化键。 |
| `description_key` | `string` | 描述本地化键。 |
| `category` | `string` | 建筑分类。 |
| `footprint` | `number[2]` | 占地说明。 |
| `build_cost` | `[{id, amount}]` | 建造成本。 |
| `foundation_requirement` | `string` | 地基要求说明。 |
| `allowed_terrain` | `string[]` | 允许地形说明。 |
| `power_requirement` | `number` | 能耗说明。 |
| `storage_slots` | `number` | 设备可拥有的缓冲槽位上限；存档校验会用到。 |
| `recipe_categories` | `string[]` | 当前主要用于说明，不是配方归属真相源。 |
| `placement_rules` | `object` | 放置规则说明。 |
| `public_level` | `string` | 公开等级。 |

当前运行时：

- `BuildSystem` 实际读取 `build_cost`。
- `BuildSystem` 的真实前置规则目前写死在脚本中，例如污染过滤器必须先有 2 块地基。
- `storage_slots` 已被 `SaveContentValidator` 用来校验设备 `input_buffer` / `output_buffer`。

### `equipment.json`

用途：定义工具、护甲和模块。

当前字段：

| 字段 | 类型 | 当前作用 |
| --- | --- | --- |
| `id` | `string` | 装备 ID。 |
| `display_name_key` | `string` | 名称本地化键。 |
| `description_key` | `string` | 描述本地化键。 |
| `slot` | `string` | 槽位，例如 `tool`、`suit`、`suit_module`。 |
| `category` | `string` | 分类。 |
| `stat_modifiers` | `object` | 数值修正；当前已接入部分字段。 |
| `effects` | `string[]` | 效果标签；当前主要给工具能力判断使用。 |
| `crafting_recipe_id` | `string` | 来源配方引用。 |
| `durability` | `number` | 耐久说明，当前未消耗。 |
| `unlock_conditions` | `string[]` | 说明性解锁条件。 |
| `public_level` | `string` | 公开等级。 |

当前已接入的 `stat_modifiers` 语义：

- `attack_power`：影响近战攻击伤害。
- `pollution_drain_mult`：影响污染消耗倍率。

当前已接入的 `effects` 语义：

- `effect.gather_basic`
- `effect.sample_basic`
- `effect.construct_basic`
- `effect.attack_basic`

`GatherSystem` 会按地图对象的 `required_tool_tags` 去检查这些效果标签。

### `enemies.json`

用途：定义敌人类型。

当前字段：

| 字段 | 类型 | 当前作用 |
| --- | --- | --- |
| `id` | `string` | 敌人 ID。 |
| `display_name_key` | `string` | 名称本地化键。 |
| `description_key` | `string` | 描述本地化键。 |
| `category` | `string` | 分类。 |
| `faction` | `string` | 阵营。 |
| `base_stats` | `object` | 当前已接入 `max_health`、`attack`、`move_speed`。 |
| `behaviors` | `string[]` | 行为标签，当前主要用于说明。 |
| `damage_types` | `string[]` | 当前已接入 `physical`、`pollution`。 |
| `resistances` | `object` | 当前主要用于说明。 |
| `drop_table_id` | `string` | 当前未接入独立掉落表，只保留占位。 |
| `drops` | `[{id, amount}]` | 当前实际掉落真相源。 |
| `spawn_regions` | `string[]` | 生成区域；静态检查会看是否为空。 |
| `public_level` | `string` | 公开等级。 |

注意：

- 当前固定第一切片里的实际敌人实例，还要同时写进场景和 `SaveContentValidator` 的原型来源表。
- 某些敌人是否出现，不只由 `spawn_regions` 决定，还受 `VerticalSliceMap._should_enemy_spawn()` 的任务阶段硬编码控制。

### `regions.json`

用途：定义区域索引、区域风险和任务归属。

当前字段：

| 字段 | 类型 | 当前作用 |
| --- | --- | --- |
| `id` | `string` | 区域 ID。 |
| `display_name_key` | `string` | 名称本地化键。 |
| `description_key` | `string` | 描述本地化键。 |
| `planet_or_world` | `string` | 所属世界。 |
| `biome_type` | `string` | 区域类型。 |
| `danger_level` | `number` | 危险等级。 |
| `resources` | `string[]` | 资源索引说明。 |
| `pollution_types` | `string[]` | 区域污染类型引用。 |
| `weather_pool` | `string[]` | 候选天气引用。 |
| `recommended_equipment` | `string[]` | 推荐装备引用。 |
| `quest_refs` | `string[]` | 当前非常关键的任务区域反查索引。 |
| `public_level` | `string` | 公开等级。 |

`quest_refs` 当前不是摆设：

- `scripts/check-client-data.ps1` 会校验直接指向 `region.*` 的任务目标。
- `scripts/check-client-scenes.ps1` 会按场景中的交互点、加工设备、建造点和敌人所在区域，反推任务必须被哪些区域收录。

### `map_objects.json`

用途：定义采集点、采样点、地块清理点和特殊检查物。

当前字段：

| 字段 | 类型 | 当前作用 |
| --- | --- | --- |
| `id` | `string` | 地图对象定义 ID。 |
| `display_name_key` | `string` | 名称本地化键。 |
| `description_key` | `string` | 描述本地化键。 |
| `object_type` | `string` | 对象类型。 |
| `interaction_types` | `string[]` | 当前支持 `gather`、`sample`、`clear`、`level`、`inspect`。 |
| `is_destructible` | `bool` | 说明性标记。 |
| `is_collectible` | `bool` | 说明性标记。 |
| `is_sampleable` | `bool` | 说明性标记。 |
| `blocks_movement` | `bool` | 说明性标记。 |
| `blocks_building` | `bool` | 说明性标记。 |
| `required_tool_tags` | `string[]` | 当前会被 `GatherSystem` 真正校验。 |
| `drops` | `[{id, amount}]` | `gather` 成功时实际掉落真相源。 |
| `sample_result_refs` | `string[]` | `sample` 成功时实际产出真相源。 |
| `pollution_effect` | `string` | 当前会触发污染防护消耗。 |
| `public_level` | `string` | 公开等级。 |

注意：

- 特殊门禁、终端、锁扣等 `inspect` 对象，很多逻辑不是通用数据驱动，而是写在 `VerticalSliceMap.try_interact()` 的专门分支里。

### `pollution_types.json`

用途：定义污染类型。

当前字段：

| 字段 | 类型 | 当前作用 |
| --- | --- | --- |
| `id` | `string` | 污染类型 ID。 |
| `display_name_key` | `string` | 名称本地化键。 |
| `description_key` | `string` | 描述本地化键。 |
| `color` | `string` | 颜色。 |
| `hazard_effects` | `object[]` | 当前已接入 `effect=protection_drain`。 |
| `build_restrictions` | `string[]` | 说明性限制。 |
| `enemy_modifiers` | `object[]` | 说明性修正。 |
| `treatment_refs` | `string[]` | 治理方式反查。 |
| `public_level` | `string` | 公开等级。 |

当前污染消耗由：

- `GatherSystem._apply_pollution_pressure()`
- `CharacterState.get_pollution_drain_multiplier()`

共同处理。

### `weather_types.json`

用途：定义天气模板。

当前字段：

| 字段 | 类型 | 当前作用 |
| --- | --- | --- |
| `id` | `string` | 天气 ID。 |
| `display_name_key` | `string` | 名称本地化键。 |
| `description_key` | `string` | 描述本地化键。 |
| `visual_profile` | `string` | 视觉风格标签。 |
| `duration_range` | `number[2]` | 时长范围。 |
| `visibility_modifier` | `number` | 说明性修正。 |
| `pollution_modifier` | `number` | 说明性修正。 |
| `energy_modifier` | `number` | 说明性修正。 |
| `protection_drain_modifier` | `number` | 说明性修正。 |
| `enemy_activity_modifier` | `number` | 说明性修正。 |
| `public_level` | `string` | 公开等级。 |

当前运行时只保存并校验 `current_weather_id`，还没有完整天气演化和全局数值接入。

### `quests.json`

用途：定义主线任务图、目标、奖励和解锁结果。

当前字段：

| 字段 | 类型 | 当前作用 |
| --- | --- | --- |
| `id` | `string` | 任务 ID。 |
| `display_name_key` | `string` | 名称本地化键。 |
| `description_key` | `string` | 描述本地化键。 |
| `quest_type` | `string` | 当前主线任务使用 `main`。 |
| `stage` | `number` | 主线阶段编号。 |
| `objectives` | `object[]` | 当前目标定义真相源。 |
| `prerequisites` | `string[]` | 前置任务。 |
| `rewards` | `[{id, amount}]` | 完成奖励。 |
| `unlock_effects` | `string[]` | 解锁区域、配方、切片标记等。 |
| `next_quest_ids` | `string[]` | 线性后续任务。 |
| `public_level` | `string` | 公开等级。 |

当前已接入的目标类型包括：

- `interact`
- `visit_region`
- `gather_item`
- `craft_item`
- `sample_object`
- `build`
- `defeat_enemy`
- `inspect`

关键约束：

- `scripts/check-client-data.ps1` 会校验主线图唯一入口、可达性、无环、阶段递增。
- 同一任务不应同时通过 `next_quest_ids` 和 `unlock_effects` 解锁同一后续任务。
- `unlock_effects` 中的 `recipe.*` / `region.*` 会进入 `quest_state.unlocked_effects`，并被存档校验继续约束。

## 当前跨表强约束

当前最容易出错、也最值得优先记住的约束是：

1. `recipes.unlock_conditions` 必须和任务 `unlock_effects` 中的 `recipe.*` 双向一致。
2. `regions.quest_refs` 必须覆盖直接区域目标和场景反推到的任务区域。
3. `quests.objectives` 中的 `gather_item` / `craft_item` / `defeat_enemy` 必须有可反查来源。
4. `recipes.required_building_id` 才是当前设备配方归属真相源，不是 `buildings.recipe_categories`。
5. 固定第一切片里的地图对象、敌人和建筑实例，不只要有静态数据，还要在场景和 `SaveContentValidator` 里有对应来源。

## 当前最容易误判的字段

以下字段现在更像“结构化说明”，不要误以为它们已经完整驱动运行时：

- `items.source_refs`
- `items.used_by_refs`
- `fluids.hazard_type`
- `recipes.energy_cost`
- `recipes.pollution_delta`
- `buildings.recipe_categories`
- `equipment.unlock_conditions`
- `enemies.behaviors`
- `enemies.drop_table_id`
- `weather_types.*_modifier`

这些字段仍然有价值，因为它们：

- 帮助文档化和后续工具化。
- 约束数据表达方向。
- 减少未来再补结构化字段时的返工。

但当前如果只改这些字段，不一定会改变原型实际行为。

## 相关文档

- [Static Data Schema](../architecture/static-data-schema.md)
- [Save Data Model](../architecture/save-data-model.md)
- [Content Authoring Guide](content-authoring-guide.md)
- [Runtime Systems Overview](../architecture/runtime-systems-overview.md)
