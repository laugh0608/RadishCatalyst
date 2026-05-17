# Runtime Systems Overview - 数据流与硬边界

返回：[Runtime Systems Overview](runtime-systems-overview.md)

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
