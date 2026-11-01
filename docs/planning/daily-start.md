# Daily Start

更新时间：2026-11-01

## 启动读取

先检查 `dev` 工作区并遵循 `AGENTS.md`，再读 [Current Plan](current.md)、[整合基线](demo-consolidation-proposal.md)、[整合总合同](../features/factory-demo-integration-v1.md)和[本周周志](../devlogs/2026-W44.md)。按任务展开核心、科技树、能源与存档子合同；坐标 / 参数使用[布局与预算](../reference/factory-integrated-demo-layout-and-budget.md)。

## 当前交接

- 萝卜SAMA已确认从分包内容验证进入统一 Demo 与第一轮成长的设计整合：先同步正式文档，再细化实施合同。**暂不修改客户端代码**，不把方向确认当成运行通过。
- 核心每物品 99,999、等级解锁能力；初始电力按设备预算确定，固定燃烧与后续可选 PWM；Godot 3D / GDScript、生产经营主线与工业科幻方向已确认。
- 主视角进一步明确待定：按用户两张截图参考确认现场取景，不把当前正交 / 50° 当最终参数；待办与来源见[视觉方向](../product/visual-and-ui-direction.md)。当前仍只改设计，不启动客户端样板。
- E1 / E2 / V8 及原 D3 / D4 工程能力继续复用；客户端当前仍按旧合同运行，旧档和亲测进度保留。E3 支路未实现，开路后持续收益纳入统一路线设计。

<a id="next-day-tasks"></a>

## 当前接续事项

资产盘点首轮已完成，先读[清单与替换计划](../reference/asset-inventory-and-transition-v1.md)及[制作来源 / 导出映射](../reference/asset-source-and-export-map.md)。下一项是镜头 / 代表场景样板的设计范围与资产选择；当前仍未授权客户端实施或旧资产迁删，不能批量重跑历史归一 / 导出工具。

1. 真相源同步及四类合同首轮已完成；依[总合同](../features/factory-demo-integration-v1.md)审阅核心足印 / 端口 / 库存和研究 / 升级事务。S0 / S1 离线几何已通过，继续核对能源 / 构件并行布局与供给成本，不重复宣称自然路径通过。
2. 复核完整电池链 + 其他生产的峰值 / 平均 / 待机、首颗与恢复路径；明确固定燃烧的实际释能 / 弃能，避免沿用 V8 供用相等的全部前提。
3. 复核新世界身份、严格字段、研究 / 升级消费账与固定燃烧余时；后续储能 / 控制单独版本化，不静默改变已经发布的规则。
4. 本轮只交付设计合同、离线核算与待验清单；审阅完成并获代码授权后才进入客户端实施。后续正式 Boot、窗口、原生输入、跨进程存读及目标平台按风险补证。
5. 旧 V8 亲测仍可显式运行 `tools/runtime-intake/review-worlds/factory-energy-v8-playtest/start.sh practice / c / d`，默认会话 `playtest-20261101-a`；先练习再看收益。它验证旧 V8，不能拿来验证新核心 / 固定燃烧。失焦仍生产，离开前暂停，不自动重开用户关闭的窗口。

## 边界与验证

- 当前为设计整合，不安装依赖、不导入资产包、不修改活动世界，不打包 / 推送 / 发布。
- 旧二维与工厂不同 schema / 身份分别保留；不为了统一界面整仓迁入旧代码，不默认提供跨规则转换。
- 新内容布局核算只是纸面证据，不能写成自然主循环、人工可玩性或性能通过。用户亲测、Windows / PowerShell、目标硬件与旧 D4 保留项继续区分。
- 文档执行 `./scripts/check-docs.sh`、`./scripts/check-repo.sh` 和 `git diff --check`；本轮无客户端改动，不重复旧 Godot 全套或长测。
- Godot / 桌面程序启动前告知；本轮设计无需启动 Godot。

## 按任务继续阅读

- 核心：[Base Core](../features/factory-base-core-v1.md)。
- 科技树：[Research And Progression](../features/factory-research-and-progression-v1.md)。
- 能源：[Fixed Burn Energy](../features/factory-fixed-burn-energy-v1.md)。
- 存档：[Integrated Demo Save](../architecture/factory-integrated-demo-save-v1.md)。
- 现行配方 / 旧证据：[生产内容扩展](../features/factory-production-expansion-v1.md)、[V8](../architecture/factory-energy-save-v8.md)、[D4](factory-d3-exit-and-d4-validation.md)。
