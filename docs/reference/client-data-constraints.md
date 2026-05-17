# Client Data Dictionary - 跨表约束

返回：[Client Data Dictionary](client-data-dictionary.md)

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
