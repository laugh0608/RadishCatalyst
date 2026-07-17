# Current Plan

更新时间：2026-07-17

## 入口约束

本文是新会话的阶段入口，只保留当前阶段、当前活跃专题、边界、验证入口和退出条件。

- 当前唯一活跃功能专题：[Slice Save Persistence V1](../features/slice-save-persistence-v1.md)。
- 已收口专题：[基地首屏接入](../features/slice-base-first-screen-integration-v1.md)（07-16）、[晶体远征区](../features/slice-crystal-expedition-v1.md)（07-17，含无缝大地图口径定档）、[最小核心循环](../features/slice-minimal-core-loop-v1.md)（07-17）。
- 美术介质机械口径：[Pixel Art And Grid Standard](../reference/pixel-art-and-grid-standard.md)（32px 网格、960x540 相机、宏块归一均已定稿）。
- 章程与复盘结论：[Project Purpose And Solo AI Development Review](project-purpose-and-solo-ai-development-review.md)（已完成，作决策存档）。
- 旧 Demo V1 路线（12 区纵切 + 写实 2.5D）已废止归档：`docs/archive/features-demo-v1/`、`docs/archive/planning-demo-v1/`。

## 阶段状态

已通过：

- 2026-07-12 至 07-15 项目级复盘与介质证据轮：五项决策产物确认、S1 到 S6 全绿、章程定稿、960x540 定档，实现开发恢复（详见复盘文档与 W29 周志）。
- 2026-07-15 至 07-16 首屏专题收口：归一管线与素材入库、基地首屏、玩家四方向行走（含 3.5 方向帧增补）。
- 2026-07-16 至 07-17 晶体区专题收口：晶体远征区落地；"单基地 + 单远征区 = 同图两区域"无缝大地图口径定档，相机跟随，正式入口跨区步行无切换。
- 2026-07-17 最小核心循环专题收口：采集晶体（小 1 / 中 2 / 大 4，全图 17）→ 回基地 → 消耗 10 晶体修复核心换态，`SliceHud` 三要素实时一致；世界状态仍仅运行时有效。

当前阶段：

```text
切片实现：存档与状态持久化（存得住 -> 读得回）
```

## 当前主线

按专题三包串行：

1. 包 1 切片存档服务与保存：新建独立 `SliceSaveService`（隔离目录 + schema 版本 + 原子写），晶体数 / 已采集簇 / 修复态 / 玩家位置写出。
2. 包 2 还原与入口接线：`SliceWorld` 按存档还原现场，入口按确认方案接读档路径。
3. 包 3 闭环验证与收口：运行时"存档 → 重启 → 读档还原"断言，前后现场截图，周志收口。

存档字段与入口方案（复用 vs 新建、`载入存档` / `继续` 接法）以专题文档为准，关键取舍待萝卜SAMA确认后实现。

## 边界与冻结

- 只做专题内三包；本专题只存现有循环状态，背包 / 多资源 / 配方、敌人与战斗、任务链、建造、立绘对话是后续专题。
- 切片存档为新建独立 `SliceSaveService`，存档目录与旧系统隔离；不迁移、不修改冻结的旧 `SaveService` / `WorldState` / `CharacterState` / 旧 `GameRoot` 链路。
- 冻结保留旧场景、旧视觉层与旧检查，不删除、不修改（清理清单专题收口后另定）。
- 不生成新素材；联机、多星球、试玩准备与发布继续冻结。

## 当前默认验证

- 代码与素材接入：`sh ./scripts/check-client.sh`（默认不启动 Godot）；场景与脚本改动按需 `--with-godot` 单项验证。
- 文档改动：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`。
- 玩家可见目标以正式入口实机截图与运行时路径复核为主证据；自动检查只兜底。

## 阶段退出条件

- 专题三包全部收口：正式入口采集 / 修复后退出，重进读档能逐项还原（晶体数、已采集簇、核心态、玩家位置），HUD 与世界状态一致。
- 收口截图（存档前 / 读档后现场对比）与验证记录写入当周周志。
- 萝卜SAMA确认后选定下一专题（立绘对话 / 采集建造扩展）。

切片整体完成定义（20 到 40 分钟完整体验五条标准）见复盘文档章程节，作为后续各专题的总验收锚点。
