# Current Plan

更新时间：2026-04-25

## 当前阶段

RadishCatalyst 当前处于“仓库初始化与项目方向定稿”阶段。

阶段重点：

- 完成仓库基础治理。
- 固定文档目录结构。
- 明确 AI 协作规则和分支治理规则。
- 收束产品方向、故事基调、视觉 UI、发布形态和联机架构边界。
- 建立玩家 Wiki 与官方工具的长期内容边界。
- 在上述方向稳定后，再进入首版 MVP 和 Godot 原型准备。

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
10. 首版 MVP 功能清单。
11. 首版战斗与交互原型边界。
12. Godot 4.x 原型工程初始化。

## 当前不做

- 首版和首个存档 + 联机版本不做 MMO 大世界，但保留更远期大型多人在线的演进口子。
- 不把联机作为首版前置条件。
- 联机方向按 2~5 人协作作为首版设计基准，长期只预留 2~10 人专服或高性能房间扩展。
- 不提前实现官方账号、交易、公会、排行榜或云存档。
- 不引入复杂服务端框架。
- 不大规模生产美术资产。
- 不提前批量编写玩家 Wiki 百科条目。
- 不立即实现完整官方工具。
- 不把参考仓库代码整包迁入本仓库。

## 当前默认验证

```powershell
pwsh ./scripts/check-text-files.ps1
```

如果未来加入 Godot 工程，应在本文件中补充对应的导入、构建、导出或测试基线。

## 下一批建议文档

- 复核 `product/project-definition.md`、`product/visual-and-ui-direction.md`、`product/worldbuilding-premise.md`、`product/player-wiki-and-official-tools.md` 和 `architecture/platform-and-compatibility.md` 是否已经形成一致的上位方向。
- 复核 `design/core-gameplay-loop.md`、`design/maps-and-regions.md`、`design/resources-and-process-chain.md` 和 `design/character-progression-and-equipment.md` 是否足以支撑首版 MVP 拆分。
- `product/mvp-feature-list.md`
- `architecture/multiplayer-roadmap.md`

## 阶段退出条件

满足以下条件后，可以进入“Godot 可玩原型”阶段：

- 仓库治理和检查脚本已稳定。
- 项目定义、故事基调、视觉 UI 和发布形态已有上位结论。
- 玩家 Wiki 与官方工具的内容边界已明确。
- 首版 MVP 范围已明确。
- 核心循环已能用一张图或一段流程描述清楚。
- 第一条资源 / 工艺 / 角色成长联动链路已确定。
- 客户端工程目录可以初始化且不会反向污染文档结构。
