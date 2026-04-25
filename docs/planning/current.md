# Current Plan

更新时间：2026-04-25

## 当前阶段

RadishCatalyst 当前处于“仓库初始化与原型准备”阶段。

阶段重点：

- 完成仓库基础治理。
- 固定文档目录结构。
- 明确 AI 协作规则和分支治理规则。
- 收束产品方向、首版范围和联机架构边界。
- 为后续 Godot 原型工程初始化做准备。

## 当前最高优先级

1. 仓库规范、换行符、编码和检查脚本。
2. `AGENTS.md` / `CLAUDE.md` 协作规则同步。
3. `docs/` 目录结构、当前计划、ADR 和周志制度。
4. 首版 MVP 功能清单。
5. 核心玩法循环图与文字说明。
6. 首版资源与工艺链设计。
7. Godot 4.x 原型工程初始化。

## 当前不做

- 不做 MMO 大世界。
- 不把联机作为首版前置条件。
- 不提前实现官方账号、交易、公会、排行榜或云存档。
- 不引入复杂服务端框架。
- 不大规模生产美术资产。
- 不把参考仓库代码整包迁入本仓库。

## 当前默认验证

```powershell
pwsh ./scripts/check-text-files.ps1
```

如果未来加入 Godot 工程，应在本文件中补充对应的导入、构建、导出或测试基线。

## 下一批建议文档

- `product/positioning-and-selling-points.md`
- `product/mvp-feature-list.md`
- `design/core-gameplay-loop.md`
- `design/resources-and-process-chain.md`
- `design/character-progression-and-equipment.md`
- `design/maps-and-regions.md`
- `architecture/multiplayer-roadmap.md`

## 阶段退出条件

满足以下条件后，可以进入“Godot 可玩原型”阶段：

- 仓库治理和检查脚本已稳定。
- 首版 MVP 范围已明确。
- 核心循环已能用一张图或一段流程描述清楚。
- 第一条资源 / 工艺 / 角色成长联动链路已确定。
- 客户端工程目录可以初始化且不会反向污染文档结构。
