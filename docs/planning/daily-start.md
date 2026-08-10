# Daily Start

更新时间：2026-08-10

## 用途

当提示是“根据项目规划和开发进度，今天要来做什么以推进开发”时，优先阅读本文。阶段方向与边界以 [Current Plan](current.md) 为准，详细历史留在 W32 / W33 周志和功能专题。

## 当前阶段

阶段：第一可玩切片玩家可见完成度补强。

- 真实新档自动、正式入口和萝卜SAMA人工完整全链均已通过，最终状态为 `delivered / 120`。
- 陌生玩家盲测已冻结：当前功能可运行，但视觉和交互仍不足以证明陌生玩家可独立理解。
- [图形化建造 / 合成 / 背包 UI V1](../features/slice-graphical-crafting-and-inventory-v1.md) 已人工收口。
- [设备操作面板统一 V1](../features/slice-unified-device-operation-panels-v1.md) 建筑包 1 已人工通过；核心仓库包 2 暂停。
- [视觉层级与色彩分离 V1](../features/slice-visual-hierarchy-and-color-separation-v1.md) 已通过架构闸门并成为当前活跃专题。
- [游戏本体 UI 视觉定稿 V1](../features/slice-game-ui-visual-finalization-v1.md) 已完成 P0、P1 与 P2-A；HUD 客户端、正式 `Boot` 和三种色彩模式逐图复核均已通过萝卜SAMA判断。P2-B 尚未开始。
- [分类库存与通电储物箱 V1](../features/slice-category-inventory-and-powered-storage-v1.md) 与 [世界设备家族接入 V1](../features/slice-world-device-family-integration-v1.md) 的联合包 2 / 3 已提交，包 3 / 4 / 5 均获人工通过；包 5 的自动、正式入口和 AI 逐图复核证据已完整保留。

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

## 8 月 5 日至 10 日进展与下一步

1. **生成路线已按 `3 / 3` 停止。**batch06 / batch07 锁定开放核心与横向反应器身份，batch08 V3 只证明高机位和世界尺度；没有一张生成稿同时通过身份、投影与四口。
2. **已获批准换介质。**萝卜SAMA确认改用 `1:1` 原生网格确定性重投影；batch09 不调用图像生成，不接客户端或 Godot。
3. **设备主体已形成原生候选。**核心 / 反应器锁定主体分别为 `144×128px`、`176×88px`；Alpha 严格二值、颜色收敛到 17 / 18 色子集，并已与现行工程师和岩地在 960×540 中复核。
4. **核心端口已锁定，反应器局部补丁已停止。**V5 核心人工反馈自然；V6—V8 仍有“断崖”感。V9 整体低平台解决连通，但两侧高 U 形端框继续被判不好看，不能把机械成立当成视觉通过。
5. **Gate A 已通过。**世界目标 V5 已用核心 V5、反应器 V10、采集器 V1、储物箱 V1 和中继 V2 按 `1:1` 重组；四个中继端子分别以 `1px` 单段示意线连接设备顶部锚点，储物箱线终止于浅色顶部面中央 `(52, 18)`。机械、AI 与萝卜SAMA人工复核均通过，正式目标稿为 `assets/reference/visual-direction/target-world-v01.png`。
6. **Gate B 与 UI 结构实现均已人工通过。**制造态与反应器态已按 [UI 结构实现 V1](../features/slice-visual-hierarchy-ui-implementation-v1.md) 收为同源右侧舷窗，完整 Godot 回归、正式 `Boot` 41 项专项及制造阻塞 / 成功、储物箱断链、反应器加工四态全部通过。
7. **世界设备接入审计已完成。**[世界设备家族接入 V1](../features/slice-world-device-family-integration-v1.md) 已确认 `building_rotation` 解耦、固定正面、显式端口、核心 / 采集器物流和旧档可恢复边界。
8. **联合包 1 等价地基已完成。**现行九类物品已统一定义，legacy profile 保持 `30 / 120 / 20 / 2 / 1`，库存调用迁到逐物品 / 原子 / 部分转移 API；方向、视觉、端点、逻辑供电探针和画线锚点已显式解耦，物流网改用统一运行时端点。
9. **联合包 2 / 3 已提交，包 3 / 4 均已人工通过。**包 4 已把真实父边输出到中继四端子、核心和三类消费者顶部锚点，每边只画 `1px` 单段直线；供电专项 `139` 项与正式 `Boot` `64` 项通过。
10. **包 5 综合闸门已通过。**正式 `Boot` 以 `138` 项断言覆盖真实新档和 schema 7 隔离旧档；两套主档、各三备份及 11 张截图已保留。逐图发现并修复放置态 `OUT` 文本裁切后，完整 Godot 与正式演练重跑通过，萝卜SAMA于 2026-08-09 确认收口。
11. **UI 定稿 P2-A 已通过。**基地边缘 HUD 与晶体区受击 / 闪避变体共用深钢壳层、钢蓝 `A1` 和局部红色；完整 Godot、正式 `Boot` `40` 项断言及九张色彩复核图完成后获萝卜SAMA人工通过。
12. **远程攻击获得后续方向授权。**枪械不重开现行近战 V1，也不插入当前 UI P1；视觉专题关闭后先建立独立功能专题，明确工业供弹、输入、HUD、数值和存档边界再决定实现包。

## 2026-08-10 今日事项

1. 晶体区战斗态目标稿已获批准：受击 / 闪避、敌我生命、任务、资源和世界焦点同屏成立，三种色彩模式与窄屏复核通过。
2. 首次充能居中确认已获批准；现状、彩色、低饱和、灰阶、`960×540` 和 `360px` 窄屏复核均通过，P1 关闭。
3. P2-A HUD 已获人工通过并收口；下一分面是 P2-B 制造 / 背包，但本日不再启动实现。
4. UI P1 关闭后，为远程攻击 / 枪械建立独立可执行专题；优先证明它如何由基地制造与补给支撑，并保留切割器作为无弹药基础能力，避免直接扩成武器树或掉落表。

## 2026-08-11 明日事项

1. 只启动 P2-B 制造 / 背包：先复读已批准目标稿、[UI 结构实现 V1](../features/slice-visual-hierarchy-ui-implementation-v1.md) 与现行 `SliceCraftPanel`，复核七个对象、材料阻塞、鼠标 / 数字键路径和分类背包真相源后再改客户端。
2. 本包只接配方网格、材料校验、结果确认与物品格视觉；不并行修改设备、核心、系统界面，不提前建立枪械专题或运行 Godot。
3. 候选完成后按矩阵执行默认检查、完整 Godot、正式 `Boot` 阻塞 / 成功 / 背包三态及同帧低饱和 / 灰阶复核，取得萝卜SAMA人工判断后再提交为通过。

## 防跑偏规则

- 玩家可见开发先有 `docs/features/` 专题和决策闸门，再进入代码、素材和场景接入。
- 视觉问题按玩家结果、场景组织、系统连接、资产家族、UI 结构、色彩数值、装饰依次归因；游戏本体不再参考 Radish 家族 UI，不能从透明度、边框、全局换色或增加装饰开始。
- 储物箱已成为二值电网消费者，但不引入发电容量、负荷或储能；schema 8 已随分类库存、双模式、固定端口和旧档迁移一次切换，后续不得拆分回滚或追加无关字段。
- 玩家可见结果以正式 `Boot` 实机截图和人工路径为主证据，自动检查只兜底。

## 当前不做

- 陌生玩家盲测、多人试玩、试玩分发、打包或发布。
- 敌潮、复杂 Boss、技能树、联机、新敌人、新配方、新建筑或新地图。
- 立绘对话、八方向动画、viewport 重构、旧地图 / 旧 `GameRoot` / 旧三槽存档复活和无关重构。

## 继续前必读

- [Current Plan](current.md)
- [视觉层级与色彩分离 V1](../features/slice-visual-hierarchy-and-color-separation-v1.md)
- [游戏本体 UI 视觉定稿 V1](../features/slice-game-ui-visual-finalization-v1.md)
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
