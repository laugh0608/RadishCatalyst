# Daily Start

更新时间：2026-09-06

计划日期：2026-09-06

## 当前任务

先读 [Current Plan](current.md) 与 [Web Topdown 3D Demo V1](../design/web-topdown-3d-demo-v1.md)。已按用户确认完成 Web 真三维样场；原手绘 / 像素 Web 对照、独立 Godot 3D 与二维样板保留。

## 下一动作

1. 用 `sh tools/run-web-topdown-3d-demo.sh` 打开本地三维样场，WASD / 方向键或点击地面移动，Q / E 转角。
2. 比较 40° / 55° / 70°、玻璃管与投影开关、设备前后遮挡；原手绘 / 像素入口 `sh tools/run-web-style-demo.sh` 继续可用。
3. 已有 Godot 3D 入口 `sh tools/run-topdown-3d-demo.sh`、12 张截图与 28 项机制检查继续保留；等待萝卜SAMA选择，不接入正式系统或决定迁移。

既有 `67 + 6`、物流 / 建造专项 `180` / `152` 与正式窗口 `59` 项断言继续保留。萝卜SAMA对整改后完整操作手感的复评仍是待办，但不是本轮首要动作；功能通过不代表视觉方向通过。

## 当前不进入

- 不执行原整改 S0 或陌生玩家盲测。
- 不批量生产或接入正式设备系统；仅制作当前已授权的有限视觉样板，不实现液气物流或升级 schema 10。
- 不迁移 Web，不把正式客户端切换 3D，不重写工程；只制作已授权的隔离对照。
- 不扩战斗、剧情、地图、多人、多星球或随机投入系统。
- 不打包、分发、发布或上传。

## 继续前必读

- [Web Topdown 3D Demo V1](../design/web-topdown-3d-demo-v1.md)
- [Web Style Comparison Demo V1](../design/web-style-comparison-demo-v1.md)

- [Topdown 3D Comparison Demo V1](../design/topdown-3d-comparison-demo-v1.md)

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
