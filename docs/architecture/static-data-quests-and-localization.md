# Static Data Schema - 任务与本地化

返回：[Static Data Schema](static-data-schema.md)

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

线性任务推进使用 `next_quest_ids`。`unlock_effects` 用于区域、配方、切片标记或非线性任务解锁；同一个任务不应同时写入 `next_quest_ids` 和 `unlock_effects`，避免任务激活来源出现双口径。`scripts/check-client-data.ps1` 会拦截这种重复声明。

当任务目标直接引用 `region.*` 时，对应区域的 `quest_refs` 必须包含该任务；当任务目标通过场景中的采集点、加工设备、建造点、敌人或检查点落在某个区域时，该区域的 `quest_refs` 也必须包含该任务，避免任务目标、区域数据和 HUD / 地图提示出现分叉。

当前主线任务图必须满足：

- 只有一个无前置的主线入口。
- `next_quest_ids` 与后续任务 `prerequisites` 双向对齐。
- 后续主线任务的 `stage` 必须递增。
- 所有主线任务都能从入口沿 `next_quest_ids` 到达。
- 主线任务图不得成环。
- 终点主线任务必须唯一解锁 `slice_01_complete`。

任务目标来源也纳入静态检查：

- `gather_item` 目标必须能从地图对象掉落 / 采样、敌人掉落、配方产物 / 副产或任务奖励中获得。
- `craft_item` 目标必须来自配方产物或副产。
- `defeat_enemy` 目标必须有敌人定义，并在当前 schema 中具备可生成来源。

这些检查只覆盖当前 schema 明确表达的来源关系，不推断复杂解锁时序；后续若引入正式关卡编辑器、动态刷怪表或掉落表，再扩展对应数据约束。

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
