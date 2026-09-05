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

上一轮 `67 + 6` 项正式 `Boot` 证据与 `1.5` 建造缩放继续保留。玩家反馈实现与系统验证现已完成：储物箱左右真实端口接缝会按模式、方向、邻接与调整结果刷新；建造态保留 `WASD` 与近身 `E`，无放置预览时可鼠标选择已有设备并从既有面板调整，战斗、UI 防穿透和 `Esc` 层级边界不变。新物流 / 建造专项分别通过 `180` / `152` 项断言，正式窗口路径通过 `59` 项断言并覆盖载货传送带禁止调整后的货物 / 位置保持，原图已由主会话审阅；下一步由萝卜SAMA使用独立反馈初始档实机复评完整手感，不提前宣称体验通过。

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
