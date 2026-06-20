# Daily Start

更新时间：2026-06-20

## 用途

当提示是“根据项目规划和开发进度，今天要来做什么以推进开发”时，优先阅读本文。

本文只提供日常入口和读取顺序；阶段方向以当前活跃专题为准，每日代码范围以当前执行包为准。

## 阶段

当前为「首版 Demo 工业基地视觉与场景化第一版」。

首版 Demo 完成规格：[Demo Definition V1](../features/demo-definition-v1.md)。

当前活跃专题：[Demo Industrial Base Visual And Scene V1](../features/demo-industrial-base-visual-and-scene-v1.md)，覆盖工业基地视觉、场景化、HUD 视觉和第一条工业链可视化。

视觉方向参考：[Visual And UI Direction](../product/visual-and-ui-direction.md)。

最近完成专题：[Demo Playable Content Substance V1](../features/demo-playable-content-substance-v1.md)、[Demo Field Task Differentiation V1](../features/demo-field-task-differentiation-v1.md)、[Demo Initial Art Identity V1](../features/demo-initial-art-identity-v1.md)、[Demo Industrial Module Task Rhythm V1](../features/demo-industrial-module-task-rhythm-v1.md) 与 [Demo Core Scene Playable Space V1](../features/demo-core-scene-playable-space-v1.md) 已落地第一包，但不能替代可试玩画面质量。

## 最近收尾

- `S0` 到 Demo 终点的主路径、存档状态、设备面板、加工、过滤、整备、战斗反馈和自动检查证据已建立。
- 2026-06-19 已撤回“自动检查通过即可进入验收”的判断。
- 2026-06-20 复核当前交付目标：内部朋友试玩或完整实机演示；核心参考《The Riftbreaker》的工业基地主导体验，探索 / 战斗服务基地。
- 当前最大缺口从“路径是否存在”切到“画面是否像游戏、基地是否像工业基地、HUD 是否像玩家界面”。

## 下一步读取顺序

1. 读 `docs/planning/current.md` 确认阶段、冻结边界和退出条件。
2. 读 `docs/features/demo-industrial-base-visual-and-scene-v1.md`，确认基地平台、HUD 和第一条工业链的视觉范围。
3. 读 `docs/product/visual-and-ui-direction.md`，确认低保真美术和 UI 气质。
4. 读 `docs/features/demo-definition-v1.md`，确认首版 Demo 必达规格。
5. 只在需要确认 12 区职责时，读 `docs/planning/demo-scope-and-playable-slice.md`。
6. 只在需要历史风险时，读取最新周志中的“风险与未完成项”和“下周建议”。
7. 按改动范围选读设计、架构和复测基线文档。

## 当前开发重点

- 优先做基地平台视觉重建：前哨核心、基础反应器、污染过滤器、基础储存箱和出发整备台要有设备轮廓、底座、材质色、状态层和工业关系。
- 优先收束 HUD 视觉：第一视野只保留当前目标、生命 / 防护 / 补给、关键材料、设备状态和警告；调试面板和长说明不能主导画面。
- 优先做第一条工业链可视化：`晶体 / 残骸 -> 基础反应器 -> 基础零件 / 修复凝胶 -> 出发整备收益`。
- 污染链作为第二优先：`污染沉积 -> 污染过滤器 -> 抗污染药剂 + 污染浆液 -> 回收 / 核心准备`。
- 每个区域后续都必须回答它给基地提供什么资源、解锁、设备输入、风险或稳定工程价值。

## 防跑偏规则

- 当前阶段没有场景、设备、HUD 或工业链视觉结果的文本、formatter、检查和“第一包”不算主线进展。
- 新增 helper / formatter / check 只能支撑可见实现，不能成为开发包主体。
- 不再用同类目标箭头、地图提示、长文案、状态字段或检查接线替代场景建设。
- 低保真可以接受，但不能继续把 `ColorRect + Label` 的 debug 流程图当作首版 Demo 可试玩画面目标。
- 每个开发包开工前先说明截图或实机中会看到什么变化；收口时优先核对画面观感，再补自动检查。

## 当前不做

- 不继续扩前线行动台、候选、窗口复盘、高压窗口或 `base_action_state`，除非出现 `P0` / `P1`。
- 不继续横向新增区域；首版 Demo 到 12 个区域封顶。
- 不新增随机成功率、新货币、队员、完整装备栏、完整 `loadout`、完整背包重构、联机入口、最终美术包或大规模美术替换。
- 不把试玩准备、修 bug 阶段、完整发布准备、大规模 polish、死亡系统、结算页、基线复核、静态审计或纯提示修补作为当前阶段目标。

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
- `docs/features/demo-industrial-base-visual-and-scene-v1.md`
- `docs/product/visual-and-ui-direction.md`
- `docs/features/demo-definition-v1.md`
- `docs/planning/demo-scope-and-playable-slice.md`

按任务选读：

- 最近完成战斗 / 工业 / 场景细专题：按 `docs/features/README.md` 选读
- 区域和首小时体验：`docs/design/onboarding-and-first-hour.md`
- 开发复测基线：`docs/design/development-retest-baselines.md`
- 代码结构和重构：`docs/architecture/code-style-and-language-practices.md`
- 存档、联机或边界：`docs/architecture/multiplayer-and-save-architecture.md`

## 验证入口

客户端改动优先执行默认检查：Windows 用 `pwsh ./scripts/check-client.ps1`，macOS / Linux / Git Bash 用 `sh ./scripts/check-client.sh`；该入口不启动 Godot。需要导入工程或运行项目自定义 GDScript 检查时，确认本机 Godot 可启动后加 `-WithGodot` / `--with-godot`。

提交前：Windows 用 `pwsh ./scripts/check-text-files.ps1`、`pwsh ./scripts/check-docs.ps1`；macOS / Linux / Git Bash 用 `./scripts/check-text-files.sh`、`./scripts/check-docs.sh`；最后执行 `git diff --check`。
