# RadishCatalyst Player Wiki

本目录是未来面向玩家的 Wiki 源内容，不是开发者内部设计文档。

目标是：当项目进入可公开阶段后，本目录内容可以较低成本迁移为在线 Wiki、官网知识库或社区文档。

## 内容边界

Wiki 面向玩家，记录玩家应该能看到、能学习、能检索的内容：

- 新手入门
- 世界观公开信息
- 材料与物品
- 配方与合成路线
- 设备与操作
- 生产线与工艺链
- 区域、未知区域与秘境
- 怪物、Boss 与生态
- 状态、伤害、抗性与异常
- 任务、事件与探索线索
- 常见问题与机制说明

Wiki 不记录：

- 内部开发计划
- 未公开剧情真相
- 剧透级隐藏机制
- 还没有定稿的实现细节
- AI 协作规则、PR 流程和仓库治理规则

## 推荐目录

- `guides/`：新手指南、机制说明、常见问题。
- `items/`：物品、材料、装备、消耗品。
- `recipes/`：配方、合成路线、替代路线。
- `facilities/`：设备、建筑、管线、储罐、反应器等。
- `production-lines/`：典型生产线、工艺链、产能规划。
- `regions/`：地图区域、资源分布、危险等级、未知区域。
- `enemies/`：怪物、Boss、敌对生态。
- `dungeons/`：秘境、副本、特殊远征区域。
- `mechanics/`：战斗、采集、污染、安全、事故、联机等机制说明。
- `lore/`：公开世界观、阵营、事件和可公开剧情。

## 当前正式切片词条

以下页面与启动菜单当前进入的空间工厂切片一致：

- [空间工厂建造与物流入门](guides/spatial-factory-basics.md)
- [工业地板](facilities/industrial-floor.md)
- [晶体采集器](facilities/crystal-collector.md)
- [电力中继](facilities/power-relay.md)
- [传送带](facilities/conveyor.md)
- [储物箱](facilities/basic-storage.md)
- [第一工业晶体线](production-lines/first-industrial-crystal-line.md)

## 冻结旧纵切保留词条

仓库仍保留旧 `GameRoot + VerticalSliceMap` 纵切用于开发回归。以下词条说明那条路径的任务、战斗、污染和前线内容，不应与当前空间工厂操作混用。

以下页面适合新玩家或首小时复查：

- [首小时外勤入门](guides/first-hour-field-guide.md)
- [基础零件](items/basic-parts.md)
- [基础过滤模块](items/basic-filter-module.md)
- [污染沉积物](items/polluted-residue.md)
- [污染浆液](items/polluted-slurry.md)
- [修复凝胶](items/repair-gel.md)
- [抗污染药剂 I](items/resistance-vial-i.md)
- [晶体矿物加工](recipes/crystal-ore-processing.md)
- [调制修复凝胶](recipes/repair-gel.md)
- [制造基础地基材料](recipes/foundation-material.md)
- [污染沉积物处理](recipes/pollution-residue-treatment.md)
- [回收基础零件](recipes/basic-parts-reclamation.md)
- [出发整备台](facilities/field-outfitting-station.md)
- [污染过滤器](facilities/pollution-filter.md)
- [污染浆液缓冲罐](facilities/slurry-buffer-tank.md)
- [晶体矿脉区](regions/crystal-vein-field.md)
- [污染边界区](regions/pollution-edge.md)
- [功能与过渡区域速览](regions/non-core-field-regions.md)
- [交互反馈与受阻恢复](mechanics/interaction-feedback-and-recovery.md)
- [污染与外勤补给](mechanics/pollution-and-field-supplies.md)

以下页面涉及中后段相位井内容，默认按剧透处理：

- [裂相脊到回声台地生产线](production-lines/fracture-ridge-echo-plateau-line.md)
- [锚定桥后的前线回稳指南](guides/late-frontier-anchor-field-guide.md)
- [前线锚点与稳定窗口](mechanics/frontline-anchors-and-stable-windows.md)
- [锚定桥前线区域](regions/phase-well-east-frontier.md)
- [核心稳定站](regions/core-stabilization-station.md)
- [相位井锚场回稳生产线](production-lines/phase-well-anchor-field-line.md)
- [污染边界到核心稳定站生产线](production-lines/pollution-edge-core-stabilization-line.md)
- [核心稳压缓冲包](items/core-stabilization-buffer.md)
- [核心写入校验片](items/core-write-charge.md)

其中功能与过渡区域速览、交互反馈与受阻恢复、前线回稳、稳定窗口和锚定桥前线区域页面已覆盖非核心区路线身份、现场对象处理、失败恢复路线、轻量前线行动、基地行动选择、压力清障、风险收益确认、下一次出发整备、行动候选判断、同一前线窗口反馈、高压窗口三模块联锁和核心稳定站 demo 终点。

## 编写原则

- 文件名使用英文，正文使用中文。
- 面向玩家解释，不使用内部代号替代正式名称。
- 每个页面优先包含“用途 / 获取方式 / 相关配方 / 相关区域 / 注意事项”。
- 数据类内容未来应尽量从结构化游戏数据生成，避免 Wiki、游戏和官方工具三处手写不一致。
- 剧透内容应单独标记或延后公开。
