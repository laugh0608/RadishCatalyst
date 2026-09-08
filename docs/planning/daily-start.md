# Daily Start

更新时间：2026-09-08

计划日期：2026-09-08

## 当前任务

先读 [Current Plan](current.md)、[Factory Foundation And Persistence V1](../features/factory-foundation-and-persistence-v1.md) 和 [Factory World State And Save V1](../architecture/factory-world-state-and-save-v1.md)。当前推进已获授权的正式工厂首包设计；具体架构、存档与规模提案待审阅后进入实现。

## 今日接续

1. 萝卜SAMA认可当前 Godot Demo 的画面和操作，但精细度尚不满意；明确当前先验证、不抠细节。停止追加同范围视觉比较，已认可风格继续作基准。
2. 既有 Demo 与最大化清晰度修正已提交为 `cfa2fee4`、`5e1701b9`；本机分辨率 / 输入窗口检查通过，事实与局限见[原专题](../features/godot-first-production-line-demo-v1.md)。
3. 首包设计分 P1 正式入口与状态、P2 保存恢复、P3 扩建与规模；先增加现有三类设备数量，新增设备类型和经济循环另包设计。
4. 首包建议独立工厂世界 / 存档、64×64 场地、普通预发供给和 100 台 / 1,000 带工程负载。这些是待审阅的新合同，不是已实现能力或实测性能。

## 下一步

审阅首包中的正式 `client/` 接入、旧世界保留、新存档格式和扩建 / 负载范围；通过后按 P1–P3 连续推进，不重复索要同范围画面认可。实施仍需按包验证，Windows 性能需明确目标机后单独完成。

## 当前不进入

- 不批量精修美术、添加设备种类、液气、多人、经济解锁、随机地图或战斗。
- 不擅自替换旧默认入口、转换 / 删除 schema 10 旧档，或把待审阅提案写成运行时真相。
- 不将旧三机采样外推为大工厂 / 最大化 / Windows 性能，不安装依赖、打包、发布或推送。

## 对照与读取顺序

1. Current、首包功能专题及工厂状态 / 存档提案。
2. 需要追溯决策和验证时读 [W37 周志](../devlogs/2026-W37.md) 与 [技术路线评估](../architecture/production-client-technology-assessment-v1.md)。
3. 同规则参照为 [Godot Demo](../features/godot-first-production-line-demo-v1.md) 和 [Web 产线](../features/web-first-production-line-v1.md)；原视觉研究不作为并行待办。

Godot 对照入口 `sh tools/run-topdown-3d-demo.sh --production`；Web 入口 `http://127.0.0.1:4318/play/`，需要时用 `sh tools/run-web-topdown-3d-demo.sh` 启动已有服务。独立 Demo 仍关闭即重置，首包持久化未实现。

## 验证入口

本次仅文档：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`./scripts/check-repo.sh`、`git diff --check`。实施后的正式 Boot、跨进程存读和负载合同见首包专题；启动 Godot 或窗口检查前先告知。
