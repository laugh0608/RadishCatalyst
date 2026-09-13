# Daily Start

更新时间：2026-09-13（日终交接）

计划日期：2026-09-14

## 当前任务

先读 [Current Plan](current.md)、[Factory Foundation And Persistence V1](../features/factory-foundation-and-persistence-v1.md) 和 [Factory World State And Save V1](../architecture/factory-world-state-and-save-v1.md)。继续收口正式三维工厂 P1–P3；前台性能仍是主要缺口，首包未整体验收。

整体开关对照与约定时段对照均已完成，官方前后帧 p95 仍出现 `27.186 / 8.584ms` 差异，未建立稳定开销估计。现已把取证收窄到提交后的等待与收尾，第二版隔离诊断引擎构建、状态 62 项、视图 15 项及记录器四种情形检查通过；第二版新增事件的离线分析器尚未补齐，窗口分段与 fence 身份配对尚未实测。细节见 [Metal 呈现诊断记录](../reference/factory-metal-presentation-review-20260912.md)。

## 已完成与交接

- 正式 Boot 工厂入口、独立 schema 1 与旧二维入口保持隔离。此前多线操作、满载存读、规模拆改、时钟和 30 分钟后台稳定性证据继续有效；后台长测不替代前台验收。
- 生产视图按模型身份、revision 和 time 同步，状态灯共享同形网格与四种只读材质；人物、相机、选择和预览继续逐帧处理。画面状态 15 项、与原实现等价比较 28,806 项通过，基准原图字节一致；绘制调用 p95 从 557 降至 508。
- 系统关闭保存 17 项、独立进程 Boot 恢复 15 项通过；完整状态首帧前比较、写入锁释放 / 再获取和原生操作已有证据。隔离世界 `native-close-20260912-a` 保留，不再列为待补。
- 共用诊断准备页已修正首次铺满；最大化尺寸稳定后开放按钮，取消 / 超时返回失败，恢复原内容比例和关闭策略。Metal 25 项、Vulkan 12 项与原图证据见 [W37 周志](../devlogs/2026-W37.md)；准备页通过不等于性能通过。
- 原配置无额外 GPU 计时的重复短测帧 p95 为 `20.595 / 20.853ms`，仍超 `16.7ms`。60 FPS 对照未改善，未采用限帧；同步、画质和默认 Metal / Forward+ 保留。
- 原生 Metal 轨迹、呈现时钟 / 对象核对和实际引擎源码审计已完成。疑点为正常 drawable 获取先于帧末渲染图编码 / 提交，尚未证实是长帧主因；4.7.2 三个相关源码文件相同。数据、失败关联和具体方案见 [Metal 呈现诊断记录](../reference/factory-metal-presentation-review-20260912.md)，不重复盲试参数或导出同类无标识事件。

## 明天事项（2026-09-14，按顺序）

今晚已停止推进，不安排自动开窗或后台接续。明日实际推进时新建 W38 周志；以下是计划，不记为完成事实。

1. **先补离线分析**：第一版 `analyze-trace.py` 不识别新增等待、回调和统计事件，不能用于宣称第二版配对通过。补齐成对区间及 fence 创建 / 销毁、command 创建 / 重置生命周期关联，验证缺失事件、指针复用和等待超时等失败样本。信号编码不等于 GPU 完成，初始值 0 与 frame 0 回调单列，嵌套区间不重复累加。
2. **再验证第二版窗口分段**：离线检查通过且桌面方便时，先告知并等待实际准备页点击，使用仓库内忽略入口 `python3 tools/runtime-intake/check-runs/factory-foundation-v1/engine-diagnostic-20260912/postwait-v2/run-postwait.py on`。沿用 15 秒预热 / 45 秒生产和双存档根隔离；核对事件零丢弃、成对区间、生命周期、原图与状态一致性。新增标记的观察开销仍待验证。
3. **按同帧证据定位慢阶段**：已覆盖 fence 等待、待释放资源整理、回调、帧统计及显存统计，原提交顺序保持不变。只在实际慢帧上比较分段与未覆盖余量，避免嵌套重复计时和分位数相减；若只得到快帧则记为未复现，不再追加整体开关批次或索要相同的稳定时段。证据指出具体等待后，再决定是否需要同轮 GPU 关联；不提前改提交策略。
4. **短测稳定后再做四档长测**：1080 / 最大化、局部 / 拉远各 450 秒真实前台生产；失焦即停、不自动重开，保留完整帧、模拟步、保存、计时守恒与积压记录。此项是后续门槛，不承诺明天直接启动。
5. **按退出合同安排回归与亲测**：按实际改动补检查，已有关闭 / 重进证据直接复用；完整客户端 Godot 套件、Windows / PowerShell、四档长测和用户亲测仍待完成，不把诊断或静态检查写成整包通过。

## 当前暂缓

- 已认可画面与操作保持；精细美术、新设备、经济解锁、液气、多人、随机地图和战斗未解冻，不转换 / 删除 schema 10 旧档。
- 不推进 1,000 台 / 10,000 带扩展档；新增依赖已按本轮授权隔离安装，打包、发布与推送未授权。

## 入口与验证

- 正式路径：`client/scenes/boot/Boot.tscn` → “工厂世界” → 新建 / 继续；在加入场景树前注入工厂与旧切片两个隔离存档根，见[运行时指南](../reference/godot-runtime-verification-guide.md)。
- 无窗口定向：`sh tools/check-factory-foundation.sh <mode>`，包括 `state`、`clock`、`view-state`、`interruption`、`process`、`legacy`、`scale`、`scale-process`、`scale-merge`；Godot 启动前仍先告知。
- `boot`、`operation-write/read`、`performance`、`sustained` 会开窗口。聊天确认不能代替实际准备页或鼠标操作证据。
- 治理与静态：`./scripts/check-repo.sh`、`sh ./scripts/check-client.sh`、`./scripts/check-docs.sh`、`git diff --check`；完整 Godot 运行时检查另行安排。
