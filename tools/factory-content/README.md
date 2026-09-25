# Factory Content Authoring

D1 的正式资源制作与静态场景复核工具；不扩展旧 Web / Godot Demo，不修改游戏存档或模拟规则。

电力模型现已用于正式勘探工厂，D2-A / D2-B 运行时检查另见 [Tools](../README.md#正式工厂定向检查)。本工具保留 D1 静态用途，不因后续玩法接入扩大其证明范围。

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
