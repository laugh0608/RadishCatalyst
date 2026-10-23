# Current Plan

更新时间：2026-10-23

## 当前阶段

**Demo 生产内容扩展与快速玩法验证。** 萝卜SAMA已明确要求扩大物品、设备和合成链，以更丰富的生产关系验证玩法；本轮先完成关系方案，再分批实现可玩的完整链条。当前活跃专题为[生产内容扩展 V1](../features/factory-production-expansion-v1.md)，其中 E1 已实现并通过定向工程验证，短试玩反馈继续保留；[E2 合同](../features/factory-production-expansion-e2.md)及布局 / 能量核算已形成，已按确认合同实现并完成开发机定向验证，短试玩继续收集，E3 仍属提案。

原发现 / 电力 / 统计联合包 D3 工程退出已获批准，D4-P / S 开发机工程验证已完成；旧 D4-U / X 与其他保留项继续登记，**不作为内容扩展设计或开发的前置门槛**。Windows 验证继续暂缓，不将暂缓或本轮优先级变化记为验收通过。

产品方向仍以 [Production-Centered Direction](../product/production-centered-direction.md) 为准：化工生产经营为核心，探索提供资源与目的，生产成果反哺开拓。旧二维切片与历史证据保留，旧试玩整改 S0 暂缓。

## 当前主线与下一步

1. **关系方案**：[生产内容扩展 V1](../features/factory-production-expansion-v1.md)提出 15 种物品、14 个加工配方、3 类新增加工设备与电芯发电机；成品分别用于制造构件、供电和开拓高产矿点。[六款游戏对照](../reference/factory-game-production-study.md)已补官方资料与 Wiki，修正副产物出口、一次性需求和高产矿价值的推断；具体供给 / 消费仍待试玩。
2. **E1 材料与扩建**：[实施合同](../features/factory-production-expansion-e1.md)与[两份布局 / 成本吞吐比较](../reference/factory-production-expansion-e1-layout.md)10 月 22 日已按确认合同实现，直接路线自然制造并放下第二炉，独立恢复后混料回用再产两包；三设备、165 起步构件、326 总拥有量和独立 schema 6 已落地。当前短试玩反馈已定位完成配额导致的停线，并按确认整改电力常显、默认连线开关、仅键盘移动与配额说明；接续混料半批复测，操作代价与节材感受仍待反馈。具体接续见 [Daily Start](daily-start.md#next-day-tasks)。
3. **E2 能源循环**：[实施合同](../features/factory-production-expansion-e2.md)、[C/P/D 布局](../reference/factory-production-expansion-e2-layout.md)与[能量收支](../reference/factory-production-expansion-e2-energy-balance.md)已按整组确认实现。保留 240 kW，同源自然四包对照从 55.05 秒降到 41.10 秒；双机耗尽、自救、半批 / 余能独立恢复及窗口检查通过。本机启停与 V7 显式复制已落地，下一步短试玩验证逐步扩建收益与操作成本。
4. **E3 开拓回报**：生产开拓用品、打开固定支路，把更高产的原料接回既有工厂。

每批按“完整可玩用途 → 短试玩 → 调整”推进；不先堆大量无用途的物品，也不把旧包逐项精细验收排在内容开发之前。物料、存读和关键操作仍做与变更风险匹配的检查；具体范围见专题，不例行重跑历史完整自然流程或四档长测。

## 已有基础与接续专题

- [分流 / 汇合](../features/factory-conveyor-routing-v1.md)、[准入口](../features/factory-item-admission-v1.md)、[C 组合](../features/factory-conveyor-combination-v1.md)：三类附件、共同物流、定量放行、双原料与两次开路的工程证据已具备。附件原位替换及取消带货两格限制已完成，萝卜SAMA随后亲测反馈无明显问题；只关闭本次整改，不扩大为旧 D4 全部通过。
- [设备交互](../features/factory-device-interaction-v1.md)、[首程引导](../features/factory-first-journey-guidance-v1.md)：手动拾样、近身 F / Tab、I 背包、物品格 / 模型面板和目标提示已有实现；作为新内容复用基础，后续按真实反馈整改。
- [发现生产](../features/factory-discovery-and-production-v1.md)、[电力](../features/factory-power-and-grid-v1.md)、[范围供电](../features/factory-range-power-and-pickup-v1.md)、[统计](../features/factory-production-statistics-v1.md)：现有四配方、样本 / 两次开路、实际同网供能、物料 / 电量事件和趋势继续承担基础能力。
- [V5 存档](../architecture/factory-admission-save-v5.md)与[工厂状态](../architecture/factory-world-state-and-save-v1.md)：当前新勘探世界仍为 V5，旧 2 / 3 / 4 原规则继续及显式升级保持，基础 schema 1 和旧二维 schema 10 独立；E1 是第三个显式入口及独立 schema 6，不迁移旧档。
- [工程规模](../architecture/factory-engineering-scale-v1.md)：独立 1,280 实体工程身份、S0 与 S1 已完成 Apple M5 验证；普通世界与工程供给不混用，现成绩不自动覆盖未来新设备负载。

## 本轮边界

- 10 月 22 日设计交付后，萝卜SAMA已明确批准按 E1 合同实施与验证，包含 165 起步构件、326 总拥有量和独立 schema 6；先提交设计文档，再完成直接扩建与混料回用。不需要先补完旧 D4。
- 设计范围包括新固体原料 / 中间品 / 成品、专用加工设备、构件制造、消耗电芯供电和固定开拓回报；这些从原“新增设备 / 经济另包”进入当前设计讨论范围，其中 E1 / E2 已实现，开拓仍待后续细化。
- 10 月 23 日先提交 E2 设计基线 `0188bdbf`，随后萝卜SAMA要求继续推进，已确认包含 V7 显式复制和设备就地启停的整组合同；现已完成实现与开发机定向工程验证；短试玩、Windows / 目标硬件与原 D4 不代签。
- 现行默认新世界、供给、存档与 6 / 12 格供电规则保持。E1 已新增内容世界入口与 schema 6，只保存当批内容；旧世界不静默换配方、矿点或供给。165 起步构件、326 总拥有量及制造来源详见已确认合同。
- 沿现有 Godot 3D、导入 GLB、既有风格和自有图标，资产随内容批次做够用版本。精细美术不作为本轮前置，不以程序几何代替正式设备画面。
- 液气管网、种植 / 交易、通用科技树、仓库自动出料、物流桥、自动蓝图、战斗扩展、多人、随机地图、多星球、离线收益及 1,000 台 / 10,000 带仍在本包外；不因参考资料包含就自动纳入。
- 不自动安装依赖、下载资产包、打包、发布或推送。外部参考只作设计研究，不迁入整仓代码或游戏资产。

<a id="retained-d4"></a>

## 原 D4 保留项

完整裁决、矩阵和证据见[D3 退出与 D4 记录](factory-d3-exit-and-d4-validation.md)，历史过程见 [W40](../devlogs/2026-W40.md)、[W41](../devlogs/2026-W41.md)、[W42](../devlogs/2026-W42.md)。

| 保留项 | 当前处理 |
| --- | --- |
| D4-U 首次理解、空世界首程、独立诊断、等待与 20–40 分钟目标 | 不标通过；结合后续内容试玩收集，不要求在 E1 开工前另走细分清单 |
| D4-X Windows / PowerShell、目标硬件 | Windows 暂缓；目标配置待登记；不拿 Apple M5 成绩代签 |
| 输入与局部交互 | 首屏偶发命中、独立样板点击、仓库布局 / 原生切窗；按复现与实际影响处理 |
| 保存与性能体验 | 约 0.3 秒保存停顿、历史 Metal 慢绘制归因、统计叠层规模性能；不例行重启长测 |
| 视觉与测试入口 | 统计页图标 / 精细美术、亲测入口强制暂停 / 朝向反馈；按内容迭代安排，不宣称已解决 |

出现丢货、复制、不能保存继续或当前玩家路径被阻断时，优先修对应问题；这与保留旧 D4 为非前置并不冲突。阶段主线与日常动作见 [Daily Start](daily-start.md)。
