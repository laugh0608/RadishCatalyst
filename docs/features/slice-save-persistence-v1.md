# Slice Save Persistence V1

更新时间：2026-07-17

状态：当前唯一活跃功能专题；切片第四个实现专题（系统层换皮第二步），2026-07-17 由萝卜SAMA择序确认。前序 [Slice Minimal Core Loop V1](slice-minimal-core-loop-v1.md) 已收口。

## 背景与定位

最小核心循环已成立：采集晶体 → 回基地 → 消耗 10 晶体修复受损核心换态，`SliceHud` 计数 / 目标 / 提示三要素实时一致（见前序专题）。但 `SliceWorld`（`client/scripts/slice/slice_world.gd`）持有的 `crystal_count` 与 `core_repaired` 仅内存有效，重启即丢——玩家一关游戏，采集与修复进度全部归零。

本专题让切片世界状态**存得住、读得回**：正式入口完成一次采集 / 修复后退出，重进能还原到离开时的进度。这是系统层换皮第二步，把"有事做"升级为"进度不丢"。

不迁移、不修改冻结的旧 `SaveService` / `WorldState` / `CharacterState` / `DataRegistry` 链路；本专题为切片新建独立轻量存档，与旧存档系统物理隔离。

## 玩家价值

- 看到：`载入存档` / `继续` 入口能把玩家带回上次离开的现场——晶体数、已采集的簇、核心是否已修复、出生位置都还原。
- 做：采集几簇晶体、修复核心后直接退出，重进游戏进度还在，不用重头再来。
- 理解：这个星球的前哨是"我的"，我的每一步建设都被记住——为后续任务链、建造、多资源的长期进度打底。

## 方案总览

### 复用 vs 新建：新建独立 `SliceSaveService`（已定档 2026-07-17）

不复用旧 `SaveService`，为切片新建独立轻量存档服务。理由：

- 旧 `SaveService` 的公共接口是 `save_game(world_state: WorldState, character_state: CharacterState)`，并内建 `SaveContentValidator` 校验 quest / region / character 内容；切片状态（两个标量 + 已采集簇集合 + 出生点）与这些域无任何映射关系。
- 直接复用只有两条路：改冻结的旧 8.2 万行系统（违反冻结边界与"不默认改旧系统"），或伪造一份能过内容校验的 `WorldState`（脆弱、误导、掩盖真实结构）。两者都不符合根因治理原则。
- 新建服务只复用旧存档已验证的**结构模式**（schema 版本号、原子写、备份轮转），不复用其代码与耦合；旧 `SaveService` 保持冻结不动。这与"系统层换皮"方向一致。

`SliceSaveService`（新建，`client/scripts/slice/slice_save_service.gd`，目标 < 150 行）：

- 存档路径与旧系统物理隔离，独立目录（如 `user://saves/slice/slice_world.json`），互不读写、互不覆盖。
- 提供 `save(world: SliceWorld) -> Dictionary`、`load() -> Dictionary`、`has_save() -> bool`、`get_summary() -> Dictionary`（供入口菜单显示）。
- JSON 明文，带 `save_schema_version` 与最近保存时间；写入走"临时文件 + 单份 `.bak` 备份"最小防损坏，不做旧系统的三份轮转（切片规模不需要）。

### 存档字段

```text
save_schema_version : int      # 本专题起始为 1
game_version        : String   # 复用现有 "prototype-slice-01" 量级标识
updated_at          : String   # Asia/Shanghai 可读时间，供菜单摘要
crystal_count       : int      # 当前晶体数
core_repaired       : bool     # 核心是否已修复
harvested_clusters  : [String] # 已采集并移除的晶体簇节点名，如 ["CrystalLarge1","CrystalMedium2"]
player              : {x, y}   # 玩家离开时的世界坐标
```

- 晶体簇身份用 `SliceMap` 内稳定唯一节点名（`CrystalLarge1` 等）作 id；`CrystalNode` 采集时把父节点名登记进 `harvested_clusters`，无需为节点新增导出 id 字段。
- 不存 HUD 状态（由世界状态派生）、不存相机（由玩家位置派生）、不存动画帧（还原后回 idle）。

### 还原语义

`SliceWorld` 正常实例化地图与玩家后，按存档应用：

1. `crystal_count` / `core_repaired` 回填世界状态并发一次信号刷新 HUD。
2. 遍历 `harvested_clusters`，按名 `queue_free` 对应已采集的簇节点（还原"已被采走"的地图现场）。
3. 若 `core_repaired`，把 `OutpostCoreDamaged` 精灵换成修复态贴图（复用 `CoreRepairSite` 已有换态逻辑或等价路径），并跳过其修复交互。
4. 玩家 `position` 设为存档坐标（无存档时用现有出生点 `START_SPAWN`）。

### 保存触发（已定档 2026-07-17：纯自动存档）

纯自动存档，无独立存档 UI：

- 状态变更即存：`crystals_changed` / `core_repair_completed` 触发一次快照写入（含当前玩家坐标）。
- 退出补存：`NOTIFICATION_WM_CLOSE_REQUEST` 时再写一次，捕获两次事件之间的玩家移动。

### 入口接法（已定档 2026-07-17：方案 A）

切片需要一条读档路径。当前 `载入存档`→旧 `GameRoot`、`新游戏`→全新 `SliceWorld`。定档方案 A：

- `载入存档` 改指切片存档——有切片存档时读回 `SliceWorld` 还原态，旧 `GameRoot` 从菜单退役（代码保留冻结、仅不再由菜单可达）。`新游戏` 始终开新档（存在旧切片存档时覆盖为新档）。
- 无切片存档时 `载入存档` 按钮禁用（沿用 StartupMenu 现有 `has_loadable_save` 逻辑，摘要改取切片存档）。
- 备选方案 B（独立 `继续` 按钮）/ C（新游戏内联询问）不采用，记录备查。

## 范围（串行推进）

### 包 1：切片存档服务与保存

- 新建 `SliceSaveService`：`save` / `load` / `has_save` / `get_summary`，独立目录 + schema 版本 + 单份备份原子写。
- `CrystalNode` 采集时登记父节点名到世界状态的已采集集合；`SliceWorld` 承载 `harvested_clusters` 并在状态变更 / 退出时触发保存。
- 出口：实机采集 / 修复后存档文件按预期字段写出；`check-client` 静态通过、`--import` 无报错。

### 包 2：还原与入口接线

- `SliceWorld` 支持按存档还原（回填标量、移除已采集簇、换核心态、定位玩家）。
- 按萝卜SAMA确认的入口方案接线（boot / StartupMenu），`新游戏` 与读档路径语义清晰。
- 出口：`新游戏` 采集修复 → 退出 → 读档，现场逐项还原，HUD 与世界状态一致。

### 包 3：闭环验证与收口

- 运行时脚本走真实入口做"存档 → 重启 → 读档还原"闭环断言：晶体数、已采集簇不复现、核心态、玩家位置、HUD 一致。
- 实机截图：存档前现场、读档还原后现场对比，记入当周周志。

## 成功证据

- 正式入口：采集若干簇并修复核心后退出，重进读档，进度逐项还原，无重复可采集的已采簇、无残留提示。
- 切片存档与旧 `SaveService` 存档物理隔离，互不影响。
- `sh ./scripts/check-client.sh` 通过；`--import` 与运行时闭环复核按需执行。

## 失败退出

- 按 [Development Decision Gates](../process/development-decision-gates.md) 两次失败停手规则执行。
- 读档还原两轮实现仍有簇复现、核心态错乱或位置错位，停手复盘还原承载结构。

## 不做

- 不做多存档槽位 / 云存档 / 存档管理 UI；单槽切片存档即可。
- 不迁移、不修改冻结的旧 `SaveService` / `WorldState` / `CharacterState` / 旧 `GameRoot` 链路。
- 不接背包 / 多资源 / 任务链 / 建造的存档字段（本专题只存现有循环状态）。
- 不生成新素材；不改冻结的旧场景、旧视觉层与旧检查。

## 状态 / 存档 / HUD / 检查

- 世界状态新增 `harvested_clusters` 集合，与晶体数 / 修复标记同层存于 `SliceWorld`。
- `SliceSaveService` 为新建独立服务，存档目录与旧系统隔离；旧存档检查（`save_service_check` 等）维持现状不动。
- 只要求 `check-client` 静态通过与无导入错误，不新建检查脚本文件。

## 验收与移交

- 专题收口以"正式入口存档 → 重启 → 读档还原完整实机路径 + 前后现场截图"判定，记入当周周志。
- 收口后下一专题候选：立绘对话最小接入、采集与建造扩展；由萝卜SAMA择序。
