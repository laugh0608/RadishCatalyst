# RadishCatalyst Documentation

本目录收纳 RadishCatalyst / 异星催化 的开发者文档：策划、设计、架构、规划、参考资料与归档材料。

玩家可见知识库源内容放在仓库根目录 `wiki/`。

面向玩家的官方辅助工具放在仓库根目录 `official-tools/`。

仓库许可条款以根目录 [LICENSE](../LICENSE) 为准。

## Entry Document Constraints

- `docs/planning/daily-start.md`、`docs/planning/current.md`、`docs/README.md` 和各目录 `README.md` 是新会话优先入口，应保持简约。
- 入口文档只保留当前阶段、最近进度、下一步重点、验证入口和必要索引。
- 历史过程、长完成清单、背景讨论和一次性分析应放入 `devlogs/`、专题文档、`reference/` 或 `archive/`，不要堆进入口文档。
- 更新入口文档时优先链接到细节来源，不复制大段背景，避免 AI / Agent 在新会话中消耗不必要上下文。
- 日常推进类提示优先读取 [Daily Start](planning/daily-start.md)，再按任务选读细节文档。

## Code Language Standards

- 正式代码语言实践规范见 [Code Style And Language Practices](architecture/code-style-and-language-practices.md)。
- 入口摘要：代码应贴近对应语言、框架和引擎的惯用实践；抽象必须有明确职责和真实收益；禁止不明意义的方法、晦涩封装和多层无收益转发。

## Structure

- `product/`：当前项目方向、产品定义、玩法支柱与开发准备总纲。
- `design/`：玩法系统、资源链、地图、角色成长等后续执行设计文档。
- `architecture/`：会影响工程结构、数据边界、联机与存档设计的前置架构文档。
- `planning/`：当前阶段、优先级、范围边界和短期计划。
- `adr/`：长期影响仓库治理、架构或流程的决策记录。
- `devlogs/`：按周记录开发推进、关键决策、验证和风险。
- `reference/`：早期方案、外部建议、同类方向分析等可参考资料。
- `archive/`：对话整理、完整历史、灵感原始材料等归档内容。

## Core Documents

- [Project Definition](product/project-definition.md)
- [Creative Development Brief](product/creative-development-brief.md)
- [Reference Positioning](product/reference-positioning.md)
- [Player Wiki And Official Tools](product/player-wiki-and-official-tools.md)
- [Visual And UI Direction](product/visual-and-ui-direction.md)
- [Worldbuilding Premise](product/worldbuilding-premise.md)
- [MVP Feature List](product/mvp-feature-list.md)
- [Multiplayer and Save Architecture](architecture/multiplayer-and-save-architecture.md)
- [Code Style And Language Practices](architecture/code-style-and-language-practices.md)
- [Platform And Compatibility](architecture/platform-and-compatibility.md)
- [Save Data Model](architecture/save-data-model.md)
- [Static Data Schema](architecture/static-data-schema.md)
- [Godot Project Structure](architecture/godot-project-structure.md)

## Design Documents

- [Design Documents](design/README.md)
- [Core Gameplay Loop](design/core-gameplay-loop.md)
- [Character Progression And Equipment](design/character-progression-and-equipment.md)
- [Combat And Interaction Prototype](design/combat-and-interaction-prototype.md)
- [Maps And Regions](design/maps-and-regions.md)
- [Narrative And Quest Framework](design/narrative-and-quest-framework.md)
- [Onboarding And First Hour](design/onboarding-and-first-hour.md)
- [Resources And Process Chain](design/resources-and-process-chain.md)

## Planning And Governance

- [Daily Start](planning/daily-start.md)
- [Current Plan](planning/current.md)
- [Vertical Slice](planning/vertical-slice.md)
- [Milestone Review Checklist](planning/milestone-review-checklist.md)
- [Architecture Decision Records](adr/README.md)
- [Development Logs](devlogs/README.md)

## Reference Documents

- [Chemical Automation Game Outline](reference/chemical-automation-game-outline.md)
- [Cultivation Game Outline](reference/cultivation-game-outline.md)
- [Community Advice](reference/community-advice.md)
- [Deepseek Advice](reference/deepseek-advice.md)

## Archive

- [Conversation Summary and Ideas](archive/conversation-summary-and-ideas.md)
- [Full Conversation History](archive/full-conversation-history.md)
