# Factory Discovery Save V2

更新时间：2026-09-25

## D2-A 合同与版本边界

本合同具体化已授权的发现 / 电力 / 统计联合 schema 2；D2-A 仅运行普通晶体配方与封闭矿区，D2-B 接多配方和开拓。基础工厂 schema 1 仍由原严格校验器处理，旧二维 schema 10 不变、不迁移。

身份组合固定为 `factory_3d / 2 / factory_discovery_v1 / factory_discovery_yard_64_v1 / factory_discovery_starter_v1`。世界 ID、名称、sequence、锁、候选恢复和原子发布沿[现行合同](factory-world-state-and-save-v1.md)。未知 schema、混配规则 / 地图 / 供给以及当前尚不能运行的发现内容必须阻断所有备份回退；损坏字段可按原合同寻找有效备份。D2-A 不把后续内容静默清零。

## 权威字段

| 位置 | 字段与约束 |
| --- | --- |
| state 基础 | `time/remainder/next_id/next_batch/generated/completed/delivered/delivered_batch/kits/bag/actor/entities` 沿基础数量、身份和空间检查；kits 加 `power_source=2`、`power_junction=12` 总预算 |
| 物品映射 | bag、仓储、采集缓冲、反应输入 / 输出 / 在制投入均以物品 ID 到非负整数的稀疏映射编码；零项省略；已知物品为 crystal、catalyst、crust_sample、crust_solvent、rich_crystal |
| 采集器 | `mineral/buffer/progress/power_node_id`；D2-A mineral 为 crystal；周期 1 秒，缓冲 50 |
| 反应器 | `recipe_id/input/output/invested/processing/progress/active_batch/output_batch/power_node_id`；D2-A recipe_id 为 basic_catalyst，在制投入严格为 2 crystal 或空；周期 10 秒，输入一批、输出一件 |
| 电力实体 | 共用 id/type/x/z/dir；仅 power_source 有 `enabled: bool`，不存额定容量 |
| state.power_links | 规范化 `[小ID,大ID]` 排序数组；最多 91 条，拒绝重复、自环、缺引用、超距、穿封闭格；每台用电设备仅一个 power_node_id，0 表示未接线 |
| state.discovery | `surveyed/sample_taken/trial_completed/passages`；passages 为 `outer/inner` 布尔映射。D2-A 全 false；非初始状态按尚未支持内容阻断。D2-B 实现唯一拾取、样本持有 / 消耗、开路前置和耗材守恒后才接受 |
| state.statistics | `ticks/totals/buckets/current`；ticks 为已推进 20Hz 步数，time 与 ticks×0.05 差不超过 1e-6 秒；totals 为累计记账，buckets 最近至多 600 个完整秒，current 为 0–19 步未完成桶 |
| 记账记录 | `produced/consumed/acquired/delivered` 为已知物品计数映射；`installed_kj/available_kj/requested_kj/supplied_kj/used_kj/deficit_kj` 为有限非负数；桶另有 `start_tick/ticks` |
| state.statistics_ui | `window_seconds/favorites`；窗口仅 60/300/600，收藏仅已掌握物品且不重复；D3 再接页面 |

全字段严格校验，JSON 数量不接受分数、布尔冒充数字或非有限数。实体上限 302，稳定序号上限 2^53−1，活动积压上限 3600 秒。图、网络编号、满足率、当前分配、库存分解及理论速率为派生数据，不保存。

## 记账与数值边界

本步先计算生产条件和剩余工作量，按连通分量分配容量，再开批、推进、提交物料事件，最后搬运。物料消耗在完成时计入；在制原投入仍属持有量，取消 / 拆回只搬运，不退电。电力、物流与统计共用 20Hz；满缓冲 / 缺料不耗电，末步不足 50ms 按真实工作量收费。

用电 kJ = 额定 kW × 本步实际加工秒。供电等于用电，源按容量比例分担；缺口为各网及未接线设备之和。能量比较采用 `1e-7 + 1e-10 × max(|a|,|b|)` kJ 容差，物料始终精确整数。累计产消与当前全世界持有量、基础计数互核；近期桶合计不得超过累计值，未截断历史必须等于累计值。

桶为 `(k,k+1]`；结束于整秒的步及其产物归刚结束桶，边界命令修改刚结束桶。空转有真实零，暂停 / 失焦无步进；恢复不补离线时间。完整桶按连续 start_tick 与 ticks=20 校验，当前桶起点、步数与时钟一致；存读重建电图不产生事件。窗口速率只使用完整桶与真实覆盖时长，未满一秒返回暂无样本。

## 验证落点

D2-A 定向夹具覆盖连接失败零变更、循环 / 并网 / 分网、多源分摊、缺电公平性、末步能量、断电不开批、半批恢复、被动物流、取消不退电、600 桶裁剪、非法字段及版本保护。正式 Boot 使用双隔离根验证新世界普通线、停复电及保存重进，合成输入与用户亲测分列；完整统计页和发现玩家路径仍属 D3。

实现入口：`discovery_rules.gd`、`discovery_model.gd`、`power_grid.gd`、`statistics.gd`、`save/codec_v2.gd` 与 `save/statistics_validator.gd`。D2-A 运行时普通线沿用窄数量字段，codec 显式编码物品映射与原投入，未把未来配方默认为基础配方。
