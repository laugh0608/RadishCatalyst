# Daily Start

更新时间：2026-07-16

## 用途

当提示是“根据项目规划和开发进度，今天要来做什么以推进开发”时，优先阅读本文。本文只提供日常入口和读取顺序；阶段方向与边界以 `docs/planning/current.md` 为准。

## 阶段

当前为「切片实现：晶体远征区与双向切换」。

- 当前唯一活跃功能专题：[Slice Crystal Expedition V1](../features/slice-crystal-expedition-v1.md)。
- 美术介质机械口径：[Pixel Art And Grid Standard](../reference/pixel-art-and-grid-standard.md)（32px 网格、960x540 相机、宏块归一均已定稿）。
- 章程与复盘结论存档：[Project Purpose And Solo AI Development Review](project-purpose-and-solo-ai-development-review.md)。

## 最近收尾

- 2026-07-15 章程定稿、960x540 定档、项目级暂停结束，首屏专题开工。
- 2026-07-15 至 07-16 首屏专题全收口：归一管线与 19 件素材入库；基地首屏场景与像素相机（实机与拼合预览逐像素一致）；玩家四方向可控行走（含 3.5 方向帧增补与斜上修正）；37 个旧检查归档路径存量修复，`check-client` 全绿。
- 2026-07-16 萝卜SAMA择序确认下一专题为晶体远征小区域，`dev` 已推送远端。

## 下一步事项

按专题三包串行，每包收口做最小验证并记入当周周志：

1. 包 1 晶体区场景：晶体地 + 污染地宏块混铺，三档晶体簇摆位与碰撞，读法对照证据轮第三屏。
2. 包 2 世界根与双向切换：单一玩家实例跨区域保留，基地东缘 ↔ 晶体区西缘出口，新档入口改指世界根。
3. 包 3 同构验证与收口：两区截图对比证据轮预览，往返路径实机复测。

素材注意点：晶体地 / 污染地 / 三档晶体簇 / 受损核心已全部在 `client/assets/` 库存，本专题不生成新素材。

## 防跑偏规则

- 只做专题内三包；采集交互、资源数值、任务、HUD、存档接入、敌人与环境伤害是后续专题，不顺手扩展。
- 不生成新素材，库存定稿素材足够本专题；图像会话稳定性约束不变。
- 冻结保留旧场景、旧视觉层与旧检查，不删除、不修改、不“顺手清理”。
- 玩家可见目标以正式入口实机截图对比证据轮拼合预览为主证据，自动检查只兜底。
- 介质口径变更、两轮失败复盘、专题切换属架构级升级点，执行会话停手上报萝卜SAMA。

## 当前不做

- 采集 / 修复交互、资源链、任务链、HUD、存档接入新场景（系统层换皮专题承接）。
- 敌人、战斗、污染伤害等环境机制；立绘对话接入。
- 旧代码与旧素材清理（清单专题收口后另定）、联机、多星球、试玩准备与发布。

## 必读与选读

日常必读：

- `docs/planning/current.md`
- `docs/features/slice-crystal-expedition-v1.md`
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
