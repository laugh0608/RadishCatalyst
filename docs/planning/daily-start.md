# Daily Start

更新时间：2026-11-07

## 启动读取

先检查 `dev` 工作区并遵循 `AGENTS.md`，再读 [Current Plan](current.md)、[整合基线](demo-consolidation-proposal.md)、[整合总合同](../features/factory-demo-integration-v1.md)和[本周周志](../devlogs/2026-W45.md)。按任务展开核心、科技树、能源与存档子合同；坐标 / 参数使用[布局与预算](../reference/factory-integrated-demo-layout-and-budget.md)。

## 当前交接

- 萝卜SAMA已确认统一 Demo 设计整合、R1-A 镜头与 R1-B 轮廓实施；轮廓已按亲测反馈改为四面各三进一出，`outline-06` 已获萝卜SAMA认可。R1-C / D 代表品质已获认可。正式核心 / 研究 / 能源 / 存档代码继续冻结。
- 核心每物品 99,999、等级解锁能力；初始电力按设备预算确定，固定燃烧与后续可选 PWM；Godot 3D / GDScript、生产经营主线与工业科幻方向已确认。
- 主视角已选：[R1-A](../features/factory-camera-and-representative-scene-v1.md)亲测后，萝卜SAMA选 C2 透视正向、默认 21 格、跟随角色；滚轮调节距离 / 高度，保持俯角与 FOV。R1-B 保持此镜头，旧正式世界镜头尚未接入。
- E1 / E2 / V8 及原 D3 / D4 工程能力继续复用；客户端当前仍按旧合同运行，旧档和亲测进度保留。E3 支路未实现，开路后持续收益纳入统一路线设计。

<a id="next-day-tasks"></a>

## 当前接续事项

11 月 7 日 `outline-04` 完成 12 口遮挡复测。收到亲测反馈后，另建四面 16 口的 `outline-05`；`outline-06` 将南侧低支座移到外角。直带、四角装饰与复测见 [R1-B](../features/factory-camera-and-representative-scene-v1.md#r1-b-outline-06)。

当前 R1-B 在 macOS 双击 `tools/factory-content/core-study.command` 或执行 `sh tools/factory-content/core-study.sh`，默认 C2 / 21 / 跟随；保留 R1-A `camera-study.command`。两者仅为独立样板，均不接新核心玩法或世界存档。

1. 从认可的 [R1-C / D](../features/factory-camera-and-representative-scene-v1.md#r1-material-review) 提取 R2 首件规范。复看可用 `tools/factory-content/material-study.command` 切换 M0、M1 岩土和 M1 工作面。
2. [四面版 S0 / S1-P](../reference/factory-integrated-demo-layout-and-budget.md#four-sided-layout) 布线已复算，接续核对自举、自然供给与能源收益；360 kW、研究 / 升级成本和新 schema 仍为设计。跨进程存读、自然生产与目标平台待后续正式实现验证。
3. 旧 V8 亲测仍可显式运行 `tools/runtime-intake/review-worlds/factory-energy-v8-playtest/start.sh practice / c / d`，默认会话 `playtest-20261101-a`；先练习再看收益。它验证旧 V8，不能拿来验证新核心 / 固定燃烧。失焦仍生产，离开前暂停，不自动重开用户关闭的窗口。

## 边界与验证

- 正式玩法处于设计整合，R1-A 复用旧资产，R1-B 仅新增自有轮廓；不安装依赖、不导入外部资产包、不修改活动世界，不打包 / 推送 / 发布。
- 旧二维与工厂不同 schema / 身份分别保留；不为了统一界面整仓迁入旧代码，不默认提供跨规则转换。
- 新内容布局核算只是纸面证据，不能写成自然主循环、人工可玩性或性能通过。用户亲测、Windows / PowerShell、目标硬件与旧 D4 保留项继续区分。
- 文档执行 `./scripts/check-docs.sh`、`./scripts/check-repo.sh` 和 `git diff --check`；样板执行客户端静态检查、定向 Godot 检查及窗口路径，不重复旧 Godot 全套或长测。
- Godot / 桌面程序启动前告知；准备页等待开始，关闭即取消，不自动重开。

## 按任务继续阅读

- 核心：[Base Core](../features/factory-base-core-v1.md)。
- 科技树：[Research And Progression](../features/factory-research-and-progression-v1.md)。
- 能源：[Fixed Burn Energy](../features/factory-fixed-burn-energy-v1.md)。
- 存档：[Integrated Demo Save](../architecture/factory-integrated-demo-save-v1.md)。
- 现行配方 / 旧证据：[生产内容扩展](../features/factory-production-expansion-v1.md)、[V8](../architecture/factory-energy-save-v8.md)、[D4](factory-d3-exit-and-d4-validation.md)。
