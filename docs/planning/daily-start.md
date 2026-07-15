# Daily Start

更新时间：2026-07-15

## 用途

当提示是“根据项目规划和开发进度，今天要来做什么以推进开发”时，优先阅读本文。本文只提供日常入口和读取顺序；阶段方向与边界以 `docs/planning/current.md` 为准。

## 阶段

当前为「切片实现：基地首屏接入」，实现开发已恢复（2026-07-15 结束项目级暂停）。

- 当前唯一活跃功能专题：[Slice Base First Screen Integration V1](../features/slice-base-first-screen-integration-v1.md)。
- 美术介质机械口径：[Pixel Art And Grid Standard](../reference/pixel-art-and-grid-standard.md)（32px 网格、960x540 相机、宏块归一均已定稿）。
- 章程与复盘结论存档：[Project Purpose And Solo AI Development Review](project-purpose-and-solo-ai-development-review.md)。

## 最近收尾

- 2026-07-12 至 07-13 项目级复盘：五项决策产物确认（第一目的、像素介质、单基地 + 单远征区结构、生产协议、仓库处置），全文档体系切换像素口径，旧路线归档。
- 2026-07-13 至 07-14 介质证据轮 S1 到 S6 全绿：锚点、地面、设备、角色行走帧表、二三屏重复性、主角立绘全部通过，未触发失败闸门；双锚点入库 `assets/reference/`。
- 2026-07-15 相机虚拟分辨率定档 960x540；章程定稿并同步产品定义；萝卜SAMA指定首个切片实现包，暂停正式结束。

## 下一步事项

按专题三包串行，每包收口做最小验证并记入当周周志：

1. 包 1 归一管线与素材入库：`tools/` 像素归一脚本（整数缩放、调色板量化、宏块切分、去底、双态切分），证据轮定稿素材处理进 `client/assets/`。
2. 包 2 单基地场景与相机：宏块地面 + 设备摆位 + 960x540 像素相机，新场景不复用旧场景树。
3. 包 3 玩家接入：d1 静态 + 4 帧行走动画、网格碰撞，正式入口可控行走。

归一注意点（证据轮审阅结论）：核心双态切两张、行走帧提亮到 d1 基线、立绘不归一，见专题文档与 W29 周志。

## 防跑偏规则

- 只做专题内三包；晶体 / 远征区、系统层换皮、HUD / 任务 / 存档接入是后续专题，不顺手扩展。
- 不生成新素材，证据轮素材足够本专题；图像会话稳定性约束不变。
- 冻结保留旧场景、旧视觉层与旧检查，不删除、不修改、不“顺手清理”。
- 玩家可见目标以正式入口实机截图对比证据轮拼合预览为主证据，自动检查只兜底。
- 介质口径变更、两轮失败复盘、专题切换属架构级升级点，执行会话停手上报萝卜SAMA。

## 当前不做

- 晶体 / 污染 / 远征区场景，任务链 / 资源链 / HUD / 存档接入新场景。
- 8 方向行走、待机动画组、角色换装、新玩法、新配方、新敌人。
- 旧代码与旧素材清理（清单专题收口后另定）、联机、多星球、试玩准备与发布。

## 必读与选读

日常必读：

- `docs/planning/current.md`
- `docs/features/slice-base-first-screen-integration-v1.md`
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
