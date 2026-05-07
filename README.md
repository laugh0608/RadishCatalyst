# RadishCatalyst / 异星催化

RadishCatalyst 是一个以异星化工基地、人物探索战斗、角色成长和后续协作联机为核心方向的 2D / 2.5D 工业科幻 ARPG。

根目录 `README.md` 只保留仓库总览和稳定入口。当前阶段、当前重点、当前不做和退出条件统一以 [docs/planning/current.md](docs/planning/current.md) 为准。

## Start Here

- 项目文档总入口：[docs/README.md](docs/README.md)
- 日常推进短入口：[docs/planning/daily-start.md](docs/planning/daily-start.md)
- 当前阶段真相源：[docs/planning/current.md](docs/planning/current.md)
- 周志索引：[docs/devlogs/README.md](docs/devlogs/README.md)

## Repository Hygiene

- 仓库文本文件统一使用 UTF-8（无 BOM）、LF 和文件末尾换行；默认格式由 `.editorconfig` 和 `.gitattributes` 约束。
- 提交前至少执行匹配的最小验证；涉及客户端状态、任务、存档、场景或脚本时，优先执行客户端聚合验证。
- 当前仓库还没有 Docker 构建入口；根目录 `.dockerignore` 只提供保守的上下文裁剪基线，避免把编辑器缓存、Git 元数据和生成目录打进未来容器上下文。

常用检查命令：

```powershell
pwsh ./scripts/check-text-files.ps1
pwsh ./scripts/check-client.ps1
git diff --check
```

## Repository Layout

- `client/`：Godot 客户端原型工程。
- `server/`：未来可选服务端或联机实验工程。
- `assets/`：可提交的源资产、设定图、音频源文件等。
- `tools/`：项目脚本、数据处理、构建或导出辅助工具。
- `scripts/`：仓库检查与自动化脚本。
- `docs/`：策划、设计、架构、规划、参考与归档文档。
- `wiki/`：未来面向玩家的 Wiki 源内容。
- `official-tools/`：未来面向玩家的官方辅助工具。
- `.github/`：PR 模板、GitHub Actions 和 ruleset 模板。

## License

本仓库采用 source-available 许可证。代码和资料可在授权平台上查看和学习，但默认不授予复制、修改、再分发、商用或衍生作品权利。详见 [LICENSE](LICENSE)。
