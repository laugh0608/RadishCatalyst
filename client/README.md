# Client

RadishCatalyst Godot 客户端工程目录。

当前工程使用普通版 Godot 4.x 初始化，首版脚本默认使用 GDScript。核心游戏主平台为 Windows 桌面版，Web 试玩和 Android 仅保留后续评估空间。

## 目录职责

- `data/`：静态配置数据，例如物品、配方、建筑、敌人、区域、天气和任务。
- `scenes/`：Godot 场景文件。
- `scripts/`：GDScript 代码，按状态、系统、角色、地图、基地、存档和 UI 拆分。
- `assets/`：客户端运行所需的图像、瓦片、图标、音频和 shader。
- `ui/`：可复用 UI 资源或主题文件。
- `save/`：存档 schema、迁移脚本和本地存档相关资源。
- `tests/`：后续 Godot 侧测试或验证入口。

详细分层规则见 `docs/architecture/godot-project-structure.md`。
