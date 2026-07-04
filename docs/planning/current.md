# Current Plan

更新时间：2026-07-04

## 入口约束

本文是新会话的阶段入口，只保留当前阶段、当前活跃专题、边界、验证入口和退出条件。首版 Demo 完成规格以 [Demo Definition V1](../features/demo-definition-v1.md) 为准。

- 当前活跃专题：[Demo Presentation Rebuild V1](../features/demo-presentation-rebuild-v1.md)，覆盖表现层重建与真实资产管线。
- 阶段级专题 [Demo First Playable Slice Assembly V1](../features/demo-first-playable-slice-assembly-v1.md) 与核心循环、叙事节拍执行线在表现层重建期间挂起，重建完成后恢复收口。
- 风格与提示词真相源：`docs/reference/ai-art-prompts.md`；免费素材包候选：`docs/reference/free-asset-pack-candidates.md`；风格锚点定稿存 `assets/reference/`。

历史过程、长完成清单和详细复盘优先查看 `docs/planning/daily-start.md`、最新周志和 `docs/planning/demo-scope-and-playable-slice.md`。

## 阶段状态

已通过：

- 系统层成立：任务链、存档、资源链、采集 / 加工、HUD 状态和 `S0` 到 Demo 结尾钩子的路径逻辑可跑通，是本阶段保留复用的资产。
- 2026-04 至 2026-07 表现层先后使用 `draw_rect`、SVG、`Polygon2D` 拼装和脚本生成 PNG 四代代码生成介质；2026-07-02 项目级复盘判定该介质上限是示意图，无法达到"像一款游戏"。
- 2026-07-02 决策：画面主介质切换为真实资产（AI 生成为主、免费素材包补位），表现层按包重建，旧视觉层删除而非降权；过程口径同步瘦身。
- 2026-07-04 风格锚点定稿：第一批 6 个 AI 反应器候选全部达可用线，`a0_reactor_v4` 定为锚点存 `assets/reference/style-anchor.png`；`P0` 余项为素材包补位评估与第二、三批素材审阅。

当前阶段：

```text
首版 Demo 表现层重建第一版
```

## 当前主线

按包串行推进，不并行开线：

1. `P0` 素材锚定包（锚点已定稿）：生成并审阅第二、三批核心素材；下载评估免费素材包补位。
2. `P1` 首屏重建包：`TileMapLayer` 地面 + 设备 sprite 场景 + 玩家 / 敌人 sprite，首屏范围关闭旧视觉层。
3. `P2` 三区扩展包：晶体矿脉、污染边界、核心稳定站换用同一资产家族。
4. `P3` 旧层清除收口包：删除旧视觉层脚本与节点，修剪失效检查。

## 介质规则（本阶段最高优先）

- 画面主介质必须是真实资产（AI 生成或素材包贴图）+ `TileMapLayer` / `Sprite2D` 场景组合。
- 禁止新增程序绘制视觉层、脚本生成贴图或 `ColorRect` / `Polygon2D` 拼装作为画面主介质；程序绘制只允许动态高亮、状态灯、选中描边和调试辅助。
- 旧视觉层只走删除路径，不再以"降权"方式与新介质长期共存。

## 过程口径（与介质规则同时生效）

- `current.md` 与 `daily-start.md` 只在开发包收口时更新，每周不超过 2 次。
- 表现层相关工作不再新开 feature 专题，统一挂在 Demo Presentation Rebuild V1 之下。
- 冻结 `client/scripts/checks/` 新增；只维护存档完整性与主线可完成两类检查，因删层失效的检查随包修剪或删除。
- 截图复核只对比风格锚点参考图，输出具体差距清单；同一实现方式最多重试一次，仍失败则升级为素材 / 介质决策，不做同类调参循环。
- 每周唯一主进度证据是 60 秒实机录像；录像与上周无可见差异即判定本周失败，与提交数、文档量和检查结果无关。

## 冻结与放宽

继续冻结：

- 前线行动台、候选、窗口复盘、高压窗口和 `base_action_state` 保持冻结，只修 `P0` / `P1` 问题。
- 首版 Demo 12 区域封顶；不新增随机成功率、新货币、队员、完整装备栏、联机入口或长期成长系统。
- 不把试玩准备、修 bug 阶段、发布准备或大规模 polish 作为当前阶段目标。

允许推进：

- 引入与处理真实美术资产、`TileMapLayer` / `Sprite2D` 场景重建、玩家与敌人 sprite，以及为此必需的旧层删除和检查修剪。
- 角色首版允许静态 sprite + 程序位移，不要求完整动画组。

## 当前默认验证

客户端相关改动优先执行默认检查：Windows 用 `pwsh ./scripts/check-client.ps1`，macOS / Linux / Git Bash 用 `sh ./scripts/check-client.sh`；需要 Godot 运行时验证时确认本机可启动后加 `-WithGodot` / `--with-godot`。涉及文档时加跑对应平台 `check-docs` 与 `check-text-files`，提交前执行 `git diff --check`。

自动检查只兜底资源加载、场景引用和主线可完成；画面是否成立以实机截图对比锚点和 60 秒录像为准。

## 阶段退出条件

- 基地首屏与晶体矿脉、污染边界、核心稳定站四个核心区均以真实资产渲染，旧视觉层删除完毕。
- 玩家与敌人拥有真实 sprite 形象，不再由 `_draw()` 几何表达。
- 60 秒实机录像能被不了解项目的人识别为"一款 2D 工业科幻游戏"。
- 达成后恢复 [Demo First Playable Slice Assembly V1](../features/demo-first-playable-slice-assembly-v1.md) 收口，再重启 [Demo First Playable Acceptance V1](../features/demo-first-playable-acceptance-v1.md)。
