# Daily Start

更新时间：2026-05-26

## 用途

当提示是“根据项目规划和开发进度，今天要来做什么以推进开发”时，优先阅读本文。本文只回答今天如何推进，不承载完整历史。

## 当前阶段一句话

「装备与战斗反哺基地闭环原型」已于 2026-05-26 按阶段通过处理；前线行动台、窗口复盘、高压窗口和三模块联锁进入冻结期。当前阶段为「首版 Demo 范围冻结与可玩切片收束」：冻结 demo 为 12 个区域，扩大核心区域尺度，做 UI 可读性 baseline，并收束一条可试玩 demo 主线。

## 最近进度

- `S0` 新档冷启动人工复测、资源循环重构、基地行动调度、同一前线窗口、窗口复盘整备、三类模块闭环、压力清障守卫门控和高压窗口目标均已通过自动检查或人工短跑。
- 高压窗口已证明“前线收益 -> 回基地整备 -> 更危险目标”可以成立，但继续围绕前线行动台打磨会拖慢项目实质推进。
- 当前判断：项目不缺区域数量，也不缺行动台分支；缺的是 demo 范围冻结、区域尺度、UI 可读性和一条清晰主线终点。
- 现在算基地共 11 个区域；下一阶段只允许再补 1 个关键区域，把首版 demo 封顶为 12 个区域。
- 已有区域不能平均扩张，应分为 4 个核心区域、4 个功能区域、4 个过渡区域。
- UI 进入必要开发项：主 HUD、目标追踪、资源摘要、基地状态和角色状态先做到可读，不做完整菜单或美术大换皮。

## 今日事项

1. 以 `docs/planning/demo-scope-and-playable-slice.md` 为细节源，确认 12 区域职责表、核心 / 功能 / 过渡分层和第 12 个 demo 终点区域。
2. 先推进 4 个核心区域的第一轮尺度规划：基地平台、晶体矿脉区、污染边界区、稳定核心设备区。
3. 启动 UI baseline 第一包：主 HUD、目标追踪、关键资源、基地摘要、角色状态摘要。
4. 若开始改客户端，先做区域 / UI 可读性相关的最小实现，不触碰已冻结的前线行动台、窗口复盘、高压窗口和 `base_action_state`，除非出现 `P0` / `P1`。

## 当前不做

- 不继续扩前线行动台、候选、窗口复盘、高压窗口或 `base_action_state`，除非出现 `P0` / `P1`。
- 不继续横向新增区域；首版 demo 到 12 个区域封顶。
- 不平均扩 12 个区域；先集中做核心区域。
- 不新增随机成功率、新货币、队员、完整 loadout、完整背包重构或大规模美术替换。
- 不用 `P2` / `P3` 细节打磨阻塞阶段切换。

## 节奏规则

个人开发阶段只做足以判断方向的完成度。一个阶段达到退出条件后，要及时进入下一阶段；不因为提示不够顺、局部拥挤、文案密度或状态字段洁癖无限打磨。

只让这些问题阻塞阶段：

- 崩溃
- 主线卡死
- 坏档
- 任务无法完成
- 关键资源断档
- UI 完全无法判断下一步

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

客户端相关改动优先执行：

```powershell
pwsh ./scripts/check-client.ps1
```

提交前执行：

```powershell
pwsh ./scripts/check-text-files.ps1
pwsh ./scripts/check-docs.ps1
git diff --check
```
