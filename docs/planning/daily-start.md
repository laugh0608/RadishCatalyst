# Daily Start

更新时间：2026-09-07

计划日期：2026-09-07

## 当前任务

先读 [Current Plan](current.md) 与 [Web First Production Line V1](../features/web-first-production-line-v1.md)。萝卜SAMA亲测后表示整体效果很满意，并提出文字遮挡、55° 偏俯视、设备端口不明显与只能逐格铺带四项反馈；这些修正及后续箭头简化、弯道外形修正已完成，萝卜SAMA再次反馈“不错，效果我很满意”，本轮视觉修正收口。

## 今日接续

1. 本机入口为 `http://127.0.0.1:4318/play/`；若服务未运行，在仓库根执行 `sh tools/run-web-topdown-3d-demo.sh`。已有依赖，无需重新安装。
2. 本轮移除场地常驻名称 / 状态文字，在选中面板查看详情；默认试调 50°，真实出入口改为常显实体边框与流向箭头；支持按住拖出正交路径、松开铺设，保留单格和精确落位。
3. 本轮定向规则检查、真实鼠标路径与用户视觉复评已完成，保留当前结果。后续若出现具体操作问题再记录与处理，不继续追加同类视觉微调。
4. 反馈与实现范围进入产线专题，实际验证事实进入 [W37 周志](../devlogs/2026-W37.md)。接下来讨论具体扩建目标与下一开发包范围，正式引擎选择与更多画风对照继续后排。

当前 Demo 不保存，刷新或确认重新开始会重置。既有 Godot 正式入口、客户端规则 / 存档和历轮视觉证据保留；当前包是有限 Web 体验验证，不代表正式迁移或美术验收。9 月 6 日实现与交接见 [W36 周志](../devlogs/2026-W36.md)。

## 当前不进入

- 不执行原整改 S0 或陌生玩家盲测。
- 不批量生产或接入正式设备系统；仅实现当前三机固体链，不实现液气物流或升级 schema 10。
- 不迁移 Web，不把正式客户端切换 3D，不重写工程；只制作已授权的隔离对照。
- 不扩战斗、剧情、地图、多人、多星球或随机投入系统。
- 不打包、分发、发布或上传。

## 读取顺序

1. [Current Plan](current.md)、[Web First Production Line V1](../features/web-first-production-line-v1.md) 和 [W37 周志](../devlogs/2026-W37.md)。
2. 涉及体验目标或下一包范围时，再读 [Production-Centered Direction](../product/production-centered-direction.md) 与 [Development Decision Gates](../process/development-decision-gates.md)。
3. 需要追溯视觉路线时，按 [Design Documents](../design/README.md) 选读；旧 Godot 片段复测入口见 [Factory Building Experience Validation V1](../features/factory-building-experience-validation-v1.md)，不作为当前默认动作。

## 验证入口

- 文档：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`、`./scripts/check-repo.sh`。
- 当前 Web 定向检查：`node --test tools/visual-studies/web-topdown-3d/production/verify.mjs tools/visual-studies/web-topdown-3d/verify.mjs`。已完成的系统与浏览器证据见专题；只亲测时不必机械重跑全部检查，后续按实际修改选择验证。
- 既有像素样板和 Godot 检查均为独立历史证据，入口见各自专题；不能将 Web 检查计作正式 Boot 回归。
