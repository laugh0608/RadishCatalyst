# Demo Field Task Differentiation V1

更新时间：2026-06-19

## 用途

本文定义资源处理与外勤任务差异第一包。它承接 `Demo Playable Content Substance V1`，把“资源链能读懂”推进到“玩家能从采集对象、设备面板、加工结果、HUD 和出发整备台判断这趟外勤材料会推动哪段任务”。

本专题覆盖 `Demo Definition V1` 的资源 / 生产链、工业基建模块、UI / HUD、任务节奏、污染与防护和存档 / 状态规格。

## 玩家价值

- 玩家采集晶体时，能知道它回基础反应器后转成基础零件，并分流到过滤模块、工具校准或核心缓冲包。
- 玩家采集污染沉积时，能知道它会带来现场承压，但回过滤器后拆成抗污染药剂和污染浆液两类收益。
- 玩家准备核心站时，能知道修复凝胶、药剂、污染浆液和基础零件如何汇入核心稳压缓冲包。
- 玩家回到出发整备台时，能把至少两类外勤处理结果登记成下一趟任务差异，而不是只看库存数字。

## 与整体规划的关系

- 承接 `Demo Resource Chain State V1`：资源链状态已可读，本包补真实操作结果与整备登记。
- 承接 `Demo Industrial Module Task Rhythm V1`：5 个核心模块已有职责，本包把资源处理结果接到任务差异。
- 承接 `Demo Initial Art Identity V1`：现场对象已有身份，本包补对象操作后的任务去向。
- 不切换到试玩准备，不替代后续实机体验判断。

## 当前已有基础

- `GatherSystem` 会写对象采集 / 采样状态并发放物品或流体。
- `ProcessingSystem` 会消费输入、启动设备加工、完成后发放产物和副产。
- `FieldOutfittingRuntime` 已把出发整备台作为防护、工具和外勤收益确认入口。
- HUD、设备面板、交互提示和结果日志已有窄职责 presenter / formatter。

## 本轮范围

- 新增 `DemoFieldTaskDifferentiationFormatter`，统一晶体、污染和核心准备三类外勤任务差异。
- 采集 / 采样成功反馈接入 `field_task`，对象提示显示材料回哪个设备处理。
- 设备面板、处理提示、处理日志和处理完成反馈显示当前配方对应的任务差异。
- 前哨 HUD 显示可登记或已登记的任务差异路线。
- 出发整备台写入 `field_task_differentiation_confirmed`，表示至少两类外勤处理结果已登记。
- 新增 `demo_field_task_differentiation_check.gd` 和静态检查接线。

## 当前不做

- 不新增资源、配方、设备、区域、敌人、任务链、完整背包或完整装备栏。
- 不做第二星球、第二章节、支线任务网、死亡系统、结算页或发布流程。
- 不把任务差异做成纯日志长文案；必须接入 HUD、设备面板、对象提示和整备台状态。
- 不修改存档 schema；整备登记复用既有地图对象状态序列化。

## 玩家操作路径

```text
采集晶体 / 污染沉积 -> 回基地按资源类型处理 -> 设备产出进入补给 / 整备 / 核心准备 -> 出发整备台登记任务差异 -> 下一趟外勤按 HUD 和设备面板判断路线
```

## 运行时、存档与数据边界

- 真相源复用 `CharacterState.inventory`、`WorldState.map_objects`、`WorldState.base_structures` 和 `quest_state`。
- `field_task_differentiation_confirmed` 只写在 `map_object_instance.field_outfitting_station`。
- 不迁移旧 ID，不新增长期存档字段，不引入完整任务网。
- 检查覆盖状态 round-trip，确认整备台登记可以保存和读取。

## HUD / 场景 / 对象反馈

- HUD：在前哨显示晶体、污染和核心准备三类路线是否已可登记或已登记。
- 对象提示：晶体、污染沉积和核心稳定设备说明当前材料的任务去向。
- 设备面板：基础反应器和污染过滤器显示当前配方对应的任务差异。
- 结果反馈：采集、采样、处理完成和整备台确认都写入结构化 `field_task`。

## 验收条件

- 晶体、污染和核心准备三类任务差异有统一 formatter 口径。
- 采集对象、设备面板、处理结果、HUD 和出发整备台至少各有一处读取任务差异。
- 出发整备台登记写入状态，并能通过 `WorldState` round-trip 保持。
- 未新增规格外资源、配方、区域、任务链、完整背包或完整装备栏。

## 验证计划

- `sh ./scripts/check-client.sh`
- 涉及 Godot runtime 路径时执行 `sh ./scripts/check-client.sh --with-godot`
- `./scripts/check-docs.sh`
- `./scripts/check-text-files.sh`
- `git diff --check`

## 风险与后续决策

- 风险：任务差异退化成又一层说明文字；本包必须保持与采集、加工、HUD、设备面板和整备台状态绑定。
- 风险：整备台确认入口过多；本包只在至少两类外勤处理结果可读时开放登记。
- 后续若仍读不出任务变化，应优先补现场对象尺寸、设备状态或真实操作顺序，不继续加同类提示。
