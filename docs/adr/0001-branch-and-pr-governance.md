# ADR 0001: Branch And PR Governance

更新时间：2026-07-12

## 状态

Accepted

## 背景

RadishCatalyst 是刚初始化的新仓库，当前重点不是堆功能，而是先建立能长期协作的仓库地基、文档结构、验证入口和分支治理方式。

如果继续在 `master` 上直接累积所有文档、规范和未来代码，后续很难形成稳定主线，也不利于多人或多代理协作。

## 决策

仓库采用以下分支与 PR 治理策略。

### 分支角色

- `master` / `main`：稳定主线，只接受 Pull Request 合并，并作为每轮阶段合并后的拓扑锚点。
- `dev`：常态开发与日常集成分支，允许直接承载日常开发提交；开始下一轮开发前必须包含默认分支最新提交。
- `feature/*`：功能开发分支。
- `docs/*`：文档、策划和规范分支。
- `chore/*`：基础设施、脚本、CI、仓库治理分支。
- `hotfix/*`：仅用于必须直接修复稳定主线的问题。

### 分支拓扑闭环

稳定主线与开发分支不是只做 `dev -> master` 的单向同步，而是每轮形成闭环：

```text
日常开发 -> dev -> PR / merge commit -> master
              ^                         |
              +---- fast-forward -------+
```

- `dev` 向 `master` / `main` 的 PR 必须使用 `merge commit`，保留 `dev` 头提交作为父节点，使合并后的默认分支可以直接快进回 `dev`。
- PR 合并后暂停向 `dev` 添加新提交；先拉取远端，并将 `dev` 快进到新的 `origin/master` / `origin/main`，推送 `origin/dev` 后再开始下一轮开发。
- 标准回流命令为 `git fetch origin`、`git switch dev`、`git pull --ff-only origin dev`、`git merge --ff-only origin/master`、`git push origin dev`；默认分支为 `main` 时替换对应名称。
- 若 `--ff-only` 失败，说明同步窗口内已有新提交或远端拓扑异常；不得 `reset`、rebase 或 force push 共享 `dev`，应先检查分支图，再用普通 merge 将默认分支合回 `dev` 并执行匹配验证。
- `hotfix/*` 等例外 PR 合入默认分支后也必须执行同样的默认分支到 `dev` 回流，避免修复只停留在稳定主线。

### 合并策略

- 默认开发流程在 `dev` 上推进；需要隔离风险时可使用 `feature/*` / `docs/*` / `chore/*` 分支，再由人工决定是否并回 `dev`。
- 阶段性稳定后，再通过 PR 将 `dev` 合并到 `master` / `main`。
- 每次默认分支 PR 合并后，必须完成默认分支到 `dev` 的回流，闭环完成前不开始下一轮日常开发。
- 仅在必须修复主线问题时，才允许 `hotfix/*` 直接向 `master` / `main` 发 PR。

### 默认分支规则

- 禁止直接 push。
- 必须通过 PR 合并。
- 必须通过仓库检查；默认分支 PR 的 `Repo Hygiene` 覆盖文本卫生、文档篇幅、客户端静态数据、客户端场景引用和提交 diff 空白检查。
- 要求 1 个审批和已解决会话。
- `dev` 向默认分支的阶段 PR 使用 `merge commit`；禁用 `rebase merge` 与 `squash merge`，避免复制提交身份后无法快进回流。
- 管理员仅可通过 PR 方式绕过规则。
- 允许在单人开发阶段保留管理员 PR 直过能力。

### `dev` 规则

- 作为当前阶段常态开发分支。
- 当前阶段不启用分支保护。
- 仍建议按改动范围执行本地检查；日常 `dev` 集成不默认触发 CI，也不要求通过 PR 进入 `dev`。
- 默认分支 PR 合并后，`dev` 必须先同步到默认分支最新 merge commit；同步完成前不得承载下一轮提交。

## 需要在 GitHub 仓库设置中完成的动作

以下规则不能仅靠仓库文件完全强制，需要仓库管理员在 GitHub Settings 中启用：

1. 创建远端 `dev` 分支。
2. 保持日常开发在 `dev` 推进，阶段性稳定后从 `dev` 向默认分支发 PR；合并后先把默认分支快进回 `dev`。
3. 对 `master` / `main` 启用 ruleset。
4. 要求 `master` / `main` 通过 `Repo Hygiene` 状态检查。
5. 开启 “Require a pull request before merging”。
6. 仓库 Merge options 中只启用 `Merge commits`，关闭 `Rebase merging` 与 `Squash merging`。
7. 配置管理员仅通过 PR 绕过，不开放直接 push。
8. `dev` 当前不配置 branch protection，但每次默认分支 PR 合并后必须完成回流。

## 仓库内已落地的支撑项

- PR 模板：`.github/PULL_REQUEST_TEMPLATE.md`
- GitHub Actions PR 检查工作流：`.github/workflows/pr-check.yml`
- Release / 手动检查工作流：`.github/workflows/release-check.yml`
- 默认分支 ruleset 模板：`.github/rulesets/master-protection.json`
- ruleset 说明：`.github/rulesets/README.md`
- 文本编码与文件格式检查脚本：
  - `scripts/check-text-files.ps1`
  - `scripts/check-text-files.sh`
- 文档篇幅检查脚本：
  - `scripts/check-docs.ps1`
  - `scripts/check-docs.sh`
- 客户端默认检查脚本：
  - `scripts/check-client.ps1`
  - `scripts/check-client.sh`

当前默认分支 PR 的 CI 强制仓库卫生、文档篇幅、客户端静态数据、客户端场景引用和提交 diff 空白检查。默认 `check-client` 不启动 Godot；需要 Godot 可执行文件的运行时验证按改动范围在本地或手动流程显式执行，等 GitHub runner 上 Godot 环境稳定后再评估是否纳入必过 CI。

## 影响

正面影响：

- `master` / `main` 可以保持稳定。
- `dev` 可以作为当前阶段真实开发与集成面。
- 默认分支的 merge commit 会及时进入 `dev`，分支拓扑保持单一闭环，不再累计只存在于稳定主线的历史节点。
- 文档、规范、脚本和未来代码都能纳入统一 PR 检查。
- 单人开发阶段仍保留必要的管理员 PR 绕过能力。

代价：

- 需要维护远端 ruleset 和 GitHub 仓库设置。
- 开发节奏从“直接提交”切换为“分支 + PR”。
- 每次默认分支 PR 合并后增加一次快进回流与推送步骤，完成前不能继续向 `dev` 提交。
- 当前只有仓库卫生门禁，未来 Godot 工程建立后需要补充正式构建和测试基线。
