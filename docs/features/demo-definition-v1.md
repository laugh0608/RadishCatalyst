# Demo Definition V1

更新时间：2026-06-18

## 用途

本文定义首版 Demo 达到“可以进入试玩准备和集中修 bug 阶段”前必须具备的完成规格。它不是当前开发任务清单，也不替代当前活跃专题；它用于约束后续功能、场景、玩法和阶段文档如何拆分。

首版 Demo 未满足本文“必达规格”前，开发继续按专题逐项推进；真实页面 smoke 只用于核对开发效果。

## Demo 定位

首版 Demo 是单人、离线、首颗星球前哨段体验。它必须让玩家完整经历：

```text
基地恢复 -> 外出采集 / 战斗 -> 回基地加工 -> 整备获得能力差异 -> 推进污染 / 遗迹 / 核心稳定站 -> 完成 Demo 终点
```

目标是证明“基地服务冒险，冒险反哺基地”。它不是完整游戏、不是发布版本、不是长期养成系统，也不是多星球或联机验证。

## 必达规格表

| 分类 | 首版 Demo 完成规格 | 数量口径 | 不做 |
| --- | --- | --- | --- |
| 主线结构 | 从新档到核心稳定站完成反馈的一条连续主线 | 1 条主线，1 个 Demo 终点，0 条必需支线 | 不开第二星球、第二章节或独立支线任务网 |
| 区域 / 场景 | 首颗星球前哨周边 12 个可识别区域 | 4 个核心区、4 个功能区、4 个过渡区；不新增第 13 区域 | 不做完整开放世界，不平均扩厚 12 区 |
| 核心场景完成度 | 核心区域具备可读路线、资源、危险、回基地理由和初步美术识别 | 基地、晶体、污染、核心稳定站 4 个核心区达到第一版场景完成度 | 不追求最终美术包或完整大迷宫 |
| 功能 / 过渡场景 | 非核心区域支撑机制展示、节奏连接和少量回访 | 封锁遗迹、裂相脊、回声台地、锚定桥 4 个功能区；盐壳、碎晶、风蚀、锁相 4 个过渡区 | 不给每个区域新增独立系统 |
| 工艺 / 科技解锁 | 一条轻量工艺解锁主干，玩家能看到基地加工逐步打开外勤能力 | 1 条主干，约 4 个阶段：前哨恢复、过滤 / 药剂、遗迹 / 回投、核心稳定 | 不做完整科技树、科技网格 UI 或长期研究系统 |
| 工业基建模块 | 基地有稳定的出发前后勤、加工、污染处理、储存和整备功能 | 5 个核心模块：前哨核心、基础反应器、污染过滤器、基础储存箱、出发整备台 | 不做完整电网、管线、物流、自动化工厂 |
| 资源 / 生产链 | 资源种类少但用途清晰，能从外勤转成能力 | 6 到 8 个核心资源 / 产物；1 条固体加工链、1 条污染 / 流体处理链、1 条副产回收或整备链 | 不堆同类材料，不做复杂化工仿真 |
| 角色成长 | 玩家至少获得一种可持续读出的外勤能力提升 | 1 条轻量成长轴，2 到 3 个可见成长状态或整备收益 | 不做大型职业树、长期等级曲线或多角色队伍 |
| 技能 / 操作 | 角色具备基础战斗和少量工具化外勤动作 | 1 个基础攻击 / 工具动作，1 个防护或模块收益动作，1 个可选扫描 / 采集 / 战斗增强动作 | 不做完整 ARPG 技能树或多职业 Build |
| 装备 / 模块 | 装备来源服务基地制造和外勤准备 | 1 套防护服或装甲，1 类武器 / 工具，2 到 3 个模块或等价整备状态，2 到 3 个消耗品 | 不做完整装备栏、完整 loadout、随机词条掉落 |
| 战斗压力 | 战斗能验证准备差异，而不是只做路障 | 1 到 2 种基础敌人，1 种区域威胁或精英，1 名 Demo 终点阶段守卫 | 不做复杂 Boss 阶段或刷怪养成 |
| 污染与防护 | 污染既是危险也是基地处理对象 | 1 套污染压力机制，1 条污染处理链，至少 1 个污染副产回收价值 | 不把污染只做成扣血地板 |
| UI / HUD | 玩家能在关键操作面读懂目标、缺料、收益和承压差异 | HUD、地图目标、对象提示、设备面板、战斗 / 结果反馈 5 类界面都要覆盖 | 不做完整菜单、设置页或高保真组件库 |
| 存档 / 状态 | Demo 主路径状态能保存、读取、复测和迁移 | 世界、角色、库存、建筑、任务、区域、敌人和关键整备状态必须可校验 | 不用场景节点路径或显示名当真相源 |
| 自动检查 | 每个开发专题都要覆盖真实玩家路径的关键判断 | `check-client` 覆盖静态数据 / 场景引用；必要时加 Godot 运行时检查 | 不用纯文档或纯提示替代主路径检查 |
| 初步美术 | 玩家能区分基地、晶体、污染、遗迹 / 异常和核心稳定站 | 4 个核心区有明确色彩 / 地貌 / 设施识别；12 区有地图与场景标识 | 不做最终资产量产、过场动画或大规模换皮 |

## 当前专题映射

| 规格项 | 专题文档 | 状态 |
| --- | --- | --- |
| Demo 完成定义 | 本文 | 已建立规格源 |
| 区域 / 场景范围 | `docs/planning/demo-scope-and-playable-slice.md` | 已定义 12 区域、4 核心区和核心稳定站终点 |
| 角色成长 / 战斗差异 | `docs/features/demo-combat-progression-v1.md`，最近完成细专题 `docs/features/demo-character-kit-v1.md`、`docs/features/ruin-outer-ring-module-pressure-v1.md` 和 `docs/features/pollution-edge-maintenance-pressure-v1.md` | 已落地第一轮 |
| 工具打击校准 / 输出整备 | `docs/features/demo-tool-strike-calibration-v1.md` | 已落地第一包 |
| 工业基建 / 工艺解锁主干 | `docs/features/demo-industrial-tech-spine-v1.md` | 已落地第一包 |
| 资源链状态 | `docs/features/demo-resource-chain-state-v1.md` | 已落地第一包 |
| 存档 / 状态 | `docs/features/demo-save-state-contract-v1.md` | 已落地第一包 |
| 主路径连续性 / 自动检查 | `docs/features/demo-main-path-continuity-v1.md` | 已落地第一包 |
| 自动检查 / 工程承载面 | `docs/features/demo-runtime-surface-decomposition-v1.md` | 已落地第一包 |
| 功能场景玩法 | `docs/features/demo-functional-scene-gameplay-v1.md` | 已落地第一包 |
| 外勤回基地收益兑现 | `docs/features/demo-field-loop-payoff-v1.md` | 已落地第一包 |
| 终点前综合准备读法 | `docs/features/demo-endpoint-readiness-v1.md` | 已落地第一包 |
| Demo 完成成果整理 | `docs/features/demo-completion-outcome-readout-v1.md` | 已落地第一包 |
| 整段体验连贯性 | `docs/features/demo-playable-experience-coherence-v1.md` | 已落地第一包 |
| 可玩场景构成 | `docs/features/demo-playable-scene-composition-v1.md` | 已落地第一包 |
| 战斗撤离恢复读法 | `docs/features/demo-combat-evacuation-recovery-v1.md` | 已落地第一包 |
| 交互可辨识度 | `docs/features/demo-interaction-affordance-v1.md` | 已落地第一包 |
| 动作反馈可读性 | `docs/features/demo-action-feedback-readability-v1.md` | 已落地第一包 |
| 受阻动作恢复读法 | `docs/features/demo-action-blocker-recovery-v1.md` | 已落地第一包 |
| 原型视觉呈现 | `docs/features/demo-prototype-visual-pass-v1.md` | 已通过退出判断 |
| 快捷补给读法 | `docs/features/demo-quick-slot-supply-readability-v1.md` | 当前活跃，第一包已落地 |
| 角色技能 / 装备模块第一版 | `docs/features/demo-character-kit-v1.md` | 已落地首个主动工具动作 |
| 防护响应 / 装备状态 | `docs/features/demo-protective-response-v1.md` | 已落地第一包 |
| 核心场景与初步美术 | `docs/features/demo-scene-art-foundation-v1.md` | 已落地第一包 |
| 非核心区域场景识别 | `docs/features/demo-non-core-scene-identity-v1.md` | 已落地第一包 |
| 主线收束与完成感 | `docs/features/demo-mainline-completion-v1.md` | 已落地第一包 |

## 专题拆分规则

新增或更新开发专题时，必须说明它覆盖本文哪几行规格。一个专题可以覆盖多行，但不能只覆盖提示文案。

优先拆成这些专题类型：

1. 功能专题：角色成长、装备模块、工业基建、污染处理、主线完成感。
2. 场景专题：核心区域场景完成度、初步美术识别、区域路线和对象表现。
3. 工程专题：脚本拆分、存档兼容、自动检查、HUD / formatter 职责边界。

专题文档必须包含玩家操作路径、状态 / 存档、HUD / 场景反馈和自动检查。只改静态清单、只做基线复核或只改提示，不应成为当前阶段主线。

## 阶段文档使用规则

- `docs/planning/current.md` 只写当前阶段、当前活跃专题、冻结边界和退出条件。
- `docs/planning/daily-start.md` 只写读取顺序和当天推进原则。
- 当前活跃专题必须来自本文的未完成规格项，并在专题内声明覆盖范围。
- 周志只记录已经发生的推进和风险，不作为下一步范围来源。
- 当本文规格发生变化时，必须同步 `current.md`、`daily-start.md`、`docs/features/README.md` 和本周周志。

## 当前优先级

当前继续推进首版 Demo 体验主干；`Demo Prototype Visual Pass V1` 已通过退出判断，下一步切到 `Demo Quick Slot Supply Readability V1`：

1. 原型视觉呈现已覆盖现有 12 区层级、核心区场地尺度、首小时目标链场景导引和专项检查。
2. 快捷补给读法只处理现有修复凝胶 / 抗污染药剂在 HUD 快捷栏、补给反馈和失败恢复路线中的可读性。
3. 只复用既有任务、库存、生命 / 防护、补给和整备系统，不新增资源、配方、区域、完整背包、完整装备栏、死亡系统、终局菜单、结算页或新任务链。

在首版 Demo 满足本文必达规格前，不切到试玩准备或集中修 bug 阶段。
