# Tools

项目辅助脚本目录，用于数据处理、构建、导出、检查和自动化任务。

## 局部视觉研究与产线试玩

`visual-studies/` 保存独立 Demo；正式 Godot 客户端仍在 `client/`。启动命令均从仓库根执行，范围和证据见专题，开窗前遵守告知要求。

| 入口 | 用途与合同 |
| --- | --- |
| `sh tools/run-web-topdown-3d-demo.sh` | 本机 `4318`：`/play/` 为[首条三维产线](../docs/features/web-first-production-line-v1.md)，`/` 为[七机视觉样场](../docs/design/web-topdown-3d-demo-v1.md)；已有 Node 与局部锁定 Three.js，无游戏存档 |
| `sh tools/run-web-style-demo.sh` | 本机 `4317`：[手绘 / 像素 Canvas 对照](../docs/design/web-style-comparison-demo-v1.md)，只需已有 Node |
| `sh tools/run-topdown-3d-demo.sh` | [独立 Godot 3D](../docs/design/topdown-3d-comparison-demo-v1.md)，不借用正式 Boot |
| `sh tools/run-pipe-visual-study.sh` | [透明管道样板](../docs/design/transparent-pipe-module-visual-validation-v1.md)，正式 Boot 隔离世界 |
| `sh tools/run-industrial-volume-study.sh` | [像素体积样板](../docs/design/industrial-volume-visual-study-v1.md)，正式 Boot 隔离世界 |
| `sh tools/run-raised-pipe-modules.sh` | [架空管道模块](../docs/design/raised-pipe-module-visual-validation-v1.md)，正式 Boot 隔离世界 |

四个 Godot 入口均支持 `--verify`；使用已安装 Godot，允许 `GODOT_EXE` 指定路径。Web 仅监听 loopback；若服务已经运行，直接访问，不重复启动或重装依赖。三维 Demo 内的 `npm test` 只覆盖原样场，完整产线定向检查命令见产线专题。

本轮像素处理入口为 `normalize_pipe_visual_study.py`、`normalize_industrial_volume_study.py`、`normalize_raised_pipe_modules.py`，均依赖已有零依赖归一基础库、固定源图及 SHA-256 校验。它们会写入对应 `client/assets/sprites/visual_studies/`，不能把“打开样板”误作重新归一素材；没有对应忽略目录源图的机器不可复跑。日志 / 隔离存档在 `tools/runtime-intake/`，原图 / 截图在 `assets/art-intake/`，具体子目录由专题约定。

正式工厂 D1 模型导出、布局检查与静态预览见 [Factory Content Authoring](factory-content/README.md)。独立低投入交互样板使用 `bash tools/factory-content/refinement-demo.sh`；两件自有模型导出和 `check-refinement.gd` 定向检查也见该文。样板通过双根隔离 Boot 挂载、内存运行，不接入正式新世界菜单或保存规则；不支持上述四个入口的 `--verify` 约定，开窗前仍须告知。

## 正式工厂定向检查

以下均使用已安装 Godot，启动前先告知；存档与日志仅写忽略的运行检查目录。完整隔离要求见 [Godot Runtime Verification Guide](../docs/reference/godot-runtime-verification-guide.md)，实际覆盖由脚本及当批日志确认。

| 入口 | 模式与用途 |
| --- | --- |
| `sh tools/check-factory-energy.sh state <新 batch>` | E2 固定步：R12 / 启停 / 供电边界、自然物料 C/P/D/D+、同源开关对照、耗尽恢复、V7 与复制 / 保存故障；显式步和人物定位单列 |
| `sh tools/check-factory-energy.sh process-read <新 batch> <state 父 batch>` | 独立进程恢复能源半程，比较完整 80 秒轨迹 |
| `sh tools/check-factory-energy.sh menu <新 batch>` | 正式 Boot 四种入口 / 继续；带真实半批的 E1 显式复制、取消、原档字节保护与全部旧字段投影比对 |
| `sh tools/check-factory-energy.sh background-write <新 batch>` | 正式 Boot 零物料自然完成第二炉，P 造 G，C 自举两电芯；真实主循环、碰撞行走和控件操作 |
| `sh tools/check-factory-energy.sh background-read <新 batch> <write 父 batch>` | 独立恢复 C，P 自然制造其余构件，改建 D 并保留 R12 半批 / 实际缺口 |
| `sh tools/check-factory-energy.sh background-complete-read/background-off <新 batch> <read 父 batch>` | 同一 D 父档分别启用 / 停用 G，比较四包新入仓；启用分支继续真实制造 D+、耗尽和停机自救，两个模式须用不同新批次 |
| `sh tools/check-factory-energy.sh background-recovered-read <新 batch> <complete-read 父 batch>` | 独立恢复耗尽自救后的 R12 半批 / 发电余能，真实继续加工与供电 |
| `sh tools/check-factory-energy.sh review <新 batch> <write 或 read 父 batch>` | 短窗口：自然检查点副本、近身面板与发电机模型；截图与后台结果分列 |
| `sh tools/check-factory-expansion.sh state <新 batch>` | E1 11 配方、原子装配 / 326 总预算、主副产物、逐物料账、独立 schema 6 与真实文件故障；模型显式步。状态脚本已登记默认 Godot 检查 |
| `sh tools/check-factory-expansion.sh process-read <新 batch> <state 父 batch>` | 炭矿半周期、混料半批、矿渣持货、制造未放置与第二炉完成，独立进程完整恢复和续跑 |
| `sh tools/check-factory-expansion.sh menu <新 batch>` | 正式 Boot 默认基础、旧 V5 与第三个显式 E1 世界的创建 / 继续及身份隔离 |
| `sh tools/check-factory-expansion.sh background-write <新 batch>` | 正式 Boot 零物料按 A 直接工艺自然制造两包，装配并放下第二炉；无窗口 |
| `sh tools/check-factory-expansion.sh background-read <新 batch> <write 父 batch>` | 独立恢复 A，实际改建 B 回用线，保存 R08 混料半批 |
| `sh tools/check-factory-expansion.sh background-complete-read <新 batch> <read 父 batch>` | 再次独立恢复，回用产出两包并取入背包供玩家选择下一次扩建 |
| `sh tools/check-factory-expansion.sh review <新 batch> <write 或 read 父 batch>` | 短窗口：自然半批副本、真实主副口拆带 / 修复、三设备两种窗口、背包与装配栏；窗口关闭即停 |
| `sh tools/check-factory-expansion.sh feedback/feedback-window <新 batch> <read 父 batch>` | 混料半批的电力常显 / 连线开关、配额提示与镜头定位、鼠标不移动 / WASD 行走、自然完成与保存；前者无窗口，后者两种尺寸原图 |
| `sh tools/check-factory-engineering.sh identity/identity-read <新 batch> [父 batch]` | [D4-S0 工程合同](../docs/architecture/factory-engineering-scale-v1.md)的严格身份、地图与隔离；identity-read 必须指定成功 identity 父批次 |
| `sh tools/check-factory-engineering.sh prepare/prepare-read <新 batch> [父 batch]` | 零库存合法前置、20 单元全量构建、服务路线和真实 600 秒历史；prepare-read 从成功 prepare 副本独立比对首态与 20 步轨迹 |
| `sh tools/check-factory-engineering.sh capacity/density/repair/competition <新 batch> <prepare 父 batch>` | 分别为 2,500 秒总容量、900–1,000 件高密度、拆带 / 停复电、真实竞争 / 配额；全为模型显式步，不计前台性能 |
| `sh tools/check-factory-engineering.sh checkpoint-write <新 batch> <prepare 或负载父 batch>` | 对命名状态生成独立 20 步预期；保留输入、来源整目录哈希与每个检查点，历史产物若在消费时补哈希会明确登记 |
| `sh tools/check-factory-engineering.sh boot-restore <新 batch> <checkpoint-write 父 batch>` | 正式双根隔离 Boot 首帧冻结、全快照与续跑终点比对、实际 Store 保存；无窗口 |
| `sh tools/check-factory-engineering.sh interrupt <新 batch> <prepare 父 batch> --interrupt-at before/sampling/close` | 三个值须分别运行；无窗口合成失焦 / 关闭，采样中先有真实步进和保存，后续档位不得继续 |
| `sh tools/check-factory-engineering.sh short-window <新 batch> <prepare 父 batch>` | 手动准备页后四档各 12 秒，正式 Boot / 原采样器 / 原门槛；失焦即停，不自动重开。仅 S0 初筛，不代替 S1 |
| `sh tools/check-factory-engineering.sh workload-check <新 batch> <prepare 父 batch>` | S1 逐帧工作记录与逐步参考计数逐台比对，验证漏采拒绝和只读；无窗口显式步 |
| `sh tools/check-factory-engineering.sh sustained-preflight <新 batch> <prepare 父 batch>` | 正式 Boot 35 秒真实时钟、周期自动保存与工作记录；无窗口，不计前台性能 |
| `sh tools/check-factory-engineering.sh sustained-interrupt <新 batch> <prepare 父 batch> --interrupt-at before/sampling/close` | S1 工作记录启用时的三个中断边界，分别运行，保留部分样本且禁止后续档位 |
| `sh tools/check-factory-engineering.sh sustained <新 batch> <prepare 父 batch>` | S1 手动开始、同一世界连续四档各 450 秒；沿原画质 / 门槛，逐台事件、滚动工作覆盖、每秒负载与全部自动保存；失焦 / 关闭停止全轮 |
| `sh tools/check-factory-foundation.sh <mode>` | 基础工厂状态 / 保存 / 规模与 Boot；各模式、前置和窗口边界见运行时指南 |
| `sh tools/check-factory-power.sh state [batch]` | 无窗口电图、能量守恒、半批存读及版本保护 |
| `sh tools/check-factory-power.sh write/read <batch>` | 同一唯一 batch、两个独立进程的普通线窗口写入 / 恢复；实际执行时分别使用 `write` 或 `read` |
| `sh tools/check-factory-discovery.sh state [batch]` | 无窗口四配方、样本 / 开路、事务和兼容检查，生成分段夹具 |
| `sh tools/check-factory-discovery.sh process-read [batch]` | 先完成 state，再用独立进程核对多件半批与后续轨迹 |
| `sh tools/check-factory-discovery.sh write/read <batch>` | 先完成 state，再用同一唯一 batch 串行执行 `write`、`read`，覆盖正式 Boot 分项交互与恢复 |
| `sh tools/check-factory-statistics-performance.sh prepare/window <batch> <absolute-source-snapshot>` | 显式 runtime-intake 内 schema 2 来源；prepare 无窗口补满 600 秒历史，window 从相同准备状态分别测关闭 / 物料 / 电力各 45 秒。窗口准备页手动开始；独立双根、唯一 batch、原预算、失焦即停；仅普通供给对照，不算首档规模或持续验收 |
| `sh tools/check-factory-statistics-performance.sh prepare-v5 <新 batch> <C 完成恢复 batch>` | 严格 V5 普通 C 完成态，真实碰撞行走后近身将空载 G4 改不限量；显式 600 秒准备与独立 45 秒工作探针，保留 84 实体 / 240 kW，不改库存或供给 |
| `sh tools/check-factory-statistics-performance.sh verify-v5 <新 batch> <prepare-v5 batch>` | 无窗口独立 Boot 分别恢复关闭 / 物料 / 电力页，首帧完整比对，暂停下各推进 900 固定步；终点和守恒一致，不计性能或自然时长 |
| `sh tools/check-factory-statistics-performance.sh interrupt-v5 <新 batch> <prepare-v5 batch> --interrupt-at before/sampling/close` | 末参数三选一；无窗口注入采样前失焦、实际采样后失焦或关闭，确认后续阶段不运行、部分证据保留，不计性能 |
| `sh tools/check-factory-statistics-performance.sh window-v5 <新 batch> <prepare-v5 batch>` | 开窗、准备页手动开始，从同一已准备快照做三段各 45 秒；原帧 / 单步预算及自动保存保持，失焦即停。须先告知并安排连续前台 |
| `sh tools/check-factory-statistics.sh state [batch]` | 统计查询、窗口、库存 / 理论口径、恢复与页面挂载定向检查 |
| `sh tools/check-factory-statistics.sh ui <batch>` | 新隔离世界短窗口复核统计按钮与 Escape，先于完整路径执行 |
| `sh tools/check-factory-statistics.sh write/read <batch>` | 新 batch 从空勘探世界按真实活动时间生产、步行与开路，复核统计 / 窗口；read 独立 Boot 恢复后继续断料 / 修复趋势验证 |
| `sh tools/check-factory-device-interaction.sh state [batch]` | 统一设备面板、执行时库存、近身 F / Tab 候选与物品格、配方候选保持、端口与物流、接线范围 / 遮挡 / 无状态变更、旧工厂边界；已登记 Shell / PowerShell 默认 Godot 检查 |
| `sh tools/check-factory-device-interaction.sh preview <batch>` | Boot 默认基础工厂及勘探工厂的三类设备预览、放置 / 取消、选中 / 近景与铺带；勘探另验电源 / 节点接线范围、非法位置、最小窗口和矿壳遮挡，要求新 batch |
| `sh tools/check-factory-device-interaction.sh background-write/background-read <batch>` | 日常功能回归优先；正式 Boot、自然生产、合成输入与独立半批恢复，不创建窗口、不等待原生焦点、不捕获截图；新 write 批次，同批 read 仅一次；结果明确模式与省略截图 |
| `sh tools/check-factory-device-interaction.sh write/read <batch>` | 新双根隔离空世界，合成鼠标拖铺 / 近身点击、近身 F / Tab、统一面板内自然生产与实时库存、暂停 / 输入隔离、各类设备与窗口布局及半批独立 Boot 恢复；write 拒绝已有 batch，read 会继续生产并保存，只运行一次 |
| `sh tools/check-factory-first-journey.sh state [batch]` | 首程引导由事实派生、先拾样 / 先建线、材料位置、供电 / 回压、替代路线、目标拆除、独立解码与只读不变；已登记 Shell / PowerShell 默认 Godot 检查 |
| `sh tools/check-factory-first-journey.sh write/read <batch>` | 正式新勘探空世界首程卡 / 回查 / 最小窗口、完整自然生产与两次开路、富集回流、停复电 / 增容及独立 Boot 全快照恢复；新 write 批次、同批 read 仅一次 |
| `sh tools/check-factory-routing.sh state/process-read <batch>` | schema 4 端口 / 公平轮转 / 守恒 / 严格解码 / 显式升级与 IO 失败、独立进程完整恢复；state 用新批次，process-read 同批一次 |
| `sh tools/check-factory-routing.sh background-preview/preview <batch>` | 正式 Boot 普通供给的单构件连接诊断、R / Esc、错接 / 非法位置、弯道拖铺取消、落位一致及普通 / 最小窗口布局；新 batch。前者无窗口，后者短窗口原图；暂停几何路径，不代替自然产线 / 亲测 |
| `sh tools/check-factory-routing.sh replacement-background-write/replacement-background-read <batch>` | 正式 Boot 零库存自然采集，人物保持两格外，以鼠标 / Enter / 按钮将三段带货传送带替换成三类附件，R 与换目标朝向、回收守恒、保存及独立恢复；无窗口不截图。write 新批次，read 同批一次 |
| `sh tools/check-factory-routing.sh replacement-write/replacement-read <batch>` | 同一路径的短窗口与原图；read 另验取消、R 转向后提交及最小窗口。使用 `factory-attachment-replacement-v1` 双根隔离目录，不消费用户亲测档 |
| `sh tools/check-factory-routing.sh menu <batch>` | 正式菜单：旧 schema 3 原规则继续、升级取消 / 确认与来源副本、不得重复领取 |
| `sh tools/check-factory-routing.sh background-write/background-read <batch>` | 正式 Boot 当前新勘探世界零库存自然两路生产、合流、堵塞修复、半程保存与独立恢复；无窗口不截图 |
| `sh tools/check-factory-routing.sh review <batch>` | 使用哈希核对过的未消费 write 副本短窗口检查面板、旋转预览和全线；原图另存 art-intake，不代替亲测 |
| `sh tools/check-factory-admission.sh state/process-read <batch>` | V5 四方向 / 配额 / 守恒 / 严格解码 / 无闸旧线一致、4→5 原档升级与 IO 故障；state 新批次，process-read 同批一次；已登记默认 Godot 状态检查 |
| `sh tools/check-factory-admission.sh menu <batch>` | 正式菜单 V4 原规则继续、升级取消 / 确认、原档与八件供给、不得重复领取、新建 V5 |
| `sh tools/check-factory-admission.sh background-write/background-read <batch>` | 正式 Boot 普通零库存筛晶体、自然试制、解壳剂配额 4；3+在途第 4 件独立恢复、关闭排空、再启用不重置与显式重置续产；前台为 0，无截图 |
| `sh tools/check-factory-admission.sh write/read/review <batch>` | write/read 为同一路径的窗口模式；review 只消费哈希核对的 write 副本，短窗口检查暂停恢复、F / Tab、配置 / 数量布局与 R 预览，不声称自然生产 / 配置提交通过；原图另存 art-intake |
| `sh tools/check-factory-combination.sh geometry <新 batch>` | C 精确 84 实体 / 63 带、实际端口、同网电力及人物碰撞采样；构造夹具，不代替自然 Boot |
| `sh tools/check-factory-combination.sh state <新 batch> <write 父 batch 或隔离快照绝对路径>` | C3 来源快照的严格守恒、双配方 / 富集多件批次、顺序 / FPS 重放、配额及故障状态；显式步进与来源类型分列 |
| `sh tools/check-factory-combination.sh process-read <新 batch> <state 父 batch>` | 新进程从哈希核对副本重放，核对完整初始和终点快照 |
| `sh tools/check-factory-combination.sh background-write <新 batch>` | 正式 Boot 普通零库存，试制 / 首轮四件开路、无损改线、双原料组合与富集来源跟踪、第二轮 7+1 保存；正常主循环，无窗口 |
| `sh tools/check-factory-combination.sh background-read <新 batch> <write 父 batch>` | 独立 Boot 首帧完整比对、关闭排出第八件、再启用不重置、取新八件开内矿道并保存 |
| `sh tools/check-factory-combination.sh background-complete-read <新 batch> <read 父 batch>` | 再次独立 Boot 恢复两次开路及配额，观察双加工源继续完成出货 |
| `sh tools/check-factory-combination.sh background-faults <新 batch> <write 父 batch> --fault <分支>` | 每分支从独立 C3 副本启动；`raw-closed` / `wrong-gap` / `sink-blocked` / `g4-blocked` / `quota-reset` / `power-shortage` 分别检查队首停收、隔带反例、仓支路断接、末件堵塞、空载重置和缺电恢复 |
| `sh tools/check-factory-combination.sh review <新 batch> <write 父 batch>` | 正式 Boot 短窗口：C3 原图、普通 / 最小面板、Tab / F / I、统计定位与旋转预览；随后在该子副本真实阻挡 / 修复第八件并捕获 8/8，不重走 C0–C4 |
| `sh tools/check-factory-range-power.sh state [batch]` | schema 3 自动图、确定改接、遮挡、供能、样本唯一性、严格解码、升级原档保留及 IO 失败；已登记默认 Godot 检查 |
| `sh tools/check-factory-range-power.sh write/read <batch>` | 新自动世界鼠标建线与自然生产、停复电、远近样本 / F 拾取；另用声明的旧布局夹具检查菜单升级和地面点击拾取。read 独立恢复新世界完整快照及半批；要求新 write 批次、同批 read 仅一次 |

范围供电窗口走真实正式创建 / 升级菜单；创建使用聚焦 Enter，恢复时列表 / 按钮信号用于首帧冻结核对。模型、HUD、升级弹窗与地面图标走路由合成鼠标，人物 WASD 行走，近身 F 拾取。新世界不注入物料 / 位置或加速；旧布局夹具仅承担迁移验证，不冒充自然建线。截图 / 世界在 `factory-range-power-v1` 与对应 `factory-range-power-preview` 忽略目录。

历史 `power` / `discovery` / `statistics` 窗口脚本保留 schema 2 回归语义：通过隔离 Store 准备旧世界，再由 Boot 的世界装配入口加载，不以旧夹具冒充当前菜单验收。继续按钮现保留旧规则；范围供电检查显式选择 2→3，routing 菜单检查显式选择 3→4，admission 菜单检查另选 4→5，新勘探世界使用 schema 5。历史世界的完整发现循环证据不自动扩展为 schema 3 已完整重跑；当前完整路径由 `first-journey` 专项承担。

设备交互复用统计路径的真实行走与输入驱动；窗口模式等待原生焦点，无窗口 `background-*` 模式直接向引擎 Viewport 投递合成输入，使用相同模型、主循环与活动时钟，不注入活动焦点。窗口模式等待期间工厂仍继续生产，计时单列；无窗口模式限 60 FPS，不加速生产，省略截图列表进入结果。Boot 首屏使用聚焦后的合成 Enter；初始建造使用既有精确放置字段 / 按钮信号，当前 schema 3 / 4 / 5 只核对自动电图，不发送手动接线命令。拖带、近身模型点击和面板按钮走合成鼠标，附近目标用 F / Tab、背包用 I、行走用 WASD；源启停经统一面板按钮，配方下拉候选由驱动选中后点击切换。场景内 `Control` 面板按所在窗口路由完整鼠标手势，检查按钮可见且仅激活一次；测试准备、合成控件输入与用户亲测分列。无物料 / 解锁 / 人物位置注入或生产加速；启动前告知，用户关闭即停止。

准入口批次根为 `tools/runtime-intake/check-runs/factory-item-admission-v1/`，原图为 `assets/art-intake/2026-10-12-factory-item-admission-preview/`，亲测另用 `tools/runtime-intake/review-worlds/factory-item-admission-v1/`。write 不复用已有目录，read 续产并保存，只消费一次；review 从未消费检查点副本启动，报告分别声明实际输入和计时，不能把截图拼成自然路径。面板下拉 / 整数候选由驱动精确设置，提交走真实按钮；状态组合夹具的显式时间推进与自然 Boot 分列。

C 入口由 Shell / PowerShell 调用已有 Python 3 标准库 runner，不安装依赖；PowerShell 参数为 `-Mode`、`-Batch`、`-Source`，支持 `-GodotExe`。所有模式均要求新 batch，恢复直接提供父 batch 名，由入口复制所需存档 / 上下文并生成 `origin.json`；父结果必须断言通过且 runner 无错误，持锁、软链接或已消费 write 拒绝。子进程结束再次核对父文件 SHA-256，`runner-result.json` 同时记录退出码与 Godot 错误，不以绿色断言掩盖字体 / 脚本错误。根为 `tools/runtime-intake/check-runs/factory-conveyor-combination-v1/`；不自动加入依赖自然检查点的默认 Godot 状态套件。逐项运行证据见 [C 专题](../docs/features/factory-conveyor-combination-v1.md)。

10 月 8 日确认薄传送带须使用带面采样，修正检查驱动并保留失败退出；返回菜单释放按钮后仍核对激活次数，但不再访问已释放控件。`unified-window-20261008-b` 的 write 211 / read 32 项通过，包含新面板下首程目标与回压恢复；read 已续产保存，不重复消费。10 月 5 日 c 与 10 月 8 日 a 的失败证据保留，不能当作通过批次；详见 [W41 周志](../docs/devlogs/2026-W41.md)。旧电力 / 发现 / 统计脚本的面板入口已适配并编译通过，本轮未重跑其全部窗口路径。

`preview` 模式的 Boot / 创建入口使用聚焦合成 Enter，放置工具、鼠标悬停、点击放置、设备点选及邻近铺带走合成鼠标；取消使用 Escape。基础工厂保留默认选择；勘探工厂由下拉选择后新建，人物真实行走到矿区。两世界独立保存，不更改正式存档。

发现检查的 `[batch]` 只控制状态日志位置；当前状态脚本将夹具 / JSON 结果固定写到 `tools/runtime-intake/check-runs/factory-discovery-v1/d2-b-20260925/`，process-read 与窗口 write 都从此取输入。复跑 state 会更新该固定目录，需先保留要审计的旧证据；窗口批次另用唯一名称，read 读取 write 的 manifest。窗口夹具由加速模型生产并准备布局 / 人物位置，不能作为自然玩家全路径。`check-client` 的 Godot 模式已登记 power / discovery / statistics 状态检查，不自动覆盖这些跨进程或窗口模式。

统计窗口 write 使用 HUD 精确放置按钮、合法接线命令、稳定 ID 选择、合成 WASD 与原生面板 Enter，不预填材料、传送人物、直接解锁或加速时间。普通功能路径失焦时停止输入、等待手动切回，在同一进程 / 世界继续并记录失焦区间；不抢焦点，连续性能检查仍失焦即中断。同名 batch 不用于重建自然路径，失败批次须保留。read 仅用于已完成 write 的批次：通过键盘 Enter 进入工厂菜单，先冻结首帧核对完整快照，再在真实恢复世界分别观察正常供料、拆带断料、重建修复各 60 秒，最后保存并记录 `read-final.json`。因此 read 成功后不能以同一最终存档再次比较原 write 快照；若需复跑，使用新 write 批次，失败证据单独保留。它是自动工程路径，不替代用户亲测或首次阅读 / 建线时长。

统计性能的 Shell / PowerShell 共用 Python runner；PowerShell 参数为 `-Mode`、`-Batch`、`-Source`、可选 `-InterruptAt` / `-GodotExe`。V5 来源必须是成功 C `complete-read` 或成功 `prepare-v5`，拒绝持锁、软链接、覆盖和失败父批次；复制后 / 运行后复核父哈希，准备产物与模型 / 检查代码指纹必须匹配。批次根仍为 `factory-statistics-v1`；当前已验证准备为 `p0-v5-prepare-20261017-c`，P1 可另选新 batch 运行 `window-v5`。代码变化则重新准备；无窗口结果 `performance_acceptance=false`，不代替窗口结果。Windows / PowerShell 尚未实跑，批次范围见 [D4 方案](../docs/planning/factory-d3-exit-and-d4-validation.md)及 [W42](../docs/devlogs/2026-W42.md)。

首程窗口复用已有完整路径：建造使用 HUD 精确字段 / 动作，操作使用聚焦 Enter，人物 WASD 行走，统计与新增引导入口使用合成鼠标；焦点注入明确登记。自动供电连接只检查实际图，不发送旧接线命令。全程不注入物料、解锁、人物位置或加速时间。恢复通过列表 / 按钮信号首帧冻结核对。日志 / 世界在 `factory-first-journey-v1`，截图在 `2026-10-05-factory-first-journey-preview`；合成路径不当作首次游玩时长。

## 像素归一管线（零依赖）

- `normalize_pixel_asset.py`：像素素材归一基础库与 CLI（仅 Python 标准库）。能力：整数块降采样（块内逐通道中位数）、近黑底去背（边界泛洪 + 封闭孔判定）、限定调色板量化（median cut 上限 + 标准锚点吸附）、地面 128x128 宏块（4x4 个 32px tile）、横版多对象切分、明度基线匹配、2x2 拼贴与接缝比率自查。机械口径见 `docs/reference/pixel-art-and-grid-standard.md`。
- `normalize_slice_pack1.py`：切片包 1 批处理驱动，把证据轮定稿素材从 `assets/art-intake/`（不入库）归一到 `client/assets/sprites/slice/`、`client/assets/tiles/slice/` 与 `client/assets/portraits/`，并输出 QA 预览。仅在持有 art-intake 源图的机器上可复跑：
- `normalize_l3a_industrial_floor.py`：校验 L3-A V2 源哈希，逐格裁切 16 个 terrain tile，共享色板归一为 32px 后编排 128x128 atlas，并输出 3x3、6x4 和带内角开孔的平台拼接预览。
- `normalize_l3b_power_relay.py`：校验 L3-B V5 双态源哈希，以断电杆体作为唯一公共几何归一到 32×64，再受控派生红灯断电态、青灯与短脉冲通电态。
- `normalize_l3c_conveyor.py`：校验 L3-C V1 四向源哈希，以统一 384×384 源窗口和 12 倍整数块降采样归一为四个 32×32 方向帧，共享限定色板并输出工业地板联系表。
- `normalize_l3d_reactor_ports.py`：锁定现有 96px 反应器为唯一不可变主体，只在四个基数连接位受控派生琥珀出料 / 青色缺口入料端口，输出四向静态帧与工业地板联系表。
- `normalize_l3e_storage_hatch.py`：锁定现有 87×88 四罐储存设备为唯一不可变主体，每帧只在一个基数连接位覆盖带青色缺口与琥珀锁扣的双向舱口，输出四向静态帧与工业地板联系表。
- `normalize_l4a_crystal_cargo.py`：锁定已审定小型晶体簇哈希，以固定逐行掩码分离中央单晶，输出 `10×12` 货物 sprite 与四向带面联系表。
- `normalize_l4b_conveyor_topology.py`：锁定 L3-C 四向直段哈希，离线派生 8 张正交转角、源 / 目标端点各 4 张及双 / 三路合流 16 张 `32×32` 固定帧；运行时只选图，不旋转或绘制轨道。

```bash
python3 tools/normalize_slice_pack1.py            # 全量
python3 tools/normalize_slice_pack1.py --only grounds   # 单类
python3 tools/normalize_l3c_conveyor.py           # L3-C 四向传送带
python3 tools/normalize_l3d_reactor_ports.py      # L3-D 反应器四向端口
python3 tools/normalize_l3e_storage_hatch.py      # L3-E 储物箱四向舱口
python3 tools/normalize_l4a_crystal_cargo.py       # L4-A 单晶货物
python3 tools/normalize_l4b_conveyor_topology.py  # L4-B 转角 / 端点
```

## 美术素材处理（旧，Pillow）

- `prepare_art_asset.py`：把审阅通过的 PNG 素材裁切、去底、缩放到 `client/assets/`，并可写入 Godot `.import` sidecar。
- `requirements-art.txt`：美术素材处理所需的本地 Python 依赖。不要把依赖装进系统 Python；需要处理素材时使用项目本地虚拟环境。

推荐流程：

```bash
python3 tools/prepare_art_asset.py --check-env
python3 -m venv .venv-art
.venv-art/bin/python -m pip install -r tools/requirements-art.txt
.venv-art/bin/python tools/prepare_art_asset.py --input assets/art-intake/.../source.png --output client/assets/sprites/.../asset.png --trim-background --max-size 320 --write-godot-import
```

地面 tile 不去底，通常使用：

```bash
.venv-art/bin/python tools/prepare_art_asset.py --input assets/art-intake/.../tile.png --output client/assets/tiles/.../tile.png --mode tile --tile-size 512 --write-godot-import
```

发现状态检查支持 `--evidence=<仓库隔离目录>`，可将本轮夹具与历史固定快照分开；独立读进程须明确指向同一批目录。routing 的 `write/read` 为对应有窗口完整模式，普通功能验证优先 `background-*`；所有 read / review 都会继续生产和保存，不重复消费同一起点。

E1 / E2 runner 使用已有 Python 3 标准库，Shell / PowerShell 均要求全新 batch；恢复模式明确指定成功父批次，复制前后核对整目录 SHA-256，父档不消费。日志同时核对退出码与 Godot 错误。源码哈希写入 `execution-inputs.json`；窗口原图和无窗口功能时长分列。路径、合同和亲测入口见 [E1 专题](../docs/features/factory-production-expansion-e1.md)。E2 批次根独立为 `tools/runtime-intake/check-runs/factory-production-expansion-e2/`，窗口原图在 `assets/art-intake/2026-10-23-factory-energy-e2-preview/`。`check-client` 的显式 Godot 路径包含 E2 状态检查，不因此代表自然 Boot 或窗口通过。PowerShell 可通过 `GODOT_EXE` 指定现有程序；不自动安装任何依赖。
