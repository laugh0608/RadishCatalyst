# Daily Start

更新时间：2026-09-12（收尾）

计划日期：2026-09-13

## 明日任务

先读 [Current Plan](current.md)、[Factory Foundation And Persistence V1](../features/factory-foundation-and-persistence-v1.md) 和 [Factory World State And Save V1](../architecture/factory-world-state-and-save-v1.md)。继续收口正式三维工厂 P1–P3；前台性能仍是主要缺口，首包未整体验收。

萝卜SAMA已要求 9 月 12 日结束工作，下一步留到明天。隔离引擎诊断构建尚未授权；今晚不下载、安装、编译或开窗，也未安排自动执行。

## 今日完成与交接

- 正式 Boot 工厂入口、独立 schema 1 与旧二维入口保持隔离。此前多线操作、满载存读、规模拆改、时钟和 30 分钟后台稳定性证据继续有效；后台长测不替代前台验收。
- 生产视图按模型身份、revision 和 time 同步，状态灯共享同形网格与四种只读材质；人物、相机、选择和预览继续逐帧处理。画面状态 15 项、与原实现等价比较 28,806 项通过，基准原图字节一致；绘制调用 p95 从 557 降至 508。
- 系统关闭保存 17 项、独立进程 Boot 恢复 15 项通过；完整状态首帧前比较、写入锁释放 / 再获取和原生操作已有证据。隔离世界 `native-close-20260912-a` 保留，不再列为待补。
- 共用诊断准备页已修正首次铺满；最大化尺寸稳定后开放按钮，取消 / 超时返回失败，恢复原内容比例和关闭策略。Metal 25 项、Vulkan 12 项与原图证据见 [W37 周志](../devlogs/2026-W37.md)；准备页通过不等于性能通过。
- 原配置无额外 GPU 计时的重复短测帧 p95 为 `20.595 / 20.853ms`，仍超 `16.7ms`。60 FPS 对照未改善，未采用限帧；同步、画质和默认 Metal / Forward+ 保留。
- 原生 Metal 轨迹、呈现时钟 / 对象核对和实际引擎源码审计已完成。疑点为正常 drawable 获取先于帧末渲染图编码 / 提交，尚未证实是长帧主因；4.7.2 三个相关源码文件相同。数据、失败关联和具体方案见 [Metal 呈现诊断记录](../reference/factory-metal-presentation-review-20260912.md)，不重复盲试参数或导出同类无标识事件。

## 明日事项（按顺序）

1. **先确认隔离诊断构建范围**：方案涉及固定构建源码下载、独立 venv 安装 SCons，以及获取 / 编码 / commit / present 标记。归档上限 512MiB、隔离目录上限 20GiB；不替换现有 Godot。完整命令、标记位置和停止条件已写入诊断记录；只有取得授权后才实施，今天的收尾要求不构成授权。
2. **授权后构建并验证顺序假设**：先核对该提交构建选项与实际依赖版本，完成独立构建、事件完整性及开销检查；再先告知窗口测试，复用用户点击准备页与双存档根隔离。比较官方二进制、诊断构建标记关闭、标记开启，分清构建差异和采样干扰；第一轮只加诊断，不改提交策略。结果不支持假设时停止该方向。
3. **短测稳定后再做四档长测**：1080 / 最大化、局部 / 拉远各 450 秒真实前台生产；失焦即停、不自动重开，保留完整帧、模拟步、保存、计时守恒与积压记录。此项是后续门槛，不承诺明天直接启动。
4. **按退出合同安排回归与亲测**：按实际改动补检查，已有关闭 / 重进证据直接复用；完整客户端 Godot 套件、Windows / PowerShell、四档长测和用户亲测仍待完成，不把诊断或静态检查写成整包通过。

## 当前暂缓

- 已认可画面与操作保持；精细美术、新设备、经济解锁、液气、多人、随机地图和战斗未解冻，不转换 / 删除 schema 10 旧档。
- 不推进 1,000 台 / 10,000 带扩展档；构建依赖在上述授权前不安装，打包、发布与推送未授权。

## 入口与验证

- 正式路径：`client/scenes/boot/Boot.tscn` → “工厂世界” → 新建 / 继续；在加入场景树前注入工厂与旧切片两个隔离存档根，见[运行时指南](../reference/godot-runtime-verification-guide.md)。
- 无窗口定向：`sh tools/check-factory-foundation.sh <mode>`，包括 `state`、`clock`、`view-state`、`interruption`、`process`、`legacy`、`scale`、`scale-process`、`scale-merge`；Godot 启动前仍先告知。
- `boot`、`operation-write/read`、`performance`、`sustained` 会开窗口。聊天确认不能代替实际准备页或鼠标操作证据。
- 治理与静态：`./scripts/check-repo.sh`、`sh ./scripts/check-client.sh`、`./scripts/check-docs.sh`、`git diff --check`；完整 Godot 运行时检查另行安排。
