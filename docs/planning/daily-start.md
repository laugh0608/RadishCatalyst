# Daily Start

更新时间：2026-05-06

## 用途

当提示是“根据项目规划和开发进度，今天要来做什么以推进开发”时，优先阅读本文。本文只回答今天如何推进，不承载完整历史。

## 当前阶段一句话

当前处于「首小时引导可玩」阶段：验证玩家是否能在无口头解释下理解并完成“外出获得资源 -> 回基地加工 -> 远征产物改变下一次外勤结果”。

## 最近进度

- 第一切片冷启动审计已于 2026-05-05 通过，原型主流程可以反复空存档复测。
- 首小时内容链已扩展到反应器校准、异常样本分析、处理点补给准备、污染处理点建设、污染边界收尾和污染残核压制。
- 基础反应器已支持任务相关配方自动优先选择，设备面板会标记当前目标推荐配方；HUD 正在从原型巨型脚本拆分为更清晰的 presenter 职责。

## 今日推荐推进

1. 复测设备面板的当前目标推荐配方标记是否足够清楚；若仍有查找摩擦，再考虑快捷选择。
2. 继续收敛正式 HUD / 调试 HUD 边界，重点判断日志 / 计时面板是否值得拆分，避免为了拆分制造晦涩封装。
3. 若空存档试玩仍无法建立闭环理解，优先补外勤风险、战斗准备价值或资源选择，不用等待时长硬拉流程。

## 今日不做

- 不扩展联机、账号、云存档、交易、公会、排行榜或复杂服务端。
- 不新增电网、管线、自动物流、多设备调度或完整教程弹窗框架。
- 不为了内容时长堆等待时间、长文本说明或纯 UI 抛光。

## 必读与选读

日常推进必读：

- `docs/planning/current.md`
- 最新周志的“风险与未完成项”和“下周建议”，当前为 `docs/devlogs/2026-W19.md`

按任务选读：

- 首小时体验：`docs/design/onboarding-and-first-hour.md`
- 代码结构和重构：`docs/architecture/code-style-and-language-practices.md`
- 存档、联机或边界：`docs/architecture/multiplayer-and-save-architecture.md`
- 阶段复核：`docs/planning/milestone-review-checklist.md`

## 今日验证入口

客户端相关改动优先执行：

```powershell
pwsh ./scripts/check-client.ps1
```

提交前执行：

```powershell
pwsh ./scripts/check-text-files.ps1
git diff --check
```
