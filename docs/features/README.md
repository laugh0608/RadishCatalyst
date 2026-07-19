# Feature Development Docs

更新时间：2026-07-18

## 用途

本目录存放玩家功能目标文档。阶段入口定主线，具体范围、路径和验收放在这里。

当开发同时影响玩法、场景、HUD、任务、存档、运行时状态或自动检查时，先建或更新专题。

## 使用规则

- `docs/planning/current.md` 只保留当前阶段、当前活跃专题、阶段边界和退出条件。
- `docs/planning/daily-start.md` 只保留日常推进入口和读取顺序。
- `docs/devlogs/` 只记录已经发生的推进、决策、验证和风险，不作为具体功能范围的真相源。
- 专题文档必须说明玩家价值、范围、不做项、路径、状态 / 存档 / HUD / 检查和验收。
- 不为文案调整、局部修错或一次性讨论创建专题；专题应对应玩家可感知功能目标或阶段开发包。
- 活跃专题接近 220 行时，优先拆成总览与子专题，或把历史过程移入周志 / 参考 / 归档。

## 专题层级

- 阶段级专题说明能力域方向、冻结边界和跨包验收。
- 可执行细专题用于定义一个基建设备、装备 / 模块、功能玩法、场景压力或工程边界包，是每日代码开发的直接范围来源。
- 细专题应由阶段入口链接。

## 当前状态

当前唯一活跃功能专题：[Slice Viewpoint Correction V1](slice-viewpoint-correction-v1.md)——介质级视角修正轮（世界层素材由 3/4 立面重出为高机位近正俯视 + 画面填充止血），2026-07-18 萝卜SAMA实机定档。

已收口专题：

- [Slice Base First Screen Integration V1](slice-base-first-screen-integration-v1.md)——归一管线、基地首屏、玩家四方向行走（2026-07-16 收口）。
- [Slice Crystal Expedition V1](slice-crystal-expedition-v1.md)——晶体远征区、无缝大地图与相机跟随口径定档（2026-07-17 收口）。
- [Slice Minimal Core Loop V1](slice-minimal-core-loop-v1.md)——采集晶体 → 回基地 → 修复核心 + 最小 HUD（2026-07-17 收口）。
- [Slice Save Persistence V1](slice-save-persistence-v1.md)——独立切片存档服务、载入存档改指切片、自动存档与读档还原（2026-07-18 收口）。
- [Slice Harvest And Build V1](slice-harvest-and-build-v1.md)——整备台建造采集器、晶体地放置、自动产出，首条化工链第一步（2026-07-18 收口）。

背景结论（复盘与证据轮）：

- 美术介质已定为像素 + 2D 俯视网格，机械口径见 [Pixel Art And Grid Standard](../reference/pixel-art-and-grid-standard.md)；介质证据轮 S1 到 S6 全绿。
- 首个交付版结构：单基地 + 单远征区 = 同一张无缝地图上的两个区域（2026-07-16 定档），20 到 40 分钟可玩切片；章程见 [复盘文档](../planning/project-purpose-and-solo-ai-development-review.md)。
- 后续专题候选（收口后由萝卜SAMA择序）：配方加工（化工链第二步）、立绘对话框最小接入、敌人与战斗（素材生成会话完成后）、角色八方向动画（2026-07-18 记录，对角朝向生成风险高、排后续）。

## 历史专题

2026-04 至 2026-07 服务旧 Demo Definition V1（12 区纵切 + 写实资产路线）的约 60 个专题已整体归档至 [docs/archive/features-demo-v1/](../archive/features-demo-v1/README.md)，仅作历史证据与设计素材，不再是任何当前规范；其中系统层设计（任务链、存档、资源链、加工、HUD 状态）对应的运行时代码仍保留复用。
