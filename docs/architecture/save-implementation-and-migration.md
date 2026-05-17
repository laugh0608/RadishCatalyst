# Save Data Model - 实现与迁移

返回：[Save Data Model](save-data-model.md)

## 当前原型实现

截至 2026-05-01，Godot 客户端已接入最小 `SaveService`：

- 存档读写脚本位于 `client/scripts/save/save_service.gd`；内容校验脚本位于 `client/scripts/save/save_content_validator.gd`。
- 当前使用 `user://saves/slots/slot_01/slice_01_autosave.json` 作为默认槽位原型单文件存档；`save_game()` / `load_game()` 默认读写 `slot_01`，`save_game_for_slot()` / `load_game_for_slot()` 已接入原型 HUD 的 `slot_01`、`slot_02` 和 `slot_03` 三槽位按钮入口。
- 当前使用 `user://saves/slots/slot_01/slice_01_autosave.bak.1.json`、`slice_01_autosave.bak.2.json` 和 `slice_01_autosave.bak.3.json` 保留最近 3 份备份；保存时如果已有旧存档，会先轮转备份再复制当前主存档到 `bak.1`，轮转或备份失败则不覆盖当前存档。
- `K` 保存当前世界和角色状态，`L` 读取并恢复。
- 当前保存 `save_schema_version`、`game_version`、`created_at`、`updated_at`、`WorldState.to_dict()` 和 `CharacterState.to_dict()`，覆盖任务、区域解锁、地图对象、敌人、建筑、污染、天气、生命、防护、位置、装备、快捷栏和背包。
- 当前读取会按主存档、`bak.1`、`bak.2`、`bak.3` 顺序尝试读取可用文件，并先校验 `save_schema_version`、`world` 和 `character` 是否存在且类型正确；文件不存在、JSON 解析失败、版本不兼容、关键块缺失或关键块类型错误且没有可用备份时，会返回清楚的中文失败提示，并避免替换当前运行中的世界和角色状态。
- 如果默认槽位下没有主存档和备份，当前读取会尝试旧原型路径 `user://saves/slice_01_autosave.json` 及其 `bak.1` / `bak.2` / `bak.3` 备份；读取和校验成功后写入默认 `slot_01`，并保留旧原型文件作为导入来源。
- 当前 `GameRoot` 会把 `DataRegistry` 注入 `SaveService`，`SaveService` 再创建 `SaveContentValidator`；读取时会校验区域、天气、地图对象、敌人、建筑、任务、装备、快捷栏、背包物品和流体是否引用已知静态定义 ID，并校验库存数量、生命 / 防护、角色坐标、敌人生命值和任务进度等数值边界。
- 当前读取还会校验首批跨块关系：世界当前区域和角色当前区域必须一致且已解锁；地图对象、敌人和基地结构实例 ID 必须使用当前原型约定前缀；对象、敌人和结构不能指向未解锁区域；`world.map_objects` 中出现的实例必须来自当前切片地图固定交互对象或建造点，且定义 ID 必须与该实例来源一致；`world.enemies` 中出现的敌人必须来自当前切片地图固定敌人来源，且定义 ID 和区域不能错配；`world.base_structures` 中出现的建筑必须来自默认前哨设备或固定建造点，且定义 ID 与建造点来源不能错配；`world.map_objects`、`world.enemies` 和 `world.base_structures` 中的单个实例只能包含当前原型允许字段，避免调试字段或临时运行时对象状态进入存档；`world.base_structures.status` 目前只允许 `idle`、`in_progress` 或 `completed`，`completed_runs` 必须为非负整数，`last_recipe_id` 必须指向已知配方且配方要求建筑必须与结构定义一致；`in_progress` 状态必须同时记录 `active_recipe_id` 和 `progress_seconds`，其中 `active_recipe_id` 必须匹配结构定义，`progress_seconds` 必须为非负数字且不能超过对应配方 `duration`；`last_recipe_id` 和 `active_recipe_id` 还必须已经出现在 `quest_state.unlocked_effects` 中，且 `quest_state.unlocked_effects` 中的 `recipe.*` 必须来自某个已完成任务的 `unlock_effects`，避免存档绕过任务解锁引用未来配方；非默认 `world.unlocked_region_ids` 与 `quest_state.unlocked_effects` 中的 `region.*` 也必须来自某个已完成任务的 `unlock_effects`，当前阶段仅 `region.outpost_platform` 允许作为默认区域；`quest_state.unlocked_effects` 中的非区域 / 非配方解锁效果同样必须来自某个已完成任务的 `unlock_effects`，已完成任务声明的全部解锁效果也必须保留在 `quest_state.unlocked_effects` 中；非默认进行中任务和已完成任务必须来自某个已完成任务的 `next_quest_ids` 或 `quest.*` 解锁效果，避免存档凭空激活或完成未进入任务链的后续任务；非加工中状态不能残留 `active_recipe_id` 或 `progress_seconds`；设备 `input_buffer` / `output_buffer` 目前只允许 `items`、`fluids` 和 `capacity_slots`，物品 / 流体 ID 与数量复用库存校验，容量不能超过建筑 `storage_slots`，无储存槽建筑不能记录缓冲；基地结构引用的建造点必须存在、已建成且定义一致；任务不能同时处于进行中和已完成状态；任务前置关系和区域解锁结果不能倒挂；`quest_state.objective_progress` 的任务 ID、目标类型和目标 ID 必须来自对应静态任务定义，目标进度所属任务必须处于进行中或已完成状态，且进度值不能超过静态任务目标 `amount`；已完成任务必须满足静态数据中定义的全部目标进度。
- 任务链、`quest_state.unlocked_effects`、`world.unlocked_region_ids` 与区域 / 配方来源追溯的读取失败提示已改为指向具体字段；区域解锁效果已额外覆盖“写入 `quest_state.unlocked_effects` 但未同步到 `world.unlocked_region_ids`”的复验场景。
- 当前 `WorldState`、`CharacterState`、`InventoryState` 和 `QuestState` 的 `from_dict()` 会对缺失或类型不符的非关键嵌套字段保留默认值，服务旧原型存档和轻度坏档兜底。
- 当前 `SaveService` 提供槽位摘要接口，用于 UI 显示空槽、可读取、主档不可用但可从备份恢复、旧原型存档可导入或不可读取等状态。
- 当前新增 `scripts/check-client-save.ps1` 和 `client/scripts/checks/save_service_check.gd`，用隔离的 Godot 用户目录复验文件缺失、坏 JSON、版本错误、关键块缺失 / 类型错误、非关键字段默认值兜底、默认状态保存后读取、切片结尾状态、保存前备份轮转、坏主档备份读取恢复、全坏档不替换状态、命名槽位保存 / 读取、槽位摘要、旧原型主档迁移、旧原型备份迁移、新槽位损坏时不回退旧档、未知物品 ID、负库存数量、未知区域 ID、无效角色坐标、敌人生命值越界、建造点关系正例、实例 ID 前缀错误、已知地图对象来源正例、未知地图对象实例来源、地图对象来源定义错配、建成定义错配、地图对象未知字段、已知敌人来源正例、未知敌人来源、敌人定义和区域错配、敌人未知字段、未知建筑来源、建筑定义和建造点来源错配、建筑未知字段、有效建筑运行时状态、建筑无效状态、建筑运行次数无效、建筑未知最近配方、建筑最近配方与建筑定义错配、建筑最近配方未解锁、有效建筑加工中状态、加工中缺少当前配方、加工中缺少进度、加工进度无效、加工进度超过配方时长、当前配方与建筑定义错配、当前配方未解锁、非加工中状态残留当前配方、有效设备缓冲、设备缓冲未知物品、设备缓冲负数量、设备缓冲未知字段、设备缓冲容量超出建筑储存槽位、`quest_state.unlocked_effects` 配方解锁缺少已完成任务来源、`world.unlocked_region_ids` 非默认区域缺少已完成任务来源、`quest_state.unlocked_effects` 区域解锁缺少世界同步或已完成任务来源、已完成任务缺少配方 / 任务 / 切片完成解锁效果、任务 / 切片完成解锁效果缺少已完成任务来源、合法进行中任务来源、`quest_state.active_quest_ids` 缺少任务链来源、合法已完成任务链来源、`quest_state.completed_quest_ids` 缺少任务链来源、当前区域未解锁、世界 / 角色区域不一致、任务状态冲突、任务前置缺失、基地结构建造点缺失、active 任务部分合法目标进度、未激活任务目标进度、任务目标进度超过目标上限、任务未定义目标类型 / 目标 ID、已完成任务目标正例、已完成任务缺少目标进度和已完成任务目标进度不足；其中任务目标进度用例由 `save_quest_objective_check.gd` 承载，任务链、`unlocked_effects`、区域 / 配方来源用例由 `save_quest_unlock_check.gd` 承载。
- 该实现用于验证第一可玩切片状态可落盘，并提供三槽位原型 UI 入口；它仍不代表最终多世界管理、正式迁移或导入导出设计。

## 迁移与校验

每个存档必须有：

- `save_schema_version`
- `game_version`
- `created_at`
- `updated_at`

加载时应检查：

- 版本是否支持。
- 必需字段是否存在。
- 引用的定义 ID 是否仍存在。
- 实例 ID 是否重复。
- 库存数量是否有效。
- 坐标、区域和地块引用是否有效。

未来修改 ID 时，应使用：

- ID 别名表。
- 迁移脚本。
- 默认值填充。
- 失败时清楚提示，而不是静默损坏。

当前原型已完成最小读取校验、最近 3 份备份轮转、坏档备份读取恢复、旧原型存档迁移、首批内容一致性校验、首批实例与跨块关系校验、地图对象 / 敌人 / 建筑来源复验、地图对象 / 敌人 / 建筑字段白名单校验、建筑状态取值、加工中进度、设备缓冲、配方归属、配方与区域解锁来源校验、任务链和 `unlocked_effects` 来源失败提示字段化、已完成任务目标满足度校验、任务目标类型复验、未激活任务目标进度复验、任务目标进度上限复验、三槽位原型 UI 入口和运行时复验入口：`save_schema_version`、`world` 和 `character` 为关键块，必须存在且类型正确；其余嵌套字段暂按默认值兜底；保存前会轮转 `.bak.1` / `.bak.2` / `.bak.3`；主存档损坏时会依次尝试读取最近 3 份备份；默认槽位完全缺失时会尝试导入旧原型路径；已开始校验静态定义 ID、库存数量、坐标、敌人生命值、实例 ID 前缀、区域解锁、区域解锁来源、运行时来源、运行时集合允许字段、建筑运行状态、建筑运行次数、最近配方归属、最近配方解锁来源、当前加工配方、当前加工配方解锁来源、加工进度秒数、设备输入 / 输出缓冲、建造点引用、任务前置关系、任务目标类型和已完成任务目标进度。后续应继续补充更多跨块关系复验。

## 首版必须保存的最小集合

首版 MVP 至少必须保存：

- 世界元数据。
- 已探索区域。
- 区域解锁。
- 地块清理、平整、地基和污染状态。
- 可采集、可采样、可破坏对象状态。
- 基地设备、库存、配方和处理进度。
- 角色位置、生命、防护、装备、背包和快捷栏。
- 已解锁配方、模块、药剂或区域通行能力。
- 当前时间段和天气状态。

如果某个状态会影响玩家进度、资源、区域、基地或角色能力，就必须进入存档。

## 当前不做

首版存档暂不做：

- 云存档。
- 账号绑定。
- 跨设备同步。
- 专用服务器持久化。
- 多人权限状态。
- 完整命令日志回放。
- 复杂随机地图重建。
- 大规模分块流式存档优化。

但当前必须避免：

- 用场景节点路径当长期 ID。
- 用显示名当 ID。
- 把库存、设备、污染、任务状态散落在 UI 节点里。
- 让天气、地形、可破坏对象只存在于临时场景状态。
- 存档里保存大量可由配置推导的数据。

## 与后续文档的关系

Godot 工程初始化后，应把本文件拆成具体实现：

- 静态数据目录和 ID 命名规则。
- SaveService 或等价存档服务。
- WorldState、CharacterState、InventoryState 等状态对象。
- 地图对象实例注册和实例 ID 生成。
- 存档加载、保存、迁移和校验流程。

如果后续新增联机、专服或官方云存档，应优先复用本文件的世界 / 角色 / 玩家 / 设置分层，而不是重写一套状态模型。

## 当前阶段结论

RadishCatalyst 的首版存档重点不是格式，而是边界。

当前最重要的结论是：

**静态配置用稳定定义 ID，运行时状态用世界内实例 ID；世界保存地图、基地、污染、时间天气和任务，角色保存生命、装备、背包和成长，设置独立保存。**

只要这条边界稳定，后续 Godot 原型、玩家 Wiki、官方工具和联机演进都会更容易接上。
