# Current Plan

更新时间：2026-04-26

## 当前阶段

RadishCatalyst 当前处于“仓库初始化、项目方向定稿与 Godot 可玩原型准备”阶段。

阶段重点：

- 完成仓库基础治理。
- 固定文档目录结构。
- 明确 AI 协作规则和分支治理规则。
- 收束产品方向、故事基调、视觉 UI、发布形态、联机架构边界和首版 MVP 范围。
- 明确参考作品口径、差异化边界和时间 / 天气系统的首版位置。
- 明确第一可玩切片、首版叙事任务框架和首小时引导节奏。
- 明确 Windows、Web 试玩、Android、WebApp 与 GDScript / .NET 的兼容边界。
- 建立玩家 Wiki 与官方工具的长期内容边界。
- Godot 客户端工程已在 `client/` 初始化，下一步进入第一可玩切片的工程地基和最小玩法系统实现。

## 当前最高优先级

1. 仓库规范、换行符、编码和检查脚本。
2. `AGENTS.md` / `CLAUDE.md` 协作规则同步。
3. `docs/` 目录结构、当前计划、ADR 和周志制度。
4. 项目定义、核心元素、故事方向和客户端形态。
5. 玩家 Wiki 与官方工具目录边界。
6. 视觉与 UI 风格方向。
7. 世界观前提、玩家身份、异星生态和主线基调。
8. 平台、离线单机、本地存档和兼容原则。
9. 核心玩法循环、地图区域、资源链和角色成长桥接文档。
10. Godot 客户端工程地基整理与第一可玩切片实现准备。

## 当前不做

- 首版和首个存档 + 联机版本不做 MMO 大世界，但保留更远期大型多人在线的演进口子。
- 不把联机作为首版前置条件。
- 联机方向按 2~5 人协作作为首版设计基准，长期只预留 2~10 人专服或高性能房间扩展。
- 不提前实现官方账号、交易、公会、排行榜或云存档。
- 不引入复杂服务端框架。
- 不把完整游戏 Web 客户端作为 MVP 必须交付项。
- 不把 Godot 客户端核心逻辑押到 C# / .NET。
- 不大规模生产美术资产。
- 不提前批量编写玩家 Wiki 百科条目。
- 不立即实现完整官方工具。
- 不把参考仓库代码整包迁入本仓库。

## 当前默认验证

```powershell
pwsh ./scripts/check-text-files.ps1
```

Godot 工程已初始化，当前默认门禁为仓库文本卫生和首批客户端静态数据一致性检查：

```powershell
pwsh ./scripts/check-client-data.ps1
```

进入客户端场景拼装后，同步执行：

```powershell
pwsh ./scripts/check-client-scenes.ps1
```

本机具备 Godot 4.6.2 console 可执行文件时，同步执行：

```powershell
pwsh ./scripts/check-godot-client.ps1
```

进入更多脚本和场景实现后，应继续补充更细的脚本检查、场景加载或导出验证入口。

## 下一步建议

- 先建立首批静态数据文件和 `DataRegistry`，只覆盖第一切片需要的物品、配方、建筑、敌人、区域、地图对象、污染、天气和任务。
- 建立最小 `WorldState`、`CharacterState`、`InventoryState` 和 `QuestState`，先保证状态对象能被保存和加载。
- 在当前 `Boot`、`GameRoot`、临时切片地图和原型 HUD 基础上，继续接入采集、敌人、基地设备和任务推进的真实规则层。
- 把 `planning/vertical-slice.md` 拆成首批 Godot 实现任务，避免一开始扩张到完整 MVP。
- 以 `design/onboarding-and-first-hour.md` 作为任务提示和系统解锁顺序基准，先做最短引导链。
- 每完成一个小阶段，都按 `planning/milestone-review-checklist.md` 做兼容、存档、数据和范围复核。
- `design/time-and-weather-system.md`
- `architecture/multiplayer-roadmap.md`

## 阶段退出条件

满足以下条件后，可以进入“Godot 可玩原型”阶段：

- 仓库治理和检查脚本已稳定。
- 项目定义、故事基调、视觉 UI 和发布形态已有上位结论。
- 玩家 Wiki 与官方工具的内容边界已明确。
- 首版 MVP 范围已通过 `product/mvp-feature-list.md` 明确。
- 核心循环已能用一张图或一段流程描述清楚。
- 第一条资源 / 工艺 / 角色成长联动链路已确定。
- 首版战斗、外勤交互、可破坏对象和地基 / 平整边界已明确。
- 参考作品与差异化边界已明确，时间 / 天气系统已确定首版轻量预留原则。
- 本地存档、稳定 ID、地图对象、时间天气和基地状态边界已明确。
- 第一可玩切片、叙事任务框架和首小时引导节奏已明确。
- 静态数据 schema 和 Godot 工程目录结构已明确。
- Windows 主平台、Web 可选试玩、Android 远期评估、WebApp 工具定位和 GDScript / .NET 边界已明确。
- 里程碑复核清单已明确。
- 客户端工程已在 `client/` 初始化且未反向污染文档结构。
