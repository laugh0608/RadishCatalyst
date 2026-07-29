# Daily Start

更新时间：2026-07-29

## 用途

当提示是“根据项目规划和开发进度，今天要来做什么以推进开发”时，优先阅读本文。阶段方向与边界以 [Current Plan](current.md) 为准，详细历史留在 W31 周志和功能专题。

## 当前阶段

阶段：第一可玩切片玩家可见完成度补强。

- 真实新档自动、正式入口和萝卜SAMA人工完整全链均已通过，最终状态为 `delivered / 120`。
- 陌生玩家盲测已冻结：当前功能可运行，但视觉和交互仍不足以证明陌生玩家可独立理解。
- [图形化建造 / 合成 / 背包 UI V1](../features/slice-graphical-crafting-and-inventory-v1.md) 已人工收口。
- [设备操作面板统一 V1](../features/slice-unified-device-operation-panels-v1.md) 建筑包 1 已人工通过；核心仓库包 2 暂停。

## 2026-07-29 收尾

- `d6b1f6e3` 完成设备自动补地板、物流端口 / 断链诊断、采集器显式取料和固定数字键制作语义；项目级一次性运行数据迁入 `tools/runtime-intake/`。
- `4e6d2a1d` 收口内部完整全链，`35ba6140` 根据人工判断延期盲测并恢复表现层开发。
- `d3953c6e` 以七张配方卡、九个背包格、鼠标制作 / 选中和权威阻塞状态替换纯文字整备主读法，并经人工通过。
- `6aa5beb2` 统一六类建筑设备面板、结构化物流状态与鼠标操作；人工通过后删除描述式“下一步：……”文案。
- 日终代码—文档审计确认：现行电网仍是二值可达模型，暂无发电容量、设备耗电、中继负荷或储能状态。

## 明日事项（2026-07-30）

1. **先建立视觉层级与色彩分离专题。**按开发决策闸门审计 UI、设备主体、地表和状态色的明度 / 材质角色，定义玩家可见结果、失败判据、截图证据和实现包；不能只给现有深色面板换一个深浅色。
2. **再建立有限电力玩法专题边界。**以当前二值电网为迁移基线，设计核心发电上限、设备固定耗电、中继下游负荷、过载分配，以及未来发电 / 储能设备与 schema 的关系；专题确认前不写实现、不在 UI 中伪造数值。
3. **继续冻结其他扩展。**设备面板包 2、陌生玩家盲测、新内容、发布与打包均不自动开工；视觉专题优先，电力专题排在其后，两者不混包。

## 防跑偏规则

- 玩家可见开发先有 `docs/features/` 专题和决策闸门，再进入代码、素材和场景接入。
- 视觉问题同时覆盖 UI 与世界设备；不能用调透明度、边框或单一换色替代材质、明度和功能色层级。
- 电力专题会影响电网、建筑定义、面板和存档；当前二值结果必须保持兼容，迁移策略未确认前不扩 schema。
- 玩家可见结果以正式 `Boot` 实机截图和人工路径为主证据，自动检查只兜底。

## 当前不做

- 陌生玩家盲测、多人试玩、试玩分发、打包或发布。
- 敌潮、复杂 Boss、技能树、联机、新敌人、新配方、新建筑或新地图。
- 立绘对话、八方向动画、viewport 重构、旧地图 / 旧 `GameRoot` / 旧三槽存档复活和无关重构。

## 明日必读

- [Current Plan](current.md)
- [第一可玩切片全链串通](../features/slice-first-playable-journey-v1.md)
- [Visual And UI Direction](../product/visual-and-ui-direction.md)
- [Pixel Art And Grid Standard](../reference/pixel-art-and-grid-standard.md)
- [Development Decision Gates](../process/development-decision-gates.md)
- [L3 建造与二值电网](../features/slice-building-placement-and-power-grid-v1.md)
- [设备操作面板统一 V1](../features/slice-unified-device-operation-panels-v1.md)

## 验证入口

- 文档：`./scripts/check-docs.sh`、`./scripts/check-text-files.sh`、`git diff --check`。
- 代码与素材：`sh ./scripts/check-client.sh`；玩家可见改动按 [Godot Runtime Verification Guide](../reference/godot-runtime-verification-guide.md) 补正式入口、截图和人工复核。
