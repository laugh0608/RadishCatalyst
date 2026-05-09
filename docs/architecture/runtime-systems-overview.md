# Runtime Systems Overview

更新时间：2026-05-09

## 目的

这份文档说明当前 Godot 原型运行时的实际系统分工、主数据流和几个关键硬边界。

它回答的是：

- 游戏启动后由谁组装系统。
- 世界状态、角色状态、任务状态和静态数据分别由谁持有。
- 交互、战斗、加工、建造、任务推进和存档是怎么串起来的。
- 哪些部分已经相对清晰，哪些部分仍是为了原型推进保留的硬编码。

它不是最终架构承诺；它描述的是 **`client/` 当前真正在跑的结构**。

## 直接真相源

本文主要对应这些文件：

- `client/scripts/game/game_root.gd`
- `client/scripts/core/data_registry.gd`
- `client/scripts/state/*.gd`
- `client/scripts/map/vertical_slice_map.gd`
- `client/scripts/systems/*.gd`
- `client/scripts/quests/*.gd`
- `client/scripts/ui/*.gd`
- `client/scripts/save/*.gd`

## 当前系统总览

### 1. 组装入口：`GameRoot`

`GameRoot` 是当前运行时的主编排器。

它在 `_ready()` 中完成：

- 创建默认 `WorldState` 和 `CharacterState`
- 初始化 `SaveService`
- 创建 `ProcessingSystem`、`BuildSystem`、`QuestRuntime`
- 创建交互提示和 HUD presenter
- 配置 `VerticalSliceMap`
- 绑定玩家输入、HUD 按钮、区域变化和交互信号

它在 `_process()` 中持续做：

- 推进设备加工进度
- 补做任务恢复 / 对账
- 刷新敌人阶段生成
- 刷新交互上下文
- 同步角色位置、相机和 HUD

当前判断：

- `GameRoot` 已不再承担所有业务细节。
- 但它仍然是运行时“总调度台”，很多流程还是通过它串接多个子系统。

### 2. 静态数据层：`DataRegistry`

`DataRegistry` 负责装载：

- `client/data/*.json`
- `client/data/localization/zh_cn.json`

当前职责：

- 读取并缓存所有表
- 建立 `definitions_by_id`
- 提供 `get_definition()`、`get_table()`、`get_text()`

它不负责：

- 跨表复杂约束
- 解锁逻辑
- 存档兼容

这些工作现在分别落在检查脚本、任务系统和存档校验器里。

### 3. 运行时状态层：`WorldState` / `CharacterState` / `InventoryState` / `QuestState`

#### `WorldState`

持有世界级运行态：

- 当前区域
- 已解锁区域
- 当前天气
- 区域污染值
- 地图对象状态
- 敌人状态
- 基地结构状态
- `QuestState`

#### `CharacterState`

持有角色级运行态：

- 生命 / 防护
- 当前区域
- 位置
- 装备
- 快捷栏
- 背包库存

#### `InventoryState`

持有：

- `items`
- `fluids`
- `capacity_slots`

#### `QuestState`

持有：

- `active_quest_ids`
- `completed_quest_ids`
- `objective_progress`
- `unlocked_effects`

当前边界是清楚的：

- 静态定义不进这些状态对象。
- 状态对象主要是可保存数据容器，不直接驱动 UI。

### 4. 场景与世界表示层：`VerticalSliceMap`

`VerticalSliceMap` 是当前第一切片地图运行时的主要表现载体。

它负责：

- 管理玩家、交互物、敌人实例
- 查找最近可交互对象和最近攻击目标
- 固定坐标阈值下的区域切换
- 区域挡门和回退
- 特殊 inspect 对象逻辑
- 敌人阶段生成开关
- 加载 / 应用运行时对象状态

当前重要事实：

- 区域划分是坐标阈值硬编码，不是完全数据驱动。
- 多个关键门禁逻辑直接写在 `VerticalSliceMap.try_interact()` 和 `_inspect_*()` 分支里。
- 第一切片实例 ID 约定也由这里的节点命名方式间接决定。

### 5. 玩法规则层：`GatherSystem` / `ProcessingSystem` / `BuildSystem`

#### `GatherSystem`

负责：

- 采集
- 采样
- 清理地块
- 调用加工和建造子系统
- 工具能力校验
- 污染压力扣防护
- 少量任务阶段交互门槛

#### `ProcessingSystem`

负责：

- 配方可用性判定
- 原料消耗
- 启动加工
- 推进加工进度
- 产物 / 副产发放
- 当前任务推荐配方
- 加工完成后的下一步提示

#### `BuildSystem`

负责：

- 建造成本校验
- 当前原型的建造前置校验
- 标记建造点完成
- 生成基地结构运行态

当前边界：

- 三个系统已经比早期原型清楚。
- 但仍有部分内容推进相关的硬编码，例如特定任务阶段配方推荐、污染过滤器前置条件等。

### 6. 任务推进层：`QuestRuntime` 与规则对象

当前任务系统拆成了：

- `QuestEventRules`
- `QuestProgressRules`
- `QuestCompletionRules`
- `QuestCompletionApplier`
- `QuestRuntime`

分工：

- `QuestEventRules`：把交互、区域进入、击败敌人等事件映射为目标更新。
- `QuestProgressRules`：写入或累加目标进度。
- `QuestCompletionRules`：判断目标是否满足、任务是否完成。
- `QuestCompletionApplier`：把完成结果真正应用到世界和角色状态。
- `QuestRuntime`：总入口，串起上述几层，并处理少量旧进度恢复。

当前任务推进不是写在 HUD 里，也不是写在某个单个交互脚本里，这一点已经比较稳。

### 7. UI 层：`PrototypeHud` + presenters

当前 HUD 结构是：

- `PrototypeHud`：控件引用、面板显隐、Label 赋值、计时
- `HudDebugPanelPresenter`
- `HudDevicePanelPresenter`
- `HudFeedbackPresenter`
- `HudHintPresenter`
- `HudLogPresenter`
- `HudMapPresenter`
- `HudStatusPresenter`
- `InteractionPromptFormatter`

当前意义：

- 文本拼装和展示规则已经从 HUD 主脚本里拆出不少。
- 但还没有进入完整 UI 框架或更通用的视图模型体系。

### 8. 存档层：`SaveService` + `SaveContentValidator`

#### `SaveService`

负责：

- 槽位路径
- 主档读写
- 最近 3 份备份轮转
- 默认槽位与旧原型路径兼容迁移
- 槽位摘要

#### `SaveContentValidator`

负责：

- 世界块 / 角色块内容一致性
- 运行时实例来源白名单
- 区域 / 配方 / 任务链来源合法性
- 建筑运行时状态合法性
- 任务目标进度和已完成任务一致性

当前存档系统不是“尽量读就算了”，而是明显偏严格校验。

这保证了原型闭环不会靠坏档继续积累，但也意味着新增固定内容时必须同步更新来源表。

## 关键数据流

### 启动流

```text
Boot / 场景进入
-> GameRoot._ready()
-> DataRegistry 已注入
-> 创建默认 WorldState / CharacterState
-> 创建系统与 presenters
-> VerticalSliceMap.setup()
-> 绑定输入和信号
-> 首次刷新 HUD
```

### 每帧流

```text
GameRoot._process()
-> ProcessingSystem.advance_processing()
-> QuestRuntime.reconcile_active_objectives()
-> VerticalSliceMap.refresh_enemy_spawns()
-> VerticalSliceMap.update_current_interactable()
-> VerticalSliceMap.update_region_presence()
-> 角色位置回写 CharacterState
-> 相机同步
-> prompt / HUD 刷新
```

### 交互流

```text
玩家输入
-> VerticalSliceMap 找到当前交互对象
-> GatherSystem / ProcessingSystem / BuildSystem 执行
-> WorldState / CharacterState 变化
-> QuestRuntime 根据事件推进任务
-> HUD feedback / log / prompt 更新
```

### 战斗流

```text
玩家攻击
-> VerticalSliceMap 选最近敌人
-> 敌人掉血
-> 反击与污染压力
-> 敌人掉落进背包
-> QuestRuntime 推进 defeat_enemy 目标
-> 生命或防护归零则触发撤离
```

### 存档流

```text
保存请求
-> SaveService 组装 save_data
-> SaveContentValidator 先校验当前运行态
-> 轮转备份
-> 写主档

读取请求
-> 主档
-> 备份 1/2/3
-> 旧原型迁移
-> WorldState.from_dict() / CharacterState.from_dict()
-> VerticalSliceMap.apply_runtime_state()
```

## 当前明确的硬边界

### 1. 第一切片仍是固定原型地图

表现为：

- 场景实例是固定节点
- 区域划分按坐标阈值
- 存档来源按白名单

这对当前阶段是合理的，但新增内容时不能假设系统已经完全数据驱动。

### 2. 特殊门禁逻辑仍是专门分支

例如：

- 遗迹入口
- 外圈雾幕
- 深段门禁
- 深段锁扣

这些对象虽然在 `map_objects.json` 里有定义，但真实行为还在 `VerticalSliceMap` 的专门函数里。

### 3. 任务相关“舒适性引导”仍含少量任务 ID 硬编码

例如：

- `ProcessingSystem.get_recommended_recipe_id()`
- `ProcessingSystem._get_completion_next_step()`
- `QuestRuntime.reconcile_active_objectives()`

这部分不是纯坏事，因为当前阶段重点就是尽快做可玩的闭环；但它们应被明确识别，而不是误以为已经完全通用。

### 4. 存档严格依赖固定实例来源

新增固定地图内容后，如果不改：

- `PROTOTYPE_MAP_OBJECT_SOURCES`
- `PROTOTYPE_ENEMY_SOURCES`
- `PROTOTYPE_BASE_STRUCTURE_SOURCES`

很容易出现“能玩，能保存，但读不回来”的问题。

## 当前对扩内容最重要的结论

如果要继续扩第一切片或首小时内容，最关键的不是再加一层抽象，而是守住这条路径：

```text
静态数据
-> 场景实例
-> 运行时规则
-> 任务推进
-> 存档校验
-> HUD 提示
```

六层里任何一层没跟上，都会在原型阶段很快暴露成断链。

## 相关文档

- [Godot Project Structure](godot-project-structure.md)
- [Static Data Schema](static-data-schema.md)
- [Save Data Model](save-data-model.md)
- [Client Data Dictionary](../reference/client-data-dictionary.md)
- [Content Authoring Guide](../reference/content-authoring-guide.md)
