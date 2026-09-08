# Daily Start

更新时间：2026-09-08

计划日期：2026-09-09

## 当前任务

先读 [Current Plan](current.md)、[Factory Foundation And Persistence V1](../features/factory-foundation-and-persistence-v1.md) 和 [Factory World State And Save V1](../architecture/factory-world-state-and-save-v1.md)。正式工厂入口、独立存档和扩建基础已提交，接续重点是收敛验证缺口，首包尚未整体验收。

## 昨日交接

- Godot Demo、最大化清晰度修正、首包设计分别为 `cfa2fee4`、`5e1701b9`、`d75075ce`；正式工厂基础为 `978d6250`。均为本地提交，未推送。
- 正式 Boot 可新建 / 继续工厂；64×64、25 矿点、多实例与独立 schema 1 已实现，旧二维入口 / schema 10 保留。
- 状态、存档故障、跨进程与双线操作已有定向证据；100 台 / 1,000 带完成满载短测。30 分钟持续测试被中断，计时差异尚未解释，Windows 未测。详见 [W37 周志](../devlogs/2026-W37.md)。

## 明天事项（按顺序）

1. **先处理模拟计时差异**：核对 `app.gd` 接收的引擎 `delta`、活动墙钟、暂停 / 失焦 / 保存停顿与模型余量。长测首档约 450 秒活动墙钟只推进约 447.9 秒；先复现和归因，再决定如何使用单调时钟，补无窗口定向验证，不能直接把差额认作正常。
2. **核对剩余验收证据**：审阅双线操作已留存的原图；按专题逐项核对规模下的汇流、连续拆改、边缘操作、满载跨进程恢复与保存失败路径，补缺项。检查性能脚本失焦后是否彻底结束所有阶段，并为计时差异加入判定；不要只依赖 p95 和积压阈值。
3. **另行安排窗口验证**：先复核移除抢焦点后的行为，再在萝卜SAMA方便的时段跑 1080 / 最大化、局部 / 拉远的 30 分钟持续生产。不得自动重开已关闭窗口、循环抢焦点或后台凑时长；明日接续不默认直接开长测。
4. **证据齐备后交付亲测**：按 P1–P3 退出条件收口，提供正式 Boot 的隔离世界和路径。Windows 目标硬件明确后单独验性能，不将本机短测外推为目标平台通过。

## 暂缓事项

- 萝卜SAMA已认可当前画面与操作，精细度暂缓；不重复索要同范围认可，不追加模型润色。
- 不增加设备种类、经济解锁、液气、多人、随机地图或战斗，不转换 / 删除 schema 10 旧档。
- 不推进 1,000 台 / 10,000 带扩展档，不安装依赖、打包、发布或推送。

## 入口与验证

- 正式路径：`client/scenes/boot/Boot.tscn` → “工厂世界” → 新建 / 继续。运行验证必须注入工厂与旧切片两个隔离存档根，操作方法见[运行时指南](../reference/godot-runtime-verification-guide.md)。
- 无窗口定向：`sh tools/check-factory-foundation.sh state`；`process` 验证跨进程 / 锁，`legacy` 验证旧入口 / 存档，`scale` 生成工程满载状态。Godot 启动前仍先告知。
- 有窗口 `boot`、`operation-write/read`、`performance`、`sustained` 的运行条件和证据见首包专题；不在收工或用户占用桌面时自动执行。
- 治理与静态：`./scripts/check-repo.sh`、`sh ./scripts/check-client.sh`、`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`。
- 独立 Godot Demo 与 Web `/play/` 只保留作参照，前者关闭重置；正式工厂已有持久化。需要追溯时再读旧专题。
