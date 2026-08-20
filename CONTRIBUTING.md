# 参与 RadishCatalyst

感谢你关注 RadishCatalyst / 异星催化。项目当前处于第一可玩切片的持续开发与整改阶段；贡献应优先服务已经确认的阶段目标、玩家路径和长期可维护性，不提前扩大未解冻的产品范围。

## 贡献前先确认

- 安全漏洞不要提交公开 Issue 或 Pull Request，请按[安全策略](SECURITY.md)私下报告。
- 参与讨论、评审和其他项目交流时，请遵循[社区行为准则](CODE_OF_CONDUCT.md)。
- 本仓库采用 [RadishCatalyst Source-Available License 1.1](LICENSE)，不是开放源码许可证。查看源码不自动授予复制、修改、再分发、商用或衍生开发权利；外部贡献以 `LICENSE` 第 5 节的贡献授权条款为准。
- 不提交真实凭据、个人数据、用户正式存档、未脱敏日志或无法确认授权的第三方代码与资产。
- 玩家可感知功能、跨系统开发包、存档 / 联机边界或架构级变化，应先通过 Issue、专题文档或设计讨论确认范围；单点修复和不改变正式边界的小型文档改进可以直接提交 PR。

## 开始之前

建议按以下顺序阅读：

1. [日常推进入口](docs/planning/daily-start.md)
2. [当前阶段与边界](docs/planning/current.md)
3. 当前规划指向的 `docs/features/` 活跃专题
4. [开发决策闸门](docs/process/development-decision-gates.md)
5. 与改动直接相关的设计、架构或复测文档

玩家可见功能默认采用“功能设计文档先行”。若阶段目标、专题文档、代码和验证基线互相冲突，应先判断哪一方已经过期，再在同一变更中统一口径。

## 工作流

1. 从最新 `dev` 创建范围明确的主题分支，并把 Pull Request 目标设为 `dev`。
2. 分支可使用 `feature/*`、`fix/*`、`docs/*`、`chore/*` 或 `hotfix/*`；`hotfix/*` 只用于必须直接修复稳定主线的问题。
3. `master` / `main` 只接收阶段性 `dev` 晋级或明确的 hotfix，不接受普通功能分支。
4. 提交遵循 Conventional Commits，例如 `feat(factory): add conveyor placement preview` 或 `docs(governance): add security policy`。
5. 不在提交信息中添加 AI 协作者署名；提交作者应是对变更负责的真实贡献者。
6. PR 只记录实际完成的验证，并明确列出未执行、受环境阻塞或仍需人工复核的项目。

完整分支、合并与默认分支回流规则见 [ADR 0001](docs/adr/0001-branch-and-pr-governance.md)。

## 变更说明要求

Pull Request 应覆盖适用内容：

- 玩家或开发者目标、实现范围和明确非目标；
- 与当前阶段、活跃专题和既有系统边界的关系；
- 对玩法、场景、HUD、输入、存档 schema、联机边界和兼容性的影响；
- 新增或替换资产的来源、处理方式和许可证；
- 实际验证、人工复核证据、未验证内容、已知风险和回滚方式；
- 架构、阶段、流程或验证基线变化所对应的文档同步；
- 目标为 `master` / `main` 时的合并策略及合并后 `master` / `main -> dev` 回流安排。

不要把自动检查通过写成玩家体验已经通过。玩法、交互、HUD、场景、状态反馈或存读结果等玩家可见目标，应按 [Godot 运行时验证指南](docs/reference/godot-runtime-verification-guide.md)补正式入口、截图或人工路径证据。

## 本地验证

macOS、Linux、Git Bash 或 zsh 的仓库基础检查：

```bash
./scripts/check-repo.sh
sh ./scripts/check-client.sh
```

Windows PowerShell：

```powershell
pwsh ./scripts/check-repo.ps1
pwsh ./scripts/check-client.ps1
```

`check-repo` 是无第三方依赖的仓库治理入口，覆盖必需文件、Issue / PR / workflow / ruleset 合同、活跃 Markdown 相对链接、JSON、文本卫生、文档篇幅、客户端静态数据与场景引用、检查器单元测试和 diff 空白；PR 模式还检查提交信息。`docs/archive/` 保留历史原貌，不纳入当前链接合同。客户端改动继续执行 `check-client`。只记录实际运行的命令；需要工程导入或运行时检查时，使用 `--with-godot` / `-WithGodot`，玩家可见改动还需完成对应的实机复核。

## 资产与许可证

提交贡献即表示你有权提供相关内容，并接受 `LICENSE` 第 5 节的贡献授权。第三方代码、字体、音频、模型、图片、像素素材和其他资产必须标明来源、许可证与必要的修改说明；不得提交来源不明、授权不兼容或超出许可范围的材料。

RadishCatalyst 的原创美术与游戏资产保留全部权利。参与项目不代表获得在其他项目中提取、训练、复用、改编或再分发这些资产的许可。
