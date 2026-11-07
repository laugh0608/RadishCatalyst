# Factory Content Authoring

工厂资源制作、D1 静态复核与独立交互样板工具；复用已有本地依赖，不修改正式世界存档或模拟规则。

电力模型现已用于正式勘探工厂，D2-A / D2-B 运行时检查另见 [Tools](../README.md#正式工厂定向检查)。D1 静态入口仍只提供资产 / 空间证据；新增交互样板另有启动和检查入口，范围见下文，不混用两者结论。

## 电力模型

`node tools/factory-content/export-power-assets.mjs` 用仓库已有 Three.js 安装和自有材质 / 几何帮助函数导出两个独立模型到 `client/assets/factory/power/`。无需下载依赖；安装缺失时应先按项目约定确认安装范围，不自动获取。

电源为低矮双封装模块与后部散热板，配电节点为细杆、三触点和接线柜。模型均以足印中心为原点、地面为 Y=0；导出时检查包围盒不越 3×3 / 1×1 足印，并记录源文件 hash、GLB hash、三角形与批次数。正式运行只加载导入 GLB，不调用本工具或 Web 场景。

## 布局与检查

静态夹具：`client/scripts/checks/fixtures/factory_discovery_layout.json`。布局阶段为矿道关闭 / 第一段打开 / 两段打开；它不是新世界 ruleset 或可玩存档。

`python3 tools/factory-content/check-layout.py` 核对阶段占用、矿点、物流位置、节点距离、封闭矿壳穿越、步行网格可达和构件预算，结果写入忽略的 `tools/runtime-intake/check-runs/factory-discovery-v1/d1-layout/`。检查不证明生产吞吐、真实人物碰撞、电力分配或玩家操作已经接通。

首轮布局将主矿点移到 `(-20,-1)`，为沿 X 正向连接的两台反应器留出空间；跨矿道节点使用 `(1,-2)` / `(9,-2)` / `(18,-2)` / `(25,-2)`，回流带走 `z=1`，避免旧草案的节点占据带格。原有 schema 1 地图未改。

## 静态预览

完成 Godot 资源导入后，在仓库根执行 `bash tools/factory-content/preview.sh`。四个按钮切换模型对照与矿道阶段，接线可隐藏。该手工入口仅显示静态场景，不运行生产、写存档或声称是 schema 2。

自动窗口审阅另从双根隔离的正式 Boot 新建原工厂、保存返回，再挂载同一预览控件；这段仅证明旧入口保护及预览可加载，不能把它当成新玩法从 Boot 可进入。原始脚本 / 日志 / 截图按 D1 批次保留，见 W39 周志。

所有 Godot 启动和窗口检查前先告知；不循环抢焦点，关闭后不自动重开，不为静态资源安排四档长测。

## R1-A 镜头与尺度试玩

macOS 双击 `tools/factory-content/camera-study.command`，或仓库根执行 `sh tools/factory-content/camera-study.sh`；已有 Godot 可由 `GODOT_EXE` 指定。先显示准备页，点击开始才挂载双存档根隔离的正式 Boot 与独立样板。无需新增依赖或导出模型；不添加正式世界身份，不运行生产或保存世界。

默认使用萝卜SAMA已选的 C2 透视正向 / 21 格 / 跟随角色。1 / 2 / 3 保留对照，主板 / 密集板、16 / 默认 21 / 28 格、固定 / 跟随、窗口大小与截图在工具栏。滚轮向上拉近 / 降低，向下拉远 / 升高，保持俯角与 FOV；默认 21 格按钮只恢复距离。WASD 为屏幕方向移动，左键选中、F 选两格内设备，B 测量、R 旋转、Esc 取消；测量不建造，口位和六个输出物品只是几何密度标尺。关闭后重新开始，不恢复角色或保存设置。

日志为 `tools/runtime-intake/check-runs/factory-camera-v1/<session>/godot.log`，审阅 JSON / 隔离根为 `tools/runtime-intake/review-worlds/factory-camera-v1/<session>/`，逐图 PNG / JSON 为 `assets/art-intake/factory-camera-v1/<session>/`，均忽略提交。每次新会话避免覆盖证据。

定向检查（启动前告知）：Godot `--headless --path <repo>/client --script <repo>/tools/factory-content/check-camera-study.gd --log-file <ignored-batch>/godot.log`，路径用绝对值。检查已选默认值、实际相机高度与缩放边界、双根、几何、投影 / UI 换算、射线选取、碰撞、密集替换及不写工厂存档；必须同时查退出码与错误日志。原生窗口和主人偏好另验；范围与实测见[R1 方案](../../docs/features/factory-camera-and-representative-scene-v1.md)。

## R1-B 核心轮廓候选

macOS 双击 `core-study.command` 或执行 `sh tools/factory-content/core-study.sh`；默认 C2 / 21 / 跟随，支持结构 I / II、邻带接入 / 移开、端口 ID、占地框和四侧观察点。观察点是位置跳转，实际行走用 WASD。当前 `outline-04` 候选通过开发机复测，供萝卜SAMA审阅。样板与 R1-A 入口并存，核心为几何审阅对象。见[R1-B 复测](../../docs/features/factory-camera-and-representative-scene-v1.md#r1-b-outline-04)。

制作命令 `node tools/factory-content/export-core-outline.mjs <new-batch> --publish-prototype` 使用已有 Three.js；先留独立 `assets/art-intake/2026-11-01-core-outline/<batch>/`，再仅复制新 GLB / 来源清单至 `client/assets/prototypes/base_core_outline/`。既有 batch 不覆盖，每批保留可编辑源快照；不下载 / 安装、改旧模型或执行其他导出器。首次须经 Godot 导入，启动前先告知，编辑器配置放仓库忽略的隔离目录。

核心无窗口检查：Godot `--headless --path <repo>/client --script <repo>/tools/factory-content/check-core-outline.gd --log-file <ignored-log> -- <batch>`（绝对路径）；双根位于检查 batch 下。`outline-04` 在同一条件下 1,051 项全部通过；`outline-03` 的 96 项边缘失败单独保留。原图 / 逐图 JSON 为 `assets/art-intake/factory-core-outline-v1/<session>/`，入口日志 / 定向结果为 `tools/runtime-intake/check-runs/factory-core-outline-v1/`，审阅 JSON / 隔离根为 `tools/runtime-intake/review-worlds/factory-core-outline-v1/<session>/`，均忽略提交。采样只证明指定核心网格的指定点，不当成全身 / 全场景可见率或性能。

## 低投入交互样板

`node tools/factory-content/export-refinement-assets.mjs` 用现有本地 Three.js 导出反应器、节点两件自有 GLB 到 `client/assets/factory/refinement/`，其余资产复用。不替换正式资产，不新增依赖。源与产物 hash、三角形和网格数记录在同目录 manifest。

先告知 Godot 启动，再导入资源：`/Applications/Godot.app/Contents/MacOS/Godot --headless --path client --import --quit --no-header`。手工入口：`bash tools/factory-content/refinement-demo.sh`。它先启动双根隔离 Boot，再挂载独立 demo；不添加正式新世界选项，不读写玩家世界。

预置采集器、电源、仓库，物料从零生产；依次放反应器、节点、铺两段带并观察首件入仓。点击设备看库存 / 进度 / 供电；右键或 Esc 取消建造，R 改带方向，WASD 移动，滚轮缩放，重置按钮重新开始。关闭后不保存。半径 6 格仅为样板参数，人物沿用现有资产；这不是完整正式新手任务、存档规则接入或美术定稿。范围及失败判据见[样板专题](../../docs/features/factory-refinement-demo-v1.md)。

定向无窗口检查（同样先告知启动 Godot）：`/Applications/Godot.app/Contents/MacOS/Godot --headless --path client --script ../tools/factory-content/check-refinement.gd --no-header --log-file ../tools/runtime-intake/refinement-check.log`。覆盖自动电网边界、真实产线与关键 UI 构造 / 布局；不能代替窗口交互和用户亲测。

## 分流 / 汇合资产

`node tools/factory-content/export-routing-assets.mjs` 复用已有 Three.js 与自有几何帮助函数，生成 `client/assets/factory/routing/{splitter,merger}.glb`。均严格位于 1×1 足印内，分流为竖直圆顶壳体，汇合为横向滚筒，配不同方向的入口 / 出口箭头；不下载素材或依赖。manifest 记录源 / 产物 SHA-256、包围盒与网格 / 三角形数。正式世界按 schema 4 / 5 规则加载导入场景；玩法与原图由 `check-factory-routing.sh` 验证，导出成功不代表用户体验或美术定稿。

## 准入口资产

`node tools/factory-content/export-admission-asset.mjs` 沿同一离线 Three.js 流程导出 `client/assets/factory/admission/admission-gate.glb`：1×1 单向窄壳体、后入前出与机械闸口，7 个网格、666 个三角形。manifest 记录源 / 产物 SHA-256 和包围盒；自有 SVG 图标进入建造栏，正式 V5 世界只加载导入资源。未新增依赖或外部资产；玩法、数量和窗口证据由 `check-factory-admission.sh` 另验。

## E1 加工与矿源资产

`node tools/factory-content/export-expansion-assets.mjs` 使用同一既有离线 Three.js，导出粉碎机、精炼炉、组装机及铁 / 炭矿源五个自有 GLB 到 `client/assets/factory/expansion/`，并生成八个 `client/assets/icons/factory_*.svg`。manifest 记录脚本 / 共用源文件与每个产物 SHA-256、包围盒和网格数。新设备足印分别 2×2、2×3、3×2，正式 E1 以导入 Node3D 资产呈现；不下载素材或依赖，不替换旧世界资产。端口预览与物流读取同一数据定义；自然工艺及窗口验证由 `check-factory-expansion.sh` 承担，导出不代表玩法验收。


## E2 能源资产

`node tools/factory-content/export-energy-assets.mjs` 继续使用仓库已有 Three.js 与自有材质，导出 `client/assets/factory/energy/cell_generator.glb` 和 `client/assets/icons/factory_industrial_cell.svg`。G 为 2×2 固定西输入、青绿底座与金色散热环，7 网格 / 1,305 三角形；包围盒不越足印，地面 Y=0。manifest 记录源码、已有 Three.js 版本文件与产物 SHA-256。正式 E2 只载入导入 GLB，图标与原物料格一致；工具不进入运行时、不安装依赖，状态 / 自然用途与窗口证据由 `check-factory-energy.sh` 另验。
