# Daily Start

更新时间：2026-08-03

## 用途

当提示是“根据项目规划和开发进度，今天要来做什么以推进开发”时，优先阅读本文。阶段方向与边界以 [Current Plan](current.md) 为准，详细历史留在 W32 周志和功能专题。

## 当前阶段

阶段：第一可玩切片玩家可见完成度补强。

- 真实新档自动、正式入口和萝卜SAMA人工完整全链均已通过，最终状态为 `delivered / 120`。
- 陌生玩家盲测已冻结：当前功能可运行，但视觉和交互仍不足以证明陌生玩家可独立理解。
- [图形化建造 / 合成 / 背包 UI V1](../features/slice-graphical-crafting-and-inventory-v1.md) 已人工收口。
- [设备操作面板统一 V1](../features/slice-unified-device-operation-panels-v1.md) 建筑包 1 已人工通过；核心仓库包 2 暂停。
- [视觉层级与色彩分离 V1](../features/slice-visual-hierarchy-and-color-separation-v1.md) 已通过架构闸门并成为当前活跃专题。

## 2026-07-29 收尾

- `d6b1f6e3` 完成设备自动补地板、物流端口 / 断链诊断、采集器显式取料和固定数字键制作语义；项目级一次性运行数据迁入 `tools/runtime-intake/`。
- `4e6d2a1d` 收口内部完整全链，`35ba6140` 根据人工判断延期盲测并恢复表现层开发。
- `d3953c6e` 以七张配方卡、九个背包格、鼠标制作 / 选中和权威阻塞状态替换纯文字整备主读法，并经人工通过。
- `6aa5beb2` 统一六类建筑设备面板、结构化物流状态与鼠标操作；人工通过后删除描述式“下一步：……”文案。
- 日终代码—文档审计确认：现行电网仍是二值可达模型，暂无发电容量、设备耗电、中继负荷或储能状态。

## 8 月 3 日收尾

1. **视觉专题包 0 已完成。**四层职责、功能色语义、实现介质、截图矩阵和失败退出已确认；不修改玩法、schema 或像素标准。
2. **统一明度校准已判失败。**自动与正式入口虽通过，但实机仍灰蒙、偏暗；地表与非样板设备已恢复，相关归一函数和数值合同已撤回。
3. **关键设备首轮已判失败。**V1—V3 虽分开纵向核心与横向反应器，整体仍由深色旧家族主导，并因提示禁止平台而缺少自有基座和结构化物流出入口；比例证据保留，视觉方向不保留。
4. **第 3 轮 `3 / 3` 已完成并停手。**V3 的核心竖直轴、反应器高度、浅色机身、深色底座和独立基座获得条件认可；设施滚轮方向互相矛盾，端口细节不通过。8 月 3 日没有客户端代码改动，也不再生成图片。

## 2026-08-04 明日事项

1. **先读真相源再开新轮次。**读取本入口、当前计划、活跃视觉专题、视觉方向框架和 `2026-08-03-batch04/_manifest.md`；关键设备端口细化从独立 `0 / 3` 计数开始，每次只生成一张并先落盘审阅。
2. **只改端口，不重做已认可结构。**保留 V3 的竖直核心、高体量反应器、浅色主体、深色底座、角色比例和固定投影；删除设施自带滚轮，改为中性深色停靠口与明确方向箭头。
3. **固定正面与可见侧接口。**核心和反应器正面始终朝向玩家，端口只围绕左、右、前三个可见边组织，同一边可有多个真实端口；核心必须有仓储输入 / 输出，反应器必须有加工输入 / 输出。
4. **不提前接入。**当前核心只有手动仓库存取，`building_rotation` 仍控制贴图、端口、供电、调整和存档。小样通过前不改客户端、schema、现行四向端口或全链；正式迁移另建功能边界。

## 防跑偏规则

- 玩家可见开发先有 `docs/features/` 专题和决策闸门，再进入代码、素材和场景接入。
- 视觉问题按玩家结果、场景组织、系统连接、资产家族、UI 结构、色彩数值、装饰依次归因；不能从透明度、边框或单一换色开始。
- 电力专题会影响电网、建筑定义、面板和存档；当前二值结果必须保持兼容，迁移策略未确认前不扩 schema。
- 玩家可见结果以正式 `Boot` 实机截图和人工路径为主证据，自动检查只兜底。

## 当前不做

- 陌生玩家盲测、多人试玩、试玩分发、打包或发布。
- 敌潮、复杂 Boss、技能树、联机、新敌人、新配方、新建筑或新地图。
- 立绘对话、八方向动画、viewport 重构、旧地图 / 旧 `GameRoot` / 旧三槽存档复活和无关重构。

## 明日必读

- [Current Plan](current.md)
- [视觉层级与色彩分离 V1](../features/slice-visual-hierarchy-and-color-separation-v1.md)
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
