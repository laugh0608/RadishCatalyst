# Daily Start

更新时间：2026-09-09

计划日期：2026-09-09

## 当前任务

先读 [Current Plan](current.md)、[Factory Foundation And Persistence V1](../features/factory-foundation-and-persistence-v1.md) 和 [Factory World State And Save V1](../architecture/factory-world-state-and-save-v1.md)。计时与失败退出修正、规模无窗口验证和原图审阅已推进，接续重点为窗口复验及持续性能，首包尚未整体验收。

## 当前交接

- Godot Demo、最大化清晰度修正、首包设计分别为 `cfa2fee4`、`5e1701b9`、`d75075ce`；正式工厂基础为 `978d6250`。均为本地提交，未推送。
- 正式 Boot 可新建 / 继续工厂；64×64、25 矿点、多实例与独立 schema 1 已实现，旧二维入口 / schema 10 保留。
- 9 月 9 日复现引擎 delta 在长帧中漏时，已改用单调活动时钟；Boot 时钟与失败退出 28 项通过。二次确认层级冲突已修正，自动保存使用实际经过时间。
- 双线 5 张原图已审阅；100 台 / 1,000 带满载跨进程写 / 读各 107 项、规模汇流 210 项通过。准备 / 采样失焦注入均中断后续阶段。修正后的原生窗口与 30 分钟长测未执行，Windows 未测；详见 [W37 周志](../devlogs/2026-W37.md)。

## 接续事项（按顺序）

1. **安排短窗口复验**：在萝卜SAMA方便的时段，从隔离正式 Boot 复核暂停 / 失焦、长帧后的继续生产、保存失败二次确认，以及原生焦点中断。当前窗口可用时段尚未确认，不默认直接开长测。
2. **补玩家路径证据**：规模状态、连续拆改及越界命令已有无窗口证据；还须核对地图边缘实际移动 / 相机 / HUD、规模操作画面及失败恢复弹窗。按原有合同逐项补缺，不把信号注入当鼠标命中或亲测。
3. **执行持续性能**：短窗口复验成立后，跑 1080 / 最大化、局部 / 拉远四档共 30 分钟持续生产，检查墙钟 / 推进 / 余量、长帧、积压及保存 / 加载耗时。失焦即中断，不重开已关闭窗口、不抢焦点、不在后台凑时长。
4. **证据齐备后交付亲测**：按 P1–P3 退出条件收口，提供正式 Boot 的隔离世界和路径。Windows 目标硬件明确后单独验性能，不将本机短测外推为目标平台通过。

## 暂缓事项

- 萝卜SAMA已认可当前画面与操作，精细度暂缓；不重复索要同范围认可，不追加模型润色。
- 不增加设备种类、经济解锁、液气、多人、随机地图或战斗，不转换 / 删除 schema 10 旧档。
- 不推进 1,000 台 / 10,000 带扩展档，不安装依赖、打包、发布或推送。

## 入口与验证

- 正式路径：`client/scenes/boot/Boot.tscn` → “工厂世界” → 新建 / 继续。运行验证必须注入工厂与旧切片两个隔离存档根，操作方法见[运行时指南](../reference/godot-runtime-verification-guide.md)。
- 无窗口定向：`state` 检查规则 / 存档，`clock` 检查时钟及失败退出，`interruption` 检查阶段中断，`process` 检查跨进程 / 锁，`legacy` 检查旧入口 / 存档，`scale` 生成满载状态，`scale-process` / `scale-merge` 补规模存读 / 拆改 / 汇流。使用 `sh tools/check-factory-foundation.sh <mode>`，Godot 启动前仍先告知。
- 有窗口 `boot`、`operation-write/read`、`performance`、`sustained` 的运行条件和证据见首包专题；不在收工或用户占用桌面时自动执行。
- 治理与静态：`./scripts/check-repo.sh`、`sh ./scripts/check-client.sh`、`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`。
- 独立 Godot Demo 与 Web `/play/` 只保留作参照，前者关闭重置；正式工厂已有持久化。需要追溯时再读旧专题。
