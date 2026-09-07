# Current Plan

更新时间：2026-09-07

## 当前阶段

```text
Web 三维产线体验收口 · 正式技术路线评估待确认
```

本轮方向以 [Production-Centered Direction](../product/production-centered-direction.md) 为优先真相源：化工生产经营成为核心，探索为生产提供资源、空间和长期目的；战斗体量、美术介质、Web 迁移和随机工业投入的具体系统均未决定。

既有[第一可玩切片全链](../features/slice-first-playable-journey-v1.md)、[试玩反馈整改](../features/slice-playtest-remediation-v1.md)包 0—4、`delivered / 120`、schema 10 及其自动和人工证据全部保留为实现与回归基线；`91f52869` 所含的工厂反馈收口事实不因本轮视觉探索而改写。原整改 S0 继续暂缓，功能与系统路径通过不等于视觉方向通过。

## 当前活跃任务

萝卜SAMA要求转向正式技术路线评估，不继续追加 Demo 功能。[Production Client Technology Assessment V1](../architecture/production-client-technology-assessment-v1.md) 已完成：推荐 Godot 3D 桌面正式化，以已认可的 Web 画面与操作为验收参照；这是待确认建议，尚未批准迁移。

萝卜SAMA已确认 [Web First Production Line V1](../features/web-first-production-line-v1.md)：暂定当前 Web 三维画面，在独立入口验证放置三机、接通固体物流、真实产出、断路停产与补接恢复。9 月 7 日亲测认可整体效果，并要求减少文字遮挡、试调 50°、强化端口标识和连续铺带。原二维 / 三维视觉对照保留；正式引擎、介质迁移与量产美术仍未决定。

## 当前边界

- 当前 Web `/play/` 为预供电、预发构件的三机固体链；真实放置、端口、加工、回压和拆改回收已实现。按亲测反馈试调为 `50°` 正交斜俯视，设备端口常显，建造时显示网格，允许转角 / 缩放；没有自动切换旧 Godot 的 `1.5` 建造倍率，也没有移植其近身 `E` 设备操作。
- 本包刷新即重置，无游戏存档、离线生产或正式 schema 改动。新增局部 Three.js 依赖和 Web 模型只服务隔离体验，不代表与正式 Godot 运行时完整等价。
- 既有 [Godot 工厂片段](../features/factory-building-experience-validation-v1.md) 的端口接缝、建造态移动 / 选择及 `1.5` 建造倍率继续作为已实现基线；手感复评保留，但不是当前首要动作。
- 管道、像素体积、Godot 3D、Web 手绘与 Web 3D 对照均保留为局部证据，按 [Design Documents](../design/README.md) 路由；概念候选与自动检查不等于美术验收。当前暂定 Web 三维承载产线，暂停追加画风和引擎对照。
- 正式平台、量产美术、完整工厂负载、液气系统与随机工业投入仍未决定；本轮视觉修正已获认可，正式路线建议待确认，首包候选与未测风险见技术评估。

## 当前不做

- 不删除既有功能、战斗或历史证据，不改写旧专题和旧周志。
- 只实现本包三机固体生产与调整；不解冻新地图、新敌人、剧情、多人、完整 ARPG 或长期多星球实现。
- 复用当前三维模型并补必要物流几何，不批量生产美术或接入正式设备系统。
- 不决定像素转 3D、双角度、Web 迁移或整仓重写。
- 不恢复陌生玩家盲测、试玩分发、打包、发布或上传。

## 下一步

确认[正式技术路线评估](../architecture/production-client-technology-assessment-v1.md)中的 Godot 3D 桌面推荐及迁移代价，再冻结“正式三维工厂基础与持久化”功能专题，明确存档兼容、目标机、规模和画面验收。当前不追加 Web Demo 功能，也不在确认前修改正式客户端。原产线退出条件作为已完成包的验证合同保留。

## 退出条件

- 玩家能从空场坪放下三种设备，依据实际端口与带向完成首件催化剂入仓。
- 拆输入后耗尽在途 / 在机存料而缺料，补接后新生产的催化剂再次入仓；输出回压也能真实恢复。
- 画面货物、设备状态、库存与物流拓扑一致，拆改回收不丢失或复制物品。
- 模型检查与真实浏览器路径通过，用户对理解、操作与继续扩建意愿的评价单独记录；自动检查不能代替体验验收。
- 本轮只验证局部体验，正式客户端、存档与旧回归证据保留。

## 默认验证

- 文档：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`、`./scripts/check-repo.sh`。
- Web 产线执行本专题 Node 定向测试及真实浏览器放置 / 连接 / 断路恢复；日志、截图与未覆盖项见专题，不替换正式 Boot。
- 后续若修改正式客户端或重做 Godot 样板，再按对应专题及 [Godot Runtime Verification Guide](../reference/godot-runtime-verification-guide.md) 选择静态 / 窗口验证；开窗前先告知。旧正式 Boot、完整套件和各批定向结果均保持独立，不混算为本包通过。
