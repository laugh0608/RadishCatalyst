# Godot Project Structure - 运行组织与边界

返回：[Godot Project Structure](godot-project-structure.md)

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
pwsh ./scripts/check-client-quests.ps1
pwsh ./scripts/check-client-flow.ps1
pwsh ./scripts/check-godot-client.ps1
pwsh ./scripts/check-text-files.ps1
```

`check-godot-client.ps1` 当前使用 Godot 4.6.2 console 的 `--import --quit` 完成项目导入和全局类注册验证。`--headless --path ... --quit` 和 `--check-only --script` 在当前 Windows / Godot 4.6.2 环境会触发引擎层崩溃，因此暂不作为门禁。

`check-client-save.ps1` 当前会先执行一次 Godot 导入，再通过 `client/scripts/checks/save_service_check.gd` 运行 `SaveService` 读写和备份校验，并将 Godot 配置、数据、缓存和 `user://` 存档目录隔离到 `.godot-check-home/save-service/` 下。

`check-client-quests.ps1` 当前会先执行一次 Godot 导入，再通过 `client/scripts/checks/quest_rules_check.gd` 直接复验 `QuestEventRules`、`QuestProgressRules` 和 `QuestCompletionRules`，并将 Godot 配置、数据和缓存隔离到 `.godot-check-home/quest-rules/` 下。

`check-client-data.ps1` 当前除了基础 JSON、引用和本地化键，还会校验配方解锁来源、任务激活来源、区域任务索引、主线任务图、任务目标来源和切片完成终点。`check-client-scenes.ps1` 当前除了资源引用、脚本 UID 和 HUD 面板布局，还会校验 `VerticalSliceMap.tscn` 中任务目标对应的交互点、建造点、加工设备、敌人实例和地图对象掉落数量。

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

当前 `GameRoot` 仍承担原型事件入口和地图 / HUD 调用编排，但任务事件映射、任务目标进度写入、目标上限封顶、目标满足度判断、任务完成状态变更、任务解锁效果写入和后续任务激活已下沉到 `scripts/quests/`；加工设备、建造点、清理地块、污染边界门槛和遗迹入口提示文本已下沉到 `scripts/ui/interaction_prompt_formatter.gd`。

HUD 侧已将可复用文本和视图数据拆入 presenter：`HudDebugPanelPresenter` 负责存档槽与快捷栏调试面板刷新，`HudDevicePanelPresenter` 负责设备面板文本、配方列表和操作提示，`HudFeedbackPresenter` 负责任务完成、撤离和补给反馈文本，`HudStatusPresenter` 负责右侧状态摘要，`HudMapPresenter` 负责小地图 / 区域标记视图数据，`HudHintPresenter` 负责任务方向和首小时引导短提示，`HudLogPresenter` 负责启动、槽位、失败、区域、设备和推荐配方等日志格式化。`PrototypeHud` 当前主要保留控件引用、Label 赋值、面板显示 / 隐藏、计时和日志入口；后续应优先避免重新把业务文案、任务判断或状态拼装堆回 HUD 主脚本或 `GameRoot`，只有当计时胶水继续膨胀时再拆新的 presenter。

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
