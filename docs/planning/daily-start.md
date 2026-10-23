# Daily Start

更新时间：2026-10-23

## 启动读取

先检查 `dev` 工作区并遵循 `AGENTS.md`，再读 [Current Plan](current.md)、[生产内容扩展 V1](../features/factory-production-expansion-v1.md)、[E2 待确认合同](../features/factory-production-expansion-e2.md)和[本周周志](../devlogs/2026-W43.md)。布局 / 算式读 [E2 坐标](../reference/factory-production-expansion-e2-layout.md)与[能量收支](../reference/factory-production-expansion-e2-energy-balance.md)；E1 反馈再读其[合同](../features/factory-production-expansion-e1.md)；研究参考按需读[六款生产游戏对照](../reference/factory-game-production-study.md)，原验收 / 历史证据再展开[D4 记录](factory-d3-exit-and-d4-validation.md)。

## 当前交接

- 萝卜SAMA明确将当前重点切到 Demo 内容扩展：增加物品、设备和合成链，以完整生产用途验证玩法。先做方案，随后分批交付可玩的内容。
- 10 月 22 日已先提交 E1 设计基线，再按整组确认实现：13 物品、11 配方、三设备、165 起步构件、326 总拥有量及独立 schema 6。直接路线自然放下第二炉，独立恢复后回用再产两包；状态、失败、正式 Boot 与窗口检查已通过，进入短试玩。
- 修订提案仍为 15 种物品 / 14 配方、3 类新加工设备与电芯发电机；跨游戏研究补充工艺取舍、回用需求变化与成品消费形态。高产矿长期价值尚未证明，不能用四件胶囊的一次性需求代替持续压力；E2 数值 / V7 已形成待确认合同，E3 仍待细化。
- 附件原位替换和取消带货两格限制已通过定向工程验证，萝卜SAMA亲测反馈无明显问题，本次整改收口。三类附件、原四配方、两次开路及统计 / 存读基础供新包复用。
- 原 D3 工程退出已批准，D4-P / S 开发机验证已完成；D4-U / X 和原保留项继续登记，**不作为内容扩展设计 / 开发的前置门槛**。Windows 暂缓，目标硬件待验。

<a id="next-day-tasks"></a>

## 当前接续事项

1. **确认 E2 后再实施**：[合同](../features/factory-production-expansion-e2.md)含 C 紧凑启动、P 自动备建、D 实际负载及 D+ 第二机。重点确认保留 240 kW、120 kW / 7,200 kJ 发电、30 包完整扩建规模、本机启停与 V7 显式复制。当前只有纸面几何 / 算式证据，没有 E2 实机或吞吐成绩。
2. **亲测已交付 E1**：[合同与亲测入口](../features/factory-production-expansion-e1.md#playtest)。优先使用本次整改的新混料半批副本，观察余料生产到两包及配额空闲提示；原第二炉 / 半批 / 完成态副本仍保留。也可从正式菜单新建 E1。重点观察制造用途、同口双料、副口停线和下一次扩建选择。
3. **按反馈收口 E1**：A 消耗 8 铁矿 / 6 晶体；B 消耗 4 铁矿 / 1 炭矿 / 1 晶体。工程自动路线已证明可行，实际换料是否值得、等待是否合适和是否愿意继续仍待玩家反馈，不把自动时长当首程承诺。
4. **后续能源 / 开拓**：先证明扩建有真实缺电、电芯能支撑新增负载；再做四件胶囊、接回高产炭矿，观察开路后持续负载是否受益。3 / 12 件每分钟尚未冻结；若没有实际收益，调整回报和节拍，不靠新增无用途物品制造需求。
5. **快速试玩驱动调整**：重点看是否愿意建线、分配材料、修瓶颈和继续扩建；观察副产物停线是否可理解、是否变成反复手工清理。最终处理设施与多场景开拓工具留作反馈后的候选，不要求先完成旧体验细分清单。
6. **按风险保留必要验证**：新配方 / 制造账、回压 / 满包、独立存读和关键正式 Boot 操作；美术做能辨认和使用的程度。只有变化影响旧证据时补相应回归，不例行重跑历史长测，不把自动通过写成玩法成立。

10 月 22 日 E1 实现及反馈整改已本地提交。10 月 23 日仅授权 E2 设计、离线核算和本地提交；待整组确认后写代码。E3 实现、推送、发布与外部依赖仍不包含；无需另行完成原 D4 才能开始。

## 保留待办与边界

- 首次理解、独立诊断、20–40 分钟首程目标；Windows / PowerShell 与目标硬件；约 0.3 秒保存停顿、输入风险、仓库 / 原生切窗、统计图标 / 精细美术及测试入口暂停 / 朝向反馈均保留，详见 [Current Plan](current.md#retained-d4)和 [D4 记录](factory-d3-exit-and-d4-validation.md)。
- 默认基础与原 V5 入口保持，E1 已使用独立世界身份 / schema 6；不静默改旧档、不消费用户亲测档，普通供给与工程夹具分开。
- 固体内容包之外的液气、种植、交易、通用科技树、战斗、多人、随机地图、物流桥 / 自动出仓和自动蓝图仍未纳入。打包、分发和发布不随主线切换自动授权。
- Godot 开窗前告知；用户关闭后不自动重开。功能检查优先无窗口，必要的关键操作与截图单独补证；遵循[运行时指南](../reference/godot-runtime-verification-guide.md)。
- 文档修改执行 `./scripts/check-docs.sh`、`./scripts/check-repo.sh` 和 `git diff --check`；客户端实现再执行 `sh ./scripts/check-client.sh` 及按风险选定的运行时检查。

## 按任务继续阅读

- 加工与物料：[发现生产](../features/factory-discovery-and-production-v1.md)、[统计](../features/factory-production-statistics-v1.md)。
- 物流与接口：[分流 / 汇合](../features/factory-conveyor-routing-v1.md)、[准入口](../features/factory-item-admission-v1.md)、[C 组合](../features/factory-conveyor-combination-v1.md)。
- 交互与存档：[设备交互](../features/factory-device-interaction-v1.md)、[V5 存档](../architecture/factory-admission-save-v5.md)。
- 性能或规模：[工程合同](../architecture/factory-engineering-scale-v1.md)与对应批次记录；旧性能不自动覆盖新设备负载。
