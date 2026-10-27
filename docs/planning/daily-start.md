# Daily Start

更新时间：2026-10-27

## 启动读取

先检查 `dev` 工作区并遵循 `AGENTS.md`，再读 [Current Plan](current.md)、[生产内容扩展 V1](../features/factory-production-expansion-v1.md)、[E2 实施合同](../features/factory-production-expansion-e2.md)、[能源与焦点反馈](../features/factory-energy-and-focus-feedback-v1.md)和[本周周志](../devlogs/2026-W44.md)。布局 / 算式读 [E2 坐标](../reference/factory-production-expansion-e2-layout.md)与[能量收支](../reference/factory-production-expansion-e2-energy-balance.md)；E1 反馈再读其[合同](../features/factory-production-expansion-e1.md)；研究参考按需读[六款生产游戏对照](../reference/factory-game-production-study.md)，原验收 / 历史证据再展开[D4 记录](factory-d3-exit-and-d4-validation.md)。

## 当前交接

- 萝卜SAMA明确将当前重点切到 Demo 内容扩展：增加物品、设备和合成链，以完整生产用途验证玩法。先做方案，随后分批交付可玩的内容。
- 10 月 22 日已先提交 E1 设计基线，再按整组确认实现：13 物品、11 配方、三设备、165 起步构件、326 总拥有量及独立 schema 6。直接路线自然放下第二炉，独立恢复后回用再产两包；状态、失败、正式 Boot 与窗口检查已通过，进入短试玩。
- 修订提案仍为 15 种物品 / 14 配方、3 类新加工设备与电芯发电机；跨游戏研究补充工艺取舍、回用需求变化与成品消费形态。高产矿长期价值尚未证明，不能用四件胶囊的一次性需求代替持续压力；E2 已从 V7 扩展为新建 V8 / 待机耗电，旧档原规则继续；新版定向验证通过，E3 仍待细化。
- 附件原位替换和取消带货两格限制已通过定向工程验证，萝卜SAMA亲测反馈无明显问题，本次整改收口。三类附件、原四配方、两次开路及统计 / 存读基础供新包复用。
- 原 D3 工程退出已批准，D4-P / S 开发机验证已完成；D4-U / X 和原保留项继续登记，**不作为内容扩展设计 / 开发的前置门槛**。Windows 暂缓，目标硬件待验。

<a id="next-day-tasks"></a>

## 当前接续事项

1. **先准备独立 V8 亲测入口，再验证反馈整改**：[能源与焦点反馈](../features/factory-energy-and-focus-feedback-v1.md)已实现并通过开发机验证。下次从已成功的 C 自举检查点及同源 D 起点准备新副本，明确显示版本、开始按钮与角色跟随；原 `tools/runtime-intake/review-worlds/factory-production-expansion-e2/` 启动器仍载入 V7，不能直接拿它验证待机。新 V8 亲测入口尚未交付，准备时保留来源 / 哈希、原副本与用户进度；不自动重启或转换活动世界。正式菜单也可新建 V8，或从旧 V7 显式“复制为待机耗电新版”。
2. **先熟悉交互，再观察 E2 收益**：先用练习副本熟悉角色移动、准入口图标、鼠标 / Tab / F 同一目标（查看布局时可暂停，移动需恢复运行），再用未消耗配额的独立 D 起点观察运行 / 待机 / 停机、G 开关与构件入仓，避免学操作期间有限目标已经耗完。从 C 看懂基础满足时有料不烧；D 全待机 56 kW 时 G 为 0 也是正常结果。V8 四包 56.40 / 41.65 秒只证明该检查点补电收益；旧 V7 自动工程 C→D 约 16.4 分钟不代签新版或“5–10 分钟感知收益”。结合 E1 再评估首次扩建成本；若施工 / 等待压过收益，先讨论紧凑布局或缩小首个目标，保留 240 kW，不直接扩张内容。证据见 [W44](../devlogs/2026-W44.md)。
3. **顺带收集 E1 反馈**：[合同与亲测入口](../features/factory-production-expansion-e1.md#playtest)。优先已有混料半批副本，观察余料到两包、配额停收提示及换料是否值得；也可从正式菜单新建 E1。已有工程证据不代签节材感受和继续扩建意愿，不为收集反馈重新跑整套自然流程。
4. **后续能源 / 开拓**：E2 已证明扩建真实缺电、电芯改善产出，短试玩后再细化 E3 合同：四件胶囊、接回高产炭矿，观察开路后持续负载是否受益。3 / 12 件每分钟尚未冻结；若没有实际收益，调整回报和节拍，不靠新增无用途物品制造需求。
5. **快速试玩驱动调整**：重点看是否愿意建线、分配材料、修瓶颈和继续扩建；观察副产物停线是否可理解、是否变成反复手工清理。最终处理设施与多场景开拓工具留作反馈后的候选，不要求先完成旧体验细分清单。
6. **按风险保留必要验证**：新配方 / 制造账、回压 / 满包、独立存读和关键正式 Boot 操作；美术做能辨认和使用的程度。只有变化影响旧证据时补相应回归，不例行重跑历史长测，不把自动通过写成玩法成立。

10 月 22 日 E1 实现及反馈整改已本地提交。10 月 23 日 E2 已完成实现与开发机定向验证；10 月 27 日本地提交 `99efeba9` 确认方案与试玩记录、`240a968e` 交付待机耗电 / V8 / 图标与焦点，详见专题 / W43 / W44。E3 实现、推送、发布与外部依赖仍不包含；无需另行完成原 D4 才能开始。

## 保留待办与边界

- 首次理解、独立诊断、20–40 分钟首程目标；Windows / PowerShell 与目标硬件；约 0.3 秒保存停顿、输入风险、仓库 / 原生切窗、统计图标 / 精细美术及其他测试入口体验继续保留；本次 E2 的角色辨认 / 移动阻断已解除，详见 [Current Plan](current.md#retained-d4)和 [D4 记录](factory-d3-exit-and-d4-validation.md)。
- 默认基础与原 V5 入口保持，E1 / 新 E2 分别使用独立身份 / schema 6、8，旧 E2 / schema 7 原规则继续，E1 / V7→V8 仅显式复制；不静默改旧档、不消费用户亲测档，普通供给与工程夹具分开。
- 固体内容包之外的液气、种植、交易、通用科技树、战斗、多人、随机地图、物流桥 / 自动出仓和自动蓝图仍未纳入。打包、分发和发布不随主线切换自动授权。
- Godot 开窗前告知；用户关闭后不自动重开。功能检查优先无窗口，必要的关键操作与截图单独补证；遵循[运行时指南](../reference/godot-runtime-verification-guide.md)。
- 文档修改执行 `./scripts/check-docs.sh`、`./scripts/check-repo.sh` 和 `git diff --check`；客户端实现再执行 `sh ./scripts/check-client.sh` 及按风险选定的运行时检查。

## 按任务继续阅读

- 加工与物料：[发现生产](../features/factory-discovery-and-production-v1.md)、[统计](../features/factory-production-statistics-v1.md)。
- 物流与接口：[分流 / 汇合](../features/factory-conveyor-routing-v1.md)、[准入口](../features/factory-item-admission-v1.md)、[C 组合](../features/factory-conveyor-combination-v1.md)。
- 交互与存档：[设备交互](../features/factory-device-interaction-v1.md)、[V5 存档](../architecture/factory-admission-save-v5.md)。
- 性能或规模：[工程合同](../architecture/factory-engineering-scale-v1.md)与对应批次记录；旧性能不自动覆盖新设备负载。
