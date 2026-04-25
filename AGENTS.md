# 仓库协作说明

## Response Language

Always response in Chinese.

## Project Context

本仓库是 `RadishCatalyst / 异星催化` 的项目仓库。当前阶段以项目策划、架构边界和原型准备为主，长期目标是一个以异星化工基地、人物探索战斗、角色成长和后续协作联机为核心的 2D / 2.5D 工业科幻 ARPG。

## Repository Rules

- 文档和代码文件统一使用 LF 换行。
- 新增仓库文件优先使用英文文件名，正文可以使用中文。
- 文档入口是 `docs/README.md`。
- 当前定稿类文档放在 `docs/product/`、`docs/design/`、`docs/architecture/`。
- 参考资料放在 `docs/reference/`，归档材料放在 `docs/archive/`。
- 不要把 `docs/archive/full-conversation-history.md` 当作当前规范，它保留历史原貌，可能包含旧路径和旧命名。

## Engineering Preferences

- 以 Godot 4.x 为优先原型方向，脚本侧默认优先考虑 GDScript。
- 首版目标应先保证单机完整闭环，联机作为架构预留和后续阶段推进。
- 不要过早引入 MMO 级服务器、账号、交易、公会等重系统。
- 核心系统设计应围绕“基地服务冒险，冒险反哺基地”的循环展开。

## File Organization

- `client/`：未来 Godot 客户端工程。
- `server/`：未来可选服务端或联机相关工程。
- `assets/`：可提交的源资产、设定图、音频源文件等。
- `tools/`：项目脚本、数据处理、构建或导出辅助工具。
- `docs/`：策划、设计、架构、参考与归档文档。
