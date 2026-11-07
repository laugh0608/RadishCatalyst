# Client

RadishCatalyst Godot 客户端工程目录。

当前工程使用普通版 Godot 4.x 初始化，首版脚本默认使用 GDScript。核心游戏主平台为 Windows 桌面版，Web 技术验证和 Android 仅保留后续评估空间。

## 目录职责

- `data/`：静态配置数据，例如物品、配方、建筑、敌人、区域、天气和任务。
- `scenes/`：Godot 场景文件。
- `scripts/`：GDScript 代码，按状态、系统、角色、地图、基地、存档和 UI 拆分。
- `assets/`：客户端运行所需的图像、瓦片、图标、音频、shader 与导入模型；工厂模型位于 `assets/factory/`。
- `ui/`：可复用 UI 资源或主题文件。
- `save/`：存档 schema、迁移脚本和本地存档相关资源。
- `tests/`：后续 Godot 侧测试或验证入口。

## 正式入口与工厂边界

`scenes/boot/Boot.tscn` 的启动菜单同时保留旧二维世界，并提供“工厂世界”入口。三维工厂的配置、场景、脚本与资产分别位于各自的 `factory/` 子目录；状态和文件发布见 `scripts/factory/model.gd`、`scripts/factory/save/`。

工厂使用独立 `user://saves/factory/worlds/`。正式菜单提供默认基础工厂（schema 1）、勘探工厂（schema 5）、生产扩建 E1（schema 6）、能源循环 E2（schema 8），以及「整合工厂 · 核心研究与固定燃烧」（schema 9）。旧 2 / 3 / 4 可继续原规则及显式逐级升级；旧 V7 可按旧规则继续，E1 / V7 仅经显式复制创建独立 V8，保留来源。旧二维 schema 10 及其目录保持独立。

D1 开拓工厂（schema 10）及 D2 核心 III、独立储能、节拍调度（schema 11–13）从对应调试隔离入口创建与继续。运行检查注入二维与工厂两个隔离根。亲测与自动检查分别存放。见[整合存档合同](../docs/architecture/factory-integrated-demo-save-v1.md)及[定向入口](../tools/README.md#正式工厂定向检查)。

详细结构见 [Godot Project Structure](../docs/architecture/godot-project-structure.md)，共用文件协议见 [Factory World State And Save V1](../docs/architecture/factory-world-state-and-save-v1.md)，能源与复制见 [V7](../docs/architecture/factory-energy-save-v7.md) / [V8](../docs/architecture/factory-energy-save-v8.md)。当前功能、验证结果与保留项以 [Current Plan](../docs/planning/current.md)及活跃专题为准；定向运行命令见 [Tools](../tools/README.md)。客户端 Godot 检查不自动代表自然 Boot、窗口、玩家体验或规模性能通过。

`client/scripts/prototypes/factory_refinement/` 与 `assets/factory/refinement/` 承载[低投入交互样板](../docs/features/factory-refinement-demo-v1.md)：通过工具启动双根隔离 Boot 后挂载，复用真实生产模型但仅在内存派生范围供电。它不是正式工厂菜单选项，不接入 Store / codec；样板自身不替换正式玩法；正式设备交互与自动供电以当前专题为准，启动方式见 [Factory Content](../tools/factory-content/README.md)。

`scripts/prototypes/factory_camera/` 承载 R1-A 镜头、R1-B 核心轮廓与 R1-C / D 材质对照。经各自准备页在隔离 Boot 运行，默认 C2 / 21 格 / 跟随。四面 16 口的 `outline-06` 和材质代表品质已获认可。正式整合加载获认可的核心轮廓，并使用 C2 跟随镜头。样板入口和证据见 [Factory Content](../tools/factory-content/README.md)。
