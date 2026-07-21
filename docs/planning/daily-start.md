# Daily Start

更新时间：2026-07-21

## 用途

当提示是“根据项目规划和开发进度，今天要来做什么以推进开发”时，优先阅读本文。本文只提供日常入口和读取顺序；阶段方向与边界以 `docs/planning/current.md` 为准。

## 阶段

当前为「切片实现：配方加工 arc（空间工厂自动化）——L0 / L1 已收口，L2 已实现待实机收口」。

- 活跃细专题 [L2 核心功能化](../features/slice-core-functionalization-v1.md)：修复核心后的直供电源与中央仓库存取已实现；headless 逻辑与有窗口正式入口 / 输入 / 截图各 25 项断言通过，5 张截图完成 AI 视觉复核，待萝卜SAMA实机收口。通用建造放置和电线杆 / 中继扩展网归 L3。
- 美术介质机械口径：[Pixel Art And Grid Standard](../reference/pixel-art-and-grid-standard.md)（32px 网格、960x540 相机、宏块归一均已定稿）。
- 章程与复盘结论存档：[Project Purpose And Solo AI Development Review](project-purpose-and-solo-ai-development-review.md)。

## 最近收尾

- 2026-07-18 存档持久化与采集建造两专题收口：`SliceSaveService` 存读闭环；整备台建造采集器、晶体地放置、每 10 秒自动产出。
- 2026-07-18 至 07-19 视角修正轮收口：投影口径两次校准定为高斜角俯视，22 张世界层素材重出换装（锚点 + 6 设备 + 13 角色帧 + 3 站立帧），画面填充 fractional、采集器足印 2x2、方向性 idle；萝卜SAMA实机确认。
- 2026-07-21 L1 手持合成经萝卜SAMA实机确认收口；L2 启动并修正层间依赖，固定核心能力留 L2、可放置扩展电网归 L3。
- 2026-07-21 L2 代码与自动验证完成：中央仓库面板、双向容量受限转移、6 格核心直供查询、schema 3 与 schema 2 兼容；25 项 headless 与 25 项有窗口正式入口 / 输入 / 截图断言通过。
- 遗留登记：八方向动画（候选专题）、viewport 整数重构（并入 HUD 换皮）、打磨清单观察项。

## 下一步事项

1. 正式入口实机复核 L2：修核心 → 按 E 打开仓库 → 数字键存 / 取晶体与零件 → 重启读档确认；通过后回填 L2 收口并切到 L3 设计。
2. 敌人素材生成会话可由萝卜SAMA择时并行启动（按高斜角口径与提示词库执行）。

## 防跑偏规则

- L2 固定核心能力复用现有修复态素材，不需新素材；L3 起的传送带 / 电线杆·中继 / 地板 / 储物箱仍属美术硬闸门，须萝卜SAMA另行授权生成会话。
- 不做敌人 / 战斗、任务链、立绘对话、八方向动画、viewport 重构；冻结旧系统与旧检查不动。
- 玩家可见目标以正式入口实机截图与运行时路径复核为主证据，自动检查只兜底。
- 自动化可生成多张截图，但单个 Codex 会话最多读取 3 张图片；多图先用 `scripts/create-screenshot-contact-sheet.sh` 合成一张带编号联系表，达到上限后由新会话继续审阅。
- 介质口径变更、两轮失败复盘、专题切换属架构级升级点，执行会话停手上报萝卜SAMA。

## 当前不做

- 敌人、战斗、污染伤害；任务链、立绘对话；八方向动画；viewport 重构与 HUD 换皮。
- 旧代码与旧素材清理（清单专题收口后另定）、联机、多星球、试玩准备与发布。

## 必读与选读

日常必读：

- `docs/planning/current.md`（配方加工阶段边界与退出条件）
- `docs/features/slice-core-functionalization-v1.md`（L2 当前可执行范围与验收）
- `docs/features/slice-recipe-processing-v1.md`（配方加工 arc 总览与层状态）
- `docs/reference/pixel-art-and-grid-standard.md`（投影口径 2026-07-18 修订）
- `docs/reference/ai-art-prompts.md`（全局风格块 2026-07-18 视角修订）

按任务选读：

- 归一与提示词口径：`docs/reference/ai-art-prompts.md`
- 流程闸门：`docs/process/development-decision-gates.md`
- 章程与完成定义：`docs/planning/project-purpose-and-solo-ai-development-review.md`
- 视觉气质与 UI 原则：`docs/product/visual-and-ui-direction.md`
- 旧路线历史证据：`docs/archive/features-demo-v1/README.md`、`docs/archive/planning-demo-v1/README.md`

## 验证入口

- 代码与素材接入：`sh ./scripts/check-client.sh`（默认不启动 Godot）；场景与脚本改动按需 `--with-godot` 单项验证。
- 玩家可见玩法 / UI / 场景 / 交互 / 存读结果：强制按 [Godot Runtime Verification Guide](../reference/godot-runtime-verification-guide.md) 从真实 `Boot` 自动运行输入链；有渲染目标必须有窗口抓图到 `assets/art-intake/` 并实际审阅，headless 断言不能替代截图。
- 文档改动：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`。
