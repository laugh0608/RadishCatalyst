# Slice Runtime Systems

更新时间：2026-08-26

## 文档目的

本文说明当前正式 `Boot` 入口所使用的像素切片运行时结构。它与冻结保留的旧 `GameRoot + VerticalSliceMap` 纵切并存，但两者不共享世界状态、建筑系统或存档格式。

直接真相源：

- `client/scripts/boot/boot.gd`
- `client/scripts/slice/slice_world.gd`
- `client/scripts/slice/slice_building_*.gd`
- `client/scripts/slice/slice_building_panel_snapshot.gd`
- `client/scripts/slice/slice_inventory_read_model.gd`
- `client/scripts/slice/slice_paired_container_view.gd`
- `client/scripts/slice/slice_placement_*.gd`
- `client/scripts/slice/slice_power_grid.gd`
- `client/scripts/slice/slice_logistics_grid.gd`
- `client/scripts/slice/slice_reactor.gd`
- `client/scripts/slice/slice_player.gd`
- `client/scripts/slice/slice_combat_controller.gd`
- `client/scripts/slice/slice_pulse_projectile.gd`
- `client/scripts/slice/slice_field_enemy.gd`
- `client/scripts/slice/slice_first_journey_controller.gd`
- `client/scripts/slice/slice_exploration_state.gd`
- `client/scripts/slice/slice_minimap.gd`
- `client/scripts/slice/slice_hud.gd`
- `client/scripts/slice/slice_power_link_layer.gd`
- `client/scripts/slice/slice_power_link_presenter.gd`
- `client/scripts/slice/slice_inventory_profiles.gd`
- `client/scripts/slice/slice_save_catalog.gd`
- `client/scripts/slice/slice_save_service.gd`
- `client/scripts/slice/slice_building_save_codec.gd`
- `client/scripts/slice/slice_save_scheduler.gd`
- `client/scripts/slice/slice_world_save_state_builder.gd`
- `client/scripts/slice/slice_crafting_plan.gd`
- `client/scripts/slice/slice_character_panel.gd`
- `client/scripts/slice/slice_logistics_transition_layer.gd`
- `client/scripts/slice/slice_demo_completion_card.gd`
- `client/scripts/slice/slice_pause_menu.gd`
- `client/scripts/settings/slice_user_settings.gd`
- `client/scripts/ui/slice_settings_panel.gd`

## 正式入口

```text
UserSettings Autoload -> 读取并应用 user://settings.cfg
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

`UserSettings` 是当前唯一应用级 Autoload，只负责窗口模式和 `Master / SFX` 音量；启动与暂停入口实例化同一 `SliceSettingsPanel`。它不持有世界、角色或库存状态，`user://settings.cfg` 也不进入世界目录、备份轮转或 schema 10。

## 系统职责

### `SliceWorld`

当前切片的运行时编排器，负责：

- 实例化地图、玩家、HUD 和面板。
- 持有背包、核心仓库、核心状态、建筑实例集合和稳定序号。
- 调用放置校验、建筑生成、调整、拆除和交互。
- 在结构变化后重建供电与物流。
- 推进采集器、反应器生产和传送带模拟。
- 装配首程引导、探索状态、战斗和 HUD，但不拥有这些窄职责组件的内部规则。
- 把状态变化按事件语义交给 `SliceSaveScheduler`；真正写盘时由 `SliceWorldSaveStateBuilder` 构造一次权威快照。
- 处理前台面板 / 放置优先的 `Esc`，以及暂停、保存返回和保存退出。

它不直接定义每类建筑的全部规则；可复用规则已下沉到窄职责对象。

### 建筑定义与实例

- `SliceBuildingCatalog`：六类建筑定义的唯一注册表。
- `SliceBuildingDefinition`：不可变规则，包括占地、表面、方向帧、碰撞、状态白名单、电力角色与端口、物流端口。
- `SliceBuildingInstance`：稳定运行时身份和共享视觉 / 碰撞壳。
- `SliceCollector`、`SliceStorage`、`SliceConveyor`、`SliceReactor`：只持有各自内部状态和窄行为。
- `SliceBuildingOccupancy`：分别维护地板占用和阻挡设施占用。

`SliceMap/GroundStructures` 是非 Y 排序地表结构层，当前承载可通行传送带；实体设备继续进入 Y 排序 `World`，其阻挡只由旋转后足印派生。`SliceLogisticsTransitionLayer` 只为已由物流拓扑确认的跨地表端口绘制会话态过渡格，不拥有连接规则或存档状态。

固定正面设施和工业地板的 `rotation` 只能为 `0`；传送带仍以 `0–3` 表达规则方向。方向选择固定帧，不直接旋转像素图。

### 放置与操作

- `SlicePlacementPointerInput` 只维护鼠标目标和地板拖铺去重；设备左键单放，工业地板允许按住左键跨格铺设，`E` 仍走兼容确认路径。
- `SlicePlacementValidator` 统一查询边界、地表、占用、物理阻挡和中继连接，并把缺地板格交给预览；它不落盘、不持有第二份世界状态。
- `SliceBuildingPlacementController` 只持有当前选择、方向、吸附原点、合法性、真实资产 ghost 和动态预览节点。
- `SlicePlacementOverlay` 只绘制放置瞬态的足印、缺地板格、连接线和电力范围；所有范围节点由 `SlicePowerGrid` 的当前派生结果提供。
- `SliceWorld` 只协调指针输入、校验结果、最终放置和自动存档；前台 HUD 控件会阻断鼠标落地。
- `SliceBuildingActionPanel` 负责设备状态、模式 / 筛选、共享成对容器表面、调整、二次确认拆除和阻塞原因展示；所有物品变更仍转交既有世界 API。

调整期间原实例暂时隐藏并从占用、供电和物流中排除；提交后保留 ID 和内部状态，取消则恢复原拓扑。

### 制造、容器与装备界面

- `SliceCraftingPlan` 是无状态制造诊断，只从现有配方和库存快照计算直接成本、基础原料折算、两种可制造数和足印补板上限；它不交换物品或隐式制造中间件。
- `SliceCraftPanel` 制造成功后保持打开，产物先成为背包财产；只有玩家从已有套件入口明确选择时才进入放置。
- `SliceInventoryReadModel` 从两个权威容器或机器缓冲快照构造只读成对条目；默认“全部”只包含实际持有物，分类只筛选视图。
- `SlicePairedContainerView` 统一左背包 / 右目标、点击、整堆拖拽、`Ctrl / Control` 逐次减半、`Enter / Space` 等价转移和取消；它只发出请求，不直接修改库存。
- `SliceCoreStoragePanel` 是共享容器表面的核心仓库壳；`SliceBuildingPanelSnapshot` 为储物箱、采集器和反应器构造同一表面所需的只读快照。机器缓冲不伪装成普通 `Inventory`，采集器仍只允许取出，反应器仍执行原子回收。
- `SliceCharacterPanel` 只呈现一个武器槽、持有武器点击 / 拖入和 `C` 开关；实际装备合法性与保存请求仍由 `SliceCombatController` 独占。

### 供电

`SlicePowerGrid` 是每次结构变化后重建的二值可达图：

- 输入只有核心在线状态、核心位置、tile 大小和建筑实例。
- 输出是通电中继集合、用电设备判定和唯一父边连接。
- `powered`、父边和连线表现都是派生状态，不进入存档。
- 当前建筑定义只有 `power_role` 与端口 / 范围信息，没有发电容量、设备需求、负荷分配、储能或过载状态；这些能力须由后续独立电力专题确定迁移与 schema 边界。

`SlicePowerLinkLayer` 只渲染供电树，不拥有网络规则；`SlicePowerLinkPresenter` 读取放置和设备面板上下文，普通游玩隐藏完整连线，只有放置用电设备或检查用电设备时显示派生拓扑。

### 物流

`SliceLogisticsGrid` 是世界权威的定步长传送带模拟：

- 固定以 `1/60s` 子步推进，带速为每秒一格。
- 从建筑原点、方向、储物箱舱口和反应器入 / 出端口派生邻接与拓扑。
- 先推进在途进度，再处理带到带 / 带到储物箱或反应器输入，最后处理储物箱 / 反应器输出发料。
- 同一目标的多入口竞争由目标带格的持久轮询游标裁决。
- 满载或占用形成回压，货物停在输出边缘。

`SliceConveyor` 只持有单格货物、进度、轮询游标和表现所需的入口方向；拓扑种类和邻接由网格重建。

### 外勤战斗与旅程引导

- `SlicePlayer` 负责移动、鼠标瞄准及未被前台 UI 消费的武器选择、攻击 / 闪避意图，不拥有敌人、弹药或任务状态。
- `SliceCombatController` 拥有切割器 / 步枪装备选择、攻击节拍、即时耗弹、闪避无敌、玩家生命和五态外勤遭遇；装备入口统一校验步枪必须在随身背包并立即请求保存。`SlicePulseProjectile` 只负责固定速度移动、首碰和射程销毁，`SliceFieldEnemy` 只负责单敌人的警戒、追击、蓄势、恢复、回巢、受击与败亡。
- `SliceWorld` 只编排首次充能扣料、样本交付、离散事件自动保存和节点装配，不承载敌人 AI。
- `SliceFirstJourneyController` 在核心修复前按库存和两个首次查看旗标派生五阶段引导，并拥有 `40×12` 探索粗格；修复后继续委托 `SliceJourneyGuidance` 从设备、库存与遭遇状态派生目标。
- `SliceHud` 与合成面板读取 `current_journey_guidance()`；小地图用同一世界视图叠加持久迷雾、玩家、核心、已发现晶体与阶段情报。阶段编号、区域名和 marker 都不保存。样本交付后的 `SliceDemoCompletionCard` 只在当次交付成功保存后出现，完成事实继续由 `delivered` 派生，读档不会重弹。
- `SliceHud` 的常驻游戏壳层由任务舷窗、三物资槽、角色生命条、三格战斗操作条、按需敌人目标条和右下小地图组成；内容区统一使用 `18px` 安全边距，宽提示在角色栏与小地图之间展开。完整套件清单仍只在合成 / 放置上下文出现。

## 权威状态与派生状态

| 类型 | 保存 | 说明 |
| --- | --- | --- |
| 背包、核心仓库 | 是 | schema 8 起只保存内容；逐物品容量由 profile 定义，步枪唯一与电池上限由现行 profile 校验 |
| 核心修复、核心能量、已采集晶簇、玩家位置 | 是 | 切片世界基础状态 |
| 玩家生命、五态外勤遭遇 | 是 | 最大生命由 `delivered` 派生，敌人 / 样本由单一状态派生 |
| 当前装备武器 | 是 | schema 10 的 `equipped_weapon_id`；只允许切割器或随身背包中的步枪 |
| 首次查看旗标、探索位图 | 是 | 两个布尔旗标与 480 位粗格；当前目标、区域名和 marker 继续派生 |
| 建筑 ID、定义 ID、原点格、方向 | 是 | 稳定布局权威 |
| 采集器缓冲与生产进度 | 是 | 断电和重启都保留 |
| 储物箱库存 | 是 | 容量与物品白名单校验 |
| 传送带货物、进度、合流游标 | 是 | 支持重启续跑与公平性 |
| 反应器输入 / 输出缓冲、加工态与进度 | 是 | 每台实例独立，断电和重启都保留 |
| 地板 / 设施占用索引 | 否 | 从建筑布局重建 |
| 供电可达性、父边、连线 | 否 | 从核心和中继重建 |
| 物流邻接、直线 / 转角 / 端点 / 合流外观 | 否 | 从相邻建筑重建 |
| 首次旅程当前目标与规则 | 否 | 从核心、通电设备、建筑库存、背包和遭遇状态派生 |
| 弹体和攻击阶段 | 否 | 纯运行时战斗过程；步枪与电池本身仍是库存财产 |
| 容器筛选、选择和拖拽过程 | 否 | 纯 UI 会话态；物品归属只由权威转移 API 改变 |
| 窗口模式、主音量、音效音量 | 独立配置 | 保存到 `user://settings.cfg`，不属于世界 schema 10 |
| 阴影、y-sort、状态灯和 ghost | 否 | 纯表现 |

当前 schema 10 延续 schema 9 的分类库存、储物箱权威状态、固定正面建筑、`first_journey_flags` 与 `explored_map_bits`，只新增 `equipped_weapon_id`。遭遇仍只取 `locked / hostile / dropped / carried / delivered`；最大生命、敌人存在和样本存在均由该状态派生。旧顶层 `catalyst_count`、`reactor_active`、弹体和攻击阶段都不写入。

## 生命周期与时间推进

载入时先恢复地板，再恢复设施，保证工业地板支撑校验和表现顺序稳定。所有建筑生成后统一重建供电和物流。

运行时：

```text
physics tick
-> SliceLogisticsGrid.tick(delta)
-> 更新货物与受影响储物箱 / 反应器缓冲
-> 有物流变化时进入约 2 秒合并保存

process tick
-> 推进每台通电采集器
-> 缓冲未满时每 1 秒产出 1 晶体
-> 推进每台反应器的 2 晶体 → 1 催化剂 / 10 秒状态机
-> 产出和加工状态变化进入约 2 秒合并保存
```

schema 4–9 的旧档仍可携带原 `0–10s` 采集进度；载入后按当前 `1s` 周期结算并继续累计。射击耗弹、普通受伤、生产、物流、探索揭雾和普通容器转移进入共享约 `2s` 合并保存；制造、装备变化、建造 / 调整 / 拆除、核心修复 / 充能、败亡、样本拾取 / 交付和撤离立即保存。暂停返回或退出只有保存成功后才释放世界或结束进程。

`SliceSaveScheduler` 只持有脏状态、防抖时间和旧档待发布上下文，通过回调在写盘时请求最新快照；普通失败保留脏状态等待重试，强制保存失败直接阻止退出。它不校验 schema、不序列化世界，也不发布文件。

## 切片存档

`SliceSaveCatalog` 与 `SliceSaveService` 均和旧 `SaveService` 物理隔离：

```text
user://settings.cfg

user://saves/slice/
  worlds/world_<stable_id>/
    metadata.json
    autosave.json
    backups/autosave.bak.1.json ... bak.3.json
  trash/<recoverable_entry>/
```

应用设置与世界存档同在 Godot `user://` 根下，但所有权和生命周期独立：世界重命名、回收、恢复、备份和迁移都不得读取或改写 `settings.cfg`。

- 最多 30 个在用世界；显示名可变，稳定 ID 和目录不随重命名变化。
- `metadata.json` 只提供列表轻读，并摘要外勤状态与玩家生命；`autosave.json` 才是 schema 10 权威世界状态。
- 写入先落临时文件，三份备份轮转成功后才替换主档；读取按主档、`bak.1`、`bak.2`、`bak.3` 回退，全部失败时不覆盖内存状态。
- 当前 schema 为 `10`，支持读取 schema `2–10`；schema `1` 不支持。
- 旧 `user://saves/slice/slice_world.json` 和单份 `.bak` 仅作迁移源：校验、复制、读回成功后发布为第一个命名世界，旧文件保留。

schema `4` 把旧采集器列表迁移为统一建筑拓扑；schema `5` 增加传送带货物与合流游标；schema `6` 增加反应器双缓冲、加工态和进度；schema `7` 增加玩家生命与五态外勤遭遇；schema `8` 原子切换分类库存、储物箱模式与固定正面设备；schema `9` 增加两个首次查看旗标与固定 480 位探索图；schema `10` 增加严格装备选择。schema `2–9` 只在内存迁移，世界完整重建后才发布当前格式。

`SliceSaveService` 与 `SliceBuildingSaveCodec` 在接受候选档案前共同校验：

- 字段白名单、实例 ID 格式与唯一性。
- 已知建筑定义、方向范围和下一序号。
- 地图边界、地板 / 设施同层不重叠。
- 设施获得完整工业地板支撑。
- 各建筑内部状态白名单、容量、数值范围和货物 ID，包括反应器加工态 / 进度一致性。
- 玩家生命上限、遭遇字段白名单、核心充能与遭遇状态一致性，以及活敌 / 败亡态生命约束。
- 两个首次查看旗标的严格布尔合同，以及固定 `80` 字符 Base64 / `60` 字节探索位图。
- 步枪跨背包与核心最多一把、电池容量和全部已知物品 ID 的联合库存约束。
- `equipped_weapon_id` 只允许 `cutter / pulse_rifle`；选择步枪时步枪必须位于随身背包。

## 扩展规则

新增建筑或机器行为时必须同步：

1. 在 `SliceBuildingCatalog` 定义占地、表面、端口和状态白名单。
2. 用窄子类持有内部状态，不在 `SliceWorld` 增加按建筑 ID 扩散的状态字典。
3. 在 `SliceBuildingSaveCodec` 增加候选校验和旧 schema 迁移。
4. 明确哪些状态保存、哪些从布局派生。
5. 扩展匹配的放置、操作、供电、物流和 schema 检查。

战斗、样本、分类库存、首程探索与装备选择权威状态已进入选中世界的 schema 10，并沿用候选校验 / 备份链；`metadata.json` 只保存列表摘要，不得成为玩法真相源。后续不得把它拆成跨世界共享角色档，或重新把旧全局催化剂计数作为权威状态。

2026-08-26 `SliceWorld` 为 1489 行；保存调度、快照构造、制造计划、角色装备页、成对容器视图、电力上下文和应用设置均已进入窄职责组件。编排器仍贴近 1500 行硬上限，后续包不得把库存交互、HUD 偏移、设备表现或音频边沿分支堆回该文件。
