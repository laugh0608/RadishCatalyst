# Daily Start

更新时间：2026-07-25

## 用途

当提示是“根据项目规划和开发进度，今天要来做什么以推进开发”时，优先阅读本文。本文只提供日常入口和读取顺序；阶段方向与边界以 `docs/planning/current.md` 为准。

## 阶段

当前为「切片实现：配方加工 arc（空间工厂自动化）——L0 / L1 / L2 已收口，L3 自动证据完成、待人工收口」。

- 活跃细专题 [L3 建造放置 + 扩展供电网](../features/slice-building-placement-and-power-grid-v1.md)：素材硬闸门及实现包 1–4 的代码、自动检查、正式入口重启和截图证据均已完成；两座大晶簇增产后新档 25 晶体可自然完成三跳采集器自举，下一步做人工复测。
- 美术介质机械口径：[Pixel Art And Grid Standard](../reference/pixel-art-and-grid-standard.md)（32px 网格、960x540 相机、宏块归一均已定稿）。
- 章程与复盘结论存档：[Project Purpose And Solo AI Development Review](project-purpose-and-solo-ai-development-review.md)。

## 最近收尾

- 2026-07-18 存档持久化与采集建造两专题收口：`SliceSaveService` 存读闭环；整备台建造采集器、晶体地放置、每 10 秒自动产出。
- 2026-07-18 至 07-19 视角修正轮收口：投影口径两次校准定为高斜角俯视，22 张世界层素材重出换装（锚点 + 6 设备 + 13 角色帧 + 3 站立帧），画面填充 fractional、采集器足印 2x2、方向性 idle；萝卜SAMA实机确认。
- 2026-07-21 L1 手持合成经萝卜SAMA实机确认收口；L2 启动并修正层间依赖，固定核心能力留 L2、可放置扩展电网归 L3。
- 2026-07-21 L2 代码与自动验证完成：中央仓库面板、双向容量受限转移、6 格核心直供查询、schema 3 与 schema 2 兼容；25 项 headless 与 25 项有窗口正式入口 / 输入 / 截图断言通过。
- 2026-07-21 萝卜SAMA按正式入口完成“新档采集与合成零件 → 修核心 → 仓库存取晶体 / 零件 → 重启载入再核对”，确认 L2 收口；随后建立 L3 可执行专题并完成采集器专用放置审计。
- 2026-07-21 L3-A 工业地板从已审定 V2 逐格裁出 16 个 32px tile，完成共享色板归一、128x128 atlas、TileSet 资源接入与三种尺寸平台视觉复核；本包未启动 Godot、未编写玩法代码。
- 2026-07-21 L3-B 首轮 V1 / V2 经萝卜SAMA复核均判废：V1 斜向下偏航且缩小后粘连，V2 是矮胖平台设备而非电线杆式中继；已补细高原型、屏幕轴对齐与首张硬失败即先改提示词的约束。
- 2026-07-24 L3-B V4 纠正为细高电线杆但仍有斜向偏航；V5 使用正交网格相机方位后通过硬判据并完成 32×64 双态归一，公共杆体只切换红 / 青状态灯、电极窗口和 4px 短脉冲，工业地板实景视觉复核通过。
- 2026-07-25 L3-C V1 同图四向直段一次通过硬判据；以统一源窗口和整数块降采样归一为四个 32×32 帧，共享 17 色，工业地板联系表确认上 / 右 / 下 / 左输出端无需文字可辨。
- 2026-07-25 L3-D V1 / V2 均未守住反应器主体像素不变量；经萝卜SAMA确认换为确定性离线派生，以同一份 96×90 运行时反应器只覆盖两个严格对置端口，四向帧与工业地板联系表通过机械断言和视觉复核，未消耗 V3。
- 2026-07-25 L3-E V1 / V2 均把四罐储存主体错误简化为三罐；经萝卜SAMA确认换介质并保留未使用的 V3，以同一份 87×88 主体只覆盖一个双向舱口，四向帧通过像素不变量断言与工业地板视觉复核。
- 2026-07-25 L3 实现包 1 收口：配方产出工业地板 / 采集器套件，两者共用建筑定义、占用索引、真实素材预览、放置提交与通用实例；旋转、连续放置、取消、短失败原因及采集器 10 秒产出通过自动与正式入口截图复核。
- 2026-07-25 L3 实现包 2 收口：其余四类建筑与固定方向帧接入；六类建筑共用调整、取消恢复、二次确认拆除与全额返还，地板承载、背包容量及内容门控通过 81 项逻辑断言、40 项正式入口断言和视觉复核。
- 2026-07-25 L3 实现包 3 收口：核心唯一源、三段中继可达传播、断连全量重算和设备端口供电成立；桥接调整 / 拆除同帧掉电，取消 / 重建恢复，采集器进度断电暂停。67 项逻辑断言、42 项正式入口断言和视觉复核通过。
- 2026-07-25 L3 实现包 4 自动证据完成：schema 4 保存所有建筑与白名单内部状态，schema 2 / 3 无损迁移，坏主档拓扑回退备份，重启后稳定 ID、布局、库存、内部状态和派生电网一致。102 项专项断言、78 项重启断言、45 项自然资源自举断言和十图联系表复核通过。
- 遗留登记：八方向动画（候选专题）、viewport 整数重构（并入 HUD 换皮）、打磨清单观察项。

## 下一步事项

1. 萝卜SAMA执行 L3 人工路径：自然采集与合成、修核心、铺地、三跳中继、首台采集器通电、孤立中继拒绝、桥接断连 / 恢复、调整 / 拆除与重启载入。
2. 人工路径通过后标记 L3 收口并建立 L4 传送带物流细专题。

## 防跑偏规则

- L3 的地板、中继、传送带与设备方向 / 状态变体是玩家可见实现硬闸门；不得用占位色块、程序贴图、运行时强转 sprite 或 debug 网络抢跑。具体拆分见 L3 专题。
- 不做敌人 / 战斗、任务链、立绘对话、八方向动画、viewport 重构；冻结旧系统与旧检查不动。
- 玩家可见目标以正式入口实机截图与运行时路径复核为主证据，自动检查只兜底。
- 自动化可生成多张截图，但单个 Codex 会话默认最多读取 3 张图片；多图先用 `scripts/create-screenshot-contact-sheet.sh` 合成一张带编号联系表，达到默认上限后先报告，萝卜SAMA明确要求时可继续。
- 图像生成默认每轮至多 3 次、每次 1 张；每轮结束必须先落盘、更新 manifest 并报告，只有经萝卜SAMA明确授权才能在同素材会话追加下一轮。
- 介质口径变更、两轮失败复盘、专题切换属架构级升级点，执行会话停手上报萝卜SAMA。

## 当前不做

- 敌人、战斗、污染伤害；任务链、立绘对话；八方向动画；viewport 重构与 HUD 换皮。
- 旧代码与旧素材清理（清单专题收口后另定）、联机、多星球、试玩准备与发布。

## 必读与选读

日常必读：

- `docs/planning/current.md`（配方加工阶段边界与退出条件）
- `docs/features/slice-building-placement-and-power-grid-v1.md`（L3 当前可执行范围、素材与验收）
- `docs/features/slice-recipe-processing-v1.md`（配方加工 arc 总览与层状态）
- `docs/reference/pixel-art-and-grid-standard.md`（投影口径 2026-07-18 修订）
- `docs/reference/ai-art-prompts.md`（全局风格块 2026-07-18 视角修订）
- `docs/reference/l3-building-art-prompts.md`（L3-A 至 L3-E 素材提示词、硬判据与路线复盘）

按任务选读：

- 归一与提示词口径：`docs/reference/ai-art-prompts.md`、`docs/reference/l3-building-art-prompts.md`
- 流程闸门：`docs/process/development-decision-gates.md`
- 章程与完成定义：`docs/planning/project-purpose-and-solo-ai-development-review.md`
- 视觉气质与 UI 原则：`docs/product/visual-and-ui-direction.md`
- 旧路线历史证据：`docs/archive/features-demo-v1/README.md`、`docs/archive/planning-demo-v1/README.md`

## 验证入口

- 代码与素材接入：`sh ./scripts/check-client.sh`（默认不启动 Godot）；场景与脚本改动按需 `--with-godot` 单项验证。
- 玩家可见玩法 / UI / 场景 / 交互 / 存读结果：强制按 [Godot Runtime Verification Guide](../reference/godot-runtime-verification-guide.md) 从真实 `Boot` 自动运行输入链；有渲染目标必须有窗口抓图到 `assets/art-intake/` 并实际审阅，headless 断言不能替代截图。
- 文档改动：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`。
