# Daily Start

更新时间：2026-09-06

计划日期：2026-09-06

## 当前任务

先读 [Current Plan](current.md) 与 [Web First Production Line V1](../features/web-first-production-line-v1.md)。按用户确认将当前 Web 三维画面用于第一条亲手搭建的产线，暂停扩展视觉 / 引擎对照。

## 下一动作

1. 用 `sh tools/run-web-topdown-3d-demo.sh` 启动本机服务，进入 `http://127.0.0.1:4318/play/`。
2. 从空场坪放采集器、反应器与终端仓，铺带、观察首件催化剂入仓，再拆开输入并补接恢复。
3. 定向系统与浏览器检查已完成；当前由萝卜SAMA亲测是否看得懂、操作是否顺手、是否愿意扩建，再按反馈确定下一包。

既有 Godot 正式入口、客户端规则 / 存档和历轮视觉证据保留；当前包是有限 Web 体验验证，不代表正式迁移或美术验收。

## 当前不进入

- 不执行原整改 S0 或陌生玩家盲测。
- 不批量生产或接入正式设备系统；仅实现当前三机固体链，不实现液气物流或升级 schema 10。
- 不迁移 Web，不把正式客户端切换 3D，不重写工程；只制作已授权的隔离对照。
- 不扩战斗、剧情、地图、多人、多星球或随机投入系统。
- 不打包、分发、发布或上传。

## 继续前必读

- [Web First Production Line V1](../features/web-first-production-line-v1.md)

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
