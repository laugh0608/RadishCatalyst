# Current Plan

更新时间：2026-11-28

## 当前阶段

**统一 Demo 与第一轮成长的核心开发已基本完成，当前处于 E 整段收口评估。** 正式基础整合（schema 9）已能从新档建线、研究、持续供燃、开路取料，再用回仓产物完成扩建。当前评审沿用 Mac 正式 Boot、独立续档和成品档审阅记录。[A–E 开发计划与原验收目标](demo-consolidation-proposal.md#整合批次与完成判据)

**R1-B 已收口，萝卜SAMA认可 `outline-06` 四面端口与四角装饰。** R1-C / D 代表品质已获萝卜SAMA认可，可作为 R2 首件规范输入。活跃主线为[整合总合同](../features/factory-demo-integration-v1.md)，B1 / B2 / C 已共同通过首程验收。

规划阅读链：[产品方向](../product/production-centered-direction.md) → [能力地图](../features/README.md) → [整合切片与原合同](../features/factory-demo-integration-v1.md#capability-slices)。地图只维护归属，不改变下面的实施顺位和冻结条件。

## 当前顺位

<a id="demo-milestone-review"></a>

**等待萝卜SAMA决定是否以现有 Godot 工程进入正式游戏的内容开发。** 评审先看哪些生产选择和探索回报值得保留为正式玩法。若决定继续，再明确下一版的玩家起点、可用工厂产出完成的新行动以及完成标准。首个正式开发里程碑及其排期留待决定。

| E 阶段评审项 | 已有结论与待验事项 |
| --- | --- |
| 正式基础整合 | B1 / B2 / C 通过联合首程和玩家亲测。扩建后的连续首程候选已在 Mac 从开局走到富集回仓、构件入仓并独立继续。萝卜SAMA已审阅成品档，从头亲测暂缓。[首程验收](../devlogs/2026-W45.md#foundation-acceptance) · [连续首程候选](../devlogs/2026-W48.md#foundation-continuous-candidate) · [成品反馈](../devlogs/2026-W48.md#foundation-candidate-owner-review) |
| 扩建经营 | 供板调整后每 10 秒入仓一包，停产定位与恢复、同网欠供降速均已复核。矿区保留核心拉电，送芯独网作为布局实验收口。[供板](../devlogs/2026-W48.md#foundation-plate-return) · [停产](../devlogs/2026-W48.md#foundation-pack-diagnosis) · [失电与停机](../devlogs/2026-W48.md#foundation-pack-power) · [降速](../devlogs/2026-W48.md#foundation-pack-brownout) · [矿区对照](../reference/factory-integrated-demo-layout-and-budget.md#mine-power-layout) |
| D1 开拓回报 | schema 10 隔离档已验证 X2 开路、高产矿持续回流和扩建，成品档审阅通过，正式入口暂不开。[持续生产](../devlogs/2026-W47.md#d1-sustained-production) · [成品档复核](../devlogs/2026-W47.md#d1-completed-world-review) |
| D2 可选测控 | 核心 III、储能、节拍与负载组保留在隔离档。长期对照的收益门槛尚未达到。schema 16 联锁短测已通过，O5 / L5 预检仍等实际调度动机与操作阻碍，随后自然长测另行确认。[长期对照](../features/factory-d2-production-comparison.md) · [联锁短测](../devlogs/2026-W47.md#d2-v5-short-checks) |
| 体验与平台 | 首次独立理解与诊断、实际首程用时、继续经营的动机仍待玩家验证。Windows / PowerShell 和目标硬件继续待验。[局部反馈](../devlogs/2026-W48.md#foundation-line-observation) · [保留项](#retained-d4) |

R2 核心和反应器已接入正式基础整合。主档继续与备份恢复已复核，周期保存的剩余停顿保留跟踪。[代表资产](../devlogs/2026-W47.md#e-r2-reactor-foundation) · [存档与恢复](../devlogs/2026-W48.md#e-autosave-latency)

11 月 1 日已完成真相源同步、四类合同首轮、S0 / S1 离线核算与[资产盘点](../reference/asset-inventory-and-transition-v1.md)。R1-A 已选 C2；R1-B 的旧候选及 96 项边缘失败保留在 [W44](../devlogs/2026-W44.md)；11 月 7 日收尾与窗口证据见 [W45](../devlogs/2026-W45.md)。B1 的 R2 场景继承原核心轮廓 GLB。并行构件布局与参数审阅继续保留，详见[预算剩余证据](../reference/factory-integrated-demo-layout-and-budget.md#remaining-evidence)。

## 本阶段设计边界

- 唯一核心、每种物品 99,999 库存上限、多口真实物流；核心等级解锁能力，基础功率固定 360 kW。[四面版 S1-P](../reference/factory-integrated-demo-layout-and-budget.md#four-sided-layout)已验证持续供燃和构件并行。
- 固定功率 / 固定燃烧时长、低负载仍耗燃料、手动停机暂停余时；普通连续供料可完成主线。独立储能、节拍和后续条件控制属于可选进阶支线。
- 核心自动出料、按前置研究、材料提交和分级升级已进入正式基础整合。液气与热管理仍在长期分支。
- 正式客户端并列提供既有世界和基础整合。旧 V8 继续按 240 kW 基础供电、按缺口消耗电芯及原终端仓规则运行；基础整合按[独立存档身份](../architecture/factory-integrated-demo-save-v1.md)新建、继续。
- 既有二维、基础 / V5 / E1 / V7 / V8 和工程世界保留原规则；未经明确转换合同不迁移、不自动插核心、不消费亲测进度。
- 多人、战斗扩展、随机地图、多星球、交易、离线收益、自动蓝图、物流桥、全量长期科技树及 1,000 台 / 10,000 带仍未纳入；不新增后端或外部依赖。
- Godot 3D / 工业科幻方向保留；主视角已选 C2 透视正向、默认 21 格跟随，滚轮调距离 / 高度，见[视觉方向](../product/visual-and-ui-direction.md)。精细模型和全部资产量产不作为本轮合同完成条件。安装依赖、打包、分发、推送与发布仍须另行授权。
- 资产按正式、共用、保留二维、实验与历史候选维护来源。基础整合复用 R1-B 四面轮廓，物流附件已按反馈更新共用模型，D2 使用独立的等级、储能与节拍模型。导出和运行引用见[来源映射](../reference/asset-source-and-export-map.md)。
- R1-A 已交付并获镜头选择；R1-B 已授权，具体范围见[轮廓实施](../features/factory-camera-and-representative-scene-v1.md#r1-b-outline)。R1-C / D 已按确认范围做独立样板。材质审阅与正式玩法实施分开。

## 已有能力与证据

E1 材料 / 构件制造、E2 电芯 / 本机启停、V8 待机 / 图标 / 统一焦点已实现并完成开发机定向验证；[生产内容扩展](../features/factory-production-expansion-v1.md)继续提供配方与既有能力依据。原 E3 的固定支路设计由统一路线的 D1 验证。

独立 V8 练习 / C / D 入口已于 11 月 1 日交付，来源与验证见 [W44](../devlogs/2026-W44.md)；可按用户反馈定向研究，短检查点不代替统一 Demo 新档验收。原 D3 工程退出与 D4-P / S 开发机结论保留，不自动覆盖新合同负载。

<a id="retained-d4"></a>

## 保留验证与退出条件

| 保留项 | 处理 |
| --- | --- |
| D4-U 首次理解、独立诊断、等待、20–40 分钟首程 | 不标通过；结合新 Demo 主线验证，时间是体验目标而非当前设计硬门禁 |
| D4-X Windows / PowerShell、目标硬件 | 暂缓 / 待验继续保留；macOS 开发机成绩不代签 |
| 保存停顿、输入 / 原生切窗、统计规模与精细美术 | 根据复现与新路径影响处理，不例行重跑历史长测 |

当前退出条件：R1-A 已选参数与证据可追溯；R1-B 已获萝卜SAMA认可，分别保留旧结构和新四面端口证据。R1-C / D 已完成代表品质审阅，开发机证据保留适用范围。正式玩法实施继续另获授权。四类玩法合同仍须可追到布局 / 配方 / 账本与失败判据，候选不自动定稿。出现丢货 / 复制 / 无法继续等当前玩家阻断仍优先处理；不将旧待验项写成通过。完整旧 D4 事实见 [D4 记录](factory-d3-exit-and-d4-validation.md)。
