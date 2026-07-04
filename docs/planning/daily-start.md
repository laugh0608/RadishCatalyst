# Daily Start

更新时间：2026-07-04

## 用途

当提示是"根据项目规划和开发进度，今天要来做什么以推进开发"时，优先阅读本文。本文只提供日常入口和读取顺序；阶段方向与边界以 `docs/planning/current.md` 为准。

## 阶段

当前为「首版 Demo 表现层重建第一版」。

当前活跃专题：[Demo Presentation Rebuild V1](../features/demo-presentation-rebuild-v1.md)。核心循环、叙事节拍与纵切装配收口在表现层重建期间挂起。

素材与风格入口：

- 提示词库与风格规范：`docs/reference/ai-art-prompts.md`
- 免费素材包候选：`docs/reference/free-asset-pack-candidates.md`
- 生成素材接收：`assets/art-intake/`（原始批次不入库）；素材包下载：`assets/third-party/`（不入库）；风格锚点定稿：`assets/reference/`

## 最近收尾

- 系统层（任务、存档、资源链、采集加工、HUD 状态、`S0` 到结尾钩子路径逻辑）成立并保留复用。
- 2026-07-02 复盘判定四代代码生成美术介质失败，切换真实资产管线；建立 Demo Presentation Rebuild V1，取代首屏 / 晶体 / 交接系列资产化专题余项。
- 2026-07-04 第一批 6 个反应器候选审阅全部达标，`a0_reactor_v4` 定稿为风格锚点（`assets/reference/style-anchor.png`）；第二批生成与 `P1` 准备解锁。

## 当前事项（P0 素材锚定包）

1. 萝卜SAMA 按提示词库「第二批：首屏核心设备」与整版出图规则生成 B1 到 B8 候选（整版 2 到 3 版、单张 2 到 4 张），整批挂 `assets/reference/style-anchor.png` 做图像参考，放入 `assets/art-intake/<日期>-batch02/`。
2. B1 / B2 前哨核心同图双状态出一张保证两态同机；B3 到 B6 优先 2x2 合版，属性混淆或走形再退单张。
3. 继续按候选清单下载 1 到 2 个 CC0 素材包到 `assets/third-party/`，补角色动画与整体兜底评估（`P0` 未完成项）。
4. 第二批放好后请 Claude 审阅；通过后仓库侧启动去底、缩放、调色接入流程与 `P1` 首屏 `TileMapLayer` 骨架。

## 防跑偏规则

- 画面主介质必须是真实资产 + `TileMapLayer` / `Sprite2D`；禁止新增程序绘制视觉层、脚本生成贴图或色块拼装作为画面主读法。
- 旧视觉层只删除，不降权共存；因删层失效的检查随包修剪。
- 表现层工作不新开 feature 专题；截图复核只对比风格锚点，同一实现方式最多重试一次。
- 文本、formatter、检查和口径整理不算主线进展；检查只兜底资源加载与主线可完成。
- 不再新增 `client/scripts/checks/` 检查脚本。

## 当前不做

- 不继续扩前线行动台、候选、窗口复盘、高压窗口或 `base_action_state`，除非出现 `P0` / `P1`。
- 不横向新增区域；首版 Demo 12 区域封顶。
- 不新增随机成功率、新货币、队员、完整装备栏、联机入口、最终美术包或发布流程。
- 不把试玩准备、修 bug 阶段或大规模 polish 作为当前阶段目标。

## 阻塞标准

只让这些问题阻塞阶段：崩溃、主线卡死、坏档、任务无法完成、关键资源断档、UI 完全无法判断下一步。

## 必读与选读

日常必读：

- `docs/planning/current.md`
- `docs/features/demo-presentation-rebuild-v1.md`
- `docs/reference/ai-art-prompts.md`

按任务选读：

- 素材包评估：`docs/reference/free-asset-pack-candidates.md`
- 视觉气质与 UI 原则：`docs/product/visual-and-ui-direction.md`
- Demo 规格：`docs/features/demo-definition-v1.md`
- 纵切路径（挂起中）：`docs/features/demo-first-playable-slice-assembly-v1.md`
- 流程闸门：`docs/process/development-decision-gates.md`

## 验证入口

客户端改动优先执行默认检查：Windows 用 `pwsh ./scripts/check-client.ps1`，macOS / Linux / Git Bash 用 `sh ./scripts/check-client.sh`；需要 Godot 运行时验证时确认本机可启动后加 `-WithGodot` / `--with-godot`。

提交前：Windows 用 `pwsh ./scripts/check-text-files.ps1`、`pwsh ./scripts/check-docs.ps1`；macOS / Linux / Git Bash 用 `./scripts/check-text-files.sh`、`./scripts/check-docs.sh`；最后执行 `git diff --check`。
