# Save Data Model - 角色档案与文件

返回：[Save Data Model](save-data-model.md)

## 角色档案结构建议

角色档案可以按逻辑块组织：

```text
character
metadata
status
progression
equipment
inventory
known_data
```

### status

保存：

- 当前世界 ID。
- 当前区域 ID。
- 位置。
- 朝向。
- 生命。
- 防护完整度。
- 能量或体力。
- 当前环境状态，例如中毒、腐蚀、低温、污染暴露。
- 复活点或撤离点。

### progression

保存：

- 等级。
- 经验。
- 已解锁基础能力。
- 外勤专精或轻量天赋。
- 区域适应进度。

### equipment

保存：

- 武器槽。
- 防护服槽。
- 模块槽。
- 快捷栏。
- 当前弹药或消耗品绑定。

装备实例可以先用定义 ID + 耐久 + 模块组合表达。首版不建议引入复杂随机词条实例。

### inventory

保存角色背包：

- 物品 ID。
- 数量。
- 可选耐久或状态。

背包容量、负重和任务物品规则应可由角色状态和配置推导。

### known_data

保存个人发现：

- 已扫描资源。
- 已识别敌人。
- 已见过天气或污染类型。
- 已发现区域提示。

这些信息未来可服务 Wiki 解锁、提示和官方工具公开等级。

## 命令与存档关系

为了兼容未来联机，关键交互应尽量命令化。

首版建议至少定义这些命令心智：

- `MoveCharacter`
- `Attack`
- `UseTool`
- `CollectResource`
- `TakeSample`
- `DamageMapObject`
- `ClearTile`
- `LevelTile`
- `PlaceFoundation`
- `BuildStructure`
- `RemoveStructure`
- `SetRecipe`
- `TransferItem`
- `UseConsumable`
- `UnlockRegion`

存档保存命令执行后的状态，不需要保存完整命令日志。

但调试和未来回放可以可选记录近期命令，用于复现错误。

## 文件格式建议

工程初始化前暂不强制具体格式。

建议原则：

- 首版可使用 JSON 或 Godot 可稳定读写的文本 / 二进制资源格式。
- 开发早期优先可读、可 diff、可排查。
- 世界存档较大后，可以拆分区域块或使用压缩。
- 不把存档和静态配置混在一个文件。
- 不在存档中保存本地化显示文本。

推荐早期结构：

```text
saves/
  worlds/
    world_20260426_001/
      world.json
      regions.json
      map_cells.json
      map_objects.json
      base.json
      inventories.json
      pollution.json
      time_weather.json
      quests.json
  characters/
    character_20260426_001.json
  player_profile.json
  settings.json
```

后续如果单文件更方便，也可以合并，但逻辑边界不应消失。
