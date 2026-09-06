# Daily Start

更新时间：2026-09-06

计划日期：2026-09-06

## 当前任务

先读 [Current Plan](current.md) 与 [Raised Pipe Module Visual Validation V1](../design/raised-pipe-module-visual-validation-v1.md)。有限可拼接管道、动态内容及隔离实机验证已按授权完成，当前等待连续装配的体积评价。

## 下一动作

1. 用 `sh tools/run-raised-pipe-modules.sh` 打开独立复核世界，查看九段 L 形架空管路。
2. 比较流动 / 停流 / 空管、反向及建造倍率，用 WASD 观察前后遮挡；自动证据已在合同中记录，需要重跑时加 `--verify`。
3. 回填连续装配的体积评价，决定保留或修正；不进入真实液气系统。工厂 v2 整体评价仍独立待办。

既有 `67 + 6`、物流 / 建造专项 `180` / `152` 与正式窗口 `59` 项断言继续保留。萝卜SAMA对整改后完整操作手感的复评仍是待办，但不是本轮首要动作；功能通过不代表视觉方向通过。

## 当前不进入

- 不执行原整改 S0 或陌生玩家盲测。
- 不批量生产或接入正式设备系统；仅制作当前已授权的有限视觉样板，不实现液气物流或升级 schema 10。
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
- [Transparent Pipe Module Visual Validation V1](../design/transparent-pipe-module-visual-validation-v1.md)
- [Industrial Volume Visual Study V1](../design/industrial-volume-visual-study-v1.md)
- [Raised Pipe Module Visual Validation V1](../design/raised-pipe-module-visual-validation-v1.md)

## 验证入口

- 文档：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`、`./scripts/check-repo.sh`。
- 当前体积样板已执行像素归一、客户端静态与正式 `Boot` 定向验证；原图和证据以本包合同为准。上一模块包证据独立保留，不混算本轮检查数量。
- 实机复测：`./scripts/run-slice-save-review-worlds.sh /Users/luobo/Code/RadishCatalyst/tools/runtime-intake/review-worlds/factory-building-experience-initial`。初始背包含各 `1` 件三机套件和 `9` 条传送带；放置采集器 `(40,11)`、反应器 `(47,10)`、储物箱 `(53,11)`，把箱子切到 `transfer`，逐格铺设输入 `(43..46,12)`（先缺 `46`）和输出 `(50..52,12)`（先缺 `50`），用 `R` 转向并依次补口观察缺料、加工、回压和恢复。
