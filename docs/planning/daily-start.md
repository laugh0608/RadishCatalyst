# Daily Start

更新时间：2026-09-06

计划日期：2026-09-07

## 当前任务

先读 [Current Plan](current.md) 与 [Web First Production Line V1](../features/web-first-production-line-v1.md)。三维产线实现和定向验证已提交；明天先由萝卜SAMA亲测，收集反馈后再定义下一包，暂停扩展视觉 / 引擎对照。

## 明天事项

1. 先检查工作区。若本机服务仍在运行，直接进入 `http://127.0.0.1:4318/play/`；否则在仓库根运行 `sh tools/run-web-topdown-3d-demo.sh`。现有依赖已安装，正常启动无需再安装。
2. 预留约 5–10 分钟，从空场坪放采集器、反应器与终端仓，铺带、观察首件催化剂入仓，再拆开输入并补接恢复。先按画面与页面说明尝试，记录需要额外解释的位置；这是体验目标，不是已测得的完成时长。
3. 记录三项反馈：能否看懂落位、端口和带向；选中 / 转向 / 拆改是否顺手；产线恢复后是否想继续建设。遇到问题保留操作步骤和画面，区分操作、生产反馈与视觉问题。
4. 把反馈回填产线专题，并记录实际发生日期对应的周志（明天为 `2026-W37`）。若有阻断，先提一个范围清楚的修正包；若体验方向获得认可，再讨论扩建目标。正式引擎选择与 Godot 同场景复现继续后排。

当前 Demo 不保存，刷新或确认重新开始会重置。既有 Godot 正式入口、客户端规则 / 存档和历轮视觉证据保留；当前包是有限 Web 体验验证，不代表正式迁移或美术验收。9 月 6 日全部提交与文档审阅记录见 [W36 周志](../devlogs/2026-W36.md)。

## 当前不进入

- 不执行原整改 S0 或陌生玩家盲测。
- 不批量生产或接入正式设备系统；仅实现当前三机固体链，不实现液气物流或升级 schema 10。
- 不迁移 Web，不把正式客户端切换 3D，不重写工程；只制作已授权的隔离对照。
- 不扩战斗、剧情、地图、多人、多星球或随机投入系统。
- 不打包、分发、发布或上传。

## 读取顺序

1. [Current Plan](current.md)、[Web First Production Line V1](../features/web-first-production-line-v1.md) 和 [W36 日终交接](../devlogs/2026-W36.md)。
2. 涉及体验目标或下一包范围时，再读 [Production-Centered Direction](../product/production-centered-direction.md) 与 [Development Decision Gates](../process/development-decision-gates.md)。
3. 需要追溯视觉路线时，按 [Design Documents](../design/README.md) 选读；旧 Godot 片段复测入口见 [Factory Building Experience Validation V1](../features/factory-building-experience-validation-v1.md)，不作为明天默认动作。

## 验证入口

- 文档：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`、`./scripts/check-repo.sh`。
- 当前 Web 定向检查：`node --test tools/visual-studies/web-topdown-3d/production/verify.mjs tools/visual-studies/web-topdown-3d/verify.mjs`。已完成的系统与浏览器证据见专题；明天只亲测时不必机械重跑全部检查，后续按实际修改选择验证。
- 既有像素样板和 Godot 检查均为独立历史证据，入口见各自专题；不能将 Web 检查计作正式 Boot 回归。
