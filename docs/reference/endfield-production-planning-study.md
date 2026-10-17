# Endfield Production Planning Study

查阅日期：2026-10-17

## 用途与来源边界

萝卜SAMA先指定两份社区工具，随后要求扩大来源并通过已打开的森空岛 Wiki 核对。本文记录工具观察、官方社区 Wiki 词条和本项目取舍，不移植代码、模型或图标。具体提案见[生产内容扩展 V1](../features/factory-production-expansion-v1.md)；跨游戏比较见[生产游戏对照](factory-game-production-study.md)。

| 来源 | 本次实际读取 | 能支持什么 |
| --- | --- | --- |
| [IndustrialPlanner](https://github.com/hsyhhssyy/IndustrialPlanner) | README；`v3` 分支提交 [`5063c4986a6e7d209359ee120c9cee9cad7959fa`](https://github.com/hsyhhssyy/IndustrialPlanner/commit/5063c4986a6e7d209359ee120c9cee9cad7959fa) 的设备、物品、配方定义 | 工序分工、投入产出关系、设备足印 / 端口 / 缓冲结构；未运行仿真，不据此证明游戏内节拍 |
| [GameHeads 蓝图规划器](https://gameheads.gg/zh/g/endfield/blueprints/new) | 可读取的页面说明、物流工具栏；浏览器动态界面读取超时 | 从生产目标到实体布局、物流与供电覆盖的规划方法；未完成交互布线或蓝图仿真 |
| [GameHeads 生产计算器](https://gameheads.gg/zh/g/endfield/calculator) | 可读取的功能说明与表头 | 目标速率、资源压力、设施数量、电力和副产物复用的联合考虑；未拿到一份计算成功的产线结果 |
| [森空岛终末地 Wiki](https://wiki.skland.com/endfield/catalog?mainTypeId=1&subTypeId=5&filterIds=&header=0) | 通过用户已打开的 Chrome 窗口读取设备目录和下列 9 个详情页；粉碎机页面另看截图 | 正式中文名称、代表配方、制造来源、设备足印 / 功率值与成品用途；未进行游戏内实测，不宣称全表核验 |

IndustrialPlanner 的 README 明确列有无限来源、无限供电及加速等调试能力，并提示部分预支持内容、复杂物流与跨基地结果仍应回游戏核实。GameHeads 自称非官方同人网站。本轮引用上述工具的结构，不把调试便利性作为 RadishCatalyst 的生产规则。

## 森空岛 Wiki 正文核对

前轮静态抓取只有标题，内置浏览器和 Chrome 标签页读取超时；后改用 Chrome 原生窗口的页面文本成功读取。部分配方名称在首次打开时尚未加载，进入配方区后重新读取，才将数量与物品名对应。不再把这个站记为当前无法读取；本次无需离线保存。Wiki 有词条贡献者和“内容仍在填充、以游戏内实际为准”的提示，以下是查阅时页面事实。

### 设备分工和实际配方

表内功率使用 Wiki 的“功率值”，不擅自换算成 kW。数字用于核对来源，不替换本项目的配方和节拍。

| 正文来源 | 核对结果 | 对当前设计的意义 |
| --- | --- | --- |
| [精炼炉（53）](https://wiki.skland.com/endfield/detail?mainTypeId=1&subTypeId=5&gameEntryId=53&header=0) | 3×3、功率值 5；蓝铁矿 1 → 蓝铁块 1，2 秒；液体模式为赤铜矿 1 + 清水 1 → 赤铜块 1 + 污水 1，2 秒，需研究液辅熔炼 | 基础设备可以通过新工艺扩展职责；联产必须同时看副产物去向。我们的固体矿渣是原创简化 |
| [粉碎机（54）](https://wiki.skland.com/endfield/detail?mainTypeId=1&subTypeId=5&gameEntryId=54&header=0) | 3×3、功率值 5；蓝铁块 1 → 蓝铁粉末 1，2 秒；源矿 1 → 源石粉末 1，2 秒；碳块 1 → 碳粉末 2，2 秒 | 物料形态决定加工顺序，并非所有矿都先磨粉；我们的铁矿直接粉碎是自有规则 |
| [配件机（171）](https://wiki.skland.com/endfield/detail?mainTypeId=1&subTypeId=5&gameEntryId=171&header=0) | 3×3、功率值 20；蓝铁块 1 → 铁制零件 1，紫晶纤维 1 → 紫晶零件 1，均为 2 秒 | 材料加工成零件后进入不同产品；不必为每种终端产物创建一条互不相干的原料链 |
| [研磨机（188）](https://wiki.skland.com/endfield/detail?mainTypeId=1&subTypeId=5&gameEntryId=188&header=0) | 6×4、功率值 50；源石粉末 2 + 砂叶粉末 1 → 致密源石粉末 1，2 秒；蓝铁粉末也可与砂叶粉末合成致密蓝铁粉末 | 研磨与粉碎是不同设备：前者汇合两条原料线做升级，不能因英文 ID 就混淆二者 |
| [封装机（177）](https://wiki.skland.com/endfield/detail?mainTypeId=1&subTypeId=5&gameEntryId=177&header=0) | 6×4、功率值 20；铁制零件 10 + 源石粉末 15 → 中容谷地电池 1，10 秒；紫晶零件 5 + 酮化灌木粉末 1 → 工业爆炸物 1，10 秒 | 一个工艺设备支持能源与工具产品；我们用组装机承担类似汇合职责，而非按参考表增加同等数量设备 |
| [热能池（178）](https://wiki.skland.com/endfield/detail?mainTypeId=1&subTypeId=5&gameEntryId=178&header=0) | 2×2、无需供电运转，须接电网；源矿 1 对应功率值 50 / 8 秒，中容谷地电池 1 对应 420 / 40 秒 | 电池应有实际消费端；原料燃料与加工燃料共用设备，是未来能源梯度候选，不在本包追加 |
| [废水处理机（1169）](https://wiki.skland.com/endfield/detail?mainTypeId=1&subTypeId=5&gameEntryId=1169&header=0) | 3×3、功率值 50；污水、壤晶废液、惰性壤晶废液分别以 1 件 / 2 秒无害化处理，产物栏不列清水 | 来源有显式处理出口，并非强迫所有副产物都转成有价成品；不能把这条工艺写成污水循环再生清水 |

设备制造也有具体物料来源：精炼炉用源矿 5，粉碎机用晶体外壳 5，配件机用晶体外壳 10，封装机用紫晶零件 20，研磨机用铁制零件 10，热能池用晶体外壳 5 + 紫晶零件 5。部分研究还给首台设备。它支持“共享材料 → 扩建设备”的观察，但不证明我们的通用构件包、预配数量或建造价格已经合适。

### 成品确实去哪里

- [中容谷地电池（378）](https://wiki.skland.com/endfield/detail?mainTypeId=1&subTypeId=5&gameEntryId=378&header=0)：词条明确列出发电、设备充能和据点交易；还列有仓储节点装箱用途。借鉴的是同一产线连接多种需求，而非把交易系统搬进当前 Demo。
- [工业爆炸物（196）](https://wiki.skland.com/endfield/detail?mainTypeId=1&subTypeId=5&gameEntryId=196&header=0)：由封装制造，作为便携工具投掷，可破坏可爆破障碍、触发受击装置、破坏暴露的侵蚀核心，也有对敌伤害和货物装箱用途。其地图交互比“消耗四件开一次门”广；我们的胶囊目前只有固定支路用途，不能据此称作已经完整借鉴了工具循环。

这两个物品页面由配方卡片进入，当前页面保留了 `subTypeId=5` 参数；上方链接照实际访问地址记录，未凭编号猜测新 URL。

### 与社区工具及本项目规则的区别

- 固定提交中的蓝铁块粉碎、中容电池封装、源石粉末与砂叶粉末研磨三组代表配方，其数量和时间与本次 Wiki 正文相符；赤铜液体精炼的双输入 / 双输出结构也得到核对。这只提高对应例子的可信度，不代表整个注册表与当前游戏完全一致。
- 工具 `grinder_1` 对应粉碎机；两粉体合成例子使用 `thickener_1`，对应本次 Wiki 的研磨工序。不要把代码中的英语字面翻译直接当正式中文名称。
- Wiki 热能池页列出了燃料、功率值与时间，没有在本次正文中明确说明低负载停耗、同网电源优先级或多机分摊。我们提案的实际送能扣余量、永久源优先和余能存读仍是本项目设计，不是官方已核验规则。
- 本项目采用有限地图、较少工序与固体副产物，尚无参考游戏的仓库存取、液气和交易体系。不能拿其整体产线的自举、缓冲或持续需求直接证明我们的简化版本成立。

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
