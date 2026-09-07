# Daily Start

更新时间：2026-09-07

计划日期：2026-09-07

## 当前任务

先读 [Current Plan](current.md) 与 [Production Client Technology Assessment V1](../architecture/production-client-technology-assessment-v1.md)。Web 画面与建造修正已获萝卜SAMA认可；本次按要求转向正式路线评估，推荐 Godot 3D 桌面客户端，以 Web 画面和操作为迁移验收参照。评估完成、方向待确认，未实施迁移。

## 今日接续

1. 试玩服务器已按萝卜SAMA要求关闭，当前等待技术评估审阅，不自动重启或推进实现。保留入口 `http://127.0.0.1:4318/play/`；后续需要复看时，在仓库根执行 `sh tools/run-web-topdown-3d-demo.sh`，已有依赖无需重新安装。
2. 本轮移除场地常驻名称 / 状态文字，在选中面板查看详情；默认试调 50°，真实出入口改为常显实体边框与流向箭头；支持按住拖出正交路径、松开铺设，保留单格和精确落位。
3. 本轮定向规则检查、真实鼠标路径与用户视觉复评已完成，保留当前结果。后续若出现具体操作问题再记录与处理，不继续追加同类视觉微调。
4. 反馈与实现范围进入产线专题，实际验证事实进入 [W37 周志](../devlogs/2026-W37.md)。接下来确认正式路线与迁移范围，再冻结正式三维工厂与持久化开发包；不再追加 Demo 功能或画风对照。

当前 Demo 不保存，刷新或确认重新开始会重置。既有 Godot 正式入口、客户端规则 / 存档和历轮视觉证据保留；当前包是有限 Web 体验验证，不代表正式迁移或美术验收。9 月 6 日实现与交接见 [W36 周志](../devlogs/2026-W36.md)。

## 当前不进入

- 不执行原整改 S0 或陌生玩家盲测。
- 不批量生产或接入正式设备系统；仅实现当前三机固体链，不实现液气物流或升级 schema 10。
- 不在路线确认前迁移 Web、切换正式客户端 3D 或重写工程；当前仅评估与文档收口。
- 不扩战斗、剧情、地图、多人、多星球或随机投入系统。
- 不打包、分发、发布或上传。

## 读取顺序

1. [Current Plan](current.md)、[技术路线评估](../architecture/production-client-technology-assessment-v1.md) 和 [W37 周志](../devlogs/2026-W37.md)。
2. 涉及体验目标或下一包范围时，再读 [Production-Centered Direction](../product/production-centered-direction.md) 与 [Development Decision Gates](../process/development-decision-gates.md)。
3. 需要追溯视觉路线时，按 [Design Documents](../design/README.md) 选读；旧 Godot 片段复测入口见 [Factory Building Experience Validation V1](../features/factory-building-experience-validation-v1.md)，不作为当前默认动作。

## 验证入口

- 文档：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`、`./scripts/check-repo.sh`。
- 当前 Web 定向检查：`node --test tools/visual-studies/web-topdown-3d/production/verify.mjs tools/visual-studies/web-topdown-3d/verify.mjs`。已完成的系统与浏览器证据见专题；只亲测时不必机械重跑全部检查，后续按实际修改选择验证。
- 既有像素样板和 Godot 检查均为独立历史证据，入口见各自专题；不能将 Web 检查计作正式 Boot 回归。
