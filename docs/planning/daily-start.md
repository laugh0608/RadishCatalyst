# Daily Start

更新时间：2026-09-06

计划日期：2026-09-06

## 当前任务

先读 [Current Plan](current.md)、[Small Chemical Factory Visual Target V1](../design/small-chemical-factory-visual-target-v1.md) 与 [Transparent Pipe Module Visual Validation V1](../design/transparent-pipe-module-visual-validation-v1.md)。透明管段、金属接头和管壁动态双箭头方向已获认可；有限模块制作与 Godot 定向验证完成，当前等待样板实机视觉评价。

## 下一动作

萝卜SAMA反馈当前效果尚未达到预期，先提交成果并暂停推进，等待进一步想法。恢复后可按管道模块合同复核：

1. 用 `sh tools/run-pipe-visual-study.sh` 打开独立复核世界。
2. 查看水平 / 竖直直管、代表弯头与端接头的管径、金属占比和拼接读法。
3. 切换常态 / 建造倍率及输送、停流、空管、物质色和反向，评价双箭头运动与辨识。
4. 把用户评价回填管道模块合同，再决定后续范围；工厂 v2 整体评价仍独立待办。

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

## 验证入口

- 文档：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`、`./scripts/check-repo.sh`。
- 本轮执行客户端静态与 Godot 隔离视觉验证；生成成功不代表模块或运行时验收通过。目录、入口与判据见管道模块合同。
- 实机复测：`./scripts/run-slice-save-review-worlds.sh /Users/luobo/Code/RadishCatalyst/tools/runtime-intake/review-worlds/factory-building-experience-initial`。初始背包含各 `1` 件三机套件和 `9` 条传送带；放置采集器 `(40,11)`、反应器 `(47,10)`、储物箱 `(53,11)`，把箱子切到 `transfer`，逐格铺设输入 `(43..46,12)`（先缺 `46`）和输出 `(50..52,12)`（先缺 `50`），用 `R` 转向并依次补口观察缺料、加工、回压和恢复。
