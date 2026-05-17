# Static Data Schema - 基础约定

返回：[Static Data Schema](static-data-schema.md)

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
