# Daily Start

更新时间：2026-07-18

## 用途

当提示是“根据项目规划和开发进度，今天要来做什么以推进开发”时，优先阅读本文。本文只提供日常入口和读取顺序；阶段方向与边界以 `docs/planning/current.md` 为准。

## 阶段

当前为「切片实现：采集与建造扩展」。

- 当前唯一活跃功能专题：[Slice Harvest And Build V1](../features/slice-harvest-and-build-v1.md)。
- 美术介质机械口径：[Pixel Art And Grid Standard](../reference/pixel-art-and-grid-standard.md)（32px 网格、960x540 相机、宏块归一均已定稿）。
- 章程与复盘结论存档：[Project Purpose And Solo AI Development Review](project-purpose-and-solo-ai-development-review.md)。

## 最近收尾

- 2026-07-17 最小核心循环专题收口：采集晶体 → 回基地 → 消耗 10 晶体修复核心换态，`SliceHud` 三要素实时一致。
- 2026-07-17 至 07-18 存档持久化专题收口：`SliceSaveService` 隔离存档、`载入存档` 改指切片、纯自动存档；双进程“存档 → 重启 → 读档”闭环 42 项断言全过，萝卜SAMA实机复核通过（含冻结启动壳检查锚点唯一例外批准）。
- 2026-07-18 萝卜SAMA择序确认下一专题为采集与建造扩展（系统层换皮第三步、首条化工链第一步）。

## 下一步事项

按专题三包串行，每包收口做最小验证并记入当周周志：

1. 包 1 建造与放置：整备台消耗晶体制造采集器，携带态 + 放置预览 + 网格校验，落地生成设备节点。
2. 包 2 自动产出与存档还原：采集器计时产出入世界计数，`collectors` 进存档、读档按坐标重建续产。
3. 包 3 全循环验证与收口：建造扣费 / 非法放置拦截 / tick 产出 / 存读还原断言，截图。

## 防跑偏规则

- 只做专题内三包；配方 / 第二资源 / 加工链、储存罐功能化、设备拆除与升级、敌人战斗、任务链、立绘对话不顺手扩展。
- 采集器用库存 `collector` 精灵，零新素材；放置预览用允许的动态高亮表达，不引入程序绘制主介质。
- 存档沿用 `SliceSaveService` 追加可选字段，schema 不升版；不迁移、不修改冻结的旧系统与旧检查。
- 冻结保留旧场景、旧视觉层与旧检查，不删除、不修改、不“顺手清理”。
- 玩家可见目标以正式入口实机截图与运行时路径复核为主证据，自动检查只兜底。
- 建造链路与放置约束定档、两轮失败复盘、专题切换属架构级升级点，执行会话停手上报萝卜SAMA。

## 当前不做

- 配方、第二资源、加工链、储存容量；设备拆除、移动、升级、多种设备。
- 敌人、战斗、污染伤害；任务链、立绘对话；多存档槽位与存档管理 UI。
- 旧代码与旧素材清理（清单专题收口后另定）、联机、多星球、试玩准备与发布。

## 必读与选读

日常必读：

- `docs/planning/current.md`
- `docs/features/slice-harvest-and-build-v1.md`
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
