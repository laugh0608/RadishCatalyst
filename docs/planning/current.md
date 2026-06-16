# Current Plan

更新时间：2026-06-16

## 入口约束

本文是新会话的阶段入口，只保留当前阶段、当前活跃专题、边界、验证入口和退出条件。首版 Demo 完成规格以 [Demo Definition V1](../features/demo-definition-v1.md) 为准，具体开发范围以当前活跃专题、最近完成细专题和下一次新建 / 切换的执行细专题为准：

- [Demo Functional Transition Route Support V1](../features/demo-functional-transition-route-support-v1.md)
- [Demo Combat Progression V1](../features/demo-combat-progression-v1.md)
- [Demo Tool Strike Calibration V1](../features/demo-tool-strike-calibration-v1.md)
- [Demo Protective Response V1](../features/demo-protective-response-v1.md)
- [Demo Scene Art Foundation V1](../features/demo-scene-art-foundation-v1.md)
- [Demo Mainline Completion V1](../features/demo-mainline-completion-v1.md)
- [Demo Industrial Tech Spine V1](../features/demo-industrial-tech-spine-v1.md)
- [Demo Character Kit V1](../features/demo-character-kit-v1.md)
- [Ruin Outer Ring Module Pressure V1](../features/ruin-outer-ring-module-pressure-v1.md)

历史过程、长完成清单和详细复盘优先查看：

- `docs/planning/daily-start.md`
- `docs/devlogs/README.md` 中列出的最新一期周志
- `docs/planning/demo-scope-and-playable-slice.md`
- `docs/design/onboarding-and-first-hour.md`
- `docs/design/development-retest-baselines.md`

`AGENTS.md` 和 `CLAUDE.md` 只保留长期协作约束与稳定入口引用；当前阶段、当前不做、当前验证重点和退出条件统一以本文和当前活跃专题为准。

## 阶段状态

已通过：

- `S0` 早期复测、资源循环、基地行动、窗口复盘、装备与战斗反哺基地原型。
- 首版 Demo 范围冻结、12 区域封顶、UI baseline、核心稳定站终点链路和早期链路审计。
- 首小时引导、首小时到 Demo 中段节奏衔接、基地后勤、出发口、污染边界、晶体侧路和核心稳定站复测内容。
- 2026-06-14：「首版 Demo 可玩内容建设推进」达到收束条件；现有路线已有可操作场景对象、运行逻辑、玩家反馈、存档来源和自动检查证据。
- 2026-06-16：「角色成长与战斗第一版」达到阶段退出条件；战术扫描、防护响应、工具校准、污染 / 遗迹 / 核心承压差异、HUD / 对象反馈、状态和专项检查已形成闭环。

当前阶段：

```text
首版 Demo 体验主干建设：功能 / 过渡路线支撑第一版
```

当前推进口径从角色成长 / 战斗差异，切到非核心功能区和过渡区的路线支撑：玩家必须能读懂封锁遗迹、裂相脊、回声台地、锚定桥和四个过渡区的路线连接、当前危险与回基地理由。

## 当前主线

当前活跃专题是 [Demo Functional Transition Route Support V1](../features/demo-functional-transition-route-support-v1.md)。本轮覆盖封锁遗迹、裂相脊、回声台地、锚定桥的机制展示，以及盐壳浅滩、碎晶沟谷、风蚀管廊、锁相框架的路线连接、当前危险、回基地理由、HUD / 对象反馈和专项检查。

角色成长与战斗第一版已收束；后续不继续加厚工具打击校准、防护响应、主线完成感、战术扫描、污染边界、遗迹外圈、工业主干或核心场景同一读法点。若后续扩到新角色动作、装备状态或战斗压力，必须另建非重复细专题。

首版 Demo 未完成初步阶段的完整玩法、场景和美术前，不进入试玩准备或修 bug 阶段。真实页面 smoke 可以用于对比开发效果，但不能替代功能、场景和玩法专题推进。

## 区域策略

- 首版 Demo 继续按 12 区域封顶。
- 4 个核心区域、4 个功能区域、4 个过渡区域不再平均加厚。
- 只修阻塞理解、主线连续性、功能闭合或场景表达的断点。

## UI 策略

UI 和场景表现已完成第一轮原型呈现支撑。当前 UI 改动只服务当前活跃专题：非核心区域的路线职责、当前危险、可观察收益和回基地理由要自然出现在 HUD、地图路线和对象反馈里。

不做完整菜单、设置页、背包大重构、完整装备栏、动画过场或大规模美术替换。

## 冻结与放宽

继续冻结：

- 前线行动台、候选、窗口复盘、高压窗口和 `base_action_state` 保持冻结，只修 `P0` / `P1`。
- 不新增第 13 区域，不平均扩 12 个区域，不继续给核心站完成态追加同构回访口袋。
- 不新增随机成功率、新货币、队员、完整装备栏、完整 `loadout`、联机入口或完整长期成长系统。
- 不把试玩准备、修 bug 阶段、发布准备或大规模 polish 作为当前阶段目标。
- 不迁移稳定数据 ID；旧 ID 先作为存档、任务和数据兼容层保留。

允许推进：

- 当前活跃专题内的功能 / 过渡区域路线支撑、对象提示、HUD / 地图读法和专项检查。
- 必要时新增窄职责 formatter、presenter helper 或专项 check，避免继续推高接近硬上限的大文件。
- 只修阻塞主线连续性、功能闭合或区域表达的断点。

## 节奏规则

个人开发阶段只做足以判断方向的完成度。一个阶段达到退出条件后，必须及时进入下一阶段；不允许因为 `P2` / `P3` 细节、局部读法、文案密度或状态字段洁癖无限打磨。

只让这些问题阻塞阶段：

- 崩溃
- 主线卡死
- 坏档
- 任务无法完成
- 关键资源断档
- UI 完全无法判断下一步

其他问题进入 backlog 或后续 polish。

## 当前默认验证

客户端相关改动优先执行默认检查：Windows 用 `pwsh ./scripts/check-client.ps1`，macOS / Linux / Git Bash 用 `sh ./scripts/check-client.sh`；该入口不启动 Godot。需要导入工程或运行项目自定义 GDScript 检查时，确认本机 Godot 可启动后加 `-WithGodot` / `--with-godot`。

涉及文档、规划、协作规则或仓库入口时额外执行：

Windows 用 `pwsh ./scripts/check-docs.ps1`、`pwsh ./scripts/check-text-files.ps1`；macOS / Linux / Git Bash 用 `./scripts/check-docs.sh`、`./scripts/check-text-files.sh`；最后执行 `git diff --check`。

## 阶段退出条件

- [Demo Functional Transition Route Support V1](../features/demo-functional-transition-route-support-v1.md) 覆盖 4 个功能区和 4 个过渡区的路线职责、当前危险和回基地理由。
- HUD、地图和对象提示至少各有一处能读出非核心区域支撑口径，并有专项检查覆盖。
- 未引入第 13 区域、独立支线网、新资源、新敌人类型、完整装备栏、行动台或高压窗口扩展。
- 新增检查和读法优先走独立文件；接近 1500 行硬上限的检查 / 地图 / HUD / 提示脚本不得继续膨胀。
