# Daily Start

更新时间：2026-11-14

## 启动读取

先检查 `dev` 工作区并遵循 `AGENTS.md`，再读 [Current Plan](current.md)、[整合基线](demo-consolidation-proposal.md)、[整合总合同](../features/factory-demo-integration-v1.md)和[本周周志](../devlogs/2026-W46.md)。按任务展开核心、科技树、能源与存档子合同；坐标 / 参数使用[布局与预算](../reference/factory-integrated-demo-layout-and-budget.md)。

## 当前交接

- 萝卜SAMA已确认统一 Demo 设计整合、R1-A 镜头与 R1-B `outline-06` 四面轮廓。R1-C / D 代表品质已获认可。B1 / B2 / C 通过基础整合首程验收。
- 核心每物品 99,999、等级解锁能力；初始电力按设备预算确定，固定燃烧与后续可选 PWM；Godot 3D / GDScript、生产经营主线与工业科幻方向已确认。
- 主视角已选：[R1-A](../features/factory-camera-and-representative-scene-v1.md)亲测后，萝卜SAMA选 C2 透视正向、默认 21 格、跟随角色；滚轮调节距离 / 高度，保持俯角与 FOV。R1-B 保持此镜头，旧正式世界镜头尚未接入。
- E1 / E2 / V8 及原 D3 / D4 工程能力继续复用，旧档和亲测进度按原身份保留。D1 开路后收益已完成隔离对照。

<a id="next-day-tasks"></a>

## 当前接续事项

### D2 长期对照 · 停在成对预检

[C3 负载组](../features/factory-load-groups-c3.md)已按 11 月 13 日确认合同接入 schema 15，开发机定向、窗口与跨进程验证见 [W46](../devlogs/2026-W46.md#c3-load-group-delivery)。C3 已提交为 `f5492931`；旧档保留原身份，D2 玩家亲测仍待验。

1. [D2 长期真实产线对照](../features/factory-d2-production-comparison.md)完成 [v4 物流短测与成对预检](../devlogs/2026-W46.md#d2-c3-fault-v4-preflight)。九个断燃周期都观察到 C3 阻断与恢复，L4 的两窗缺电量均未减半。[Fd 排空错峰诊断](../devlogs/2026-W46.md#d2-c3-fd-drain-diagnostic)两窗均达缺电和交付目标，[C3 开工联锁首轮预检](../devlogs/2026-W46.md#d2-c3-interlock-preflight)因驱动参数类型错误未安装联锁，停在样本门禁。v1–v4 和错峰证据已保留。
2. 有新的 D2 / D1 玩家阻断反馈时优先复现和修因；保留基础连续供燃完成主线的路径，不把进阶控制变成必选。
3. 自然长测、独立恢复和窗口复核停在成对预检门禁，正式 P0 与亲测副本未发布。C3 的身份边界见 [schema 15](../architecture/factory-load-groups-save-v15.md)；C2 / C3 短测和离线核算不能代替 D2 整体收益结论。

### 已交付入口与待验

1. [基础整合验收](../devlogs/2026-W45.md#foundation-acceptance)通过。正式菜单选择「整合工厂 · 核心研究与固定燃烧」新建，后续从目录继续。已有亲测档仍用 `sh tools/check-factory-integrated-c.sh play joint-first-run` 继续。
2. 用 `sh tools/check-factory-frontier.sh play <batch>` 开始 [D1 开拓回报](../features/factory-research-and-progression-v1.md#d1-frontier-reward)隔离亲测。从核心 II 的 X2 到胶囊开路，实地把高产矿接回工厂并观察回报。Windows 与目标硬件待验。
3. 旧 V8 亲测仍可显式运行 `tools/runtime-intake/review-worlds/factory-energy-v8-playtest/start.sh practice / c / d`，默认会话 `playtest-20261101-a`；先练习再看收益。它验证旧 V8，不能拿来验证新核心 / 固定燃烧。失焦仍生产，离开前暂停，不自动重开用户关闭的窗口。
4. [D2 C3 负载组](../features/factory-load-groups-c3.md)已接入，含核心 III、E2、C1 和 C2。用 `sh tools/check-factory-grid-controls.sh play c3-load-groups-20261113` 继续已备好的阻断 / 在制检查点；另用新批次新建选择 C3。C2 / C1 / E2 / III 旧档沿原选项继续。D2 玩家亲测仍待验。
5. R1 镜头、四面轮廓及材质对照可从各自独立样板回查。入口和原图索引见 [Factory Content](../../tools/factory-content/README.md)。

## 边界与验证

- D1 公开入口待验收。R1-A 复用旧资产，R1-B 使用自有轮廓；安装依赖、引入外部资产及打包 / 推送 / 发布仍须另行授权。
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
