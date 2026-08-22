# Process Docs

更新时间：2026-08-22

## 用途

本目录存放开发协作流程、决策闸门和执行规则。这里的文档约束“怎么推进”，不承载具体功能范围。

## 当前文档

- [Agent Collaboration](agent-collaboration.md)：根入口、按需专题、当前规划与记录的职责分层，以及通用任务推进和授权规则。
- [Development Decision Gates](development-decision-gates.md)：玩家可见开发包的开工、复盘、证据和文档落点规则。
- [Image Generation And Review Workflow](image-generation-and-review-workflow.md)：图像生成轮次、候选落盘、中断恢复、读取稳定性和审阅交接。

## 使用规则

- 阶段方向仍以 `docs/planning/current.md` 为准。
- 具体功能范围仍以 `docs/features/` 专题为准。
- `AGENTS.md`、`CLAUDE.md` 只保留启动级长期约束；稳定但按任务读取的细则归入本目录。
- 当连续实机反馈说明当前做法低效时，先按决策闸门复盘，再决定继续、换实现方式或拆新专题。
