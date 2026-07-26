# Slice Runtime Systems

更新时间：2026-07-25

## 文档目的

本文说明当前正式 `Boot` 入口所使用的像素切片运行时结构。它与冻结保留的旧 `GameRoot + VerticalSliceMap` 纵切并存，但两者不共享世界状态、建筑系统或存档格式。

直接真相源：

- `client/scripts/boot/boot.gd`
- `client/scripts/slice/slice_world.gd`
- `client/scripts/slice/slice_building_*.gd`
- `client/scripts/slice/slice_power_grid.gd`
- `client/scripts/slice/slice_logistics_grid.gd`
- `client/scripts/slice/slice_save_service.gd`
- `client/scripts/slice/slice_building_save_codec.gd`

## 正式入口

```text
Boot
-> DataRegistry.load_all()
-> StartupMenu
-> 新游戏 / 载入存档
-> 实例化 SliceWorld
-> 注入同一个 SliceSaveService
-> 新建世界或恢复切片存档
```

启动菜单和世界使用同一个 `SliceSaveService` 实例，因此菜单摘要、载入判断和世界读写不会各自读取不同目录。旧 `_start_game()` 只为冻结纵切兼容保留，不由当前菜单进入。

## 系统职责

### `SliceWorld`

当前切片的运行时编排器，负责：

- 实例化地图、玩家、HUD 和面板。
- 持有背包、核心仓库、核心状态、建筑实例集合和稳定序号。
- 调用放置校验、建筑生成、调整、拆除和交互。
- 在结构变化后重建供电与物流。
- 推进采集器生产和传送带模拟。
- 组装并触发自动存档。

它不直接定义每类建筑的全部规则；可复用规则已下沉到窄职责对象。

### 建筑定义与实例

- `SliceBuildingCatalog`：六类建筑定义的唯一注册表。
- `SliceBuildingDefinition`：不可变规则，包括占地、表面、方向帧、碰撞、状态白名单、电力角色与端口、物流端口。
- `SliceBuildingInstance`：稳定运行时身份和共享视觉 / 碰撞壳。
- `SliceCollector`、`SliceStorage`、`SliceConveyor`：只持有各自内部状态和窄行为。
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
- 从建筑原点、方向和储物箱端口派生邻接与拓扑。
- 先推进在途进度，再处理带到带 / 带到箱转移，最后处理箱到带发料。
- 同一目标的多入口竞争由目标带格的持久轮询游标裁决。
- 满载或占用形成回压，货物停在输出边缘。

`SliceConveyor` 只持有单格货物、进度、轮询游标和表现所需的入口方向；拓扑种类和邻接由网格重建。

## 权威状态与派生状态

| 类型 | 保存 | 说明 |
| --- | --- | --- |
| 背包、核心仓库 | 是 | `Inventory` 容量与内容 |
| 核心修复、核心能量、已采集晶簇、玩家位置 | 是 | 切片世界基础状态 |
| 建筑 ID、定义 ID、原点格、方向 | 是 | 稳定布局权威 |
| 采集器缓冲与生产进度 | 是 | 断电和重启都保留 |
| 储物箱库存 | 是 | 容量与物品白名单校验 |
| 传送带货物、进度、合流游标 | 是 | 支持重启续跑与公平性 |
| 地板 / 设施占用索引 | 否 | 从建筑布局重建 |
| 供电可达性、父边、连线 | 否 | 从核心和中继重建 |
| 物流邻接、直线 / 转角 / 端点 / 合流外观 | 否 | 从相邻建筑重建 |
| 阴影、y-sort、状态灯和 ghost | 否 | 纯表现 |

旧顶层 `catalyst_count` 和 `reactor_active` 字段暂时只为兼容既有切片存档保留，不应作为新反应加工的权威状态。

## 生命周期与时间推进

载入时先恢复地板，再恢复设施，保证工业地板支撑校验和表现顺序稳定。所有建筑生成后统一重建供电和物流。

运行时：

```text
physics tick
-> SliceLogisticsGrid.tick(delta)
-> 更新货物与受影响储物箱
-> 有物流变化时按最多约 1 秒间隔自动保存

process tick
-> 推进每台通电采集器
-> 缓冲未满时每 10 秒产出 1 晶体
-> 产出后自动保存
```

建造、调整、拆除、仓库存取、核心修复和采集等离散变化会立即触发自动保存。

## 切片存档

`SliceSaveService` 与旧 `SaveService` 物理隔离：

- 默认目录：`user://saves/slice`。
- 主档：`slice_world.json`。
- 单份轮转备份：`slice_world.bak.json`。
- 写入方式：临时文件写完后替换主档。
- 当前 schema：`5`；支持读取 schema `2–5`，schema `1` 不支持。
- 读取顺序：主档失败后尝试备份；全部失败时保留当前运行状态。

schema `4` 把旧采集器列表迁移为统一建筑拓扑；schema `5` 增加传送带货物与合流游标。schema `2 / 3` 的旧采集器会获得稳定 ID，携带中的旧采集器会迁回背包套件，schema `2` 核心仓库迁移为空仓。

`SliceBuildingSaveCodec` 在接受候选档案前校验：

- 字段白名单、实例 ID 格式与唯一性。
- 已知建筑定义、方向范围和下一序号。
- 地图边界、地板 / 设施同层不重叠。
- 设施获得完整工业地板支撑。
- 各建筑内部状态白名单、容量、数值范围和货物 ID。

## 扩展规则

新增建筑或机器行为时必须同步：

1. 在 `SliceBuildingCatalog` 定义占地、表面、端口和状态白名单。
2. 用窄子类持有内部状态，不在 `SliceWorld` 增加按建筑 ID 扩散的状态字典。
3. 在 `SliceBuildingSaveCodec` 增加候选校验和旧 schema 迁移。
4. 明确哪些状态保存、哪些从布局派生。
5. 扩展匹配的放置、操作、供电、物流和 schema 检查。

反应加工接入时应使用每台反应器的输入缓冲、输出缓冲和在制批次升级 schema；不得重新把全局催化剂计数或激活布尔作为机器权威状态。
