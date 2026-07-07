# Demo Presentation Rebuild V1

更新时间：2026-07-07

状态：当前活跃执行专题；2026-07-07 `R0` 代码基线已推进，等待新档第一分钟截图序列复核。

## 背景与问题

2026-04 至 2026-07 期间，表现层先后使用 `draw_rect` 叠线、SVG 分件、`Polygon2D` 拼装和脚本生成 PNG 四代介质，共堆积约 20 个视觉层脚本、1.5 万行绘制代码，层与层以"降权"方式共存。多轮截图复核证明这条路线的上限是示意图：画面始终读成流程图与色块，而不是游戏。

2026-07-02 项目级复盘判定失败根因是介质而不是执行：代码生成美术无法跨过"像一款游戏"的门槛。本专题把表现层一次性切换到"真实资产 + 引擎场景组合"，并按包删除旧视觉层。

## 玩家价值

- 看到：真实贴图的岩地与金属平台、有体积和材质的设备、有形象的角色和敌人。
- 做：与之前完全相同的纵切操作——修核心、采晶体、入料加工、整备、抗污染、写入核心。
- 理解：这是一款 2D 工业科幻 ARPG，而不是规划板。

## 素材来源

- 主管线：AI 生成，提示词与风格规范见 [AI Art Prompt Library](../reference/ai-art-prompts.md)。
- 补位与兜底：CC0 免费素材包，见 [Free Asset Pack Candidates](../reference/free-asset-pack-candidates.md)；角色行走动画优先由素材包承担。
- 风格锚点定稿存 `assets/reference/style-anchor.png`，是所有生成批次和截图复核的唯一参照。

## 范围与分包（串行推进）

### P0 素材锚定包

- 提示词库与素材目录已建立（本包文档部分已完成）。
- 萝卜SAMA 生成第一批基础反应器候选，审阅定稿风格锚点。2026-07-04 已定稿 `a0_reactor_v4`。
- 第二批首屏核心设备与第三批地面 tile 已通过审阅；主候选已处理到 `client/assets/sprites/demo_presentation_rebuild/` 与 `client/assets/tiles/demo_presentation_rebuild/`。
- 下载评估 1 到 2 个 CC0 素材包作为角色补位与兜底；该项不阻塞已审定设备 / 地面进入 P1。
- 出口：锚点定稿，第二、三批核心素材通过审阅并形成可提交运行时资产。

### P1 首屏重建包

- 用 `TileMapLayer` 铺基地首屏地面：异星岩地 + 金属平台，tile 64px。
- 前哨核心（受损 / 修复）、基础反应器、储存、整备台、过滤器改为独立小场景：`Sprite2D` 主体 + 状态灯节点 + 既有交互组件，编辑器内摆放。
- 玩家挂真实 sprite，移除 `player_controller.gd` 的 `_draw()` 绘制；敌人同理。
- 首屏范围内关闭全部旧视觉层。
- 出口：新档首屏截图对比锚点参考成立。
- 2026-07-05 进度：首屏核心区主体、玩家可见性和真实资产主读法已成立；后续不继续围绕首屏做同类调参。
- 2026-07-06 复盘：实机截图证明"资产已接入"不等于"首分钟成立"；设备堆叠、旧语义轮廓、HUD 截断和交互范围仍破坏玩家读法。

### R0 首分钟体验重基线包

- 暂停 `P2` 录像与 `P3` 删除收口，不再把单张定点截图当作阶段通过证据。
- `Boot` / `GameRoot` / 地图链路是正式项目入口，Godot 打开主场景不能只看到空壳节点；不新增临时工作台场景名来绕开正式项目。
- 开局只保留玩家、损坏前哨核心和少量环境道具；基础反应器、储存、整备台、过滤器、采集器和控制台不得一开始挤在首屏。
- 修复核心后，下一步必须能在场景中看到晶体簇，并以晶体 / 残骸采集作为明确目标。
- 修复核心后，晶体路径需要同步出现路径道具、工作灯和残骸提示，避免下一目标只靠 HUD 文案成立。
- 旧规划色块、旧 art pass、交互物语义轮廓先硬禁用，后续 `P3` 再删文件和修剪检查。
- 收紧交互范围；玩家不站到目标前方时不应提前弹出交互提示。
- 当前目标优先交互覆盖"恢复前哨"和"勘探晶体矿脉"，但远距离目标仍必须在玩家朝向前方。
- HUD 先收束为可读的目标、状态和当前交互提示，不继续堆小字。
- 角色首版不要求完整动画组，但静态 sprite 不得按方向整张旋转；先用固定朝向 / 翻转 / 轻微步态摆动替代。
- 出口：新档第一分钟截图序列能读成"损坏核心 -> 修复 -> 去晶体矿脉采集"，且没有旧流程图色块突然出现。
- 2026-07-07 进度：正式入口可见、旧层硬禁用、过早设备显隐、晶体路径视觉和晶体任务目标选择已接入；下一步必须用实机截图序列复核。

### P2 三区扩展包

- 晶体矿脉、污染边界、核心稳定站换用同一资产家族：地面变体 tile、晶体簇、污染贴花、核心稳定站主体。
- 出口：四个核心区截图对比成立，录制第一段 60 秒实机录像。
- 2026-07-05 进度：晶体 / 污染地面、远场采集器 / 过滤器和核心稳定站主体已接入；当前只补三区定点截图证据，失败时只收束对应场景摆位、范围和可读性。
- 2026-07-06 复判：2 / 5 / 6 号定点截图不能代表连续体验成立；待 `R0` 通过后再重做路径截图 / 录像判断。

### P3 旧层清除收口包

- 删除旧视觉层脚本与对应场景节点、`sprite manifest` 和生成脚本 `tools/generate_demo_first_screen_raster_assets.py`。
- 修剪因删层失效的检查脚本；不新建检查。
- 出口：`client/scripts/map/` 只保留运行时与新表现结构，行数账目写入周志。

## 旧层处置清单

先硬禁用，后续 `P3` 删除（纯视觉层、历代 art pass 与交互语义轮廓）：

`demo_initial_art_identity_layer`、`prototype_visual_priority_layer`、`demo_industrial_base_visual_layer`、`demo_crystal_resource_visual_layer`、`demo_pollution_boundary_visual_layer`、`demo_core_stabilization_visual_layer`、`demo_first_industrial_path_visual_layer`、`demo_first_industrial_path_handoff_art_pass`、`demo_crystal_workface_asset_art_pass`、`demo_base_handoff_asset_art_pass`、`demo_playable_scene_rebuild_layer`、`demo_base_first_screen_scene_layer`、`demo_base_first_screen_art_pass`、`demo_base_startup_presentation_layer`、`demo_default_path_asset_language_art_pass`、`demo_scene_focus_depth_layer`、`demo_region_industrial_value_layer`、`demo_core_scene_space_layer`、`demo_pollution_short_challenge_readiness_art_pass`、`demo_pollution_to_core_handoff_art_pass`、`demo_base_completion_outcome_art_pass`。

保留并逐步瘦身（承担玩法与运行时职责）：

`vertical_slice_map` / `vertical_slice_map_surface`（场景承载结构）、`current_objective_guidance_layer`（目标指引，改为轻量高亮）、`interactable_target_selector` / `interactable_visual_refresher`（交互反馈）、`enemy_counterattack_runtime`、`phase_well_frontier_runtime`。

`VerticalSliceMap.tscn` 中的旧 `ColorRect` / `Polygon2D` 装饰节点随 `R0` 先硬禁用，后续 `P3` 分区清除。

## 不做

- 不新增玩法、区域、资源、任务、配方、敌人种类或存档字段。
- 不新增临时工作台、临时 Demo 场景或一次性编辑器专用入口；编辑器可见性必须回到正式场景。
- 不新增 `client/scripts/checks/` 检查脚本文件；只维护已有检查或修剪失效检查。
- 不做完整动画组；角色首版允许静态 sprite + 程序位移与旋转。
- 不追最终美术质量；目标是"低保真但成立的游戏画面"。
- 不新增程序绘制视觉层、脚本生成贴图或色块拼装作为画面主介质。

## 验收与证据

- 每个包收口做一次实机截图，对比 `assets/reference/style-anchor.png` 给出具体差距清单；同一实现方式最多重试一次，仍失败升级为素材 / 介质决策。
- `R0` 当前以新档第一分钟截图序列为主证据；未通过前不恢复 `P2` 录像。
- P2 起每周录制 60 秒实机录像作为唯一主进度证据。
- 自动检查只兜底资源加载、场景引用和主线可完成。
- 专题出口：四核心区真实资产渲染、玩家敌人有 sprite 形象、旧层删除完毕、录像可被不了解项目的人识别为一款 2D 工业科幻游戏。

## 取代关系

本专题取代以下专题的未尽事项，相关文档保留作历史记录，不再单独推进：

- `demo-playable-ui-and-art-pass-v1`（执行线整体并入）
- `demo-base-first-screen-asset-quality-pass-v1`
- `demo-base-first-screen-raster-art-pack-v1`
- `demo-base-first-screen-scene-v2`
- `demo-playable-scene-rebuild-v1`
- `demo-first-screen-assetized-scene-v1`
- `demo-crystal-workface-assetized-scene-v1`
- `demo-base-handoff-assetized-scene-v1`
- `demo-industrial-base-visual-and-scene-v1`（视觉余项）

核心循环与叙事节拍专题（`demo-core-loop-playable-v1`、`demo-narrative-beats-v1`）在本专题期间挂起，重建完成后恢复。
