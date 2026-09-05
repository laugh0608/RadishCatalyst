# Daily Start

更新时间：2026-09-05

计划日期：2026-09-05

## 当前任务

先读 [Current Plan](current.md) 与 [Production-Centered Direction](../product/production-centered-direction.md)。当前阶段是产品方向调整与建造体验验证定义；原试玩整改 S0 暂缓，既有功能和证据继续保留。

## 下一动作

起草一个可评审的工厂片段体验合同，具体回答：

1. 玩家从什么资源、设备和场地状态开始。
2. 玩家如何放置设备并真实接通输入、加工和输出。
3. 正常产出、缺料和堵塞分别如何在世界画面与必要 UI 中被看见。
4. 玩家调整布局后，什么变化证明操作有效。
5. 固定高斜角常态与建造模式各显示什么，网格、足印、接口、流向、缩放和遮挡如何配合。
6. 哪些结果算验证成功，哪些失败应停止实现并改向。

合同形成后审计现有 Godot 设备、物流、建造、相机和反馈能力，给出可复用项与缺口。随后再评估是否需要同范围 Web 对照；实验实现、平台和时间预算需另行确认。

## 当前不进入

- 不执行原整改 S0 或陌生玩家盲测。
- 不改代码，不生产新美术，不迁移 Web，不重写工程。
- 不扩战斗、剧情、地图、多人、多星球或随机投入系统。
- 不打包、分发、发布或上传。

## 继续前必读

- [Current Plan](current.md)
- [Production-Centered Direction](../product/production-centered-direction.md)
- [Project Definition](../product/project-definition.md)
- [Development Decision Gates](../process/development-decision-gates.md)

## 验证入口

- 文档：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`、`./scripts/check-repo.sh`。
- 启动 Godot、有窗口复核或进入实验实现前，先按当前授权边界处理。
