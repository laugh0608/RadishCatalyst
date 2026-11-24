# DSP Online Production Study

调研日期为 2026-11-24。DSP 极简网络（DSPO）是以《戴森球计划》生产流程为题材的 2D 无限画布工厂游戏。本次关注产线诊断、设备定位与工艺规划。网页版为 `1.3.16`，源码按发布记录固定到 `baff97282123`。[在线试玩](https://dsponline.cn/) · [发布记录](https://github.com/snowsnow0926/DSPONLINE/blob/baff972821237835381c8f7ea40960ad8138f477/docs/releases/1.3.16.md)

## 网页操作观察

在未登录的临时新档放置一台默认生产铁块的电弧熔炉，保持输入端口空置。画布显示「缺少铁矿石」和 `0.0/min`。打开「生产统计 → 管理」，同一台炉的异常行显示「未连接输入线路」，并提供物料路径和定位入口。点击「定位电弧熔炉」后，统计关闭，画布聚焦到炉子并显示其检查器。[在线试玩](https://dsponline.cn/)

从源码可见，生产管理数据由当前工厂状态派生，按物料和真实线路追踪供给与接收设备。生产定位模块同样从当前状态计算可供高亮的实体及线路。架构文档还记录了按目标产能反推需求的规划模块。[生产管理](https://github.com/snowsnow0926/DSPONLINE/blob/baff972821237835381c8f7ea40960ad8138f477/src/game/productionManagement.ts) · [产线定位](https://github.com/snowsnow0926/DSPONLINE/blob/baff972821237835381c8f7ea40960ad8138f477/src/game/productionLocator.ts) · [系统架构](https://github.com/snowsnow0926/DSPONLINE/blob/baff972821237835381c8f7ea40960ad8138f477/docs/ARCHITECTURE.md)

<a id="diagnostics"></a>

## 对异星催化的诊断启发

- 从可见问题走到现场处理。目标栏提示缺的是什么或哪里受阻，并提供定位。设备面板核对当前原因，生产统计用恢复后的实际产出提供反馈。沿用角色在现场走近并操作的规则。[生产统计](../features/factory-production-statistics-v1.md#界面与玩家路径)
- 保留历史成果的同时，让当前故障在目标栏可见。优先从已扩建的 D1 成品档复测晶体断供，保留既有烧结批次和载体回仓线。代码已计算炉子的当前反馈，结果分支仍可能只展示累计批次和核心载体。以正式 Boot 窗口确定表现，再决定局部修正。[目标栏实现](../../client/scripts/factory/discovery_guidance.gd#L145-L156) · [D1 诊断复测](../features/factory-research-and-progression-v1.md#d1-production-diagnostics)
- 如果现场仍难找到故障源，再评估高亮已连接的上游供料或下游回仓段。定位依据为实际物料、端口和可达线路。配方能生产某种物料，只能证明工艺关系。[产线定位实现](https://github.com/snowsnow0926/DSPONLINE/blob/baff972821237835381c8f7ea40960ad8138f477/src/game/productionLocator.ts)

<a id="official-tools"></a>

## 对官方工具的启发

工艺链规划器可沿「目标速率 → 配方 → 设备、原料及副产物」展开。这适合静态 Web。用本项目现行配方说明板材与矿渣联产、矿渣回用和多孔载体产量，帮助玩家在搭线前估算供料与去向。游戏内仍由当前设备、线路、缓冲和电网证明实际产出。工具排期见[官方工具策略](../../official-tools/docs/tooling-strategy.md#process-chain-planner)。

正式客户端按现行 Godot 3D 基线推进，借鉴时使用自有规则和实现。DSPO 的原创代码、文档和资产按 PolyForm Noncommercial 1.0.0 提供，商业使用须单独取得书面授权。[当前规划](../planning/current.md) · [DSPO 商业使用说明](https://github.com/snowsnow0926/DSPONLINE/blob/baff972821237835381c8f7ea40960ad8138f477/COMMERCIAL_USE.md)
