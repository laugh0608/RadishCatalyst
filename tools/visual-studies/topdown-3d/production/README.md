# Godot Production Line Demo

本目录在既有独立 Godot 工程中复现已认可的 Web 三机固体产线。功能合同见 [Godot First Production Line Demo V1](../../../../docs/features/godot-first-production-line-demo-v1.md)。无正式客户端依赖和游戏存档，关闭即重置。

## 启动

仓库根目录运行：

```sh
sh tools/run-topdown-3d-demo.sh --production
```

启动器默认使用 `/Applications/Godot.app/Contents/MacOS/Godot`，其他现有安装可通过 `GODOT_EXE` 指定。首次获取资源后，应先用该 Godot 对 `tools/visual-studies/topdown-3d/` 执行 `--headless --import --quit`。原无参数入口仍打开旧视觉样件，Web `/play/` 保留。

- WASD / 方向键移动，点空地移动；建造状态可移动。
- 1–4 选择构件，点击放置；传送带按住拖动、松开提交，回拖缩短。下方 X / Z 与“放置”支持精确落位。
- R 转带向，Q / E 转相机，滚轮缩放；Esc 依次取消拖铺、构件、详情、建造。
- 点设备或带查看真实状态；拆回构件与全部货物，回收物可通过设备面板投入。
- 手动暂停 / 失焦停止生产，没有后台补产；“重新开始”需要在界面确认。

## 文件职责

| 文件 | 职责 |
| --- | --- |
| `model.gd` | 有限生产状态、拓扑、守恒、拖铺与移动规则 |
| `app.gd` | 独立入口、输入、暂停、重开与场景协调 |
| `hud.gd` | Godot 控件、建造栏、详情和目标显示 |
| `view.gd` | 导入模型、50° 相机、光影、货物轨迹与几何选取 |
| `assets/` | 从仓库内 Web 自制模型导出的 glTF 及来源校验清单 |
| `export-web-assets.mjs` | 使用既有 Web Three.js 导出同一套几何，不下载或修改 Web |
| `verify-parity.mjs` / `verify-model.gd` | Web 生成操作与期望值，Godot 独立重放比较 |
| `verify-window.gd` / `verify-navigation.gd` | 产线输入链、正常时间生产、人物碰撞 / 取消与截图 |

重新导出资源：`node tools/visual-studies/topdown-3d/production/export-web-assets.mjs`。只有 Web 源几何确实更新时才重建，随后导入并复核截图；不得用过期导出冒称与 Web 同源。

## 检查

```sh
sh tools/check-godot-production-demo.sh
sh tools/run-topdown-3d-demo.sh --verify-production
sh tools/run-topdown-3d-demo.sh --verify-navigation
```

运行 Godot 前按仓库约定先告知。定向检查涵盖同输入状态、拆回、回压、恢复、争用、守恒与弯道；窗口检查通过合成输入事件操作真实入口，不写隐藏生产状态。输入链证据仍需逐张查看截图，最终手感由用户亲测。补充检查中的失焦分支使用窗口信号，重开确认 / 取消使用可见按钮 `pressed` 信号；其余放置、移动与产线操作使用输入事件。

测试夹具、结果和日志在 `tools/runtime-intake/check-runs/godot-production-line/`；窗口截图在 `assets/art-intake/2026-09-08-godot-production-line-preview/`。这些目录均忽略提交。GLB 为仓库自制网格，无第三方资产包；本机测试只能说明三机小场景，不能外推大型工厂或其他硬件。
