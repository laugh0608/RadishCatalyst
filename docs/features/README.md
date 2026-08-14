# Feature Development Docs

更新时间：2026-08-13

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

当前阶段专题：[Slice First Playable Journey V1](slice-first-playable-journey-v1.md)——自动与人工完整全链已通过，但萝卜SAMA判定表现仍有大量草稿层，陌生玩家盲测延期。

最新收口子专题：[Slice Visual Hierarchy And Color Separation V1](slice-visual-hierarchy-and-color-separation-v1.md) 与 [Slice Game UI Visual Finalization V1](slice-game-ui-visual-finalization-v1.md)——世界设备、HUD、制造 / 背包、设备、核心与系统界面均已完成正式入口和人工定稿。

当前活跃专题：[Slice Ranged Weapon And Industrial Ammunition V1](slice-ranged-weapon-and-industrial-ammunition-v1.md)——P0 与目标稿 V3 枪械身份已获人工确认；原生尺寸 V1—V3 均已否决，删臂拼接路线停止，等待换介质确认，不接客户端。

最新人工通过子专题：[Slice Category Inventory And Powered Storage V1](slice-category-inventory-and-powered-storage-v1.md) 与 [Slice World Device Family Integration V1](slice-world-device-family-integration-v1.md)——联合 schema 8、设备家族、实体物流、真实二值供电线和双档迁移闸门已收口；[Slice Unified Device Operation Panels V1](slice-unified-device-operation-panels-v1.md) 核心仓库包 2 的视觉与行为也已随 UI 定稿收口。

已收口专题：

- [Slice Base First Screen Integration V1](slice-base-first-screen-integration-v1.md)——归一管线、基地首屏、玩家四方向行走（2026-07-16 收口）。
- [Slice Crystal Expedition V1](slice-crystal-expedition-v1.md)——晶体远征区、无缝大地图与相机跟随口径定档（2026-07-17 收口）。
- [Slice Minimal Core Loop V1](slice-minimal-core-loop-v1.md)——采集晶体 → 回基地 → 修复核心 + 最小 HUD（2026-07-17 收口）。
- [Slice Save Persistence V1](slice-save-persistence-v1.md)——独立切片存档服务、载入存档改指切片、自动存档与读档还原（2026-07-18 收口）。
- [Slice Harvest And Build V1](slice-harvest-and-build-v1.md)——整备台建造采集器、晶体地放置、自动产出，首条化工链第一步（2026-07-18 收口）。
- [Slice Viewpoint Correction V1](slice-viewpoint-correction-v1.md)——投影口径修订为高斜角俯视、全部世界层素材重出换装、画面填充止血、方向性 idle（2026-07-19 收口）。
- [Slice Core Functionalization V1](slice-core-functionalization-v1.md)——修复核心后启用 6 格直供电源与中央仓库，schema 3 存读兼容（2026-07-21 收口）。
- [Slice Building Placement And Power Grid V1](slice-building-placement-and-power-grid-v1.md)——六类建筑通用放置、扩展供电、schema 4、自举资源与视觉修正包 5（2026-07-25 收口）。
- [Slice Conveyor Logistics V1](slice-conveyor-logistics-v1.md)——直线、转角、端点、双 / 三路合流、公平轮询、回压与 schema 5 存读（2026-07-25 收口）。
- [Slice Reactor Automation V1](slice-reactor-automation-v1.md)——双端口反应器、催化剂货物、schema 6、自然完整产线、双状态重启与人工确认（2026-07-26 收口）。
- [Slice Recipe Processing V1](slice-recipe-processing-v1.md)——L0–L5 空间工厂自动化 arc，总体完成“冒险资源 → 电力 / 物流 / 加工 → 催化剂”（2026-07-26 收口）。
- [Slice Multi-World Save List V1](slice-multi-world-save-list-v1.md)——最多 30 个世界、三份备份、损坏隔离、可恢复回收、启动列表与游戏内保存返回（2026-07-26 收口）。
- [Slice First Field Combat And Sample Recovery V1](slice-first-field-combat-and-sample-recovery-v1.md)——首次充能、鼠标瞄准战斗、单敌人、撤离、关键样本、基地交付与 schema 7（2026-07-27 收口）。
- [Slice HUD Gameplay Shell V1](slice-hud-gameplay-shell-v1.md)——任务舷窗、三物资槽、角色 / 敌人余量条与上下文键帽（2026-07-28 收口）。
- [Slice Graphical Crafting And Inventory V1](slice-graphical-crafting-and-inventory-v1.md)——七张配方卡、九个背包格、鼠标制作 / 选中与权威阻塞反馈（2026-07-29 收口）。

背景结论（复盘与证据轮）：

- 美术介质已定为像素 + 2D 俯视网格，机械口径见 [Pixel Art And Grid Standard](../reference/pixel-art-and-grid-standard.md)；介质证据轮 S1 到 S6 全绿。
- 首个交付版结构：单基地 + 单远征区 = 同一张无缝地图上的两个区域（2026-07-16 定档），20 到 40 分钟可玩切片；章程见 [复盘文档](../planning/project-purpose-and-solo-ai-development-review.md)。
- 当前先完成第一可玩切片全链串通；立绘对话框与角色八方向动画继续作为后续候选，不抢占全链里程碑证据。

## 历史专题

2026-04 至 2026-07 服务旧 Demo Definition V1（12 区纵切 + 写实资产路线）的约 60 个专题已整体归档至 [docs/archive/features-demo-v1/](../archive/features-demo-v1/README.md)，仅作历史证据与设计素材，不再是任何当前规范；其中系统层设计（任务链、存档、资源链、加工、HUD 状态）对应的运行时代码仍保留复用。
