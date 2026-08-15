# Daily Start

更新时间：2026-08-15

## 用途

当提示是“根据项目规划和开发进度，今天要来做什么以推进开发”时，优先阅读本文。阶段方向与边界以 [Current Plan](current.md) 为准，详细历史留在 W32 / W33 周志和功能专题。

## 当前阶段

阶段：第一可玩切片阶段验收与下一阶段立项。

- 真实新档自动、正式入口和萝卜SAMA人工完整全链均已通过，最终状态为 `delivered / 120`。
- 陌生玩家盲测已冻结：玩家可见补强已经完成，但当前版本尚未形成一份连续的无人指导阶段验收证据。
- 图形化制造 / 背包与统一设备面板均已人工收口。
- [视觉层级与色彩分离 V1](../features/slice-visual-hierarchy-and-color-separation-v1.md) 与 [游戏本体 UI 视觉定稿 V1](../features/slice-game-ui-visual-finalization-v1.md) 已完成并人工收口。
- [远程武器与工业供弹 V1](../features/slice-ranged-weapon-and-industrial-ammunition-v1.md)、[破损核心视觉家族 V1](../features/slice-damaged-core-visual-family-v1.md)与[首程引导与探索小地图 V1](../features/slice-first-journey-guidance-and-exploration-map-v1.md)均已人工收口。
- [设备—传送带接驳视觉 V1](../features/slice-device-conveyor-docking-visual-v1.md) 的反应器与核心代表分面均已人工通过；采集器和储物箱只在后续实机暴露同类遮挡时按已验证合同复核。
- [分类库存与通电储物箱 V1](../features/slice-category-inventory-and-powered-storage-v1.md) 与 [世界设备家族接入 V1](../features/slice-world-device-family-integration-v1.md) 的联合包 2 / 3 已提交，包 3 / 4 / 5 均获人工通过；包 5 的自动、正式入口和 AI 逐图复核证据已完整保留。

## 近期基线

- 7 月底已完成真实新档 `delivered / 120` 全链、20—40 分钟人工计时、鼠标放置、设备端口与图形化制造 / 背包；历史细节见 W31 周志。
- 视觉失败轮按闸门停止后改用 `1:1` 原生网格重投影，世界设备、UI 结构、接驳代表分面和 P2-A—P2-E 已于 8 月 13 日前人工收口。
- schema 8 已稳定承载分类库存、双模式储物箱、固定正面设备、实体物流和真实二值供电线；当前 schema 9 只追加首程旗标与探索图。
- 现行电网仍为二值可达模型，没有发电容量、设备负荷、储能或过载状态。

## 2026-08-15 日终

1. P1 已收口：完整人物四向 sheet 与弹体 / 枪口 / 命中特效家族均获人工通过，失败的删臂 + 覆盖层介质不再恢复。
2. P2 已完成充能解锁、制造、跨库存唯一、电池上限、手动转移和 schema 2–8 兼容验证；完整 Godot、正式 `Boot` `41` 项、一个主档、三份备份和五张截图均已保留。
3. 独立步枪图标已替换人物持枪帧并获人工通过；P3 随后完成 `1 / 2` 切换、左键当前武器、即时耗弹、固定弹体、首个敌人命中与三格战斗 HUD。
4. P3 精准 Godot `87` 项、完整回归与正式 `Boot` `55` 项通过；六张原图及十二张低饱和 / 灰阶派生图确认无 HUD 互叠、截断或主体遮挡。萝卜SAMA于 2026-08-15 授权提交并确认专题收口；有限电力和陌生玩家盲测仍须经下一次阶段闸门决定是否解冻。
5. 旧 `103×93px` 破损核心已替换为 V5 同族 `144×128px` 原生双态；核心专项 `98` 项、完整回归、正式 `Boot` `33` 项和九张复核图通过并获人工收口。
6. 五步首程引导、右下小地图、进度情报 + `64px` 行走揭雾及 schema 9 已人工收口；今日玩家可见专题全部结束。

## 2026-08-16 明日事项

1. 以 [第一可玩切片全链串通](../features/slice-first-playable-journey-v1.md)为阶段专题，从正式 `Boot` 真实新档复核终端配方、探索、核心修复、自动化产线、首次充能、步枪补给与战斗、样本交付、`120` 生命和保存重载。
2. 按 20—40 分钟、无人指导理解、正式像素画面与 HUD、零不可逆卡死、存读连续性五条退出标准记录时间、输入、存档与关键截图，形成阶段证据矩阵。
3. 把 `SliceWorld` 1499 行作为架构闸门同步审阅；不再向世界编排器追加业务分支，下一专题涉及新协调逻辑时先确定职责提取方案。
4. 验收通过后再申请解冻一次受控陌生玩家盲测；若发现阻断，按玩家结果、职责边界和验收建立明确收尾专题。第一可玩阶段关闭后，再立项下一能力专题。
5. 明日启动 Godot、`--with-godot` 或正式有窗口复核前，先告知萝卜SAMA。

## 防跑偏规则

- 玩家可见开发先有 `docs/features/` 专题和决策闸门，再进入代码、素材和场景接入。
- 视觉问题按玩家结果、场景组织、系统连接、资产家族、UI 结构、色彩数值、装饰依次归因；游戏本体不再参考 Radish 家族 UI，不能从透明度、边框、全局换色或增加装饰开始。
- 储物箱已成为二值电网消费者，但不引入发电容量、负荷或储能；schema 9 只在 schema 8 上增加两个首程旗标与 480 位探索图，后续不得拆分回滚或追加无关字段。
- 玩家可见结果以正式 `Boot` 实机截图和人工路径为主证据，自动检查只兜底。

## 当前不做

- 陌生玩家盲测、多人试玩、试玩分发、打包或发布。
- 敌潮、复杂 Boss、技能树、联机、新敌人、新配方、新建筑或新地图。
- 立绘对话、八方向动画、viewport 重构、旧地图 / 旧 `GameRoot` / 旧三槽存档复活和无关重构。

## 继续前必读

- [Current Plan](current.md)
- [视觉层级与色彩分离 V1](../features/slice-visual-hierarchy-and-color-separation-v1.md)
- [游戏本体 UI 视觉定稿 V1](../features/slice-game-ui-visual-finalization-v1.md)
- [远程武器与工业供弹 V1](../features/slice-ranged-weapon-and-industrial-ammunition-v1.md)
- [首程引导与探索小地图 V1](../features/slice-first-journey-guidance-and-exploration-map-v1.md)
- [设备—传送带接驳视觉 V1](../features/slice-device-conveyor-docking-visual-v1.md)
- [世界设备家族接入 V1](../features/slice-world-device-family-integration-v1.md)
- [分类库存与通电储物箱 V1](../features/slice-category-inventory-and-powered-storage-v1.md)
- [第一可玩切片全链串通](../features/slice-first-playable-journey-v1.md)
- [Visual And UI Direction](../product/visual-and-ui-direction.md)
- [Pixel Art And Grid Standard](../reference/pixel-art-and-grid-standard.md)
- [Visual Direction Decision Framework](../reference/visual-direction-decision-framework.md)
- [Development Decision Gates](../process/development-decision-gates.md)
- [L3 建造与二值电网](../features/slice-building-placement-and-power-grid-v1.md)
- [设备操作面板统一 V1](../features/slice-unified-device-operation-panels-v1.md)

## 验证入口

- 文档：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`。
- 代码与素材：`sh ./scripts/check-client.sh`；玩家可见改动按 [Godot Runtime Verification Guide](../reference/godot-runtime-verification-guide.md) 补正式入口、截图和人工复核。
