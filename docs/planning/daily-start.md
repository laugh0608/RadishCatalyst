# Daily Start

更新时间：2026-07-17

## 用途

当提示是“根据项目规划和开发进度，今天要来做什么以推进开发”时，优先阅读本文。本文只提供日常入口和读取顺序；阶段方向与边界以 `docs/planning/current.md` 为准。

## 阶段

当前为「切片实现：存档与状态持久化」。

- 当前唯一活跃功能专题：[Slice Save Persistence V1](../features/slice-save-persistence-v1.md)。
- 美术介质机械口径：[Pixel Art And Grid Standard](../reference/pixel-art-and-grid-standard.md)（32px 网格、960x540 相机、宏块归一均已定稿）。
- 章程与复盘结论存档：[Project Purpose And Solo AI Development Review](project-purpose-and-solo-ai-development-review.md)。

## 最近收尾

- 2026-07-15 至 07-16 首屏专题收口：归一管线与素材入库、基地首屏、玩家四方向行走（含 3.5 方向帧增补与斜上修正）。
- 2026-07-16 至 07-17 晶体区专题收口：晶体远征区落地；"单基地 + 单远征区 = 同图两区域"无缝大地图口径定档（萝卜SAMA拍板，参照 Factorio / The Riftbreaker 空间体验），相机改跟随式，箱庭切换机制废弃。
- 2026-07-17 最小核心循环专题收口：采集晶体 → 回基地 → 消耗 10 晶体修复核心换态，`SliceHud` 三要素实时一致；世界状态仍仅运行时有效。
- 2026-07-17 萝卜SAMA择序确认下一专题为存档与状态持久化（系统层换皮第二步）。

## 下一步事项

按专题三包串行，每包收口做最小验证并记入当周周志：

1. 包 1 切片存档服务与保存：新建独立 `SliceSaveService`（隔离目录 + schema 版本 + 原子写），晶体数 / 已采集簇 / 修复态 / 玩家位置写出。
2. 包 2 还原与入口接线：`SliceWorld` 按存档还原现场，入口按确认方案接读档路径。
3. 包 3 闭环验证与收口：运行时”存档 → 重启 → 读档还原”断言，前后现场截图。

## 防跑偏规则

- 只做专题内三包；本专题只存现有循环状态，背包 / 多资源 / 配方、任务链、建造、立绘对话不顺手扩展。
- 切片存档为新建独立 `SliceSaveService`，与旧存档系统物理隔离；不迁移、不修改冻结的旧 `SaveService` / `WorldState` / `GameRoot` 链路。
- 不生成新素材；图像会话稳定性约束不变。
- 冻结保留旧场景、旧视觉层与旧检查，不删除、不修改、不”顺手清理”。
- 玩家可见目标以正式入口实机截图与运行时路径复核为主证据，自动检查只兜底。
- 存档字段与入口方案、两轮失败复盘、专题切换属架构级升级点，执行会话停手上报萝卜SAMA。

## 当前不做

- 背包、多资源种类、配方加工链、建造；敌人、战斗、污染伤害。
- 任务链、立绘对话；多存档槽位 / 云存档 / 存档管理 UI。
- 旧代码与旧素材清理（清单专题收口后另定）、联机、多星球、试玩准备与发布。

## 必读与选读

日常必读：

- `docs/planning/current.md`
- `docs/features/slice-save-persistence-v1.md`
- `docs/reference/pixel-art-and-grid-standard.md`

按任务选读：

- 归一与提示词口径：`docs/reference/ai-art-prompts.md`
- 流程闸门：`docs/process/development-decision-gates.md`
- 章程与完成定义：`docs/planning/project-purpose-and-solo-ai-development-review.md`
- 视觉气质与 UI 原则：`docs/product/visual-and-ui-direction.md`
- 旧路线历史证据：`docs/archive/features-demo-v1/README.md`、`docs/archive/planning-demo-v1/README.md`

## 验证入口

- 代码与素材接入：`sh ./scripts/check-client.sh`（默认不启动 Godot）；场景与脚本改动按需 `--with-godot` 单项验证。
- 文档改动：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`。
