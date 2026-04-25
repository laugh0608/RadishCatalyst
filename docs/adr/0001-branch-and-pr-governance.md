# ADR 0001: Branch And PR Governance

更新时间：2026-04-25

## 状态

Accepted

## 背景

RadishCatalyst 是刚初始化的新仓库，当前重点不是堆功能，而是先建立能长期协作的仓库地基、文档结构、验证入口和分支治理方式。

如果继续在 `master` 上直接累积所有文档、规范和未来代码，后续很难形成稳定主线，也不利于多人或多代理协作。

## 决策

仓库采用以下分支与 PR 治理策略。

### 分支角色

- `master` / `main`：稳定主线，只接受 Pull Request 合并。
- `dev`：日常集成分支，功能、文档、规范类分支默认合并到这里。
- `feature/*`：功能开发分支。
- `docs/*`：文档、策划和规范分支。
- `chore/*`：基础设施、脚本、CI、仓库治理分支。
- `hotfix/*`：仅用于必须直接修复稳定主线的问题。

### 合并策略

- 默认开发流程为 `feature/*` / `docs/*` / `chore/*` -> `dev`。
- 阶段性稳定后，再通过 PR 将 `dev` 合并到 `master` / `main`。
- 仅在必须修复主线问题时，才允许 `hotfix/*` 直接向 `master` / `main` 发 PR。

### 默认分支规则

- 禁止直接 push。
- 必须通过 PR 合并。
- 必须通过仓库检查。
- 要求 1 个审批和已解决会话。
- 当前允许 `merge commit` 与 `rebase merge`，禁用 `squash merge`。
- 管理员仅可通过 PR 方式绕过规则。
- 允许在单人开发阶段保留管理员 PR 直过能力。

### `dev` 规则

- 允许作为当前阶段默认目标分支。
- 当前阶段不启用分支保护。
- 仍建议保留 CI 检查和 PR 习惯，但不作为强制规则。

## 需要在 GitHub 仓库设置中完成的动作

以下规则不能仅靠仓库文件完全强制，需要仓库管理员在 GitHub Settings 中启用：

1. 创建远端 `dev` 分支。
2. 将日常开发 PR 默认目标设为 `dev`。
3. 对 `master` / `main` 启用 ruleset。
4. 要求 `master` / `main` 通过 `Repo Hygiene` 状态检查。
5. 开启 “Require a pull request before merging”。
6. 仓库 Merge options 中启用 `Merge commits` 与 `Rebase merging`，关闭 `Squash merging`。
7. 配置管理员仅通过 PR 绕过，不开放直接 push。
8. `dev` 当前不配置 branch protection。

## 仓库内已落地的支撑项

- PR 模板：`.github/PULL_REQUEST_TEMPLATE.md`
- GitHub Actions PR 检查工作流：`.github/workflows/pr-check.yml`
- Release / 手动检查工作流：`.github/workflows/release-check.yml`
- 默认分支 ruleset 模板：`.github/rulesets/master-protection.json`
- ruleset 说明：`.github/rulesets/README.md`
- 文本编码与文件格式检查脚本：
  - `scripts/check-text-files.ps1`
  - `scripts/check-text-files.sh`

## 影响

正面影响：

- `master` / `main` 可以保持稳定。
- `dev` 可以作为当前阶段真实集成面。
- 文档、规范、脚本和未来代码都能纳入统一 PR 检查。
- 单人开发阶段仍保留必要的管理员 PR 绕过能力。

代价：

- 需要维护远端 ruleset 和 GitHub 仓库设置。
- 开发节奏从“直接提交”切换为“分支 + PR”。
- 当前只有仓库卫生门禁，未来 Godot 工程建立后需要补充正式构建和测试基线。
