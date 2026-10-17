# Endfield Production Planning Study

查阅日期：2026-10-17

## 用途与来源边界

萝卜SAMA指定以下两份资料，作为本轮物品、设备、合成链与机制设计参考。本文只提炼可核对的工具表现及本项目取舍，不把第三方仿真器当作游戏官方规则，也不移植其代码、模型或图标。具体提案见[生产内容扩展 V1](../features/factory-production-expansion-v1.md)；后续扩大到官方资料、Wiki 与六款游戏的研究见[生产游戏对照](factory-game-production-study.md)。

| 来源 | 本次实际读取 | 能支持什么 |
| --- | --- | --- |
| [IndustrialPlanner](https://github.com/hsyhhssyy/IndustrialPlanner) | README；`v3` 分支提交 [`5063c4986a6e7d209359ee120c9cee9cad7959fa`](https://github.com/hsyhhssyy/IndustrialPlanner/commit/5063c4986a6e7d209359ee120c9cee9cad7959fa) 的设备、物品、配方定义 | 工序分工、投入产出关系、设备足印 / 端口 / 缓冲结构；未运行仿真，不据此证明游戏内节拍 |
| [GameHeads 蓝图规划器](https://gameheads.gg/zh/g/endfield/blueprints/new) | 可读取的页面说明、物流工具栏；浏览器动态界面读取超时 | 从生产目标到实体布局、物流与供电覆盖的规划方法；未完成交互布线或蓝图仿真 |
| [GameHeads 生产计算器](https://gameheads.gg/zh/g/endfield/calculator) | 可读取的功能说明与表头 | 目标速率、资源压力、设施数量、电力和副产物复用的联合考虑；未拿到一份计算成功的产线结果 |

IndustrialPlanner 的 README 明确列有无限来源、无限供电及加速等调试能力，并提示部分预支持内容、复杂物流与跨基地结果仍应回游戏核实。GameHeads 自称非官方同人网站。本轮引用上述工具的结构，不把调试便利性作为 RadishCatalyst 的生产规则。

## 可以核对的关系

以下标识来自固定提交的[配方定义](https://github.com/hsyhhssyy/IndustrialPlanner/blob/5063c4986a6e7d209359ee120c9cee9cad7959fa/src/registry/recipe-definition.ts)；名称采用工序概括，避免未经本地化核对就断言游戏中文名称。

| 源码例子 | 观察到的结构 | 本项目建议 |
| --- | --- | --- |
| `r_furnace_iron_nugget_from_iron_ore_basic`、`r_crusher_iron_powder_from_iron_nugget_basic` | 原料经不同设备得到不同形态的中间品 | 给粉碎、精炼独立职责；粉末应进入后续配方，不能只是多过一道机器 |
| `r_component_iron_cmpt_from_iron_nugget_basic`、`r_packaging_battery_2_from_iron_cmpt_and_originium_powder_basic` | 配件与另一条原料支线在组装阶段汇合，产出电池 | 用共用材料连接设备扩建与能源产品，产生分配选择 |
| `r_chrono_liquid_furnace_refined_copper_from_copper_ore_basic` | 同一批次有主、副两种产物 | 本包先用固体矿渣验证副产物利用和回压，液体物流另包处理 |
| `r_thickener_originium_enr_powder_from_originium_and_moss_powder_basic` | 两类粉末合成更高阶中间品 | 借鉴多来源加工，不直接复制其植物、稀有度与材料名称 |

[设备定义](https://github.com/hsyhhssyy/IndustrialPlanner/blob/5063c4986a6e7d209359ee120c9cee9cad7959fa/src/registry/entity-definition.ts)中的 `grinder_1` 有独立原料 / 产物缓冲及端口绑定；`tools_asm_mc_1` 与 `power_sta_1` 是不同设施。值得保留的设计原则是让工序、接口和布局彼此对应，而非所有加工都只是同一种机器换配方。

## 本轮采用与暂缓

- 采用：专用加工设备、共享中间品、双原料合成、直接 / 高效两条工艺、副产物回用、能源产品的持续用途，以及从成品倒推需求。
- 本项目原创：物品命名、具体配方、节拍、功率、构件换算和开拓奖励，均为 Demo 初始建议值，不能标成终末地数值。
- 暂缓：液气管网、种植 / 采种循环、地区交易、跨基地物流、蓝图自动布局和完整科技树。它们可以后续评估，但不与这一包绑定。
- 不采用：无限来源、免费供电、重叠建筑等仿真调试能力作为正式玩法；不因工具里存在大量设备就一次性实现全表。

## 对当前 Demo 的启发

现有五种物品 / 四配方和三类物流附件已能承载更丰富的链条。下一包优先回答三个问题：玩家是否愿意为了制造更多机器建立材料线；是否愿意分出产能维持新增电力；是否愿意制造开拓用品以获得更好的原料供给。每个成品都必须在本包内有实际消费入口和可见回报。

先用有限的固体物料把这些关系做成可玩的闭环，再根据反馈决定是否进入液体化工。验证重点是建线、选择和扩建的行为；配平表用于排除自举死锁和明显数值矛盾，不预先承诺首次完成时长。
