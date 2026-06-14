# Daily Start

更新时间：2026-06-14

## 用途

当提示是“根据项目规划和开发进度，今天要来做什么以推进开发”时，优先阅读本文。

## 阶段

当前为「首版 Demo 体验主干建设：角色成长与战斗第一版」。

重点不再是继续给既有区域追加同类内容包，也不再把基线复核写成下一步主线；当前要补玩家继续玩的体验主干，让基地制造和出发整备能带来明确战斗 / 成长差异。

## 最近收尾

- 早期复测、资源循环、基地行动、窗口复盘、三类模块和高压窗口等前置阶段均已通过检查或短跑。
- 2026-05-27 已完成首版 demo 范围冻结、12 区域封顶、4 个核心区域第一轮重排、UI baseline、核心稳定站终点链路和 `S21` 人工短跑。
- 2026-05-28 `S0` 新档冷启动审计通过；完整 demo 能抵达核心稳定站完成反馈，未发现新的 `P0` / `P1`。
- 2026-06-01 首小时引导可玩 AI 侧收口判断通过；首小时核心区、处理点、过滤器首趟产出、遗迹门前压力和处理点入口收束包均已通过自动检查。
- 2026-06-03 首小时到 Demo 中段节奏衔接收口复核通过；`S1` 到 `S21` 基线和 `check-client` 已支撑主线骨架继续开发。
- 2026-06-04 至 2026-06-08 已补设备面板、HUD 重排、对象反馈、污染过滤、遗迹外圈回波沉积、核心设备写入排压、污染高压点药剂接入和核心稳压缓冲接续。
- 2026-06-09 已停止把试玩前取样、提示审计和静态清单作为主线产出，切到 Demo 可操作内容建设，并完成基础储存箱基建收益包。
- 2026-06-10 已完成出发整备台、基地后勤区 UI、晶体侧路、污染侧翼、污染浆液副产回收口袋和门前准备确认。
- 2026-06-13 已补核心稳定站完成态、出发口复测、双药剂余量、核心归档维护、污染边界回访压力段和回访过滤后的出发整备反馈。
- 2026-06-14 已完成基地后勤路线牌、污染边界复测压力、核心稳定站复测采样、晶体侧路后勤补料回访、基地后勤区补料处理、核心站后勤维护复测压力验证和首版 Demo 可试玩呈现建设包。
- 2026-06-14 阶段口径复核结论：当前内容建设没有偏离长期主线，但同一条核心站归档后回访链继续加厚的收益递减；阶段应转入角色成长与战斗第一版。
- 首版 demo 12 区域封顶；第 12 区域是 `region.demo_stabilization_core / 核心稳定站`。

## 下一步重点

1. 优先做「首版 Demo 角色成长与战斗第一版」：只做 1 到 2 个可感知模块、技能或战斗差异，由基地制造或出发整备台驱动。
2. 优先复用 `building.field_outfitting_station`、`FieldOutfittingRuntime`、`EnemyCounterattackRuntime`、基础过滤模块、校准状态和核心归档维护状态；不做完整装备栏或完整 `loadout`。
3. 差异必须覆盖真实操作路径：制造 / 整备、HUD / 对象反馈、污染或遗迹或核心守卫战斗结果、存档状态和自动检查。
4. 工程上优先整理接近边界的 `vertical_slice_flow_check.gd`、`vertical_slice_map.gd`、`prototype_hud.gd`、`interaction_prompt_formatter.gd` 和相关系统职责，后续新增断言或提示不要继续堆进大文件。
5. 阶段末再判断是否继续扩 1 个成长差异、转入外部试玩，或收束到工程边界拆分；不要把基线复核写成下一步开发主线。

## 当前不做

- 不继续扩前线行动台、候选、窗口复盘、高压窗口或 `base_action_state`，除非出现 `P0` / `P1`。
- 不继续横向新增区域；首版 demo 到 12 个区域封顶。
- 不再默认给核心站完成态追加同构回访口袋；只有试玩证明主线断档时才补内容。
- 不新增随机成功率、新货币、队员、完整装备栏、完整 `loadout`、完整背包重构、联机入口或大规模美术替换。
- 不把完整发布准备、大规模 polish、基线复核或静态审计作为当前阶段目标；当前优先角色成长与战斗差异、真实操作路径和工程边界。

## 放宽口径

- 允许首版 demo 级角色成长与战斗第一版，范围控制在少量明确差异，不扩成完整装备系统。
- 允许为角色成长和战斗反馈调整 UI、场景提示、承压计算和路线节奏，但必须服务真实操作路径和玩家可感知差异。
- 允许拆分检查脚本、地图脚本、提示 formatter 或系统职责，以守住源码行数和维护边界。

## 节奏规则

个人开发阶段只做足以判断方向的完成度。阶段达到退出条件后及时进入下一阶段；不因局部读法、文案密度或状态字段洁癖无限打磨。

只让这些问题阻塞阶段：

- 崩溃
- 主线卡死
- 坏档
- 任务无法完成
- 关键资源断档
- UI 完全无法判断下一步

其他问题进入 backlog 或后续 polish。

## 必读与选读

日常推进必读：

- `docs/planning/current.md`
- `docs/devlogs/` 下最新一期周志中的“风险与未完成项”和“下周建议”

按任务选读：

- Demo 范围与 UI baseline：`docs/planning/demo-scope-and-playable-slice.md`
- 区域和首小时体验：`docs/design/onboarding-and-first-hour.md`
- 开发复测基线：`docs/design/development-retest-baselines.md`
- 代码结构和重构：`docs/architecture/code-style-and-language-practices.md`
- 存档、联机或边界：`docs/architecture/multiplayer-and-save-architecture.md`
- 阶段复核：`docs/planning/milestone-review-checklist.md`

## 验证入口

客户端改动优先执行默认检查：Windows 用 `pwsh ./scripts/check-client.ps1`，macOS / Linux / Git Bash 用 `sh ./scripts/check-client.sh`；该入口不启动 Godot。需要导入工程或运行项目自定义 GDScript 检查时，确认本机 Godot 可启动后加 `-WithGodot` / `--with-godot`。

提交前：Windows 用 `pwsh ./scripts/check-text-files.ps1`、`pwsh ./scripts/check-docs.ps1`；macOS / Linux / Git Bash 用 `./scripts/check-text-files.sh`、`./scripts/check-docs.sh`；最后执行 `git diff --check`。
