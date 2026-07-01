# Demo Base First Screen Raster Art Pack V1

更新时间：2026-07-01

## 用途

本专题接续 [Demo Base First Screen Scene V2](demo-base-first-screen-scene-v2.md)，用于明天重做基地第一屏的贴图素材介质。

结论很明确：问题不只是 `SVG` 文件格式，而是当前首屏缺少真正的美术贴图、材质细节、设备 sprite 和环境边缘资产。继续用 `Polygon2D`、半透明矢量块或线稿 SVG 拼装，会让画面继续像示意图。

## 闸门来源

- `DemoPlayableSceneRebuildLayer` 已判定为部分通过，但不再作为观感主线。
- `DemoBaseFirstScreenSceneLayer` 能承载独立首屏和压低旧层，但程序几何与 SVG 拆分素材仍缺乏贴图质感。
- 整张效果图不能作为实机底图；参考图只能用来提炼资产需求、构图和材质方向。

## 玩家价值

- 新档第一眼应像受损异星工业前哨，而不是矢量地图或 UI 规划图。
- 玩家能从地面、设备、管线、阴影、污染和晶体边缘理解自己所处的基地场景。
- HUD 只确认当前目标，不负责解释画面是什么。

## 本轮范围

1. 生成并接入低保真 raster 贴图 / sprite：
   - 浅色异星岩地地表贴图。
   - 金属设备底座 / 地台。
   - 损坏前哨核心。
   - 基础反应器。
   - 储存箱组。
   - 整备台 / 工具架。
   - 短管线和接口。
   - 右侧晶体岩壁与污染渗漏边缘。

2. 复用现有运行时：
   - 不改任务、资源、配方、敌人或存档字段。
   - 不改现有交互对象和碰撞职责。
   - 只替换首屏主画面素材介质和装配方式。

3. 控制旧层职责：
   - `DemoBaseFirstScreenSceneLayer` 继续承载首屏范围、旧层降权和现有交互聚焦。
   - 程序几何只保留为阴影、状态灯、端口高亮和检查辅助。
   - SVG 可保留给 HUD 图标、状态描边或开发辅助，不再承担主画面。

## 实现记录

2026-07-01 已完成首屏 raster 素材包第一版：

- 新增 `tools/generate_demo_first_screen_raster_assets.py`，用标准库生成可复现的低保真 PNG 分件和 Godot import 元数据。
- `client/assets/sprites/demo_first_screen/` 新增岩地、设备底座、管线、晶体岩壁、污染渗漏、前哨核心、反应器、储存、整备台和晶体边缘 10 个首屏专用 PNG。
- `DemoBaseFirstScreenSceneLayer` 的主 sprite manifest 已切到 PNG；旧 `Polygon2D` / 程序几何只承担阴影、端口、状态灯和检查辅助。
- 本包继续复用既有任务、交互对象、碰撞、资源、配方、敌人和存档字段。

## 当前不做

- 不把参考效果图整图导入工程作为背景。
- 不新增区域、任务、资源、配方、敌人、存档字段或完整最终美术管线。
- 不继续围绕透明度、边框、线宽、色块、截图点做同类修补。
- 不扩到污染处理、核心稳定站或全地图重绘。

## 玩家操作路径

```text
新档进入基地
-> 看到贴图化的岩地、设备、管线和环境边缘
-> 玩家站在核心附近
-> 靠近前哨核心或反应器
-> 执行一次现有交互
-> 通过设备局部反馈确认基地恢复动作
```

## 验收条件

- 默认截图中，首屏主读法来自 raster 贴图 / sprite，不是矢量色块或整图参考底图。
- 地面有材质噪声、碎石、磨损或明暗细节，不再像一整块平面色板。
- 核心、反应器、储存和整备台有设备体积、材质和阴影差异。
- 右侧晶体 / 污染边缘读成环境上下文，而不是 UI 装饰层。
- 玩家仍能移动，并完成一次现有交互。

## 验证记录

2026-07-01：

- `./scripts/check-client.sh`
- `./scripts/check-client.sh --with-godot`
- Godot 图形截图复核：默认首屏主读法已由 PNG 岩地、设备、管线和阴影承担；右侧晶体 / 污染保留为边缘上下文。

## 验证计划

- `./scripts/check-client.sh`
- 涉及 Godot 资产导入和运行时接入时执行 `./scripts/check-client.sh --with-godot`
- 文档改动执行 `./scripts/check-docs.sh`、`./scripts/check-text-files.sh` 和 `git diff --check`
- 最终结论以一次实机截图和人工观感判断为主，自动检查只证明接线未断。
