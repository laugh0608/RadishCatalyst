# Godot Project Structure

更新时间：2026-09-25

## 拆分说明

本文已按主题拆分为子文档；当前文件只保留入口索引，避免新会话读取过长背景。

## 子文档

- [Factory World State And Save V1](factory-world-state-and-save-v1.md)：正式三维工厂入口、权威状态、独立 schema 1 与工厂共用的文件协议；保留旧二维世界，当前未实现多人。
- [Factory Discovery Save V2](factory-discovery-save-v2.md)：勘探工厂独立 schema 2、电力 / 发现 / 多物料 / 统计状态，不迁移已有 schema 1 或旧二维 schema 10。

- [工程结构与分层原则](godot-project-structure-layout.md)：工程位置、推荐目录结构和 Godot 分层原则。
- [运行组织与边界](godot-project-structure-runtime.md)：场景组织、自动加载、命令流、验证入口和当前边界。
