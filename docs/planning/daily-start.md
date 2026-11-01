# Daily Start

更新时间：2026-11-01

## 启动读取

先检查 `dev` 工作区并遵循 `AGENTS.md`，再读 [Current Plan](current.md)、[整合基线](demo-consolidation-proposal.md)、[整合总合同](../features/factory-demo-integration-v1.md)和[本周周志](../devlogs/2026-W44.md)。按任务展开核心、科技树、能源与存档子合同；坐标 / 参数使用[布局与预算](../reference/factory-integrated-demo-layout-and-budget.md)。

## 当前交接

- 萝卜SAMA已确认统一 Demo 设计整合、R1-A 镜头与 R1-B 轮廓实施；当前轮廓可试玩但端口边缘遮挡未通过，按两次失败规则等待路线复盘确认。正式核心 / 研究 / 能源 / 存档代码继续冻结。
- 核心每物品 99,999、等级解锁能力；初始电力按设备预算确定，固定燃烧与后续可选 PWM；Godot 3D / GDScript、生产经营主线与工业科幻方向已确认。
- 主视角已选：[R1-A](../features/factory-camera-and-representative-scene-v1.md)亲测后，萝卜SAMA选 C2 透视正向、默认 21 格、跟随角色；滚轮调节距离 / 高度，保持俯角与 FOV。R1-B 保持此镜头，旧正式世界镜头尚未接入。
- E1 / E2 / V8 及原 D3 / D4 工程能力继续复用；客户端当前仍按旧合同运行，旧档和亲测进度保留。E3 支路未实现，开路后持续收益纳入统一路线设计。

<a id="next-day-tasks"></a>

## 当前接续事项

11 月 1 日日终：R1-B 已提交为 `ce37059b`，今天停止开发；收尾建议仅记入接续事项，不视为第三次几何调整已获授权。原图、失败条件和复盘见[R1-B](../features/factory-camera-and-representative-scene-v1.md#r1-b-outline)。

当前 R1-B 在 macOS 双击 `tools/factory-content/core-study.command` 或执行 `sh tools/factory-content/core-study.sh`，默认 C2 / 21 / 跟随；保留 R1-A `camera-study.command`。两者仅为独立样板，均不接新核心玩法或世界存档。

1. 下次先确认 R1-B 的明确收尾包：仅内收后仓储块 / 前角支座，保持 C2、6×6、12 口 / 接带高、I / II 包围与当前材质预算。不新增贴图、消隐或核心玩法。
2. 获确认后按同一 1,051 项条件复核，重点看 `IN_N0 / IN_N3` 内沿与 `IN_W1 / OUT_E3` 前边缘，再补默认起点、近身、四侧 / 四角及最小窗口原图；96 项失败是多种镜头 / 位置 / 等级下的边缘断言，不是 96 个端口。通过后再由萝卜SAMA审阅轮廓。
3. R1-B 收口后再明确 R1-C / D 授权。正式整合仍未实现，不把 I / II 网格切换当升级、不把接带外观当物流，也不把角色样点当全身可见率。
4. 保留[总合同](../features/factory-demo-integration-v1.md)的并行构件布局 / 自举与能源预算审阅；360 kW、研究 / 升级成本和新 schema 仍为设计。跨进程存读、自然生产与目标平台待后续正式实现验证。
5. 旧 V8 亲测仍可显式运行 `tools/runtime-intake/review-worlds/factory-energy-v8-playtest/start.sh practice / c / d`，默认会话 `playtest-20261101-a`；先练习再看收益。它验证旧 V8，不能拿来验证新核心 / 固定燃烧。失焦仍生产，离开前暂停，不自动重开用户关闭的窗口。

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
