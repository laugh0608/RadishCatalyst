# Daily Start

更新时间：2026-09-05

计划日期：2026-09-05

## 当前任务

先读 [Current Plan](current.md)、[Production-Centered Direction](../product/production-centered-direction.md) 与 [Small Chemical Factory Visual Target V1](../design/small-chemical-factory-visual-target-v1.md)。当前阶段是小型化工厂视觉目标探索与评审；既有功能和验证证据继续保留。

## 下一动作

查看新设计记录，以推荐的 v2 为主要评审稿、v1 为比例修订对照，并评审四项：

1. 小型化工厂的规模与设备密度是否成立。
2. 左侧输入、中段加工、右侧储存出料及主通道是否可读。
3. 高斜角、矩形足印和两排模块关系是否适合后续装配。
4. 砂岩、平台、漆面 / 金属分区、状态色和阴影是否符合工业科幻气质。

既有 `67 + 6`、物流 / 建造专项 `180` / `152` 与正式窗口 `59` 项断言继续保留。萝卜SAMA对整改后完整操作手感的复评仍是待办，但不是本轮首要动作；功能通过不代表视觉方向通过。

## 当前不进入

- 不执行原整改 S0 或陌生玩家盲测。
- 不批量生产或接入正式资产；仅允许本轮一张目标图及有限修订，不升级 schema 10。
- 不迁移 Web，不切换 3D，不重写工程。
- 不扩战斗、剧情、地图、多人、多星球或随机投入系统。
- 不打包、分发、发布或上传。

## 继续前必读

- [Current Plan](current.md)
- [Production-Centered Direction](../product/production-centered-direction.md)
- [Project Definition](../product/project-definition.md)
- [Development Decision Gates](../process/development-decision-gates.md)
- [Factory Building Experience Validation V1](../features/factory-building-experience-validation-v1.md)
- [Small Chemical Factory Visual Target V1](../design/small-chemical-factory-visual-target-v1.md)

## 验证入口

- 文档：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`、`./scripts/check-repo.sh`。
- 本轮不执行客户端或 Godot 验证；目标图生成成功不代表运行时或视觉验收通过。
- 实机复测：`./scripts/run-slice-save-review-worlds.sh /Users/luobo/Code/RadishCatalyst/tools/runtime-intake/review-worlds/factory-building-experience-initial`。初始背包含各 `1` 件三机套件和 `9` 条传送带；放置采集器 `(40,11)`、反应器 `(47,10)`、储物箱 `(53,11)`，把箱子切到 `transfer`，逐格铺设输入 `(43..46,12)`（先缺 `46`）和输出 `(50..52,12)`（先缺 `50`），用 `R` 转向并依次补口观察缺料、加工、回压和恢复。
