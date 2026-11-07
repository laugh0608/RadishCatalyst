# Current Plan

更新时间：2026-11-07

## 当前阶段

**统一 Demo 与第一轮成长：隔离实现核心、研究与能源。** 萝卜SAMA已确认[整合基线](demo-consolidation-proposal.md)：化工生产经营为主、角色现场探索反哺生产，沿 Godot 4.x / GDScript / 风格化工业科幻 3D，形成同一新档可连续游玩的核心、材料、能源、研究与开拓路线。

**R1-B 已收口，萝卜SAMA认可 `outline-06` 四面端口与四角装饰。** R1-C / D 代表品质已获萝卜SAMA认可，可作为 R2 首件规范输入。活跃主线仍为[整合总合同](../features/factory-demo-integration-v1.md)，B1 核心 I 与 B2 研究、核心 II 已接入隔离 Boot。C 固定燃烧与正式存读接续实施。

规划阅读链：[产品方向](../product/production-centered-direction.md) → [能力地图](../features/README.md) → [整合切片与原合同](../features/factory-demo-integration-v1.md#capability-slices)。地图只维护归属，不改变下面的实施顺位和冻结条件。

## 当前顺位

1. [R2 首件资产规范](../design/factory-representative-asset-brief-v1.md#r2-first-asset-baseline)已落档。[B1 首包](../features/factory-base-core-v1.md#b1-first-delivery)已实现核心 I、16 口、库存与接口，隔离复核首件板材自动回仓；正式菜单尚未开放。[B2](../features/factory-research-and-progression-v1.md#b2-delivery)已验证七节点、核心 II 与自然产出的首颗电芯。下一包 C 接入[固定燃烧](../features/factory-fixed-burn-energy-v1.md)和[整合存读](../architecture/factory-integrated-demo-save-v1.md)，通过联合验证后开放正式新建。
2. [核心](../features/factory-base-core-v1.md)、[科技](../features/factory-research-and-progression-v1.md)、[能源](../features/factory-fixed-burn-energy-v1.md)、[存档](../architecture/factory-integrated-demo-save-v1.md)首轮合同与真相源同步已完成。[四面版 S0 / S1-P](../reference/factory-integrated-demo-layout-and-budget.md#four-sided-layout) 已完成离线布线复算，B1 已验证 S0 的采铁直炼子路线；并行供给、玩家操作量和扩建收益待复核。后续按研究与成长 → 普通能源 / 扩建 → 开拓 → 可选测控 → 整段收口接续。

11 月 1 日已完成真相源同步、四类合同首轮、S0 / S1 离线核算与[资产盘点](../reference/asset-inventory-and-transition-v1.md)。R1-A 已选 C2；R1-B 的旧候选及 96 项边缘失败保留在 [W44](../devlogs/2026-W44.md)；11 月 7 日收尾与窗口证据见 [W45](../devlogs/2026-W45.md)。B1 复用现有核心轮廓 GLB，不改旧世界的规则与资产。并行构件布局与参数审阅继续保留，详见[预算剩余证据](../reference/factory-integrated-demo-layout-and-budget.md#remaining-evidence)。

## 本阶段设计边界

- 唯一核心、每种物品 99,999 库存上限、多口真实物流；核心等级解锁能力，基础功率不随等级增长。起步电力由完整电池链与部分其他生产预算推导，B1 隔离入口使用候选 360 kW，完整电芯链和并行生产仍待实测。
- 固定功率 / 固定燃烧时长、低负载仍耗燃料、手动停机暂停余时；普通连续供料可完成主线。独立储能 / 节拍 / 条件控制作为后续进阶支线，PWM 不作首次通关要求。
- 核心自动出料、研究前置与材料提交、分级能力进入当前合同设计；液气 / 热管理等只留长期分支，不在本批实现。
- 正式客户端现在仍为 V8 等既有世界规则：240 kW 基础供电、按缺口消耗电芯和原终端仓。新合同不追改旧档，独立新世界与版本身份按存档合同办理。
- 既有二维、基础 / V5 / E1 / V7 / V8 和工程世界保留原规则；未经明确转换合同不迁移、不自动插核心、不消费亲测进度。
- 多人、战斗扩展、随机地图、多星球、交易、离线收益、自动蓝图、物流桥、全量长期科技树及 1,000 台 / 10,000 带仍未纳入；不新增后端或外部依赖。
- Godot 3D / 工业科幻方向保留；主视角已选 C2 透视正向、默认 21 格跟随，滚轮调距离 / 高度，见[视觉方向](../product/visual-and-ui-direction.md)。精细模型和全部资产量产不作为本轮合同完成条件。安装依赖、打包、分发、推送与发布仍须另行授权。
- 资产已按正式 / 共用 / 保留二维 / 实验 / 历史候选建立引用与[来源映射](../reference/asset-source-and-export-map.md)；既有资产不搬迁、删除、重导出或重导入。R1-B 仅新增自有原型核心、制作源 / 来源清单及导入配置；旧路线的待退役候选不等于已批准删除。
- R1-A 已交付并获镜头选择；R1-B 已授权，具体范围见[轮廓实施](../features/factory-camera-and-representative-scene-v1.md#r1-b-outline)。R1-C / D 已按确认范围做独立样板。材质审阅与正式玩法实施分开。

## 已有能力与证据

E1 材料 / 构件制造、E2 电芯 / 本机启停、V8 待机 / 图标 / 统一焦点已实现并完成开发机定向验证；[生产内容扩展](../features/factory-production-expansion-v1.md)继续提供配方与既有能力依据。原 E3 固定支路未实施，其高产炭矿持续价值须在统一路线中证明。

独立 V8 练习 / C / D 入口已于 11 月 1 日交付，来源与验证见 [W44](../devlogs/2026-W44.md)；可按用户反馈定向研究，短检查点不代替统一 Demo 新档验收。原 D3 工程退出与 D4-P / S 开发机结论保留，不自动覆盖新合同负载。

<a id="retained-d4"></a>

## 保留验证与退出条件

| 保留项 | 处理 |
| --- | --- |
| D4-U 首次理解、独立诊断、等待、20–40 分钟首程 | 不标通过；结合新 Demo 主线验证，时间是体验目标而非当前设计硬门禁 |
| D4-X Windows / PowerShell、目标硬件 | 暂缓 / 待验继续保留；macOS 开发机成绩不代签 |
| 保存停顿、输入 / 原生切窗、统计规模与精细美术 | 根据复现与新路径影响处理，不例行重跑历史长测 |

当前退出条件：R1-A 已选参数与证据可追溯；R1-B 已获萝卜SAMA认可，分别保留旧结构和新四面端口证据。R1-C / D 已完成代表品质审阅，开发机证据保留适用范围。正式玩法实施继续另获授权。四类玩法合同仍须可追到布局 / 配方 / 账本与失败判据，候选不自动定稿。出现丢货 / 复制 / 无法继续等当前玩家阻断仍优先处理；不将旧待验项写成通过。完整旧 D4 事实见 [D4 记录](factory-d3-exit-and-d4-validation.md)。
