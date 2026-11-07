# Feature Development Docs

更新时间：2026-11-01

## 用途与层级

本页是唯一能力专题地图：[产品方向](../product/production-centered-direction.md)与[整合基线](../planning/demo-consolidation-proposal.md)维护整体目标，六条大专题按能力组织，既有功能文件或合同承载子专题。阶段与能力分开；阶段整合包连接多条能力，不取代能力归属。

[Current Plan](../planning/current.md)维护实际顺位、冻结项与退出条件，[Daily Start](../planning/daily-start.md)提供日常路由。每个子专题有一个主要归属，其他关系为协同；实施切片保留原 ID，任务状态与验收只在下表指定来源维护。本页不复制进度，详细规则见[协作专题](../process/agent-collaboration.md#planning-hierarchy)。

## 当前阶段包

[统一 Demo 与第一轮成长](factory-demo-integration-v1.md)是跨能力整合包，主要归属为生产物流，协同其余五条主线；[切片映射](factory-demo-integration-v1.md#capability-slices)连接 B1 / B2 / C / D1 / D2 / E 与原合同。[R1 镜头与代表场景](factory-camera-and-representative-scene-v1.md)是视觉准备切片，实施状态独立维护。设计方向确认、离线核算、样板、正式玩法、自然新档路径和目标平台验收分别判断。

<a id="production"></a>

## 生产物流

玩家通过材料生产与真实物流建设基地。拥有核心库存、端口、加工与运输规则；依赖能源和世界存档，协同研究、设备交互与视觉，不把图示或工程检查点当自然生产完成。

| 子专题 / 切片 | 任务状态与验收来源 | 阶段 / 协同 |
| --- | --- | --- |
| 唯一核心与库存 | [核心合同](factory-base-core-v1.md) | 整合 B1；研究、交互、存档 |
| 材料、构件与内容扩展 | [生产扩展总纲](factory-production-expansion-v1.md)、[E1 切片](factory-production-expansion-e1.md) | 旧 E1 / 后续内容批次；研究、能源 |
| 发现与工业生产 | [发现生产](factory-discovery-and-production-v1.md) | 旧 D3 / D4；探索与研究 |
| 传送带与准入 | [分流汇合](factory-conveyor-routing-v1.md)、[物品准入](factory-item-admission-v1.md)、[组合切片](factory-conveyor-combination-v1.md) | 旧附件 / C 组合；存档与交互 |

完成条件：选定内容版本的自举、供料、回压与物料账成立，失败不丢货 / 复制；自然路径与跨进程恢复按该合同验收，历史通过不覆盖新负载。

<a id="energy"></a>

## 能源

让电力支持可理解的扩建与断供恢复。拥有发电、供需、耗能与储能 / 测控边界，依赖生产燃料与存档；不追改旧世界规则，不把可选优化变为普通通关门槛。

| 子专题 / 切片 | 任务状态与验收来源 | 阶段 / 协同 |
| --- | --- | --- |
| 固定燃烧与测控 | [固定燃烧合同](factory-fixed-burn-energy-v1.md)、[D2 测控](factory-grid-controls-d2.md) | 整合 C / D2，协同研究与存档 |
| 既有电网与范围供电 | [电网](factory-power-and-grid-v1.md)、[范围供电与拾取](factory-range-power-and-pickup-v1.md) | 旧 D3 / D4；拾取交互协同设备主线 |
| 电芯及能耗反馈 | [E2 内容切片](factory-production-expansion-e2.md)、[V8 能源与焦点反馈](factory-energy-and-focus-feedback-v1.md) | 旧 E2 / V8；设备交互 |

完成条件：指定版本的燃料、输出 / 弃能、停机、恢复与存读账守恒；新固定燃烧不能由旧按缺口耗能证据代签。

<a id="progression"></a>

## 科技成长与探索

让发现资源和研究解锁反哺生产。拥有节点、等级、前置 / 消费及开拓收益，依赖生产和能源；不扩张战斗、多星球或全量长期科技。

| 子专题 | 任务状态与验收来源 | 阶段 / 协同 |
| --- | --- | --- |
| 科技树、等级与开拓回报 | [科技树合同](factory-research-and-progression-v1.md) | B2 / D1；D2 的等级要求协同能源，首包与后续节点分别验收 |

完成条件：首包节点无自举循环，研究与升级消费原子，开拓资源具有持续用途；未实施节点和旧 E3 保持各自边界，不伪称完整成长体验已成立。

<a id="interaction"></a>

## 设备交互

让玩家能识别、选择、操作设备并理解反馈。拥有近身动作、界面投影、引导与统计呈现；所有值来自生产 / 能源 / 存档权威状态，不另设 UI 事实源。

| 子专题 | 任务状态与验收来源 | 阶段 / 协同 |
| --- | --- | --- |
| 设备选择与操作 | [设备交互](factory-device-interaction-v1.md) | 旧设备基线及后续整合；生产、视觉 |
| 首程引导 | [首次旅程](factory-first-journey-guidance-v1.md) | 旧首程 / 新路径协同；成长与探索 |
| 生产统计 | [统计专题](factory-production-statistics-v1.md) | 旧 D3 / D4；生产、能源 |

完成条件：正常、阻塞、无效选择与恢复反馈可操作且符合真实状态；自动断言不替代正式入口和用户路径证据。

<a id="world-save"></a>

## 世界与存档

让每个内容版本能独立创建、持续游玩和恢复。拥有世界身份、权威字段与文件事务，协同所有玩法；不默认转换旧档或消费用户亲测进度。

| 子专题 / 技术合同 | 任务状态与验收来源 | 阶段 / 协同 |
| --- | --- | --- |
| 工厂基础与持久化 | [基础专题](factory-foundation-and-persistence-v1.md)、[既有世界合同](../architecture/factory-world-state-and-save-v1.md) | 旧 P1–P3 与对应版本 |
| 新整合世界身份与恢复 | [整合存档合同](../architecture/factory-integrated-demo-save-v1.md) | B1 / B2 / C 联合首包，D1 / D2 单独身份；文件仍保留 architecture 目录 |

完成条件：内容身份、库存 / 研究 / 能源账、严格读档、备份和跨进程恢复有对应证据；旧二维与世界 1–8 保留，未定义转换不自动迁移。

<a id="visual-delivery"></a>

## 视觉与交付验证

让玩法以已确认的画面与可复验路径交付。拥有镜头 / 代表资产准备和跨能力验收，具体功能行为仍由其合同负责；不把样板、开发机结果或历史视觉认可扩大为新内容发布。

| 子专题 / 证据入口 | 任务状态与验收来源 | 阶段 / 协同 |
| --- | --- | --- |
| 镜头与代表场景 | [R1 方案](factory-camera-and-representative-scene-v1.md) | R1-A–D；新核心与材质和镜头分别审阅 |
| 既有样板 / 工厂体验 | [交互样板](factory-refinement-demo-v1.md)、[建造体验验证](factory-building-experience-validation-v1.md) | 旧样板，只提供其原范围依据 |
| 整段与平台验收 | [Demo 整合检查](factory-demo-integration-v1.md#检查与保留边界)、[D4 保留项](../planning/factory-d3-exit-and-d4-validation.md) | 新 E 与旧 D4 分别留证，不合并状态 |

完成条件：同一候选的正式 Boot、自然新档、窗口 / 原生操作、玩家反馈和平台结果有证据；D4-U / X 待验继续可见，发布另行授权。

## 历史与维护

原索引中的状态、旧切片与像素路线摘要保留于[整理前快照](../archive/feature-index-before-capability-map-2026-11-01.md)，旧 Demo Definition V1 仍见[原归档](../archive/features-demo-v1/README.md)。旧二维、Web / Godot 产线试验与当前整合世界各有独立历史边界；不修改原验收结论，不从旧“当前 / 最新”恢复任务。

新增子专题先写玩家价值、范围 / 非目标、输入输出、依赖、正常 / 失败 / 恢复路径、状态 / 存档 / HUD、实施切片和验收。细项状态与证据在所属合同维护；持续能力以已交付基线和剩余范围表达，不按文档或勾选数量计算完成率。
