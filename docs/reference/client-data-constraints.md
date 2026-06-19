# Client Data Dictionary - 跨表约束

返回：[Client Data Dictionary](client-data-dictionary.md)

## 当前跨表强约束

当前最容易出错、也最值得优先记住的约束是：

1. `recipes.unlock_conditions` 必须和任务 `unlock_effects` 中的 `recipe.*` 双向一致。
2. `regions.quest_refs` 必须覆盖直接区域目标和场景反推到的任务区域。
3. `quests.objectives` 中的 `gather_item` / `craft_item` / `defeat_enemy` 必须有可反查来源。
4. `recipes.required_building_id` 才是当前设备配方归属真相源，不是 `buildings.recipe_categories`。
5. 固定第一切片里的地图对象、敌人和建筑实例，不只要有静态数据，还要在场景和 `SaveContentValidator` 里有对应来源。
6. 新增固定回访对象或守卫时，要同步 `client/data/*`、场景实例、`SaveContentValidator` 来源表和允许字段；否则存档读取会把该实例视为未知来源。

## 当前固定回访内容

2026-06-14 后，核心稳定站与基地后勤回访链新增了几类固定实例：

- `map_object.outpost_logistics_route_sign`：基地后勤路线牌，只做 `inspect`，用于把前哨核心、储存箱、浆液缓冲罐、出发整备台和外勤出发口读成同一条出发路线。
- `map_object.demo_stabilization_retest_readout_cache`：核心复测读数缓存，掉落基础零件和修复凝胶，来源写入 `items.source_refs`。
- `map_object.demo_stabilization_logistics_retest_residue`：后勤维护复测沉积，掉落污染沉积物，使用独立定义但仍沿污染处理链回过滤器。
- `enemy.demo_stabilization_logistics_retest_skitter`：核心站后勤维护复测守卫，实例归属 `region.demo_stabilization_core`。

这些实例会使用 `core_archive_maintained`、`logistics_material_processed`、`logistics_maintenance_confirmed` 和 `logistics_maintenance_retest_processed` 等运行时字段；字段白名单必须和运行时写入保持一致。

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
