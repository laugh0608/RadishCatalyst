# RadishCatalyst / 异星催化 联机模式与存档架构前置设计


## 拆分说明

本文已按主题拆分为子文档；当前文件只保留入口索引，避免新会话读取过长背景。

## 子文档

- [Factory World State And Save V1](factory-world-state-and-save-v1.md)：正式三维工厂入口、权威状态与独立 schema 1；保留旧二维世界，当前未实现多人。

- [联机模型](multiplayer-model.md)：最终联机方向、形态分层、核心玩法边界和房间模型。
- [存档归属模型](save-ownership-model.md)：世界、角色、基地、队伍和版本兼容的存档归属。
- [同步与服务边界](network-sync-and-service-boundaries.md)：同步方式、P2P 边界、协作人数、权限和云存档建议。
- [演进路线与避坑](multiplayer-roadmap-and-pitfalls.md)：长期架构演进、当前必须避免的问题和执行建议。
