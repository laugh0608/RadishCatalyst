# Godot Project Structure - 工程结构与分层原则

返回：[Godot Project Structure](godot-project-structure.md)

## 文档目的

这份文档用于定义 RadishCatalyst 客户端工程目录、代码分层和首个原型落点。

它不是最终代码规范，也不是完整技术设计。它只回答：

- Godot 工程放在哪里。
- 目录如何拆。
- 哪些逻辑不能写进场景节点或 UI。
- 第一个可玩切片应优先实现哪些模块。
- 如何避免未来存档、联机、Wiki 和官方工具接入时重构。

## 工程位置

Godot 客户端工程放在：

```text
client/
```

当前工程已在 `client/` 初始化：

- 项目名：`RadishCatalyst`
- 渲染器：`Forward+`
- Godot 版本线：Godot 4.x 普通版
- 首版脚本语言：GDScript
- 当前提交范围：保留 `project.godot`、Godot 默认图标、首批静态数据、脚本、场景和 Godot 生成的 `.gd.uid`，不提交 `.godot/` 编辑器缓存。

仓库根目录仍保留：

- `docs/`：开发者文档。
- `assets/`：可提交源资产和概念素材。
- `scripts/`：仓库检查脚本。
- `tools/`：开发辅助脚本。
- `wiki/`：玩家 Wiki 源内容。
- `official-tools/`：未来官方辅助工具。

不要把 Godot 工程文件散落在仓库根目录。

## 推荐目录结构

首版建议：

```text
client/
  project.godot
  data/
  scenes/
  scripts/
  assets/
  ui/
  save/
  tests/
```

更细分：

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
  scenes/
    boot/
    game/
    actors/
    base/
    maps/
    ui/
  scripts/
    core/
    systems/
    state/
    actors/
    combat/
    interaction/
    base/
    inventory/
    map/
    quests/
    save/
    ui/
  assets/
    sprites/
    tiles/
    icons/
    audio/
    shaders/
  save/
    schemas/
    migrations/
  tests/
```

目录可以随实现微调，但职责边界不要混乱。

## 分层原则

### core

放通用基础能力：

- ID 工具。
- 时间工具。
- 事件总线或信号协调。
- 配置加载入口。
- 全局常量。

不放具体玩法规则。

### state

放可保存的状态对象：

- `WorldState`
- `CharacterState`
- `InventoryState`
- `BaseState`
- `MapState`
- `QuestState`
- `TimeWeatherState`

状态对象应尽量是数据容器，不直接操作 UI 和场景表现。

### systems

放规则处理：

- 资源与配方系统。
- 建造放置系统。
- 污染系统。
- 时间天气系统。
- 任务系统。
- 存档协调。

系统读取状态，执行命令，产出新的状态或事件。

### quests

放任务规则和任务推进 helper：

- `QuestEventRules`：把交互、区域、配方、建造和敌人击败事件映射为任务目标进度更新请求。
- `QuestProgressRules`：根据静态任务定义写入目标进度、按目标上限封顶，并判断任务目标是否满足。
- `QuestCompletionRules`：根据目标满足度完成 active 任务，写入任务解锁效果，激活后续任务，并返回奖励、解锁和后续任务结果。

`QuestState` 只保存 active / completed / objective progress / unlock effects 等状态，不直接读取静态数据。

### actors

放玩家、敌人和可行动实体的表现与控制。

注意：

- 移动和动画可以在 actor 脚本中。
- 战斗结算、掉落、任务推进不应只写在 actor 场景里。

### combat

放战斗规则：

- 伤害计算。
- 命中和受击。
- 武器和工具效果。
- 敌人战斗行为。

首版保持简单，但不要直接写死在 UI 或地图对象里。

### interaction

放交互规则：

- 采集。
- 采样。
- 可破坏对象。
- 清理。
- 平整。
- 地基放置。
- 使用工具。

交互应产生命令或状态变更，便于存档和未来联机。

### base

放基地和工业系统：

- 设备运行。
- 配方处理。
- 库存输入输出。
- 储存。
- 管线预留。
- 设备异常状态。

首版可以没有完整自动化，但设备状态和库存变化必须走规则层。

### inventory

放库存、背包、箱体和储罐逻辑。

库存逻辑应支持：

- 物品数量。
- 流体数量。
- 设备内部缓存。
- 背包容量。
- 存档序列化。

### map

放地图与地块逻辑：

- 地块高度。
- 可建造性。
- 污染覆盖。
- 已探索状态。
- 地图对象实例。
- 区域解锁。

不要把地图状态只放在 TileMap 视觉层。

### quests

放任务和目标系统：

- 任务定义加载。
- 任务状态。
- 目标检测。
- 解锁触发。
- UI 提示事件。

任务系统不应硬编码在教程 UI 里。

### save

放存档服务：

- 保存。
- 加载。
- 校验。
- 迁移。
- 备份。
- 导入导出预留。

首版至少要能保存和读取第一可玩切片。

### ui

放 UI 控制器和视图。

原则：

- UI 显示状态，不持有核心状态所有权。
- UI 触发命令，不直接改世界状态。
- UI 文本使用本地化键。
