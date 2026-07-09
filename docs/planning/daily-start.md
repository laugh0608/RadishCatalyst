# Daily Start

更新时间：2026-07-09

## 用途

当提示是"根据项目规划和开发进度，今天要来做什么以推进开发"时，优先阅读本文。本文只提供日常入口和读取顺序；阶段方向与边界以 `docs/planning/current.md` 为准。

## 阶段

当前为「首版 Demo 表现层重建第一版：画面地基重建（地形 / 平台 / 光影 / 接地阴影 / 构图）」。

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
- 2026-07-08 首分钟截图复核暴露靠近晶体时旧层回流和晶体路径不够可读；已补 `GameRoot` 末尾旧层压制、核心到晶体中段资产路径和修复前 / 修复后显隐检查。
- 2026-07-09 架构级路线判定：对比宽幅参考图确认打转根因是画面地基缺失（空背景、无统一光影、无接地阴影、真实资产平铺），不是资产不足；插入 `R1` 地形+光影地基包，验收改为"场景成立四要件"，真实资产平铺不算通过。
- 2026-07-09 `R1` 工程半落地：新增 `GroundBedFoundation`（`demo_ground_bed.gd`），用既有真实岩地 tile 把 `GroundTileMap` 覆盖扩展到填满可视地面并关闭黑 `Background`，解决空背景 + 悬浮物；`sh ./scripts/check-client.sh` 通过、Godot headless 导入无报错。同时暴露更深根因见下方待决策。

## 待决策（架构级 / 美术方向，`R1` 关键闸门）

调色板冲突：项目风格锚点与调色板是"暗青灰"（岩地 `#151C1E`、`dark teal-gray basalt`、暗青反应堆锚点），而宽幅参考图 `assets/concept-art/2026-06-25-demo-first-screen-wide-reference.png` 是"浅暖荒漠地面 + 暗金属建筑"。参考图之所以像游戏，靠浅地面与暗建筑的图/底对比；当前把地面和设备做成同一种暗青，明度贴死、没有图底分离，铺满也塌成暗色虚空。结论：**只要地表仍按 `#151C1E` 暗青生成，无论工程多对都到不了参考图**，这是风格锚点内部矛盾，属萝卜SAMA 的美术方向决策，Claude 不改锚点、不生成美术。

## 明日事项（2026-07-10）

1. 先决定调色板方向：**是否把地表 / 平台从暗青改为浅暖荒漠（地面变浅暖、建筑保持暗金属，重建图底对比）**。建议改，这几乎是收敛到参考图的唯一路径。
2. 若定改：重生成 C1 岩地、C2 平台、C3 晶体区变体、C4 污染区变体四张 tile（提示词 `dark ... teal-gray` 改为 `light warm sandy-grey rock, sunlit`，保留 `seamless tileable`），并同步更新 `ai-art-prompts.md` 的 `#151C1E` 岩地色值与风格锚点说明。
3. 新 tile 生成后交给执行会话接进 `GroundBedFoundation`（换贴图即可，零代码改动），再跑实机截图，第一次真正判断地形层是否成立。
4. 地形成立后再按 `R1` 顺序推进平台落座面、统一光向 / 色调、接地阴影、构图收拢；地基不成立不摆物件。

## 今日事项（已完成，2026-07-09）

1. `R1` 地形工程半：`GroundBedFoundation` 铺满可视地面 + 关闭黑底，已提交。
2. 定位并升级更深根因：暗青调色板与浅暖参考图冲突，已转为明日待决策闸门。

## 防跑偏规则

- 画面主介质必须是真实资产 + `TileMapLayer` / `Sprite2D`；禁止新增程序绘制视觉层、脚本生成贴图或色块拼装作为画面主读法。
- 旧视觉层和交互语义轮廓先硬禁用，不再降权共存；后续 `P3` 再删文件与修剪检查。
- 不新增临时工作台或临时 Demo 场景名；正式项目的正式入口和正式场景必须承担编辑器可见性。
- 表现层工作不新开 feature 专题；截图复核只对比风格锚点，同一实现方式最多重试一次。
- 文本、formatter、检查和口径整理不算主线进展；检查只兜底资源加载与主线可完成。
- 不新建 `client/scripts/checks/` 检查脚本文件；已有检查可补与当前改动直接相关的覆盖。
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
