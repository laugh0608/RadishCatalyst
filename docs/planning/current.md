# Current Plan

更新时间：2026-09-05

## 当前阶段

```text
产品方向调整与建造体验实机评价
```

本轮方向以 [Production-Centered Direction](../product/production-centered-direction.md) 为优先真相源：化工生产经营成为核心，探索为生产提供资源、空间和长期目的；战斗体量、美术介质、Web 迁移和随机工业投入的具体系统均未决定。

既有[第一可玩切片全链](../features/slice-first-playable-journey-v1.md)、[试玩反馈整改](../features/slice-playtest-remediation-v1.md)包 0—4、`delivered / 120`、schema 10 及其自动和人工证据全部保留为实现与回归基线。原整改 S0 暂缓，不把旧 20–40 分钟 ARPG 全链当作本阶段退出条件，也不宣称当前生产体验已经通过验证。

## 当前边界

- 小区域工厂片段的合同与实现已经完成：设备放置、真实物流接通、缺料与输出回压观察、补接恢复均有正式 `Boot` 系统路径证据。
- 常态画面采用固定高斜角，建造模式以 `1.5` 档位拉远并显示网格、足印、接口和流向，同时弱化遮挡；继续复用现有素材与实现。
- 操作画面目标、玩家成功标准、失败标准和证据方式已经冻结；当前剩余玩家实机评价。
- 玩家评价完成后再判断是否值得做同范围 Web 对照；当前不决定迁移、重写、具体平台或时间预算。
- 工业研发、试制、勘探和传统抽卡都只是随机投入的候选表达，不进入本轮实现。

## 当前不做

- 不删除既有功能、战斗或历史证据，不改写旧专题和旧周志。
- 不解冻新地图、新敌人、剧情、多人、完整 ARPG、长期多星球实现或新美术生产。
- 不决定像素转 3D、双角度、Web 迁移或整仓重写。
- 不恢复陌生玩家盲测、试玩分发、打包、发布或上传。

## 下一步

[Factory Building Experience Validation V1](../features/factory-building-experience-validation-v1.md) 已完成 Godot 局部实现与正式 `Boot` 输入运行：16:9 窗口 `1440×810` 的 `67` 项断言和 16:10 窗口 `1440×900` 的 `6` 项断言通过，建造缩放冻结为 `1.5`。下一步由萝卜SAMA使用隔离初始世界评价操作读法和手感；暂不做 Web 对照或全仓重构。

## 退出条件

- 工厂片段的起点、操作步骤、结束状态和非目标清楚，且不依赖口头补充。
- 已定义玩家如何完成放置与真实接通，如何看到正常产出、缺料或堵塞，如何通过调整布局改变结果。
- 固定高斜角常态与建造模式的网格、足印、接口、流向、遮挡和缩放目标可评审。
- 成功证据、失败判据和停止／改向条件明确。
- 已完成 Godot 局部实验的建造会话 / 视图实现，并以正式输入链与玩家评价决定是否需要同范围 Web 对照。

## 默认验证

- 文档：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`、`./scripts/check-repo.sh`。
- 本轮 `./scripts/check-client.sh` 静态检查通过；旧完整 `check-client --with-godot` 在最后的焦点 / 缩放小修前通过，焦点专门 probe 通过，修后的正式 `Boot` 路径以 `67 + 6` 项断言通过。后续玩家可见实现仍须遵循 [Godot Runtime Verification Guide](../reference/godot-runtime-verification-guide.md)。
