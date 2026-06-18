# Demo Quick Slot Supply Readability V1

更新时间：2026-06-18

## 用途

本文定义首版 Demo 快捷补给读法第一版。它不新增消耗品、背包、装备栏或 UI 面板，只让现有 `1/2` 快捷栏在 HUD 与补给反馈里直接读出修复凝胶、抗污染药剂当前是可用、暂存还是缺补给，并指向对应回补设备。

## 玩家价值

玩家进入污染、战斗或终点承压前，不应只看到补给数量。快捷栏应回答：

1. 哪个键能处理当前生命 / 防护压力。
2. 补给已经满状态暂存，还是现在可用。
3. 缺补给时应回基础反应器还是污染过滤器。

## 与整体规划的关系

本专题覆盖 [Demo Definition V1](demo-definition-v1.md) 的「装备 / 模块」中 2 个消耗品读法，以及「UI / HUD」中关键操作面读懂承压差异和缺口的规格。

它承接已完成的防护响应、战斗撤离恢复、动作受阻恢复和原型视觉呈现；本轮不再加厚目标箭头、地图提示、对象提示或失败文案，只处理快捷补给这一条未独立收束的玩家可见切面。

## 阶段入口判断

`Demo Prototype Visual Pass V1` 已通过阶段退出判断：场景视觉、HUD / 地图、对象状态和 `demo_prototype_visual_pass_check.gd` 均满足当前阶段验收。下一步不继续堆视觉 cue、目标导引或 HUD 目标文本，切到快捷补给读法。

## 当前已有基础

- `CharacterState.quick_slots` 已默认绑定修复凝胶和抗污染药剂。
- `CharacterState.use_quick_slot` 已处理成功、满状态、缺补给和失败恢复反馈。
- HUD 角色状态已有快捷栏数量行，补给使用已有临时反馈面板和日志。
- 补给来源已稳定：修复凝胶来自基础反应器，抗污染药剂来自污染过滤器。

## 本轮范围

- 新增 `DemoQuickSlotSupplyReadabilityFormatter`，集中生成快捷栏短状态。
- HUD 快捷栏从纯数量改为 `数量/状态`：满、可用、生命低可用、防护低可用、缺:反应器、缺:过滤器。
- 新增 `demo_quick_slot_supply_readability_check.gd`，覆盖默认缺药剂、承压可用、使用后缺补给和失败恢复路线。
- 接入默认静态检查和 Godot runtime 检查。

## 当前不做

- 不新增资源、配方、区域、任务链、完整背包或完整装备栏。
- 不新增 UI 面板、快捷栏拖拽、消耗品轮盘、冷却系统或随机词条。
- 不继续加厚原型视觉 cue、首小时目标箭头、对象提示、失败文案或动作成功结果。

## 玩家操作路径

1. 新档启动时，HUD 显示修复凝胶已满状态暂存，抗污染药剂缺口指向污染过滤器。
2. 玩家受伤或防护偏低时，HUD 快捷栏显示对应补给可用。
3. 玩家按 `1` 使用修复凝胶后，反馈面板显示剩余数量，HUD 显示缺口回到基础反应器。
4. 玩家按 `2` 但缺抗污染药剂时，失败反馈和日志继续指向污染过滤器。

## 运行时、存档与数据边界

- 不新增存档 schema；继续读取 `CharacterState.quick_slots`、`CharacterState.inventory`、生命 / 防护和当前区域。
- 不新增消耗品定义；只读取现有 `item.repair_gel` 与 `item.resistance_vial_t1`。
- 快捷栏绑定仍由既有状态保存读取负责。

## HUD / 场景 / 对象反馈

- HUD：角色状态快捷栏行必须显示数量和短状态，不挤占当前目标链。
- 补给反馈：使用成功显示恢复量、当前值和剩余数量。
- 失败反馈：缺补给时必须保留恢复路线，不吞掉真实缺口。
- 场景与对象：本轮不新增场景 cue 或对象状态。

## 第一包完成状态

- 2026-06-18 已新增 `DemoQuickSlotSupplyReadabilityFormatter`，HUD 快捷栏接入可用 / 暂存 / 缺补给短状态。
- `demo_quick_slot_supply_readability_check.gd` 已覆盖默认、承压、使用后和缺补给路径。
- 默认 `check-client` 与 Godot runtime 检查入口已接入本专题。

## 验收条件

- 快捷栏能读出两类补给当前数量、是否可用和缺口回补设备。
- 补给成功 / 失败反馈与 HUD 快捷栏状态一致。
- 未引入当前不做事项，新增检查走独立专项文件。

## 验证计划

- `sh ./scripts/check-client.sh`
- 如涉及 Godot 运行时检查，执行 `sh ./scripts/check-client.sh --with-godot`
- `sh ./scripts/check-docs.sh`
- `sh ./scripts/check-text-files.sh`
- `git diff --check`

## 风险与后续决策

- 若后续仍读不懂补给收益，应优先检查消耗品获得节奏和承压数值，不继续拉长 HUD 文案。
- 若扩到第三个消耗品或快捷栏重绑，先建立新的装备 / 补给专题边界。
