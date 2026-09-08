# Daily Start

更新时间：2026-09-08

计划日期：2026-09-08

## 当前任务

先读 [Current Plan](current.md)、[Godot First Production Line Demo V1](../features/godot-first-production-line-demo-v1.md) 和 [W37 周志](../devlogs/2026-W37.md)。萝卜SAMA已授权先做独立 Godot 3D 三机产线 Demo，与已认可 Web 版本直接对照，再决定正式技术路线；不等待正式迁移确认才开工。

## 今日接续

1. 已同步最新决定并完成实现，沿用 `tools/visual-studies/topdown-3d/` 独立工程。固定 Web 设备造型、50° 视角、光照、单枚接口箭头、拖动铺带与真实弯道，不重新探索画风。
2. 已按 Web 同一三机固体规则实现人物移动、设备放置、拖铺、拆回、生产、断路与恢复，不混入旧 Godot 的额外规则。
3. 定向核对 1,931 个状态 / 轨迹检查点、完整窗口 61 项和补充窗口 28 项通过，13 张最终截图已查看。下一步由萝卜SAMA亲测；启动命令 `sh tools/run-topdown-3d-demo.sh --production`，启动 Godot 或窗口测试前先告知。
4. 本次交接已重新启动本机 Web 服务器，`http://127.0.0.1:4318/play/` 实测 HTTP 200，可与已打开的 Godot 空厂坪直接对照；服务退出后执行 `sh tools/run-web-topdown-3d-demo.sh` 重新启动，已有依赖无需重装。

当前独立 Demo 关闭即重置，无游戏存档。正式客户端、存档、旧验证证据保留；技术评估的 Godot 推荐不等于正式路线已经批准。

## 当前不进入

- 不恢复原整改 S0、陌生玩家盲测或新增画风探索。
- 不迁移正式客户端、改存档 schema、引入液气 / 多人 / 新地图 / 战斗。
- 不把三机小场景的帧时间推断为大型工厂性能通过。
- 不安装新依赖、引入外部资产、打包、分发、发布或上传。

## 读取顺序

1. [Current Plan](current.md)、[当前 Godot Demo](../features/godot-first-production-line-demo-v1.md)、[W37 周志](../devlogs/2026-W37.md)。
2. [Web 产线规则与认可事实](../features/web-first-production-line-v1.md)、[Godot 3D 独立工程与旧证据](../design/topdown-3d-comparison-demo-v1.md)。
3. 需要评估正式化时再读[技术路线评估](../architecture/production-client-technology-assessment-v1.md)，不把其正式首包候选带入当前 Demo。

## 验证入口

- 文档与治理：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`、`./scripts/check-repo.sh`。
- Godot Demo 的定向与窗口入口、证据目录见当前专题；静态客户端检查不能替代窗口复核。
- 既有 Web、像素样板和 Godot 视觉检查保持独立，不混算为本次或正式 Boot 回归。
