## 变更说明

请简要说明本次 PR 的目标、范围和原因。

## 关联信息

- 关联 Issue / 任务：
- 目标分支：`dev` / `master` / `main`
- 玩家或开发者结果：
- 明确非目标：
- 变更类型：
  - [ ] 功能
  - [ ] 修复
  - [ ] 重构
  - [ ] 文档
  - [ ] 配置 / 仓库治理
  - [ ] 测试 / 验证基线

## 检查清单

- [ ] 本次改动符合 `docs/planning/current.md` 与当前活跃专题，或已明确说明为何需要例外
- [ ] 已执行对应的最小验证
- [ ] 如修改了架构、阶段边界、流程或规范，已同步更新 `docs/` / `AGENTS.md` / `CLAUDE.md`
- [ ] 如属于本周重要推进，已追加到 `docs/devlogs/YYYY-Www.md`
- [ ] 未直接向 `master` / `main` 提交常规功能改动
- [ ] 普通贡献以 `dev` 为目标；目标为 `master` / `main` 时，本 PR 来自 `dev` 或已说明 hotfix 例外

## 合并后回流

以下步骤只适用于目标为 `master` / `main` 的 PR；完成前不要开始下一轮 `dev` 提交：

- [ ] 本 PR 已使用 `merge commit` 或 `rebase merge` 合并，未使用 `squash merge`
- [ ] 已将最新 `origin/master` / `origin/main` 回流到 `dev`；merge commit 可快进时使用 fast-forward，rebase merge 使用普通 merge
- [ ] 已推送更新后的 `origin/dev` 并确认分支拓扑闭环

## 验证记录

请列出实际执行过的命令，只保留真实跑过的内容：

```text
pwsh ./scripts/check-repo.ps1
./scripts/check-repo.sh
pwsh ./scripts/check-client.ps1
./scripts/check-client.sh
git diff --check
```

## 影响评估

- 文档影响：
  - [ ] 无
  - [ ] 有，已同步更新 `docs/`
- Godot 客户端影响：
  - [ ] 无
  - [ ] 有，已说明影响范围
- 服务端 / 联机影响：
  - [ ] 无
  - [ ] 有，已说明影响范围
- 资产影响：
  - [ ] 无
  - [ ] 有，已说明新增或替换资产来源
- 存档 / 兼容性影响：
  - [ ] 无
  - [ ] 有，已说明 schema、迁移、备份与失败模式

## 风险与后续

- 已知风险：
- 未验证内容：
- 回滚方式：
- 未完成项：
- 后续建议：
