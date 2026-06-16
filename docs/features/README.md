# Feature Development Docs

更新时间：2026-06-16

## 用途

本目录存放玩家可感知功能目标的设计与开发文档。阶段入口只决定当前主线，具体范围、边界、玩家路径、验收和检查放在这里。

当一次开发会同时影响玩法、场景、HUD、任务、存档、运行时状态或自动检查时，应优先建立或更新对应专题文档，再开始实现。

## 使用规则

- `docs/planning/current.md` 只保留当前阶段、当前活跃专题、阶段边界和退出条件。
- `docs/planning/daily-start.md` 只保留日常推进入口和读取顺序。
- `docs/devlogs/` 只记录已经发生的推进、决策、验证和风险，不作为具体功能范围的真相源。
- 专题文档必须说明玩家价值、整体规划关系、已有基础、本轮范围、当前不做、真实操作路径、状态 / 存档 / HUD / 检查要求和验收条件。
- 不为单个文案调整、局部修错或一次性讨论创建专题文档；专题应对应一个玩家可感知功能目标或阶段开发包。
- 活跃专题接近 220 行时，优先拆成总览与子专题，或把历史过程移入周志 / 参考 / 归档。

## 专题层级

- 阶段级专题用于说明能力域方向、冻结边界和跨包验收，例如角色成长与战斗第一版。
- 可执行细专题用于定义一个基建设备、装备 / 模块、功能玩法、场景压力或工程边界包，是每日代码开发的直接范围来源。
- 当前或最近执行细专题应由阶段入口或阶段级专题显式链接；完成后再切换到下一个细专题。

## 当前活跃专题

- [Demo Definition V1](demo-definition-v1.md)：首版 Demo 完成规格表，后续专题必须映射到其中的未完成规格项。
- [Demo Resource Chain State V1](demo-resource-chain-state-v1.md)：当前执行细专题，2026-06-16 第一包已落地，覆盖核心资源 / 产物的链路状态、HUD / 设备 / 加工反馈和状态序列化检查。
- [Demo Non-Core Scene Identity V1](demo-non-core-scene-identity-v1.md)：最近完成细专题，2026-06-16 第一包已落地，覆盖 4 个功能区和 4 个过渡区的场景身份、视觉标识、HUD / 对象反馈和专项检查。
- [Demo Functional Transition Route Support V1](demo-functional-transition-route-support-v1.md)：最近完成细专题，已覆盖 4 个功能区和 4 个过渡区的路线支撑、当前危险、回基地理由和专项检查。
- [Demo Combat Progression V1](demo-combat-progression-v1.md)：最近完成阶段级专题，已完成首版 Demo 角色成长与战斗第一版。
- [Demo Tool Strike Calibration V1](demo-tool-strike-calibration-v1.md)：最近完成细专题，已把基础多用工具、基础零件和出发整备台收束成一次可读战斗输出整备。
- [Demo Protective Response V1](demo-protective-response-v1.md)：最近完成细专题，已把基础防护服、基础过滤模块和前哨补给收束成一次可读防护响应。
- [Demo Scene Art Foundation V1](demo-scene-art-foundation-v1.md)：最近完成细专题，已建立核心区场景与初步美术识别第一包。
- [Demo Mainline Completion V1](demo-mainline-completion-v1.md)：最近完成细专题，已收束核心稳定站写入后的 Demo 主线完成读法。
- [Demo Industrial Tech Spine V1](demo-industrial-tech-spine-v1.md)：最近完成细专题，已收束基础反应器、污染过滤器和出发整备台之间的轻量工艺主干读法。
- [Demo Character Kit V1](demo-character-kit-v1.md)：最近完成细专题，已验证 `C` 战术扫描主动工具动作。
- [Ruin Outer Ring Module Pressure V1](ruin-outer-ring-module-pressure-v1.md)：最近完成细专题，已验证模块状态在遗迹外圈形成承压差异。
- [Pollution Edge Maintenance Pressure V1](pollution-edge-maintenance-pressure-v1.md)：最近完成细专题，已验证后勤维护在污染边界形成第二个承压差异。

## 专题文档推荐结构

1. 用途
2. 玩家价值
3. 与整体规划的关系
4. 当前已有基础
5. 本轮范围
6. 当前不做
7. 玩家操作路径
8. 运行时、存档与数据边界
9. HUD / 场景 / 对象反馈
10. 验收条件
11. 验证计划
12. 风险与后续决策
