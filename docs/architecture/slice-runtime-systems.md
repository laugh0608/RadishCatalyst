# Slice Runtime Systems

更新时间：2026-07-27

## 文档目的

本文说明当前正式 `Boot` 入口所使用的像素切片运行时结构。它与冻结保留的旧 `GameRoot + VerticalSliceMap` 纵切并存，但两者不共享世界状态、建筑系统或存档格式。

直接真相源：

- `client/scripts/boot/boot.gd`
- `client/scripts/slice/slice_world.gd`
- `client/scripts/slice/slice_building_*.gd`
- `client/scripts/slice/slice_power_grid.gd`
- `client/scripts/slice/slice_logistics_grid.gd`
- `client/scripts/slice/slice_reactor.gd`
- `client/scripts/slice/slice_player.gd`
- `client/scripts/slice/slice_combat_controller.gd`
- `client/scripts/slice/slice_field_enemy.gd`
- `client/scripts/slice/slice_hud.gd`
- `client/scripts/slice/slice_save_catalog.gd`
- `client/scripts/slice/slice_save_service.gd`
- `client/scripts/slice/slice_building_save_codec.gd`
- `client/scripts/slice/slice_pause_menu.gd`

## 正式入口

```text
Boot
-> DataRegistry.load_all()
-> SliceSaveCatalog 迁移旧单档并枚举世界
-> StartupMenu
-> 创建或选择一个稳定 world_id
-> SliceSaveCatalog.service_for_world(world_id)
-> 实例化 SliceWorld
-> 注入该世界唯一的 SliceSaveService
-> 新建世界或恢复切片存档
```

`SliceSaveCatalog` 只拥有世界目录、轻量元数据、30 世界上限、回收恢复和旧单档迁移；玩法状态仍由选中世界的 `SliceSaveService` 独占。`Esc` 暂停后“保存并返回主菜单”会先保存当前世界，再由 `Boot` 释放 `SliceWorld`、清空选中服务并重建列表。旧 `_start_game()` 只为冻结纵切兼容保留，不由当前菜单进入。

## 系统职责

### `SliceWorld`

当前切片的运行时编排器，负责：

- 实例化地图、玩家、HUD 和面板。
- 持有背包、核心仓库、核心状态、建筑实例集合和稳定序号。
- 调用放置校验、建筑生成、调整、拆除和交互。
- 在结构变化后重建供电与物流。
- 推进采集器、反应器生产和传送带模拟。
- 组装并触发自动存档。
- 处理前台面板 / 放置优先的 `Esc`，以及暂停、保存返回和保存退出。

它不直接定义每类建筑的全部规则；可复用规则已下沉到窄职责对象。

### 建筑定义与实例

- `SliceBuildingCatalog`：六类建筑定义的唯一注册表。
- `SliceBuildingDefinition`：不可变规则，包括占地、表面、方向帧、碰撞、状态白名单、电力角色与端口、物流端口。
- `SliceBuildingInstance`：稳定运行时身份和共享视觉 / 碰撞壳。
- `SliceCollector`、`SliceStorage`、`SliceConveyor`、`SliceReactor`：只持有各自内部状态和窄行为。
- `SliceBuildingOccupancy`：分别维护地板占用和阻挡设施占用。

建筑方向只选择固定帧；`rotation` 是 `0–3` 的规则状态，不直接旋转像素图。

### 放置与操作

- `SliceBuildingPlacementController` 只持有当前选择、方向、吸附原点、合法性和真实资产 ghost。
- `SliceWorld._validate_placement()` 负责世界规则，包括边界、地表、占用、物理阻挡和中继连接。
- `SliceBuildingActionPanel` 负责调整、二次确认拆除、储物箱晶体存取和阻塞原因展示。

调整期间原实例暂时隐藏并从占用、供电和物流中排除；提交后保留 ID 和内部状态，取消则恢复原拓扑。

### 供电

`SlicePowerGrid` 是每次结构变化后重建的二值可达图：

- 输入只有核心在线状态、核心位置、tile 大小和建筑实例。
- 输出是通电中继集合、用电设备判定和唯一父边连接。
- `powered`、父边和连线表现都是派生状态，不进入存档。

`SlicePowerLinkLayer` 只渲染供电树，不拥有网络规则。

### 物流

`SliceLogisticsGrid` 是世界权威的定步长传送带模拟：

- 固定以 `1/60s` 子步推进，带速为每秒一格。
- 从建筑原点、方向、储物箱舱口和反应器入 / 出端口派生邻接与拓扑。
- 先推进在途进度，再处理带到带 / 带到储物箱或反应器输入，最后处理储物箱 / 反应器输出发料。
- 同一目标的多入口竞争由目标带格的持久轮询游标裁决。
- 满载或占用形成回压，货物停在输出边缘。

`SliceConveyor` 只持有单格货物、进度、轮询游标和表现所需的入口方向；拓扑种类和邻接由网格重建。

### 外勤战斗与旅程引导

- `SlicePlayer` 负责移动、鼠标瞄准及未被前台 UI 消费的攻击 / 闪避意图，不拥有敌人或任务状态。
- `SliceCombatController` 拥有攻击节拍、闪避无敌、玩家生命和五态外勤遭遇；`SliceFieldEnemy` 只负责单敌人的警戒、追击、蓄势、恢复、回巢、受击与败亡。
- `SliceWorld` 只编排首次充能扣料、样本交付、离散事件自动保存和节点装配，不承载敌人 AI。
- `SliceHud` 与合成面板读取 `current_journey_guidance()`；当前目标和规则从权威世界状态派生，不保存阶段编号或平行任务进度。

## 权威状态与派生状态

| 类型 | 保存 | 说明 |
| --- | --- | --- |
| 背包、核心仓库 | 是 | `Inventory` 容量与内容 |
| 核心修复、核心能量、已采集晶簇、玩家位置 | 是 | 切片世界基础状态 |
| 玩家生命、五态外勤遭遇 | 是 | 最大生命由 `delivered` 派生，敌人 / 样本由单一状态派生 |
| 建筑 ID、定义 ID、原点格、方向 | 是 | 稳定布局权威 |
| 采集器缓冲与生产进度 | 是 | 断电和重启都保留 |
| 储物箱库存 | 是 | 容量与物品白名单校验 |
| 传送带货物、进度、合流游标 | 是 | 支持重启续跑与公平性 |
| 反应器输入 / 输出缓冲、加工态与进度 | 是 | 每台实例独立，断电和重启都保留 |
| 地板 / 设施占用索引 | 否 | 从建筑布局重建 |
| 供电可达性、父边、连线 | 否 | 从核心和中继重建 |
| 物流邻接、直线 / 转角 / 端点 / 合流外观 | 否 | 从相邻建筑重建 |
| 首次旅程当前目标与规则 | 否 | 从核心、通电设备、建筑库存、背包和遭遇状态派生 |
| 阴影、y-sort、状态灯和 ghost | 否 | 纯表现 |

schema 7 延续 schema 6 的设备状态，并新增 `player_health` 与 `field_encounter {state, enemy_health}`。遭遇只取 `locked / hostile / dropped / carried / delivered`；最大生命、敌人存在和样本存在均由该状态派生，不保存平行布尔真相。旧顶层 `catalyst_count` 和 `reactor_active` 仍不写入。

## 生命周期与时间推进

载入时先恢复地板，再恢复设施，保证工业地板支撑校验和表现顺序稳定。所有建筑生成后统一重建供电和物流。

运行时：

```text
physics tick
-> SliceLogisticsGrid.tick(delta)
-> 更新货物与受影响储物箱 / 反应器缓冲
-> 有物流变化时按最多约 1 秒间隔自动保存

process tick
-> 推进每台通电采集器
-> 缓冲未满时每 10 秒产出 1 晶体
-> 推进每台反应器的 2 晶体 → 1 催化剂 / 10 秒状态机
-> 产出、加工状态切换或最多约 1 秒后自动保存
```

建造、调整、拆除、仓库存取、核心修复、采集，以及战斗伤害、败亡、样本拾取 / 交付和撤离等离散变化会立即触发自动保存；普通敌人 AI tick 不写盘。暂停返回或退出只有保存成功后才释放世界或结束进程。

## 切片存档

`SliceSaveCatalog` 与 `SliceSaveService` 均和旧 `SaveService` 物理隔离：

```text
user://saves/slice/
  worlds/world_<stable_id>/
    metadata.json
    autosave.json
    backups/autosave.bak.1.json ... bak.3.json
  trash/<recoverable_entry>/
```

- 最多 30 个在用世界；显示名可变，稳定 ID 和目录不随重命名变化。
- `metadata.json` 只提供列表轻读，并摘要外勤状态与玩家生命；`autosave.json` 才是 schema 7 权威世界状态。
- 写入先落临时文件，三份备份轮转成功后才替换主档；读取按主档、`bak.1`、`bak.2`、`bak.3` 回退，全部失败时不覆盖内存状态。
- 当前 schema 为 `7`，支持读取 schema `2–7`；schema `1` 不支持。
- 旧 `user://saves/slice/slice_world.json` 和单份 `.bak` 仅作迁移源：校验、复制、读回成功后发布为第一个命名世界，旧文件保留。

schema `4` 把旧采集器列表迁移为统一建筑拓扑；schema `5` 增加传送带货物与合流游标；schema `6` 增加反应器双缓冲、加工态和进度，并迁移旧全局催化剂；schema `7` 增加玩家生命与五态外勤遭遇。schema `2–6` 缺省生命 `100`，并按核心充能状态迁为 `locked` 或满血 `hostile`。

`SliceBuildingSaveCodec` 在接受候选档案前校验：

- 字段白名单、实例 ID 格式与唯一性。
- 已知建筑定义、方向范围和下一序号。
- 地图边界、地板 / 设施同层不重叠。
- 设施获得完整工业地板支撑。
- 各建筑内部状态白名单、容量、数值范围和货物 ID，包括反应器加工态 / 进度一致性。
- 玩家生命上限、遭遇字段白名单、核心充能与遭遇状态一致性，以及活敌 / 败亡态生命约束。

## 扩展规则

新增建筑或机器行为时必须同步：

1. 在 `SliceBuildingCatalog` 定义占地、表面、端口和状态白名单。
2. 用窄子类持有内部状态，不在 `SliceWorld` 增加按建筑 ID 扩散的状态字典。
3. 在 `SliceBuildingSaveCodec` 增加候选校验和旧 schema 迁移。
4. 明确哪些状态保存、哪些从布局派生。
5. 扩展匹配的放置、操作、供电、物流和 schema 检查。

战斗与样本权威状态已进入选中世界的 schema 7，并沿用候选校验 / 备份链；`metadata.json` 只保存列表摘要，不得成为玩法真相源。后续不得把它拆成跨世界共享角色档，或重新把旧全局催化剂计数作为权威状态。

2026-07-27 日终审计时 `SliceWorld` 已达 1398 行。后续新增鼠标放置、范围预览、HUD 或旅程反馈时，应优先提取放置输入 / 预览或目标派生组件，不得越过 1500 行硬上限继续扩写世界编排器。
