# Static Data Schema

更新时间：2026-04-29

## 文档目的

这份文档用于在 Godot 工程初始化前，先定义 RadishCatalyst 首版静态数据的组织方式。

它不是最终字段全集，也不是数据编辑器设计。它只回答：

- 哪些内容应写成静态配置。
- 静态配置与存档状态如何分离。
- 稳定 ID 如何命名。
- 首个可玩切片至少需要哪些数据表。
- 这些数据如何服务游戏、存档、玩家 Wiki 和官方工具。

## 总原则

RadishCatalyst 的核心数据不应散落在场景节点、UI 文本和脚本常量里。

首版应尽早把以下内容配置化：

- 物品。
- 流体。
- 配方。
- 建筑和设备。
- 装备和模块。
- 消耗品。
- 敌人。
- 地图区域。
- 地图对象。
- 污染类型。
- 天气类型。
- 任务。
- 文本和本地化键。

原则：

- 静态数据描述“规则和定义”。
- 存档描述“玩家改变后的状态”。
- UI 从静态数据和状态中读取，不直接持有规则。
- Wiki 和官方工具未来应优先复用静态数据。

## 数据格式建议

工程早期推荐使用可读文本格式。

可选方案：

- `JSON`：通用、容易调试，适合早期。
- `TOML` 或 `YAML`：更适合手写，但 Godot 支持需要额外处理。
- Godot `Resource`：编辑器集成更好，但与外部工具共享需要额外导出。

首版建议：

- 先使用 `JSON` 或 Godot 原生可稳定读写的资源格式。
- 静态数据放在统一目录中。
- 每类数据一个文件或一个目录。
- 不把开发者注释依赖为运行时字段。
- 不把中文显示名当作 ID。

推荐早期目录：

```text
client/
  data/
    items.json
    fluids.json
    recipes.json
    buildings.json
    equipment.json
    enemies.json
    regions.json
    map_objects.json
    pollution_types.json
    weather_types.json
    quests.json
    localization/
      zh_cn.json
```

后续如果数据量变大，可以改成每类一个目录。

## ID 命名规则

静态定义 ID 必须稳定、英文、可读、可分类。

格式建议：

```text
category.name_variant
```

示例：

- `item.crystal_ore`
- `item.basic_alloy_plate`
- `fluid.polluted_slurry`
- `recipe.basic_filter_module`
- `building.basic_reactor`
- `building.foundation_t1`
- `equipment.filter_module_t1`
- `consumable.antitoxin_vial_t1`
- `enemy.polluted_larva`
- `region.crystal_vein_field`
- `map_object.fragile_crystal_cluster`
- `pollution.yellow_residue`
- `weather.acid_mist`
- `quest.restore_outpost`

禁止：

- 使用显示名作为 ID。
- 使用中文 ID。
- 使用自增数字作为定义 ID。
- 为了文案改名而改 ID。
- 在存档发布后随意删除旧 ID。

## 通用字段

多数静态数据都应包含：

```text
id
display_name_key
description_key
category
tags
icon
public_level
```

字段说明：

- `id`：稳定定义 ID。
- `display_name_key`：本地化显示名键。
- `description_key`：本地化描述键。
- `category`：主分类。
- `tags`：可搜索标签。
- `icon`：图标资源引用。
- `public_level`：公开等级，例如 `public`、`spoiler`、`internal`。

`public_level` 用于未来玩家 Wiki 和官方工具，避免提前公开主线或隐藏机制。

## 物品数据

用于固体资源、材料、部件、任务物品和制造产物。

建议字段：

```text
id
display_name_key
description_key
category
tags
stack_size
mass
rarity
source_refs
used_by_refs
public_level
```

首版必需物品：

- 晶体矿物。
- 基础零件。
- 污染沉积物。
- 异常样本。
- 基础过滤模块材料。
- 地基材料。

规则：

- 物品定义不保存数量。
- 数量只存在于库存和存档中。
- 来源和用途可以先作为引用列表，后续由工具自动反查。

## 流体数据

用于污染液、溶剂、燃料、冷却剂和反应介质。

建议字段：

```text
id
display_name_key
description_key
category
tags
storage_unit
default_color
hazard_type
public_level
```

可选扩展：

- 温度范围。
- 压力范围。
- 腐蚀性。
- 毒性。
- 稳定性。
- 挥发性。

首版可以只使用数量和污染属性，但字段设计应允许后续扩展。

## 配方数据

配方是连接基地与外勤的核心。

建议字段：

```text
id
display_name_key
description_key
category
required_building_id
inputs
outputs
byproducts
duration
energy_cost
pollution_delta
unlock_conditions
public_level
```

`inputs`、`outputs`、`byproducts` 应引用物品或流体 ID。

`unlock_conditions` 当前用于说明配方由哪些任务解锁，并必须与任务定义中的 `unlock_effects` 保持一致；`scripts/check-client-data.ps1` 会校验这种对应关系，避免配方显示条件、任务奖励和运行时解锁来源分叉。

首版配方至少包括：

- 晶体矿物加工。
- 污染沉积物处理。
- 基础过滤模块制造。
- 抗性药剂或净化剂制造。
- 基础地板 / 地基制造。

规则：

- 配方不要写死在设备脚本中。
- 设备只声明可执行哪些配方类型或配方 ID。
- 任务解锁只改变配方是否可用，不改变配方定义本身。

## 建筑与设备数据

建筑和设备包含地基、储存、反应器、过滤器、污染处理设施等。

建议字段：

```text
id
display_name_key
description_key
category
footprint
build_cost
foundation_requirement
allowed_terrain
power_requirement
storage_slots
recipe_categories
placement_rules
public_level
```

首版必需：

- 基础地板 / 地基。
- 基础储存箱。
- 基础反应器或过滤器。
- 污染处理设备。

放置规则应引用：

- 是否需要平整地面。
- 是否需要地基。
- 是否允许污染地块。
- 是否允许高低差。
- 是否阻挡移动。
- 是否连接管线或能源。

## 装备、模块与消耗品数据

装备和消耗品负责把基地生产转成外勤能力。

建议字段：

```text
id
display_name_key
description_key
slot
category
stat_modifiers
effects
crafting_recipe_id
durability
unlock_conditions
public_level
```

首版必需：

- 基础武器或工具。
- 基础防护服。
- 过滤模块。
- 抗性药剂或净化剂。
- 治疗或修复物品。

规则：

- 装备效果引用效果 ID 或效果描述，不直接写在 UI 文案里。
- 消耗品效果需要可被存档和战斗系统识别。
- 首版不引入复杂随机词条。

## 敌人数据

敌人数据描述类型，不保存具体实例状态。

建议字段：

```text
id
display_name_key
description_key
category
faction
base_stats
behaviors
damage_types
resistances
drop_table_id
drops
spawn_regions
public_level
```

首版必需：

- 原生小型生物。
- 受扰污染体。
- 精英节点守卫。

规则：

- 具体敌人位置、生命、是否死亡属于存档运行时状态。
- 掉落表应独立配置，便于 Wiki 和工具反查。
- 当前原型阶段允许在敌人定义中临时保留 `drops`，用于先验证击败反馈和库存闭环；后续进入更完整掉落系统时再拆为独立掉落表。

## 区域与地图对象数据

区域定义描述区域模板。

建议字段：

```text
id
display_name_key
description_key
planet_or_world
biome_type
danger_level
resources
pollution_types
weather_pool
recommended_equipment
quest_refs
public_level
```

地图对象定义描述可交互对象类型。

建议字段：

```text
id
display_name_key
description_key
object_type
interaction_types
is_destructible
is_collectible
is_sampleable
blocks_movement
blocks_building
required_tool_tags
drops
sample_result_refs
pollution_effect
public_level
```

具体对象是否已破坏、已采集、已采样属于存档。

## 污染与天气数据

污染类型建议字段：

```text
id
display_name_key
description_key
color
hazard_effects
build_restrictions
enemy_modifiers
treatment_refs
public_level
```

天气类型建议字段：

```text
id
display_name_key
description_key
visual_profile
duration_range
visibility_modifier
pollution_modifier
energy_modifier
protection_drain_modifier
enemy_activity_modifier
public_level
```

首版可以只定义：

- 白天。
- 夜晚。
- 晴朗。
- 酸雾或污染雾。

天气当前状态属于存档，天气定义属于静态数据。

## 任务数据

任务数据需要支持主线、支线和教程目标。

建议字段：

```text
id
display_name_key
description_key
quest_type
stage
objectives
prerequisites
rewards
unlock_effects
next_quest_ids
public_level
```

目标类型限制在首版可实现范围：

- 前往地点。
- 采集资源。
- 采样对象。
- 击败敌人。
- 建造或启用设备。
- 制造物品。
- 使用物品。
- 解锁区域。
- 返回基地。

任务进度属于存档，任务定义属于静态数据。

## 本地化数据

所有玩家可见文本都应使用本地化键。

示例：

```text
item.crystal_ore.name
item.crystal_ore.desc
quest.restore_outpost.name
quest.restore_outpost.desc
ui.error.need_foundation
```

原则：

- 静态数据引用文本键。
- 中文文本放在本地化文件。
- UI 不直接硬编码正式文案。

## 首版最小数据集

第一个可玩切片至少需要：

- 6 到 10 个物品。
- 1 到 2 个流体或污染资源。
- 5 到 8 条配方。
- 4 到 6 个建筑 / 设备。
- 2 到 3 件装备 / 模块 / 消耗品。
- 2 个普通敌人和 1 个精英敌人。
- 3 个区域。
- 8 到 12 个地图对象类型。
- 1 到 2 个污染类型。
- 2 到 4 个时间 / 天气类型。
- 6 到 10 个任务。

超过这个规模前，应先确认第一可玩切片已经闭合。

## 与存档模型的关系

静态数据与 `save-data-model.md` 的关系：

- 存档引用静态定义 ID。
- 存档保存实例 ID、数量、位置、状态和进度。
- 静态数据不保存玩家进度。
- 静态数据可以被 Wiki 和官方工具读取。
- 修改静态 ID 时必须提供迁移或别名。

## 当前阶段结论

Godot 工程初始化时，应先建立 `data/` 目录和加载规则，而不是把物品、配方和任务硬编码进脚本。

首版最重要的不是字段完整，而是让：

**物品、配方、设备、任务、区域、污染和天气都能通过稳定 ID 被游戏、存档、Wiki 和官方工具共同引用。**
