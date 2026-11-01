# Daily Start

更新时间：2026-11-01

## 启动读取

先检查 `dev` 工作区并遵循 `AGENTS.md`，再读 [Current Plan](current.md)、[整合基线](demo-consolidation-proposal.md)、[整合总合同](../features/factory-demo-integration-v1.md)和[本周周志](../devlogs/2026-W44.md)。按任务展开核心、科技树、能源与存档子合同；坐标 / 参数使用[布局与预算](../reference/factory-integrated-demo-layout-and-budget.md)。

## 当前交接

- 萝卜SAMA已确认统一 Demo 的设计整合，并另授权 R1-A 隔离镜头样板；样板已交付，正式核心 / 研究 / 能源 / 存档代码继续冻结，不把方向确认当成运行通过。
- 核心每物品 99,999、等级解锁能力；初始电力按设备预算确定，固定燃烧与后续可选 PWM；Godot 3D / GDScript、生产经营主线与工业科幻方向已确认。
- 主视角已选：[R1-A](../features/factory-camera-and-representative-scene-v1.md)亲测后，萝卜SAMA选 C2 透视正向、默认 21 格、跟随角色；滚轮调节距离 / 高度，保持俯角与 FOV。旧正式世界镜头尚未接入，下一步按 C2 明确核心结构样板。
- E1 / E2 / V8 及原 D3 / D4 工程能力继续复用；客户端当前仍按旧合同运行，旧档和亲测进度保留。E3 支路未实现，开路后持续收益纳入统一路线设计。

<a id="next-day-tasks"></a>

## 当前接续事项

资产盘点为 `2fe4beb7`，R1 设计已提交为 `31efe2ae`。R1-A 已实施并获萝卜SAMA选择 C2；在 macOS 双击 `tools/factory-content/camera-study.command` 或执行 `sh tools/factory-content/camera-study.sh`，准备页点击开始，默认 C2 / 21 格 / 跟随。具体入口、原生记录与限制见[R1 方案](../features/factory-camera-and-representative-scene-v1.md)。[核心 / 材质需求](../design/factory-representative-asset-brief-v1.md)仍未实施，不迁删旧资产。

1. 真相源同步及四类合同首轮已完成；依[总合同](../features/factory-demo-integration-v1.md)审阅核心足印 / 端口 / 库存和研究 / 升级事务。S0 / S1 离线几何已通过，继续核对能源 / 构件并行布局与供给成本，不重复宣称自然路径通过。
2. 复核完整电池链 + 其他生产的峰值 / 平均 / 待机、首颗与恢复路径；明确固定燃烧的实际释能 / 弃能，避免沿用 V8 供用相等的全部前提。
3. 复核新世界身份、严格字段、研究 / 升级消费账与固定燃烧余时；后续储能 / 控制单独版本化，不静默改变已经发布的规则。
4. R1-A 已完成隔离 Boot、定向断言、必要原生窗口路径与镜头方向选择；R1-B 核心轮廓和正式玩法代码另定范围。新整合世界的跨进程存读、自然生产及目标平台仍待后续实现验证。
5. 旧 V8 亲测仍可显式运行 `tools/runtime-intake/review-worlds/factory-energy-v8-playtest/start.sh practice / c / d`，默认会话 `playtest-20261101-a`；先练习再看收益。它验证旧 V8，不能拿来验证新核心 / 固定燃烧。失焦仍生产，离开前暂停，不自动重开用户关闭的窗口。

## 边界与验证

- 正式玩法处于设计整合，R1-A 只实例化旧资产；不安装依赖、不导入外部资产包、不修改活动世界，不打包 / 推送 / 发布。
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
