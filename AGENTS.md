# RadishCatalyst 协作约定

本文件为 RadishCatalyst 仓库中的 AI 协作者与人工协作者提供统一协作规范。

## 语言规范

- 默认使用中文进行讨论、说明、提交总结和开发日志记录。
- 代码、命令、路径、配置键、类型名、接口名和外部产品名保留原文。
- 新增文档正文默认使用中文；文件名、目录名和稳定锚点优先使用英文。

## 项目定位

`RadishCatalyst / 异星催化` 是一个以异星化工基地、人物探索战斗、角色成长和后续协作联机为核心方向的 2D / 2.5D 工业科幻 ARPG。

当前阶段以“仓库地基、策划定稿、架构边界和可玩原型准备”为主，不应过早进入大规模内容生产、复杂后端或 MMO 化实现。

## 文档真相源

`docs/` 是本仓库正式文档源。日常推进类提示（例如“根据项目规划和开发进度，今天要来做什么以推进开发”）优先阅读：

1. `docs/planning/daily-start.md`
2. `docs/planning/current.md`
3. 最新周志的“风险与未完成项”和“下周建议”（当前为 `docs/devlogs/2026-W19.md`）

按任务选读：

- 项目方向：`docs/product/creative-development-brief.md`
- 首小时体验：`docs/design/onboarding-and-first-hour.md`
- 联机、存档或边界：`docs/architecture/multiplayer-and-save-architecture.md`
- 代码结构和重构：`docs/architecture/code-style-and-language-practices.md`
- 阶段复核：`docs/planning/milestone-review-checklist.md`
- 协作治理：`docs/adr/0001-branch-and-pr-governance.md`

规则：

- 若文档、代码和阶段目标冲突，先判断哪一方过期，再统一修正。
- 优先更新已有文档，不为一次性讨论创建大量散文档。
- `docs/planning/daily-start.md`、`docs/planning/current.md`、`docs/README.md`、各目录 `README.md` 等关键入口文档应保持简约，只描述当前阶段、最近进度、下一步重点和必要索引；历史过程、长清单和背景材料应放入周志、专题文档、`docs/reference/` 或 `docs/archive/`，避免新会话读取入口时浪费上下文。
- 参考资料放在 `docs/reference/`，归档材料放在 `docs/archive/`。
- `docs/archive/full-conversation-history.md` 保留历史原貌，可能包含旧路径和旧中文文件名，不作为当前规范。
- 重大架构、阶段边界、协作规则、验证基线或目录职责变化，必须同步更新 `docs/`。
- 玩家可见知识库内容放在 `wiki/`，不要混入开发者内部规划。
- 面向玩家的官方辅助工具放在 `official-tools/`，不要和仓库脚本目录 `tools/` 混淆。

## 协作流程

- 开始任务前，先检查工作区状态，并阅读与任务直接相关的文档。
- 若用户明确要求直接修改，且范围清晰、风险可控，则直接实施。
- 若用户没有明确要求直接修改，编写代码前应先说明方案。
- 若需求不明确，或改动会影响架构、阶段边界、接口口径、验证基线，则先说明判断并做必要澄清。
- 每次新增/修改功能、修复 bug 或处理其他任务时，优先从根因、长期维护性和系统一致性出发，选择更完整、更稳妥的治理方案；不要把“最小修复”当作默认优先级，也不要无节制地层层增加兜底来掩盖问题。
- 每做完一个可分割子步骤，应进行匹配的最小验证。
- 重要阶段性推进除了修改文件，还应同步追加到本周周志。

## Agent 协同文件

- `AGENTS.md` 与 `CLAUDE.md` 应保持基本同步。
- 若某个协作文件更新了通用协作规则、执行边界、验证基线或阶段约束，另一个文件也应同步更新。
- 同类协作文件只允许保留与入口名称直接相关的表述差异，不应分叉实际协作规范。

## 当前分支约定

- `dev` 是日常开发与文档集成分支。
- `master` / `main` 仅作为稳定主线。
- 常规功能、文档、规范类变更默认先进入 `dev`。
- 阶段性稳定后，再从 `dev` 向 `master` / `main` 发起 Pull Request。
- `master` / `main` 不直接 push，只通过 Pull Request 合并。
- 当前允许 `merge commit` 与 `rebase merge`，禁用 `squash merge`。
- 当前阶段不要求保护 `dev`。

## 当前验证基线

当前仓库已初始化 Godot 原型工程。默认验证以仓库文本卫生、客户端静态数据、场景引用、HUD 关键面板布局、存档运行时、任务规则、第一切片关键流程和 Godot 导入为主。

仓库文本卫生仍需执行：

```powershell
pwsh ./scripts/check-text-files.ps1
```

Linux/macOS 或 Git Bash 环境可执行：

```bash
./scripts/check-text-files.sh
```

检查内容：

- UTF-8 文本编码。
- 不含 UTF-8 BOM。
- 文本文件统一 LF 换行。
- 文本文件末尾有换行。
- 非 Markdown / CSV 文本文件不保留行尾空白。
- 源码类文件原则上不超过 1500 行。

客户端聚合验证可执行：

```powershell
pwsh ./scripts/check-client.ps1
```

该聚合脚本会按顺序执行：

```powershell
pwsh ./scripts/check-client-data.ps1
pwsh ./scripts/check-client-scenes.ps1
pwsh ./scripts/check-client-save.ps1
pwsh ./scripts/check-client-quests.ps1
pwsh ./scripts/check-client-flow.ps1
pwsh ./scripts/check-godot-client.ps1
```

其中 `check-client-data.ps1` 会校验客户端静态数据 JSON、稳定 ID、引用、本地化键、配方 `unlock_conditions` 与任务 `unlock_effects` 的来源一致性，以及任务不要同时出现在 `next_quest_ids` 和 `unlock_effects`；`check-client-scenes.ps1` 会校验场景资源引用、Godot 脚本 UID 和原型 HUD 关键面板默认布局，避免状态、地图、设备、任务完成、撤离、补给、提示和日志面板互相遮挡。

提交前按改动范围至少执行匹配的单项验证；涉及客户端状态、任务、存档、场景或脚本时，优先执行聚合验证，再执行 `pwsh ./scripts/check-text-files.ps1` 和 `git diff --check`。

如果未来加入 Godot 导出配置、脚本静态检查或更多自动化测试入口，应同步更新本文件、`CLAUDE.md`、`docs/planning/current.md` 和 CI。

## AI 执行边界

### 可直接执行

- 读取和修改仓库内代码、文档、配置。
- `git status`、`git diff`、`git log` 等只读 Git 操作。
- `pwsh ./scripts/check-text-files.ps1`、`./scripts/check-text-files.sh`。
- `pwsh ./scripts/check-client.ps1` 及其单项客户端检查脚本。
- 简洁明确的提交操作。

### 需要先告知用户再执行

- 启动 Godot 编辑器、桌面程序或长期运行进程。
- 安装依赖、下载大文件、引入外部资产包。
- 修改系统环境、注册表、证书、全局 Git 配置或编辑器全局配置。
- 打包、发布、上传、推送远端分支或创建 Release。

### 当前默认不做

- 跨工作区编辑历史旧仓库、兄弟仓库、参考仓库或其他项目；确需跨仓库操作时必须先获得明确授权。
- 把旧仓库代码整包迁入当前仓库。
- 在首版前实现 MMO 级账号、交易、公会、官方大世界或复杂专用服务器。
- 未经明确要求执行破坏性 Git 操作。

## 工程与内容边界

- 优先以 Godot 4.x 作为原型方向。
- 脚本侧默认优先考虑 GDScript。
- 首版必须先保证离线单机完整闭环。
- 联机作为架构预留和后续阶段推进，不作为首版依赖。
- 核心设计围绕“基地服务冒险，冒险反哺基地”展开。
- 化工自动化是项目差异化卖点，但不应成为玩家理解门槛。
- 战斗、探索、成长与生产链必须形成互相推动的闭环。

## 代码与文件规范

- 文档和代码文件统一使用 LF 换行。
- 新增仓库文件优先使用英文文件名。
- 正文可以使用中文。
- 文本文件使用 UTF-8，无 BOM。
- 单个源码文件原则上不超过 1000 行，硬上限 1500 行。
- 文件接近 1000 行时，后续新增实现应优先拆分职责、提取子模块或测试 helper。
- 不以单文件承载全部状态、全部 UI 或全部玩法逻辑。
- 避免为了“整齐”堆出过深目录树，优先按职责做浅层分组。
- 编写代码时遵循对应语言和框架的惯用实践，例如 GDScript 优先使用 Godot 4.x 的节点、资源、信号和类型习惯，PowerShell 脚本使用清晰的参数、管道和错误处理方式。
- 禁止为了显得“高级”而编写不明意义的方法名、晦涩抽象、空泛 `Manager` / `Helper` / `Service` 包装或多层转发；抽象必须有明确职责、真实复用价值或清晰边界收益。
- 优先使用标准库、引擎 API、结构化数据和明确类型表达意图，不用脆弱的字符串拼接、隐式约定或注释解释一段本可以写清楚的代码。
- 详细代码语言实践规范见 `docs/architecture/code-style-and-language-practices.md`。

## 仓库结构

- `client/`：未来 Godot 客户端工程。
- `server/`：未来可选服务端或联机实验工程。
- `assets/`：可提交的源资产、设定图、音频源文件等。
- `tools/`：项目脚本、数据处理、构建或导出辅助工具。
- `scripts/`：仓库检查与自动化脚本。
- `docs/`：策划、设计、架构、参考与归档文档。
- `wiki/`：未来面向玩家的 Wiki 源内容。
- `official-tools/`：未来面向玩家的官方辅助工具。
- `.github/`：PR 模板、GitHub Actions 和 ruleset 模板。

## Git 提交规范

- 使用简洁明确的 Conventional Commits 风格。
- 常用类型：`feat`、`fix`、`docs`、`refactor`、`test`、`chore`、`ci`、`build`、`perf`、`revert`。
- 优先把代码改动和文档改动按主题拆分。
- 不添加 AI 协作者署名。
- 小修改提交时，commit message 保持一条简洁说明即可。
- 大修改提交时，除了首行 commit message 外，优先补充 3 到 6 条简短说明。
- 提交前至少确认本次改动对应的最小验证已经执行。

示例：

```text
docs: 更新项目协作与治理文档

- 新增分支保护 ruleset 模板
- 补充周志与规划文档入口
- 对齐 AGENTS 与 CLAUDE 协作规则
```

## 文档与周志要求

- 架构、边界、阶段目标变化时，必须同步更新 `docs/`。
- 影响协作方式或工作流的变更，应同步更新 `AGENTS.md` 和 `CLAUDE.md`。
- 每周重要推进记录到 `docs/devlogs/YYYY-Www.md`。
- 周志记录应包含：本周目标、完成情况、关键决策、验证记录、风险与未完成项、下周建议。
- 更新日志和周志使用 Asia/Shanghai（UTC+8）日期。

## 当前阶段判断标准

如果一个改动同时满足以下条件，则方向通常是正确的：

- 项目边界更清晰。
- 首版闭环更容易落地。
- 文档、代码和阶段目标一致。
- 没有把后续阶段复杂度提前压进当前阶段。
- 仓库规则、验证入口和协作说明仍能保持同步。
