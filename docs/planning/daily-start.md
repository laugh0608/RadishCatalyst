# Daily Start

更新时间：2026-06-24

## 用途

当提示是“根据项目规划和开发进度，今天要来做什么以推进开发”时，优先阅读本文。

本文只提供日常入口和读取顺序；阶段方向以当前活跃专题为准，每日代码范围以当前执行包为准。

## 阶段

当前为「首版 Demo 可玩纵切装配第一版」。

首版 Demo 完成规格：[Demo Definition V1](../features/demo-definition-v1.md)。

当前活跃专题：[Demo First Playable Slice Assembly V1](../features/demo-first-playable-slice-assembly-v1.md)，覆盖首版 Demo 可玩纵切装配；在默认画面明显像游戏前，不转向完整路径体感复核。

当前执行线：

- [Demo Playable UI And Art Pass V1](../features/demo-playable-ui-and-art-pass-v1.md)
- [Demo Core Loop Playable V1](../features/demo-core-loop-playable-v1.md)
- [Demo Narrative Beats V1](../features/demo-narrative-beats-v1.md)

视觉方向参考：[Visual And UI Direction](../product/visual-and-ui-direction.md)。

## 最近收尾

- `S0` 到 Demo 终点的主路径、存档状态、设备面板、加工、过滤、整备、战斗反馈和自动检查证据已建立。
- 2026-06-19 已撤回“自动检查通过即可进入验收”的判断。
- 2026-06-20 复核交付目标为内部朋友试玩或完整实机演示；核心回到“工业基地为主，探索 / 战斗服务基地”。
- 2026-06-20 至 2026-06-23 已完成基地工业视觉、HUD 层级、第一条工业链、污染链、角色 / 敌人轮廓、晶体 / 污染 / 核心地貌材质和核心稳定站完成态多轮推进。
- 2026-06-23 阶段复盘确认：继续围绕单点截图降噪会让项目回到读法修补；当前切到可玩纵切装配。
- 2026-06-23 至 2026-06-24 已完成 UI / Art pass 前六包、核心循环两包和叙事节拍前两包：默认画面已有快捷补给、底部摘要、关键对象轮廓、设备关系、本地目标焦点、局部画面收束、短循环读法、压短必经操作量、`现场记录` 和场景证据。

## 下一步读取顺序

1. 读 `docs/planning/current.md` 确认阶段、冻结边界和退出条件。
2. 读 `docs/features/demo-first-playable-slice-assembly-v1.md`，确认纵切路径。
3. 按执行包读取 UI / Art、核心循环或叙事节拍专题。
4. 读 `docs/product/visual-and-ui-direction.md`，确认低保真美术和 UI 气质。
5. 读 `docs/features/demo-definition-v1.md`，确认首版 Demo 必达规格。
6. 只在需要确认 12 区职责时，读 `docs/planning/demo-scope-and-playable-slice.md`。
7. 只在需要历史风险时，读取最新周志中的“风险与未完成项”和“下周建议”。
8. 按改动范围选读设计、架构和复测基线文档。

## 当前开发重点

- 不再把 2 / 3 / 5 截图点降噪作为主线；若仍影响纵切核心路径，纳入 UI / Art pass。
- 当前首要问题是默认画面仍偏 debug / 流程图 / 原型图层；下一步优先解决“不像游戏”。
- 优先推进低保真游戏画面成型：角色、敌人、设备、地面、材质、空间层次、动作反馈和场景氛围。
- HUD、读法、状态整理和检查只能支撑画面成型，不能作为当前主线开发包。
- 每个开发包必须回答：玩家会看到什么、做什么、理解什么。

## 明日事项（2026-06-25）

1. 继续 UI / Art 的低保真游戏画面成型，优先让默认画面从 debug / 流程图观感转向可玩的 2D / 2.5D 工业科幻 ARPG 场景。
2. 优先补角色、敌人、设备、地面、材质、阴影、空间层次和操作动作反馈；HUD 只做辅助，不作为主体。
3. 若 2 号晶体矿脉或 5 号污染边界仍抢主读法，只做对应核心路径局部收束，不把 5 / 6 已通过画面重新打开。

## 防跑偏规则

- 当前阶段没有玩家可见画面、操作、反馈或叙事节拍的文本、formatter、检查和“第一包”不算主线进展。
- 默认画面仍不像游戏时，不建议“完整新档路径体感复核”、试玩准备、验收或同类阶段切换。
- 不能把读法、UI 字段、状态整理、设备面板字段和检查补充包装成当前主线；它们只能服务角色、场景、设备、敌人和操作反馈的画面成型。
- 新增 helper / formatter / check 只能支撑可见实现，不能成为开发包主体。
- 不再用同类目标箭头、地图提示、长文案、状态字段或检查接线替代场景建设。
- 低保真可以接受，但不能继续把 `ColorRect + Label` 的 debug 流程图当作首版 Demo 可试玩画面目标。
- 阶段退出后必须重启首次可玩验收专题，而不是直接进入修 bug。

## 当前不做

- 不继续扩前线行动台、候选、窗口复盘、高压窗口或 `base_action_state`，除非出现 `P0` / `P1`。
- 不横向新增区域；首版 Demo 到 12 个区域封顶。
- 不新增随机成功率、新货币、队员、完整装备栏、完整 `loadout`、完整背包重构、联机入口、最终美术包或发布流程。
- 不把试玩准备、修 bug 阶段、大规模 polish、死亡系统、结算页、基线复核、静态审计或纯提示修补作为当前阶段目标。

## 阻塞标准

只让这些问题阻塞阶段：

- 崩溃
- 主线卡死
- 坏档
- 任务无法完成
- 关键资源断档
- UI 完全无法判断下一步
- 首屏或基地平台仍主要表现为 debug 色块和长文本

其他问题进入 backlog 或后续 polish。

## 必读与选读

日常推进必读：

- `docs/planning/current.md`
- `docs/features/demo-first-playable-slice-assembly-v1.md`
- `docs/product/visual-and-ui-direction.md`
- `docs/features/demo-definition-v1.md`

按任务选读：

- UI / Art：`docs/features/demo-playable-ui-and-art-pass-v1.md`
- 核心循环：`docs/features/demo-core-loop-playable-v1.md`
- 叙事节拍：`docs/features/demo-narrative-beats-v1.md`
- 区域和首小时体验：`docs/design/onboarding-and-first-hour.md`
- 开发复测基线：`docs/design/development-retest-baselines.md`

## 验证入口

客户端改动优先执行默认检查：Windows 用 `pwsh ./scripts/check-client.ps1`，macOS / Linux / Git Bash 用 `sh ./scripts/check-client.sh`；该入口不启动 Godot。需要导入工程或运行项目自定义 GDScript 检查时，确认本机 Godot 可启动后加 `-WithGodot` / `--with-godot`。

提交前：Windows 用 `pwsh ./scripts/check-text-files.ps1`、`pwsh ./scripts/check-docs.ps1`；macOS / Linux / Git Bash 用 `./scripts/check-text-files.sh`、`./scripts/check-docs.sh`；最后执行 `git diff --check`。
