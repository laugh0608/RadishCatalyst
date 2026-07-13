# Daily Start

更新时间：2026-07-13

## 用途

当提示是“根据项目规划和开发进度，今天要来做什么以推进开发”时，优先阅读本文。本文只提供日常入口和读取顺序；阶段方向与边界以 `docs/planning/current.md` 为准。

## 阶段

当前为「复盘收尾与介质证据轮待启动」，实现开发仍暂停。

- 项目定位：像素风 2D 俯视工业科幻 ARPG；首个交付版为单基地 + 单远征小区域的 20 到 40 分钟可玩切片。
- 美术介质机械口径：[Pixel Art And Grid Standard](../reference/pixel-art-and-grid-standard.md)。
- 复盘议题与逐项确认记录：[Project Purpose And Solo AI Development Review](project-purpose-and-solo-ai-development-review.md)。

## 最近收尾

- 2026-07-12 `R1` / `R2` 两条写实资产路线实证失败，暂停全部实现开发，转入项目级复盘。
- 2026-07-12 复盘首批结论确认：第一目的（证明产品可行性）、介质切换像素 + 2D 俯视网格、32px 玩法网格、介质证据计划。
- 2026-07-13 确认产品结构（单基地 + 单远征区）与仓库处置（激进归档），完成全文档体系整改：上位口径、美术生产真相源、入口与索引切换像素口径；约 60 个旧 features 专题与 6 个旧规划文档归档。

## 下一步事项

1. 定稿章程剩余要素：目标玩家、核心体验、明确不做、完成定义（需萝卜SAMA确认）。
2. 介质证据轮由萝卜SAMA择时启动；启动后按证据计划执行：第一屏（地形 + 3 台设备 + 角色 + 4 帧行走）→ 第二、三屏重复性 → 立绘小样。
3. 证据轮通过后建立首个切片专题，恢复实现开发。

## 防跑偏规则

- 不修改客户端、玩法、场景、HUD、存档或检查脚本；不删除冻结的旧代码与旧素材。
- 不自行启动图像生成；证据轮启动是萝卜SAMA的显式决策。
- 不在暂停期以工程整理、修小问题或新设计包制造“仍在推进”的假象。
- 图像生成会话稳定性约束（单会话最多 3 张、生成与接入分离）不因新介质放宽。

## 当前不做

- 所有代码、场景、素材、玩法、UI、检查、工程整改、试玩和发布工作。
- 12 区纵切、多区域大地图、旧 Demo 定义的任何续接。
- 在章程与证据轮完成前细化首小时、联机或长期成长设计。

## 阻塞标准

当前暂停是主动决策，不以 bug 或工程状态作为恢复开发理由。

## 必读与选读

日常必读：

- `docs/planning/current.md`
- `docs/planning/project-purpose-and-solo-ai-development-review.md`

按任务选读：

- 像素介质与生产管线：`docs/reference/pixel-art-and-grid-standard.md`
- 提示词库：`docs/reference/ai-art-prompts.md`
- 素材包候选：`docs/reference/free-asset-pack-candidates.md`
- 视觉气质与 UI 原则：`docs/product/visual-and-ui-direction.md`
- 流程闸门：`docs/process/development-decision-gates.md`
- 旧路线历史证据：`docs/archive/features-demo-v1/README.md`、`docs/archive/planning-demo-v1/README.md`

## 验证入口

暂停期间只验证文档：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`。不启动 Godot。
