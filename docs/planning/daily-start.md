# Daily Start

更新时间：2026-09-25

## 当前任务

先读 [Current Plan](current.md)、[Factory Discovery And Production V1](../features/factory-discovery-and-production-v1.md)、[Factory Power And Grid V1](../features/factory-power-and-grid-v1.md) 和 [Factory Production Statistics V1](../features/factory-production-statistics-v1.md)，涉及兼容时再读[现行存档合同](../architecture/factory-world-state-and-save-v1.md)。正式三维工厂 P1–P3 开发机交付收口，亲测反馈“没啥问题”；Windows / 目标平台最终验收仍待完成。发现、基础电力与统计提案已对齐。当前等待联合范围确认后实施，首个动手包为 D1 场景与资产验证。

9 月 25 日经萝卜SAMA明确通知重新开始，正式 Godot 完成四档各 450 秒，共 `1800.015679s`，29 项检查通过、无失焦或错误。帧 p95 为 `8.726 / 8.562 / 8.808 / 9.696ms`，60 次采样内自动保存全部成功；四张原图已审阅。本次独立完整运行不拼接此前中断样本，详细证据见 [W39 周志](../devlogs/2026-W39.md)。

## 已完成与交接

- 正式 Boot 工厂入口、独立 schema 1 与旧二维入口保持隔离。此前多线操作、满载存读、规模拆改、时钟和 30 分钟后台稳定性证据继续有效；后台长测不替代前台验收。
- 生产视图按模型身份、revision 和 time 同步，状态灯共享同形网格与只读材质；画面状态 15 项、与原实现等价比较 28,806 项通过，绘制调用 p95 从 557 降至 508。
- 系统关闭保存 17 项、独立进程 Boot 恢复 15 项已通过。隔离世界 `native-close-20260912-a` 保留，已有原生关闭 / 重进证据可复用。
- 第二版分析器 `postwait-v2/analyze_postwait.py` 已完成，34 项离线测试在普通 / `-O` 模式各通过；8 项离线执行记录包含命令行失败与保护检查。原诊断二进制和 8 份源码 hash 未变。
- 窗口批次 `on-20260925-133319` 完成 15 秒预热 / 45 秒生产，359,359 条事件零丢弃、8,590 次等待无超时；5,390 个生产绘制帧分段守恒。记录在显示设备析构前结束，3 个仍存活 fence 单列，不伪造销毁证据。
- 该诊断轮交付 125 件、900 模拟步、自动保存成功；唯一超过预算的原始帧区间为 `102.525ms`，其中自动保存占 `98.630ms`，对应绘制跨度仅 `1.743ms`。初始状态与历史对照相同，最终状态仅正常时间余量不同；原图有 8 个像素差异，已实际审阅，不声称字节一致。

- 本日前次正式版本短测批次 `official-20260925-135157` 完成 45 秒生产，8 项检查通过，帧 p95 `8.680ms`；原图与本日诊断图字节一致。长测 `performance-1790315800-15236` 保留 220.697779 秒、26,411 帧、7 次成功自动保存，但 `phases=[]`，不计验收；随后完整通过批次为 `performance-1790317200-22165`。
- `sh ./scripts/check-client.sh --with-godot` 首次沙箱执行有 FreeType 字体错误；经授权在主机重跑全部 74 个 Godot 入口（含导入）通过，原始日志无未预期错误。失败与成功日志分别保留，不能因此扩大错误忽略规则。
- 等待前台时段期间已完成 Boot / 存档 / 锁的离线验收审计，核对 16 份结果、存档检查日志与 10 份源码。可复用项、合成 / 原生输入及尚缺界面证据见[玩家路径证据核对](../features/factory-foundation-and-persistence-v1.md#玩家路径证据核对)，不再将整条 Boot 链路笼统列为未验。
- 后续 `menu-review-20260925-a` 完成备份 / 坏档 / 未来版本反馈、真实独立进程锁阻断与显式恢复、旧二维载入画面：55 项检查通过，11 张原图已审阅，拒绝世界与历史源档 hash 保持；合成输入与亲测分列，产品代码未变。

## 下次技术接续（按顺序）

四档长测、本机完整 Shell 回归及已通过的原生保存 / 重进证据均可复用，不再重复启动长测。

1. **确认联合提案**：基础电力建议两套 120 kW 封装电源 / 12 节点，显式接线、按比例降速，带与仓不耗电；与发现循环、统计记账共同使用新世界 schema 2。确认这些参数、两个自有电力模型及版本范围，已有基础工厂不迁移。
2. **确认后从 D1 开始**：审阅电源 / 节点与矿道场景、接线反馈和跨矿道构件预算；随后 D2-A 先做基础供电 / 统计记账，D2-B 接多配方与开拓，D3–D4 走完整路径和亲测。数学推演只核对设计公式，不替代客户端或窗口验证。
3. **保持平台与历史问题边界**：Windows / PowerShell、目标硬件仍待验。历史慢绘制和诊断标记开销未归因；若以后真实慢帧复现，再复用第二版分析器。

## 当前暂缓

- 已认可画面与操作保持；精细美术、新设备、经济解锁、液气、多人、随机地图和战斗未解冻，不转换 / 删除 schema 10 旧档。
- 不推进 1,000 台 / 10,000 带扩展档；本轮未安装依赖、重建引擎、打包、发布或推送。

## 当前设计依据

“从发现到掌握”的产品体验目标见 [Discovery And Industrial Reproduction](../design/discovery-and-industrial-reproduction.md)。当前具体方案已进入发现与生产专题，仍不代表已获实施授权或完成玩法验证。

## 入口与验证

- 正式路径：`client/scenes/boot/Boot.tscn` → “工厂世界” → 新建 / 继续；在加入场景树前注入工厂与旧切片两个隔离存档根，见[运行时指南](../reference/godot-runtime-verification-guide.md)。
- 第二版脚本根：`tools/runtime-intake/check-runs/factory-foundation-v1/engine-diagnostic-20260912/postwait-v2/`，分析、样本和原始证据继续忽略提交；该目录 README 记录命令与边界。
- `sh tools/check-factory-foundation.sh <mode>` 的 `state`、`clock`、`view-state`、`interruption`、`process`、`legacy`、`scale`、`scale-process`、`scale-merge` 无窗口；Godot 启动前仍先告知。
- `boot`、`operation-write/read`、`performance`、`sustained` 会开窗口。聊天确认不能代替实际准备页或鼠标操作证据。
- 治理与静态：`./scripts/check-repo.sh`、`sh ./scripts/check-client.sh`、`./scripts/check-docs.sh`、`git diff --check`；本机 Shell Godot 套件本轮已通过，窗口与目标平台检查仍分别安排。
