# Daily Start

更新时间：2026-07-06

## 用途

当提示是"根据项目规划和开发进度，今天要来做什么以推进开发"时，优先阅读本文。本文只提供日常入口和读取顺序；阶段方向与边界以 `docs/planning/current.md` 为准。

## 阶段

当前为「首版 Demo 表现层重建第一版：首分钟体验重基线」。

当前活跃专题：[Demo Presentation Rebuild V1](../features/demo-presentation-rebuild-v1.md)。核心循环、叙事节拍与纵切装配收口在表现层重建期间挂起。

素材与风格入口：

- 提示词库与风格规范：`docs/reference/ai-art-prompts.md`
- 免费素材包候选：`docs/reference/free-asset-pack-candidates.md`
- 生成素材接收：`assets/art-intake/`（原始批次不入库）；素材包下载：`assets/third-party/`（不入库）；风格锚点定稿：`assets/reference/`；可提交运行时素材：`client/assets/`

## 最近收尾

- 系统层（任务、存档、资源链、采集加工、HUD 状态、`S0` 到结尾钩子路径逻辑）成立并保留复用。
- 2026-07-02 复盘判定四代代码生成美术介质失败，切换真实资产管线；建立 Demo Presentation Rebuild V1，取代首屏 / 晶体 / 交接系列资产化专题余项。
- 2026-07-04 第一批 6 个反应器候选审阅全部达标，`a0_reactor_v4` 定稿为风格锚点（`assets/reference/style-anchor.png`）；第二、三批主候选已审定并处理到 `client/assets/`。
- 2026-07-05 `P1` 首屏真实资产层已成立；`P2` 晶体矿脉、污染边界和核心稳定站已接入同一资产家族；夜间修正了远场截图定位与旧视觉层压读问题。
- 2026-07-06 `P2` 三区定点截图一度判定成立，但后续实机截图暴露旧语义轮廓 / 旧色块仍会抢读、首屏设备堆叠、HUD 过小截断、交互范围过大和首分钟目标断裂；暂停录像与 `P3`，插入首分钟体验重基线包。

## 今日事项（2026-07-06，首分钟体验重基线）

1. 暂停 `P2` 录像和 `P3` 旧层删除，不再把素材接入等同于表现成立。
2. 新档首分钟只保留玩家、损坏前哨核心和少量环境道具；修复核心后才放开晶体 / 残骸采集目标。
3. 硬禁用旧规划色块、旧 art pass、交互物语义轮廓和过早出现的设备 sprite；收紧交互范围，放大 HUD 运行时面板。
4. 出口证据改为新档第一分钟截图序列：开局不再出现流程图色块，核心交互后能看见并采集晶体簇，HUD 能读清下一步。

## 防跑偏规则

- 画面主介质必须是真实资产 + `TileMapLayer` / `Sprite2D`；禁止新增程序绘制视觉层、脚本生成贴图或色块拼装作为画面主读法。
- 旧视觉层和交互语义轮廓先硬禁用，不再降权共存；后续 `P3` 再删文件与修剪检查。
- 表现层工作不新开 feature 专题；截图复核只对比风格锚点，同一实现方式最多重试一次。
- 文本、formatter、检查和口径整理不算主线进展；检查只兜底资源加载与主线可完成。
- 不再新增 `client/scripts/checks/` 检查脚本。
- 介质与风格锚点变更、阶段与专题切换、两次失败复盘属架构级升级点（见 `docs/process/development-decision-gates.md`），执行会话停手升级，不自行决策。

## 当前不做

- 不继续扩前线行动台、候选、窗口复盘、高压窗口或 `base_action_state`，除非出现 `P0` / `P1`。
- 不横向新增区域；首版 Demo 12 区域封顶。
- 不新增随机成功率、新货币、队员、完整装备栏、联机入口、最终美术包或发布流程。
- 不把装备面板、完整工具面板、技能树、科技树、试玩准备、修 bug 阶段或大规模 polish 作为当前包目标；这些进入后续首小时设计包。

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
