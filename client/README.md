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

工厂使用独立 `user://saves/factory/worlds/` 与 schema 1，旧二维 schema 10 及其目录保留；不自动转换。运行检查须注入两个隔离存档根，不能直接使用用户正式档。纯状态 / 存档检查已接入客户端 Godot 模式，窗口和持续负载需按专题单独执行。

详细结构见 [Godot Project Structure](../docs/architecture/godot-project-structure.md)，当前功能与验收状态见 [Factory Foundation And Persistence V1](../docs/features/factory-foundation-and-persistence-v1.md)，状态与存档合同见 [Factory World State And Save V1](../docs/architecture/factory-world-state-and-save-v1.md)。
