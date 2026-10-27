# Runtime Systems Overview

更新时间：2026-10-23

## 拆分说明

本文已按主题拆分为子文档；当前文件只保留入口索引，避免新会话读取过长背景。

## 子文档

- [Factory World State And Save V1](factory-world-state-and-save-v1.md)：正式三维工厂入口、权威状态与独立 schema 1；保留旧二维世界，当前未实现多人。
- [Factory Energy Save V8](factory-energy-save-v8.md)：新版待机能量账、有限余能与统计校验、保留原 E1 / V7 的显式复制；旧规则见 [V7](factory-energy-save-v7.md)，内容范围见 [E2](../features/factory-production-expansion-e2.md)。

- [Slice Runtime Systems](slice-runtime-systems.md)：保留的 `Boot → SliceWorld` 的建筑、供电、物流、外勤战斗、派生旅程引导、时间推进和切片存档边界。
- [冻结旧纵切运行时总览](runtime-systems-summary.md)：`GameRoot + VerticalSliceMap` 系统组成、职责和直接真相源。
- [冻结旧纵切数据流与硬边界](runtime-dataflow-and-boundaries.md)：旧纵切关键数据流、硬边界和扩内容结论。
