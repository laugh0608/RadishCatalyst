# Current Plan

更新时间：2026-06-30

## 入口约束

本文是新会话的阶段入口，只保留当前阶段、当前活跃专题、边界、验证入口和退出条件。首版 Demo 完成规格以 [Demo Definition V1](../features/demo-definition-v1.md) 为准，具体开发范围以当前活跃专题为准：

- 当前活跃专题：[Demo First Playable Slice Assembly V1](../features/demo-first-playable-slice-assembly-v1.md)，覆盖首版 Demo 20 到 30 分钟可玩纵切装配。
- 当前执行线：[Demo Playable UI And Art Pass V1](../features/demo-playable-ui-and-art-pass-v1.md)（当前细专题：[Demo Base First Screen Raster Art Pack V1](../features/demo-base-first-screen-raster-art-pack-v1.md)，最近暂停：[Demo Base First Screen Scene V2](../features/demo-base-first-screen-scene-v2.md)）、[Demo Core Loop Playable V1](../features/demo-core-loop-playable-v1.md)、[Demo Narrative Beats V1](../features/demo-narrative-beats-v1.md)。
- 视觉承接：[Demo Industrial Base Visual And Scene V1](../features/demo-industrial-base-visual-and-scene-v1.md) 的未完成观感问题并入 UI / Art pass，不再作为单点截图微调主线。
- 参考视觉源：[Visual And UI Direction](../product/visual-and-ui-direction.md)。

历史过程、长完成清单和详细复盘优先查看：

- `docs/planning/daily-start.md`
- `docs/devlogs/README.md` 中列出的最新一期周志
- `docs/planning/demo-scope-and-playable-slice.md`
- `docs/design/development-retest-baselines.md`

## 阶段状态

已通过：

- `S0` 早期复测、资源循环、基地行动、窗口复盘、装备与战斗反哺基地原型。
- 首版 Demo 范围冻结、12 区域封顶、UI baseline、核心稳定站终点链路和早期链路审计。
- 2026-06-14 至 2026-06-19：可操作场景对象、运行逻辑、玩家反馈、存档来源、自动检查、角色 / 战斗、路线、资源链、功能场景、设备面板、初步美术识别和外勤任务差异均已落地第一包。
- 2026-06-19：撤回“自动检查通过即可进入验收”的判断，确认第一包与检查证据不足以证明玩家可试玩质量。
- 2026-06-20 至 2026-06-29：基地工业视觉、HUD 层级、第一条工业链、污染链、核心稳定站完成态、核心循环短节奏、叙事节拍场景证据、启动界面、首屏资产化、晶体工作面资产化、基地交接专用工作面和 Demo 结尾钩子已完成多轮玩家可见推进；阶段复核显示项目应从单点读法修补切到可玩纵切装配。

当前阶段：

```text
首版 Demo 可玩纵切装配第一版
```

当前推进口径：先让默认画面像一款可玩的 2D / 2.5D 工业科幻 ARPG，而不是 debug 流程图、色块地图或截图定位图层。连续截图复核显示矢量 / 程序几何方案仍缺少贴图质感；当前主线切到基地首屏 raster 贴图 / sprite 素材包。

## 当前主线

当前活跃专题是 [Demo First Playable Slice Assembly V1](../features/demo-first-playable-slice-assembly-v1.md)。它优先装配这条路径：

```text
前哨核心恢复 -> 晶体矿脉手采 -> 回基地入料 -> 基础反应器加工
-> 采集 / 过滤设备接管重复产出 -> 整备获得补给 / 模块收益
-> 污染边界短挑战 -> 核心稳定站写入 -> Demo 结尾钩子
```

三条执行线：

- UI 与低保真美术：停止把基地交接 #2 / #3、`DemoPlayableSceneRebuildLayer` 或 V2 矢量拆分截图微调作为主线；下一步生成并接入基地首屏 raster 贴图 / sprite，让角色、地面、核心设备、反应器、储存和整备台先像游戏场景。
- 核心循环：让采集、加工、设备启用、整备、污染承压、短战斗和核心写入形成可操作的前后接力。
- 叙事节拍：用开场事故、基地恢复、污染信号、核心稳定、场景证据和结尾悬念替代任务表式推进。

体验主干建设尚未达到试玩准备判断标准；真实页面 smoke、自动检查和人工实机复测只能提供证据，不能替代可玩路径装配。

## 区域策略

- 首版 Demo 继续按 12 区域封顶。
- 当前只把基地、晶体矿脉、污染边界和核心稳定站作为可玩纵切核心区。
- 4 个功能区和 4 个过渡区只保留必要连接、资源、风险或稳定工程价值，不平均加厚。
- 如果 12 区层级继续压垮画面和节奏，优先保证 4 个核心区的玩家可读性。

## 视觉与 UI 策略

- 首版 Demo 不能以 `ColorRect + Label`、`draw_line` / `draw_rect` 叠线或 debug 流程图作为可试玩画面目标。
- HUD 要像游戏 UI，不像开发面板；开发基线、GM 控件和长说明默认隐藏或折叠。
- 低保真允许，但玩家、敌人、设备、资源、污染和核心目标至少要有轮廓、材质色、状态和用途关系。
- 当前 UI / Art 优先级是低保真游戏画面成型：角色、设备、地面贴图、材质、阴影、空间层次和操作动作反馈优先于截图点、透明度、线框、状态字段或设备面板字段。
- 场景内提示优先使用高亮、短标签、图标或描边，避免大字遮挡玩家操作。

## 冻结与放宽

继续冻结：

- 前线行动台、候选、窗口复盘、高压窗口和 `base_action_state` 保持冻结，只修 `P0` / `P1`。
- 不新增第 13 区域，不平均扩 12 个区域，不继续给核心站完成态追加同构回访口袋。
- 不新增随机成功率、新货币、队员、完整装备栏、完整 `loadout`、完整背包重构、联机入口或完整长期成长系统。
- 不把试玩准备、修 bug 阶段、发布准备或大规模 polish 作为当前阶段目标。

允许推进：

- 低保真资产、正式 HUD 第一版、核心设备轮廓、管线 / 物流 / 介质流向、核心路径场景和短反馈。
- 重建 1 到 2 屏真实可玩场景，把旧色块和规划层退为开发辅助。
- 围绕纵切路径补真实操作、状态表现、UI 反馈和叙事节拍。
- 必要时新增窄职责 helper、presenter 或 check，但只能支撑可见实现，不能成为开发包主体。

## 节奏规则

当前阶段的进展以玩家可见体验为准：没有场景、角色、敌人、设备、地面、操作、反馈或叙事节拍结果的文本、formatter、检查和“第一包”不算主线完成。

默认画面仍不像游戏时，不把下一步切到完整路径体感复核、读法整理、UI 字段整理、设备面板字段整理、纯检查补充或同类线框叠层；这些工作只有在支撑资产化场景成型时才进入范围。

每个开发包开工前先说明实机里会看到什么、玩家会做什么、完成后玩家能理解什么。收口时优先用实机跑通和截图 / 录像观感判断，再补文档与检查。

只让这些问题阻塞阶段：崩溃、主线卡死、坏档、任务无法完成、关键资源断档、UI 完全无法判断下一步，或首屏 / 基地平台仍主要表现为 debug 色块和长文本。

## 当前默认验证

客户端相关改动优先执行默认检查：Windows 用 `pwsh ./scripts/check-client.ps1`，macOS / Linux / Git Bash 用 `sh ./scripts/check-client.sh`；该入口不启动 Godot。需要导入工程或运行项目自定义 GDScript 检查时，确认本机 Godot 可启动后加 `-WithGodot` / `--with-godot`。

涉及文档、规划、协作规则或仓库入口时额外执行：Windows 用 `pwsh ./scripts/check-docs.ps1`、`pwsh ./scripts/check-text-files.ps1`；macOS / Linux / Git Bash 用 `./scripts/check-docs.sh`、`./scripts/check-text-files.sh`；最后执行 `git diff --check`。

## 阶段退出条件

- [Demo First Playable Slice Assembly V1](../features/demo-first-playable-slice-assembly-v1.md) 的 20 到 30 分钟路径能从新档跑到 Demo 结尾钩子。
- 玩家至少完成一次采集、一次加工、一次设备启用或建造、一次整备收益、一次污染 / 战斗承压和一次核心写入。
- HUD 默认画面不被开发面板主导，基地、晶体、污染、核心站四个核心区能被快速识别。
- 玩家能复述“基地让我走得更远，远征让我把基地建得更强”。
- 后续再重新启动 [Demo First Playable Acceptance V1](../features/demo-first-playable-acceptance-v1.md)，由人工实机体验和自动检查共同判断是否进入试玩准备。
