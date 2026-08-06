# Daily Start

更新时间：2026-08-06

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

## 8 月 5 日进展与停点

1. **生成路线已按 `3 / 3` 停止。**batch06 / batch07 锁定开放核心与横向反应器身份，batch08 V3 只证明高机位和世界尺度；没有一张生成稿同时通过身份、投影与四口。
2. **已获批准换介质。**萝卜SAMA确认改用 `1:1` 原生网格确定性重投影；batch09 不调用图像生成，不接客户端或 Godot。
3. **设备主体已形成原生候选。**核心 / 反应器锁定主体分别为 `144×128px`、`176×88px`；Alpha 严格二值、颜色收敛到 17 / 18 色子集，并已与现行工程师和岩地在 960×540 中复核。
4. **核心端口已锁定，反应器局部补丁已停止。**V5 核心人工反馈自然；V6—V8 仍有“断崖”感。V9 整体低平台解决连通，但两侧高 U 形端框继续被判不好看，不能把机械成立当成视觉通过。
5. **当前停点。**世界目标 V4 因辅助设备断代和折线电网被退回；核心 V5 / 反应器 V10 继续锁定，采集器 `96×112px`、储物箱 `104×80px` 暂时通过，中继 `48×76px` V2 已通过机械、AI 与萝卜SAMA人工复核。下一执行包以这组候选和中继—设备单段直线电网重组 Gate A；当前尚未接入客户端或启动 Godot。

## 防跑偏规则

- 玩家可见开发先有 `docs/features/` 专题和决策闸门，再进入代码、素材和场景接入。
- 视觉问题按玩家结果、场景组织、系统连接、资产家族、UI 结构、色彩数值、装饰依次归因；不能从透明度、边框或单一换色开始。
- 电力专题会影响电网、建筑定义、面板和存档；当前二值结果必须保持兼容，迁移策略未确认前不扩 schema。
- 玩家可见结果以正式 `Boot` 实机截图和人工路径为主证据，自动检查只兜底。

## 当前不做

- 陌生玩家盲测、多人试玩、试玩分发、打包或发布。
- 敌潮、复杂 Boss、技能树、联机、新敌人、新配方、新建筑或新地图。
- 立绘对话、八方向动画、viewport 重构、旧地图 / 旧 `GameRoot` / 旧三槽存档复活和无关重构。

## 继续前必读

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
