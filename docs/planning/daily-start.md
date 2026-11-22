# Daily Start

更新时间：2026-11-22

## 启动读取

先检查 `dev` 工作区并遵循 `AGENTS.md`，再读 [Current Plan](current.md)、[整合基线](demo-consolidation-proposal.md)、[整合总合同](../features/factory-demo-integration-v1.md)和[本周周志](../devlogs/2026-W47.md)。按任务展开核心、科技树、能源与存档子合同；坐标 / 参数使用[布局与预算](../reference/factory-integrated-demo-layout-and-budget.md)。

## 当前交接

- 萝卜SAMA已确认统一 Demo 设计整合、R1-A 镜头与 R1-B `outline-06` 四面轮廓。R1-C / D 代表品质已获认可。B1 / B2 / C 通过基础整合首程验收。
- 核心每物品 99,999、等级解锁能力；初始电力按设备预算确定，固定燃烧与后续可选 PWM；Godot 3D / GDScript、生产经营主线与工业科幻方向已确认。
- 主视角已选：[R1-A](../features/factory-camera-and-representative-scene-v1.md)亲测后，萝卜SAMA选 C2 透视正向、默认 21 格、跟随角色；滚轮调节距离 / 高度，保持俯角与 FOV。R1-B 保持此镜头，旧正式世界镜头尚未接入。
- E1 / E2 / V8 及原 D3 / D4 工程能力继续复用，旧档和亲测进度按原身份保留。D1 开路后收益已完成隔离对照。

<a id="next-day-tasks"></a>

## 当前接续事项

### E 整段收口 · Mac 正式首程

R2 核心 I / II 已接入正式基础整合，现有 Mac 已复核新档和接入前 schema 9 档的独立继续。联合首程通过状态与正式 Boot 窗口复跑。本机 R2 运行中产线已采样，供燃和加工持续，保留一次约 98 ms 周期保存证据。[正式接入](../devlogs/2026-W47.md#r2-foundation-integration) · [运行中采样](../devlogs/2026-W47.md#e-r2-live-production)

### E 整段收口 · D1 备份恢复复测

正式 Boot 隔离预检和修复复测已完成。主档身份不可读时，以成功保存留下的 `metadata.json` 确认身份，能确认才恢复。两种 D1 身份互换备份、旧摘要缺少身份及身份记录属于其他世界时均拒绝继续，原文件哈希一致。D1 公开入口保持关闭。[修复复测](../devlogs/2026-W47.md#d1-recovery-identity-fix)

### D1 开拓首程候选

正式 Boot 检查从隔离新档跑通基础生产、供燃、开路、回流和扩建。目标栏沿实际线路指向粉碎机、混料炉和回仓目标。两枚由混料板材制得的构件包装配精炼炉，新炉连续两批把四件多孔载体送回核心。物料账、供燃及独立进程继续均通过。[验证记录](../devlogs/2026-W47.md#e-d1-production-guidance)

里程碑空档用 `sh tools/check-factory-frontier.sh play 20261122-d1-expansion-review-01` 打开，进入「工厂世界」继续「D1 首程候选 · 开拓与扩建」。候选从核心 I、零物料开始。集中亲测观察玩家能否独立判断该接哪段线、完成扩建，以及之后想继续解决的经营问题。

如需回查萝卜SAMA的序号 44 原档，运行 `sh tools/check-factory-frontier.sh play 20261122-d1-x2-02`，继续「D1 开拓亲测 · X2 待提交」。X2 与外矿道已完成，人在支路北入口。按目标栏定位组装机，制作四枚胶囊后再到入口按 F。缺采集器时可回核心装配或回收闲置采集器。[原档接续验证](../devlogs/2026-W47.md#d1-frontier-guidance)

收益不清楚就先修反馈或节奏，有调度动机但控制受阻就回到 D2 的独立档观察，暂无动机就保留现有机制。丢货、复制或无法继续的缺陷优先处理。

### D2 长期对照 · 等调度需求证据

schema 16 驱动已修正，首个断燃周期和 Fd 重启两项短测均通过，保留原失败批次及冷父档。[短测记录](../devlogs/2026-W47.md#d2-v5-short-checks)

玩家观察支持继续优化时，才跑 `fault-preflight-v5`。O5 / L5 各两窗，沿用正常 N / B / T / F、原验收门槛和 kW、kWh / Wh 报告口径。任一门禁失败先留证汇报，两窗通过后自然长测仍等萝卜SAMA确认。跨进程恢复、正式窗口复核、正式 P0 和亲测副本待后续。

### 已交付入口与待验

1. [基础整合验收](../devlogs/2026-W45.md#foundation-acceptance)通过。正式菜单选择「整合工厂 · 核心研究与固定燃烧」新建，后续从目录继续。已有亲测档仍用 `sh tools/check-factory-integrated-c.sh play joint-first-run` 继续。
2. [D1 开拓回报](../features/factory-research-and-progression-v1.md#d1-frontier-reward)有核心 I 首程候选与 X2 阶段回查档，入口见上方。
3. 旧 V8 亲测仍可显式运行 `tools/runtime-intake/review-worlds/factory-energy-v8-playtest/start.sh practice / c / d`，默认会话 `playtest-20261101-a`；先练习再看收益。它验证旧 V8，不能拿来验证新核心 / 固定燃烧。失焦仍生产，离开前暂停，不自动重开用户关闭的窗口。
4. [D2 C3 负载组](../features/factory-load-groups-c3.md)已接入，含核心 III、E2、C1 和 C2。用 `sh tools/check-factory-grid-controls.sh play c3-load-groups-20261113` 继续已备好的阻断 / 在制检查点；另用新批次新建选择 C3。C2 / C1 / E2 / III 旧档沿原选项继续。D2 玩家亲测仍待验。
5. R1 镜头、四面轮廓及材质对照可从各自独立样板回查。入口和原图索引见 [Factory Content](../../tools/factory-content/README.md)。

## 边界与验证

- D1 公开入口待验收。R1-A 复用旧资产，R1-B 使用自有轮廓；安装依赖、引入外部资产及打包 / 推送 / 发布仍须另行授权。
- 旧二维与工厂不同 schema / 身份分别保留；不为了统一界面整仓迁入旧代码，不默认提供跨规则转换。
- 新内容布局核算只是纸面证据，不能写成自然主循环、人工可玩性或性能通过。用户亲测和旧 D4 保留项仍在各自的验收记录中跟踪。
- 文档执行 `./scripts/check-docs.sh`、`./scripts/check-repo.sh` 和 `git diff --check`；样板执行客户端静态检查、定向 Godot 检查及窗口路径，不重复旧 Godot 全套或长测。
- Godot / 桌面程序启动前告知；准备页等待开始，关闭即取消，不自动重开。

## 按任务继续阅读

- 核心：[Base Core](../features/factory-base-core-v1.md)。
- 科技树：[Research And Progression](../features/factory-research-and-progression-v1.md)。
- 能源：[Fixed Burn Energy](../features/factory-fixed-burn-energy-v1.md)。
- 存档：[Integrated Demo Save](../architecture/factory-integrated-demo-save-v1.md)。
- 现行配方 / 旧证据：[生产内容扩展](../features/factory-production-expansion-v1.md)、[V8](../architecture/factory-energy-save-v8.md)、[D4](factory-d3-exit-and-d4-validation.md)。
