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

## 当前原型已补的词条

以下页面涉及中后段相位井内容，默认按剧透处理：

- [井系桥后的前线回稳指南](guides/late-frontier-anchor-field-guide.md)
- [前线锚点与稳定窗口](mechanics/frontline-anchors-and-stable-windows.md)
- [相位井东侧前线区域](regions/phase-well-east-frontier.md)
- [相位井锚场回稳生产线](production-lines/phase-well-anchor-field-line.md)
- [基础零件](items/basic-parts.md)
- [晶体矿物加工](recipes/crystal-ore-processing.md)
- [回收基础零件](recipes/basic-parts-reclamation.md)

其中前线回稳、稳定窗口和相位井东侧区域页面已覆盖第一版轻量前线行动：基地确认、稳窗回波探点、回基地解析前线行动回报。

## 编写原则

- 文件名使用英文，正文使用中文。
- 面向玩家解释，不使用内部代号替代正式名称。
- 每个页面优先包含“用途 / 获取方式 / 相关配方 / 相关区域 / 注意事项”。
- 数据类内容未来应尽量从结构化游戏数据生成，避免 Wiki、游戏和官方工具三处手写不一致。
- 剧透内容应单独标记或延后公开。
