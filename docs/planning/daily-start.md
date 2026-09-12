# Daily Start

更新时间：2026-09-12

计划日期：2026-09-12

## 当前任务

先读 [Current Plan](current.md)、[Factory Foundation And Persistence V1](../features/factory-foundation-and-persistence-v1.md) 和 [Factory World State And Save V1](../architecture/factory-world-state-and-save-v1.md)。当前继续收口正式三维工厂 P1–P3；原生关闭保存已补验，前台性能仍是主要缺口，首包未整体验收。

## 当前交接

- 正式 Boot 可新建 / 继续工厂；64×64、25 矿点、多实例与独立 schema 1 已实现，旧二维入口 / schema 10 保留。
- 单调活动时钟、失败退出、双线操作、满载跨进程存读、规模汇流 / 拆改、边缘 / 相机 / HUD 已有定向证据。30 分钟隔离后台长测通过，只覆盖生产、计时及存档稳定性；历史批次见 [W37 周志](../devlogs/2026-W37.md)。
- 9 月 12 日系统关闭保存 17 项、独立进程 Boot 恢复 15 项通过；原生按钮操作、关闭事件、完整状态首帧前比较、写入锁释放 / 再获取均有证据。原图已审阅，最终隔离世界保留在 `check-runs/factory-foundation-v1/native-close-20260912-a/`。
- 已完成同状态同步开 / 关 / 恢复各 90 秒及三份有效调用栈；三段帧 p95 为 `33.550 / 17.459 / 28.654ms`，均未达标。采样干扰时间单列，不将临时关闭同步作为产品方案。
- `view.gd` 省去未变生产状态的重复属性提交，状态灯共享同形网格及四种只读状态材质；人物、相机、预览及暂停命令仍及时更新。最终与原实现 28,806 项比较通过，基准原图 SHA-256 相同。
- 最新默认 Metal / 原画质短测 `performance-1789193700-5867` 完成 `90.006909s`，交付 225 件；绘制调用 p95 `508`，模拟步 p95 `1.113ms`，节点处理跨度 p95 `3.324ms`。帧 p95 `21.237ms` 仍超 `16.7ms`，未启动四档长测。
- 临时 Vulkan 90 秒对照帧 p95 `24.537ms`，取得 3D GPU p95 `22.240ms`。随后原效果 / 无 SSAO / 无阴影 / 恢复各 45 秒对照完成；恢复原效果后也出现改善，仍有运行时波动，不能把差额全归于单个效果。默认驱动、同步、画质、负载及预算均未改。

## 接续事项（按顺序）

1. **继续收窄 GPU 与帧调度瓶颈**：复用已完成对照，不从零重跑；先核对预热、分项 GPU / 阴影提交和帧等待，采用相同生产快照、实际像素及重复恢复对照。需获得能解释原配置超预算的证据，再做明确修正；不继续凭单次 p95 叠加优化，不永久关闭同步或效果来过线。
2. **短测稳定后安排四档长测**：1080 / 最大化、局部 / 拉远各 450 秒真实前台生产。先告知并确认桌面可用，失焦即停，不自动重开；保留完整帧、模拟步、保存、计时守恒和积压记录。
3. **核对退出条件并交付亲测**：已有原生关闭 / 重进、失败返回、规模拆改、地图边缘证据按合同使用，按实际改动补回归。P1–P3 本机证据齐备后交付隔离世界；完整客户端 Godot 套件和 Windows 未测项如实单列。

## 暂缓事项

- 已认可的画面和操作保持；精细模型、材质和角色动画另包推进。
- 不新增设备、经济解锁、液气、多人、随机地图或战斗，不转换 / 删除 schema 10 旧档。
- 不推进 1,000 台 / 10,000 带扩展档，不安装依赖、打包、发布或推送。

## 入口与验证

- 正式路径：`client/scenes/boot/Boot.tscn` → “工厂世界” → 新建 / 继续；必须注入工厂和旧切片两个隔离存档根，见[运行时指南](../reference/godot-runtime-verification-guide.md)。
- 无窗口定向：`sh tools/check-factory-foundation.sh <mode>`，包括 `state`、`clock`、`view-state`、`interruption`、`process`、`legacy`、`scale`、`scale-process`、`scale-merge`。Godot 启动前仍先告知；`view-state` 不替代截图或性能验收。
- `boot`、`operation-write/read`、`performance`、`sustained` 会开窗口；用户占用桌面时不自动执行。
- 治理与静态：`./scripts/check-repo.sh`、`sh ./scripts/check-client.sh`、`./scripts/check-docs.sh`、`git diff --check`。
