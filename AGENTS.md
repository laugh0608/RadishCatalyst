# RadishCatalyst 协作约定

本文件为 AI 协作者提供 RadishCatalyst 项目的启动级长期约束。

## 定位与优先级

- `docs/` 是项目正式文档源；本文件只保留跨任务、跨阶段且必须在任务开始时生效的约束，不承载当前阶段、临时门禁、历史记录或专题实现细节。
- 当前阶段、优先级、冻结项、“当前不做”和退出条件以 [Current Plan](docs/planning/current.md) 及其当前活跃专题为准。
- 萝卜SAMA在当前任务中的明确要求优先于仓库默认流程；若要求会改变架构、规则、接口、依赖、验证基线或运行时边界，仍应先说明影响并确认范围。
- 只读取当前任务需要的文档；除追溯历史事实外，不默认展开 `docs/archive/` 或旧专题。

## 称呼与语言

- 对话开始或结束总结时，请称呼项目所有者为 `萝卜SAMA`。
- 默认使用中文讨论、说明、编写文档和记录开发日志。
- 代码、命令、路径、配置键、类型名、接口名和外部产品名保留原文。
- 新增文件名、目录名和稳定锚点优先使用英文。

## 协作原则

- 开始任务前先检查工作区状态，并阅读任务路由指向的必要文档。
- 需求明确、范围可控且萝卜SAMA要求直接修改时直接实施；未明确要求修改时，编写代码前先说明方案。
- 不同合理解释会明显改变结果、风险或范围时先澄清；已确认方案发生实质扩张时重新确认。
- 优先治理根因、长期维护性、系统一致性和可验证性；不以玩具式最小实现、临时兼容、吞错或层层兜底掩盖问题。
- 在满足真实需求和质量的前提下控制修改范围；不做无关重构，不为“架构感”增加无真实收益的抽象。
- 玩家可感知功能、跨系统开发包和阶段性玩法推进默认设计文档先行；单点文案、局部修错或不改变玩法、状态与检查边界的调整可沿现有专题实施。
- 每完成一个可分割子步骤，执行与风险匹配的最小验证；重要阶段性推进同步记录到本周周志。
- 详细任务推进、授权、文档分层和证据规则见 [Agent Collaboration](docs/process/agent-collaboration.md)。

## 必须先告知或授权的操作

- 启动 Godot 编辑器、桌面程序、有窗口测试，或执行 `check-client --with-godot` / `-WithGodot` 前，先告知萝卜SAMA。
- 安装或更新依赖、下载大文件、引入外部资产包前，说明具体命令、范围和落盘影响并取得授权。
- 修改系统环境、注册表、证书、全局 Git 配置或编辑器全局配置前，必须取得授权。
- 打包、发布、上传、推送远端分支或创建 Release 前，先说明目标、影响和验证状态并取得授权。
- 跨工作区默认只读；写入兄弟仓库、参考仓库或其他项目必须取得明确授权。
- 不执行未经明确要求的破坏性 Git 或文件操作；授权只覆盖当前任务已说明的范围，不沿用历史会话授权。
- 仓库内文件读写、只读 Git、非 Godot 检查、构建、测试、静态分析和范围明确的本地提交可直接执行。

## 任务文档路由

| 任务 | 优先读取 |
| --- | --- |
| 今天做什么、当前阶段和下一步 | [Daily Start](docs/planning/daily-start.md)、[Current Plan](docs/planning/current.md)、当前活跃专题、最新周志 |
| Agent 协作、授权和文档分层 | [Agent Collaboration](docs/process/agent-collaboration.md) |
| 玩家可见功能、专题切换和失败复盘 | [Feature Documents](docs/features/README.md)、[Development Decision Gates](docs/process/development-decision-gates.md) |
| 图像生成、素材落盘和视觉审阅 | [Image Generation And Review Workflow](docs/process/image-generation-and-review-workflow.md)、[Pixel Art And Grid Standard](docs/reference/pixel-art-and-grid-standard.md) |
| Godot 正式入口、截图和隔离存档 | [Godot Runtime Verification Guide](docs/reference/godot-runtime-verification-guide.md)、[Development Retest Baselines](docs/design/development-retest-baselines.md) |
| 项目方向和首小时体验 | [Creative Development Brief](docs/product/creative-development-brief.md)、[Onboarding And First Hour](docs/design/onboarding-and-first-hour.md) |
| 联机、存档和运行时边界 | [Multiplayer And Save Architecture](docs/architecture/multiplayer-and-save-architecture.md)、相关架构专题 |
| 代码结构、语言实践和重构 | [Code Style And Language Practices](docs/architecture/code-style-and-language-practices.md) |
| 分支、PR、提交和回流 | [Branch And PR Governance](docs/adr/0001-branch-and-pr-governance.md) |
| 文档结构、索引和篇幅 | [Documentation](docs/README.md) |

## 项目长期边界

- `RadishCatalyst / 异星催化` 是以异星化工基地、人物探索战斗、角色成长和后续协作联机为核心方向的像素风 2D 俯视工业科幻 ARPG。
- 核心设计围绕“基地服务冒险，冒险反哺基地”；化工自动化是差异化卖点，但不应成为玩家理解门槛。
- 原型方向为 Godot 4.x，脚本侧优先使用 GDScript；详细工程职责以架构文档和现有代码为准。
- 世界画面主介质是固定网格像素资产与 `TileMapLayer` / `Sprite2D` 场景组合；程序绘制只用于动态高亮、状态灯、选中描边和调试辅助，不作为画面主介质。
- 玩家可见知识库内容放在 `wiki/`，官方辅助工具放在 `official-tools/`，项目内部脚本放在 `tools/`。
- 当前阶段范围和未解冻事项只在当前规划与活跃专题声明，不复制到根入口。

## 实现与文件红线

- 修改前先理解现有模块边界和调用关系，沿用项目既有结构；直接影响当前需求的结构问题应做范围清楚的必要修正。
- 代码应清晰、直观、符合语言与框架惯例；抽象必须对应真实复用、边界隔离或复杂度下降。
- 单个源码文件建议控制在 `1000` 行内，硬上限 `1500` 行；接近上限时按真实职责拆分，不做机械切片。
- 外部输入、IO、网络、权限、并发和兼容风险应明确校验；不得吞掉真实错误、伪造成功或用默认值掩盖契约问题。
- 仓库文本统一使用 UTF-8 无 BOM 和 LF；新增仓库文件优先使用英文文件名。
- 不把旧仓库代码整包迁入当前仓库，不为当前目标提前引入未解冻复杂度。

## 验证与文档

- 提交前默认执行仓库治理入口：macOS / Linux 使用 `./scripts/check-repo.sh`，Windows 使用 `pwsh ./scripts/check-repo.ps1`。
- 涉及客户端状态、任务、存档、场景或脚本时，再执行 `sh ./scripts/check-client.sh` 或 `pwsh ./scripts/check-client.ps1`；脚本实际实现是覆盖范围的真相源。
- 玩家可见玩法、交互、HUD、场景、状态反馈或存读结果不能只用静态检查或 headless 断言判定通过，必须按风险补正式 `Boot`、有窗口截图和人工路径证据。
- 自动检查、临时验证、人工复测存档和截图必须使用仓库内忽略提交的规定目录，不污染用户正式存档；详细路径与保留规则以 Godot 运行时指南为准。
- 修改架构、阶段边界、协作规则、验证基线或目录职责时同步更新对应 `docs/` 真相源；批次事实、失败复盘和验证证据进入周志或专题记录。
- 只报告实际执行的验证；未执行、环境阻塞和仍需人工复核的内容必须明确说明。

## Git 约束

- `dev` 是日常开发与文档集成分支，`master` / `main` 是稳定主线；分支保护、PR 合并和回流规则以 ADR 为准。
- 提交信息使用 Conventional Commits；大修改建议补充 `3-6` 条简短说明，不添加 AI 协作者署名。
- 默认使用当前用户 Git 身份；提交前确认匹配的最小验证已执行。
- 禁止通过 reset、rebase 或 force push 重写共享 `dev` 历史；不在未授权情况下推送、发布或创建 Release。

## 根入口维护

- 一条规则只有在“跨任务成立、跨阶段成立、必须启动即生效、无法仅靠任务路由可靠承载”时，才进入 `AGENTS.md` / `CLAUDE.md`。
- 阶段状态、临时门禁、“当前不做”、批次计数、专题实现和历史证据必须更新对应 `docs/`，不得复制回根入口。
- 两个根入口只允许标题和首段入口名称不同，从第 4 行开始必须逐字一致；修改任一文件时同步另一份。
- 根入口目标是短、稳定、可路由，不是项目手册副本；详细维护判定见 Agent 协作文档和 `docs/README.md`。
- 修改根入口后执行 `./scripts/check-docs.sh` 或 `pwsh ./scripts/check-docs.ps1`，再执行仓库治理入口。
