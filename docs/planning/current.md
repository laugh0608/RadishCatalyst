# Current Plan

更新时间：2026-09-08

## 当前阶段

```text
独立 Godot 3D 三机产线 Demo 已复核 · 等待与 Web 亲测对照
```

本轮方向以 [Production-Centered Direction](../product/production-centered-direction.md) 为优先真相源：化工生产经营成为核心，探索为生产提供资源、空间和长期目的；战斗体量、美术介质、Web 迁移和随机工业投入的具体系统均未决定。

既有[第一可玩切片全链](../features/slice-first-playable-journey-v1.md)、[试玩反馈整改](../features/slice-playtest-remediation-v1.md)包 0—4、`delivered / 120`、schema 10 及其自动和人工证据全部保留为实现与回归基线；`91f52869` 所含的工厂反馈收口事实不因本轮视觉探索而改写。原整改 S0 继续暂缓，功能与系统路径通过不等于视觉方向通过。

## 当前活跃任务

2026-09-08，萝卜SAMA明确授权先做[独立 Godot 3D 产线 Demo](../features/godot-first-production-line-demo-v1.md)，与已认可的 Web 版本直接对照画面、操作手感和流畅度，再决定正式技术路线。此授权包含本次规划同步与 Demo 实现，不包含正式客户端迁移；技术评估中的“等待确认正式迁移”不是当前任务。

[Web First Production Line V1](../features/web-first-production-line-v1.md) 已获认可的设备造型、50° 视角、光照、单枚接口箭头、拖动铺带与真实弯道作为固定参照。沿用 `tools/visual-studies/topdown-3d/` 独立工程，保留 Web 与旧视觉入口；[技术路线评估](../architecture/production-client-technology-assessment-v1.md) 继续作为建议材料。

## 当前边界

- 当前 Web `/play/` 为预供电、预发构件的三机固体链；真实放置、端口、加工、回压和拆改回收已实现。按亲测反馈试调为 `50°` 正交斜俯视，设备端口常显，建造时显示网格，允许转角 / 缩放；没有自动切换旧 Godot 的 `1.5` 建造倍率，也没有移植其近身 `E` 设备操作。
- 本包刷新即重置，无游戏存档、离线生产或正式 schema 改动。新增局部 Three.js 依赖和 Web 模型只服务隔离体验，不代表与正式 Godot 运行时完整等价。
- 既有 [Godot 工厂片段](../features/factory-building-experience-validation-v1.md) 的端口接缝、建造态移动 / 选择及 `1.5` 建造倍率继续作为已实现基线；手感复评保留，但不是当前首要动作。
- 管道、像素体积、Godot 3D、Web 手绘与 Web 3D 对照均保留为局部证据，按 [Design Documents](../design/README.md) 路由；概念候选与自动检查不等于美术验收。当前以已认可 Web 画面为固定参照，新增同规则 Godot 产线对照，不重新探索画风。
- 正式平台、量产美术、完整工厂负载、液气系统与随机工业投入仍未决定；本轮只授权独立 Godot 产线复现，正式路线待亲测后决定，首包候选与未测风险见技术评估。

## 当前不做

- 不删除既有功能、战斗或历史证据，不改写旧专题和旧周志。
- 只实现本包三机固体生产与调整；不解冻新地图、新敌人、剧情、多人、完整 ARPG 或长期多星球实现。
- 复用当前三维模型并补必要物流几何，不批量生产美术或接入正式设备系统。
- 不决定像素转 3D、双角度、Web 迁移或整仓重写。
- 不恢复陌生玩家盲测、试玩分发、打包、发布或上传。

## 下一步

独立 Godot 同规则复现、定向与窗口复核已完成；由萝卜SAMA从空厂坪亲测移动、放置、拖铺、拆回与生产恢复，并与 Web 直接比较画面、操作和流畅度，再决定正式技术路线。不把自动检查当体验验收，不在亲测选择前推进正式迁移。

## 退出条件

- 玩家能从空场坪放下三种设备，依据实际端口与带向完成首件催化剂入仓。
- 拆输入后耗尽在途 / 在机存料而缺料，补接后新生产的催化剂再次入仓；输出回压也能真实恢复。
- 画面货物、设备状态、库存与物流拓扑一致，拆改回收不丢失或复制物品。
- Godot 定向规则检查与独立入口窗口路径通过，用户对理解、操作与继续扩建意愿的评价单独记录；自动检查不能代替体验验收。
- 本轮只验证三机局部体验；与 Web 对照后由用户评价，不宣称大型工厂性能通过。正式客户端、存档与旧回归证据保留。

## 默认验证

- 文档：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`、`./scripts/check-repo.sh`。
- 当前执行 Godot Demo 的规则 / Web 对照检查和独立产线入口窗口路径；日志、截图与未覆盖项见活跃专题，不替换正式 Boot。
- Godot Demo：`sh tools/check-godot-production-demo.sh`、`sh tools/run-topdown-3d-demo.sh --verify-production`，补充窗口为 `--verify-navigation`。开窗前先告知；旧正式 Boot 与完整套件证据保持独立，不混算为本包通过。
