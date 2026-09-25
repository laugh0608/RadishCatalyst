# Daily Start

更新时间：2026-09-25

## 当前任务

先读 [Current Plan](current.md)、[Factory Foundation And Persistence V1](../features/factory-foundation-and-persistence-v1.md) 和 [Factory World State And Save V1](../architecture/factory-world-state-and-save-v1.md)。继续收口正式三维工厂 P1–P3；前台持续性能仍是主要缺口，首包未整体验收。

9 月 25 日补齐第二版离线分析器并完成一轮实际点击准备页的窗口采样。新增区间、fence / command 身份和同帧分段在本轮记录范围内通过；生产帧 p95 `8.600ms`，未复现此前持续慢绘制。诊断标记开销和历史波动根因仍未确定，不把这一次快样本当成问题已修复。批次见 [W39 周志](../devlogs/2026-W39.md)，分析边界见 [Metal 呈现诊断记录](../reference/factory-metal-presentation-review-20260912.md)。

## 已完成与交接

- 正式 Boot 工厂入口、独立 schema 1 与旧二维入口保持隔离。此前多线操作、满载存读、规模拆改、时钟和 30 分钟后台稳定性证据继续有效；后台长测不替代前台验收。
- 生产视图按模型身份、revision 和 time 同步，状态灯共享同形网格与只读材质；画面状态 15 项、与原实现等价比较 28,806 项通过，绘制调用 p95 从 557 降至 508。
- 系统关闭保存 17 项、独立进程 Boot 恢复 15 项已通过。隔离世界 `native-close-20260912-a` 保留，已有原生关闭 / 重进证据可复用。
- 第二版分析器 `postwait-v2/analyze_postwait.py` 已完成，34 项离线测试在普通 / `-O` 模式各通过；8 项离线执行记录包含命令行失败与保护检查。原诊断二进制和 8 份源码 hash 未变。
- 窗口批次 `on-20260925-133319` 完成 15 秒预热 / 45 秒生产，359,359 条事件零丢弃、8,590 次等待无超时；5,390 个生产绘制帧分段守恒。记录在显示设备析构前结束，3 个仍存活 fence 单列，不伪造销毁证据。
- 本轮交付 125 件、900 模拟步、自动保存成功；唯一超过预算的原始帧区间为 `102.525ms`，其中自动保存占 `98.630ms`，对应绘制跨度仅 `1.743ms`。初始状态与历史对照相同，最终状态仅正常时间余量不同；原图有 8 个像素差异，已实际审阅，不声称字节一致。

## 下次技术接续（按顺序）

本轮只取得快绘制样本，按原停止条件结束窗口诊断；不自动接续开窗、GPU 采样或长测。

1. **复用现有分析成果**：不再把第二版分析器与首轮窗口配对列为待做。实际未出现的 fence 地址复用、初始值 0 和 frame 0 回调，仅有离线样本覆盖，不扩大实测结论。
2. **回到正式版本原配置复核**：下次桌面方便时先告知，经准备页实际点击取得有界前台证据。若再次出现持续慢帧，复用第二版分析器定位同帧等待与收尾；不追加整套官方 / 开关 / 恢复对照，不盲试限帧、画质或提交策略。快样本记为未复现，不能用快帧排除慢路径。
3. **短测稳定后再做四档长测**：1080 / 最大化、局部 / 拉远各 450 秒真实前台生产；失焦即停、不自动重开，保留完整帧、模拟步、保存、计时守恒与积压记录。诊断构建快样本不替代正式版本的稳定性证据。
4. **按退出合同安排回归与亲测**：按实际改动补检查；完整客户端 Godot 套件、Windows / PowerShell、四档长测和用户亲测仍待完成。Windows 目标硬件未定，保持单列待验，不改 P1–P3 退出条件。

## 当前暂缓

- 已认可画面与操作保持；精细美术、新设备、经济解锁、液气、多人、随机地图和战斗未解冻，不转换 / 删除 schema 10 旧档。
- 不推进 1,000 台 / 10,000 带扩展档；本轮未安装依赖、重建引擎、打包、发布或推送。

## 首包后的设计入口

“从发现到掌握”的产品体验目标已入档。首包收口后，优先讨论探索发现如何经由试制与稳定量产改变玩家能力，见 [Discovery And Industrial Reproduction](../design/discovery-and-industrial-reproduction.md)；设计建议不等于已获实施授权的功能包。

## 入口与验证

- 正式路径：`client/scenes/boot/Boot.tscn` → “工厂世界” → 新建 / 继续；在加入场景树前注入工厂与旧切片两个隔离存档根，见[运行时指南](../reference/godot-runtime-verification-guide.md)。
- 第二版脚本根：`tools/runtime-intake/check-runs/factory-foundation-v1/engine-diagnostic-20260912/postwait-v2/`，分析、样本和原始证据继续忽略提交；该目录 README 记录命令与边界。
- `sh tools/check-factory-foundation.sh <mode>` 的 `state`、`clock`、`view-state`、`interruption`、`process`、`legacy`、`scale`、`scale-process`、`scale-merge` 无窗口；Godot 启动前仍先告知。
- `boot`、`operation-write/read`、`performance`、`sustained` 会开窗口。聊天确认不能代替实际准备页或鼠标操作证据。
- 治理与静态：`./scripts/check-repo.sh`、`sh ./scripts/check-client.sh`、`./scripts/check-docs.sh`、`git diff --check`；完整 Godot 运行时检查另行安排。
