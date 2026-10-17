# Daily Start

更新时间：2026-10-17

## 启动读取

先检查 `dev` 工作区并遵循 `AGENTS.md`，再读 [Current Plan](current.md)、[生产内容扩展 V1](../features/factory-production-expansion-v1.md)和[本周周志](../devlogs/2026-W42.md)。研究参考时读[六款生产游戏对照](../reference/factory-game-production-study.md)及其中的来源链接；只有任务涉及原验收或历史证据时再展开[D4 记录](factory-d3-exit-and-d4-validation.md)。

## 当前交接

- 萝卜SAMA明确将当前重点切到 Demo 内容扩展：增加物品、设备和合成链，以完整生产用途验证玩法。先做方案，随后分批交付可玩的内容。
- 修订提案仍为 15 种物品 / 14 配方、3 类新加工设备与电芯发电机；跨游戏研究补充工艺取舍、回用需求变化与成品消费形态。高产矿长期价值尚未证明，不能用四件胶囊的一次性需求代替持续压力；数值 / 存档方案未实现。
- 附件原位替换和取消带货两格限制已通过定向工程验证，萝卜SAMA亲测反馈无明显问题，本次整改收口。三类附件、原四配方、两次开路及统计 / 存读基础供新包复用。
- 原 D3 工程退出已批准，D4-P / S 开发机验证已完成；D4-U / X 和原保留项继续登记，**不作为内容扩展设计 / 开发的前置门槛**。Windows 暂缓，目标硬件待验。

<a id="next-day-tasks"></a>

## 当前接续事项

1. **确认内容方案并进入 E1**：核对物品用途、三加工设备分工、直接 / 高效工艺及构件制造成本；第一批必须能从零物料做出构件包并实际扩建，不能只交付物品注册表。
2. **随后接 E2 / E3**：电芯有实际供电消费，开拓用品有真实可进入的资源回报。地图坐标、端口、制造来源与新存档字段随对应实现批次明确。
3. **快速试玩驱动调整**：重点看是否愿意建线、分配材料、修瓶颈和继续扩建；不要求先完成旧体验细分清单，不把自动通过写成玩法成立。
4. **按风险保留必要验证**：新配方 / 制造账、回压 / 满包、独立存读和关键正式 Boot 操作；美术做能辨认和使用的程度。只有变化影响旧证据时补相应回归，不例行重跑历史长测。

本轮已授权规划与设计文档，不自动实现提案中的新经济 / 电力 / 存档机制。后续代码按确认后的内容批次推进；无需另行完成原 D4 才能开始。

## 保留待办与边界

- 首次理解、独立诊断、20–40 分钟首程目标；Windows / PowerShell 与目标硬件；约 0.3 秒保存停顿、输入风险、仓库 / 原生切窗、统计图标 / 精细美术及测试入口暂停 / 朝向反馈均保留，详见 [Current Plan](current.md#retained-d4)和 [D4 记录](factory-d3-exit-and-d4-validation.md)。
- 现有新世界仍为 V5。新内容建议独立世界身份 / 新版本；不静默改旧档、不消费用户亲测档，普通供给与工程夹具分开。
- 固体内容包之外的液气、种植、交易、通用科技树、战斗、多人、随机地图、物流桥 / 自动出仓和自动蓝图仍未纳入。打包、分发和发布不随主线切换自动授权。
- Godot 开窗前告知；用户关闭后不自动重开。功能检查优先无窗口，必要的关键操作与截图单独补证；遵循[运行时指南](../reference/godot-runtime-verification-guide.md)。
- 文档修改执行 `./scripts/check-docs.sh`、`./scripts/check-repo.sh` 和 `git diff --check`；客户端实现再执行 `sh ./scripts/check-client.sh` 及按风险选定的运行时检查。

## 按任务继续阅读

- 加工与物料：[发现生产](../features/factory-discovery-and-production-v1.md)、[统计](../features/factory-production-statistics-v1.md)。
- 物流与接口：[分流 / 汇合](../features/factory-conveyor-routing-v1.md)、[准入口](../features/factory-item-admission-v1.md)、[C 组合](../features/factory-conveyor-combination-v1.md)。
- 交互与存档：[设备交互](../features/factory-device-interaction-v1.md)、[V5 存档](../architecture/factory-admission-save-v5.md)。
- 性能或规模：[工程合同](../architecture/factory-engineering-scale-v1.md)与对应批次记录；旧性能不自动覆盖新设备负载。
