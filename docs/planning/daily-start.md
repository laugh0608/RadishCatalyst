# Daily Start

更新时间：2026-09-05

计划日期：2026-09-05

## 当前任务

先读 [Current Plan](current.md) 与 [Production-Centered Direction](../product/production-centered-direction.md)。当前阶段是产品方向调整与建造体验实机评价；原试玩整改 S0 暂缓，既有功能和证据继续保留。

## 下一动作

收口已实现的 [Factory Building Experience Validation V1](../features/factory-building-experience-validation-v1.md) Godot 局部实验，重点验证：

1. 玩家从什么资源、设备和场地状态开始。
2. 玩家如何放置设备并真实接通输入、加工和输出。
3. 正常产出、缺料和堵塞分别如何在世界画面与必要 UI 中被看见。
4. 玩家调整布局后，什么变化证明操作有效。
5. 固定高斜角常态与建造模式各显示什么，网格、足印、接口、流向、缩放和遮挡如何配合。
6. 哪些结果算验证成功，哪些失败应停止实现并改向。

合同、源码审计、架构复核和建造实现已汇合；正式 `Boot` 输入运行在 `1440×810` 通过 `67` 项断言、在 `1440×900` 通过 `6` 项断言，建造缩放冻结为 `1.5`。下一步由萝卜SAMA从隔离初始世界复测操作读法和手感；暂不做 Web 对照或全仓重构。

## 当前不进入

- 不执行原整改 S0 或陌生玩家盲测。
- 不生产新美术，不升级 schema 10，不迁移 Web，不重写工程。
- 不扩战斗、剧情、地图、多人、多星球或随机投入系统。
- 不打包、分发、发布或上传。

## 继续前必读

- [Current Plan](current.md)
- [Production-Centered Direction](../product/production-centered-direction.md)
- [Project Definition](../product/project-definition.md)
- [Development Decision Gates](../process/development-decision-gates.md)
- [Factory Building Experience Validation V1](../features/factory-building-experience-validation-v1.md)

## 验证入口

- 文档：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`、`./scripts/check-repo.sh`。
- 本轮 Godot 局部实验和有窗口复核已获授权；后续仍按隔离存档与截图规范执行。
- 实机复测：`./scripts/run-slice-save-review-worlds.sh /Users/luobo/Code/RadishCatalyst/tools/runtime-intake/review-worlds/factory-building-experience-initial`。初始背包含各 `1` 件三机套件和 `9` 条传送带；放置采集器 `(40,11)`、反应器 `(47,10)`、储物箱 `(53,11)`，把箱子切到 `transfer`，逐格铺设输入 `(43..46,12)`（先缺 `46`）和输出 `(50..52,12)`（先缺 `50`），用 `R` 转向并依次补口观察缺料、加工、回压和恢复。
