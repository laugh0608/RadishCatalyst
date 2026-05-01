# Godot Project Structure

更新时间：2026-04-29

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

- `QuestProgressRules`：根据静态任务定义写入目标进度、按目标上限封顶，并判断任务目标是否满足。

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

## 场景组织

推荐首版场景：

```text
scenes/boot/Boot.tscn
scenes/game/GameRoot.tscn
scenes/actors/Player.tscn
scenes/actors/EnemyBasic.tscn
scenes/actors/EnemyPolluted.tscn
scenes/maps/VerticalSliceMap.tscn
scenes/base/BasePlatform.tscn
scenes/ui/Hud.tscn
scenes/ui/BasePanel.tscn
scenes/ui/InventoryPanel.tscn
scenes/ui/QuestTracker.tscn
```

`GameRoot` 负责组合世界、玩家、地图、UI 和系统入口。

不要让单个场景承担全部逻辑。

## 自动加载建议

Godot `Autoload` 应少而清楚。

可考虑：

- `DataRegistry`：加载静态配置。
- `GameSession`：持有当前世界和角色状态引用。
- `SaveService`：保存、加载、槽位、备份和迁移协调。
- `SaveContentValidator`：存档内容一致性、运行时来源和跨块关系校验。
- `EventBus`：跨系统信号协调。

不建议：

- 把所有游戏规则都塞进一个全局单例。
- UI 通过全局单例直接改库存、任务和地图。
- 用 Autoload 替代清晰系统分层。

## 命令流

关键交互建议遵循：

```text
输入 / UI
-> 命令
-> 系统验证
-> 状态变更
-> 事件
-> 表现刷新
-> 存档可保存
```

示例：

```text
玩家点击建造过滤器
-> BuildStructureCommand
-> BuildSystem 检查地基、材料、污染、占地
-> BaseState 和 InventoryState 更新
-> UI 显示成功，地图生成设备表现
-> SaveService 可保存新设备实例
```

这种心智能减少未来联机重构。

## 首个原型实现顺序

建议顺序：

1. 建立 `DataRegistry`，加载最小静态数据。已完成。
2. 建立 `WorldState`、`CharacterState`、`InventoryState`。已完成，并补充 `QuestState`。
3. 建立 `GameRoot` 和玩家移动。已完成。
4. 建立基础地图和地块数据。已完成临时地图和地图对象实例状态雏形。
5. 建立采集和库存。已完成采集 / 采样规则层雏形。
6. 建立基础战斗和敌人。已完成基础攻击、基础敌人、污染区基础敌人、HP、击败状态和即时反击压力雏形。
7. 建立基地设备和一条配方。已完成基础反应器多配方命令和污染过滤器单配方命令雏形。
8. 建立任务目标和 HUD。已完成当前目标、目标进度、生命、防护、模块、背包摘要、交互提示和日志雏形。
9. 建立建造、地基和建造失败提示。
10. 建立污染边界和防护消耗。已完成污染沉积斑防护消耗、过滤模块减免、污染敌人防护压力和污染处理点雏形。
11. 建立存档保存 / 读取。已完成原型单文件 `SaveService`，支持 `K` 保存、`L` 读取和保存前最近 3 份备份轮转。
12. 建立存档运行时复验。已完成 `check-client-save.ps1`，覆盖原型坏档、旧档兜底、默认状态保存 / 读取、切片结尾状态和备份轮转。
13. 串起第一可玩切片。

不要先做：

- 完整 UI 皮肤。
- 多区域地图。
- 完整自动化管线。
- 复杂天气。
- 多武器和技能树。
- 联机入口。

## 当前验证入口

当前客户端原型的最小验证入口：

```powershell
pwsh ./scripts/check-client-data.ps1
pwsh ./scripts/check-client-scenes.ps1
pwsh ./scripts/check-client-save.ps1
pwsh ./scripts/check-godot-client.ps1
pwsh ./scripts/check-text-files.ps1
```

`check-godot-client.ps1` 当前使用 Godot 4.6.2 console 的 `--import --quit` 完成项目导入和全局类注册验证。`--headless --path ... --quit` 和 `--check-only --script` 在当前 Windows / Godot 4.6.2 环境会触发引擎层崩溃，因此暂不作为门禁。

`check-client-save.ps1` 当前会先执行一次 Godot 导入，再通过 `client/scripts/checks/save_service_check.gd` 运行 `SaveService` 读写和备份校验，并将 Godot 配置、数据、缓存和 `user://` 存档目录隔离到 `.godot-check-home/save-service/` 下。

## GDScript 与 C# 边界

当前项目默认优先使用 GDScript。

原因：

- Godot 原型速度快。
- 与编辑器和场景工作流贴合。
- 当前项目首版重点是验证玩法闭环，不是高性能后端计算。
- 避免额外引入 C# / .NET 工具链复杂度和平台兼容风险。
- Windows、Web 试玩和 Android 远期评估的共同客户端基线更适合先用 GDScript。

只有在后续出现明确需求时，才评估 C#：

- 大型工具链。
- 复杂数据处理。
- 团队已有 C# 工程基础。
- 性能瓶颈需要重写核心模块。

.NET / C# 更适合优先放在：

- 外部数据校验工具。
- 静态数据编辑器或检查器。
- 存档迁移工具。
- 官方 WebApp 后端。
- 后续服务端、房间服务或专用服务器。

当前不建议把 Godot 客户端核心押到 C#，尤其是在 Web 试玩仍作为可选传播渠道保留时。

如果未来要在客户端引入 C#，必须先复核平台影响，并同步更新平台兼容、存档模型和工程结构文档。

## 当前不做

Godot 初始工程不做：

- 完整插件架构。
- 完整 ECS。
- 完整多人网络层。
- 复杂资源热更新。
- 自研编辑器工具。
- 大型内容导入流水线。
- 高保真 UI 组件库。

但必须避免：

- 单文件主脚本。
- UI 直接修改核心状态。
- 场景节点路径作为存档 ID。
- 任务和配方硬编码。
- 静态数据和存档混在一起。
- 所有系统都挂在 `GameRoot` 一个脚本里。

当前 `GameRoot` 仍承担原型任务事件编排，但任务目标进度写入、目标上限封顶和目标满足度判断已下沉到 `scripts/quests/quest_progress_rules.gd`。后续进入更完整任务系统、存档或联机命令化之前，应继续把目标检测、奖励发放和解锁触发逐步下沉到 `scripts/quests/` 或系统层，避免场景根脚本继续膨胀。

## 与仓库结构的关系

Godot 工程只负责客户端原型。

仓库其他目录仍保持：

- `docs/`：决策和设计真相源。
- `assets/`：源资产和概念图。
- `scripts/`：仓库检查脚本。
- `tools/`：开发辅助工具。
- `wiki/`：玩家 Wiki 源内容。
- `official-tools/`：未来官方工具。
- `server/`：后续联机或服务端实验。

不要把玩家 Wiki、官方工具或服务端代码放进 Godot 客户端目录。

## 当前阶段结论

Godot 工程初始化的目标不是搭一个“大而全框架”，而是为第一可玩切片建立清晰边界。

最重要的结构是：

**静态数据在 `data/`，可保存状态在 `state/`，规则在 `systems/`，表现和场景在 `scenes/` 与 `ui/`，存档在 `save/`。**

只要这条边界稳定，后续扩展任务、天气、污染、装备、基地和联机都会更可控。
