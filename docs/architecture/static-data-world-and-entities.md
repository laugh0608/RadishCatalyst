# Static Data Schema - 世界与实体

返回：[Static Data Schema](static-data-schema.md)

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

`quest_refs` 表示该区域承载或强关联的任务，用于地图、HUD 和玩家指引反查。多地点任务应写入每个关键地点，例如先在野外采样、再回基地加工的任务，需要同时出现在野外区域和基地区域中。`scripts/check-client-data.ps1` 会校验任务中直接指向 `region.*` 的目标已被对应区域的 `quest_refs` 收录；`scripts/check-client-scenes.ps1` 会继续按第一切片场景中的交互点、加工设备、建造点和敌人实际所在区域，补查采集、制造、战斗、检查等间接地点关系，避免任务目标、区域索引和地图 / HUD 指引分叉。

当前第一切片仍是固定原型地图，场景实例与任务目标的同步由 `scripts/check-client-scenes.ps1` 兜底：任务中的交互、采样、检查、建造、加工和击败目标必须能在 `VerticalSliceMap.tscn` 找到对应交互点、建造点、加工设备或敌人实例；地图对象掉落数量也会按任务需求做最小核对，避免静态数据正确但场景未放目标。

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
