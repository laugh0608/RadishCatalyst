# Daily Start

更新时间：2026-09-06

计划日期：2026-09-06

## 当前任务

先读 [Current Plan](current.md) 与 [Industrial Volume Visual Study V1](../design/industrial-volume-visual-study-v1.md)。用户反馈候选 v2“有点那种感觉了”，随后授权的独立素材与正常游戏比例定向验证已完成；当前等待实机体积评价。

## 下一动作

1. 用 `sh tools/run-industrial-volume-study.sh` 打开独立复核世界，查看一台设备与一段架空管道。
2. 用底部按钮比较阴影 / 支撑及两种现有地面，`WASD` 查看角色前后遮挡；确认正常比例下体积是否保住。
3. 回填用户评价；建造态弱化与网格遮盖、玻璃细节损失仍待判断，不自动扩设备族或再生成。工厂 v2 整体评价仍独立待办。

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

## 验证入口

- 文档：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`、`./scripts/check-repo.sh`。
- 当前体积样板已执行像素归一、客户端静态与正式 `Boot` 定向验证；原图和证据以本包合同为准。上一模块包证据独立保留，不混算本轮检查数量。
- 实机复测：`./scripts/run-slice-save-review-worlds.sh /Users/luobo/Code/RadishCatalyst/tools/runtime-intake/review-worlds/factory-building-experience-initial`。初始背包含各 `1` 件三机套件和 `9` 条传送带；放置采集器 `(40,11)`、反应器 `(47,10)`、储物箱 `(53,11)`，把箱子切到 `transfer`，逐格铺设输入 `(43..46,12)`（先缺 `46`）和输出 `(50..52,12)`（先缺 `50`），用 `R` 转向并依次补口观察缺料、加工、回压和恢复。
