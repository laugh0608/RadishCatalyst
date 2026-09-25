# Factory Discovery Save V2

更新时间：2026-09-25

## 联合合同与版本边界

本合同具体化已授权的发现 / 电力 / 统计联合 schema 2；D2-A 最初只运行普通晶体配方与封闭矿区；当前 D2-B 已沿同一形状接入多配方和开拓，不迁移现有 schema 2 普通状态。基础工厂 schema 1 仍由原严格校验器处理，旧二维 schema 10 不变、不迁移。

身份组合固定为 `factory_3d / 2 / factory_discovery_v1 / factory_discovery_yard_64_v1 / factory_discovery_starter_v1`。世界 ID、名称、sequence、锁、候选恢复和原子发布沿[现行合同](factory-world-state-and-save-v1.md)。未知 schema、混配规则 / 地图 / 供给以及未知配方内容必须阻断所有备份回退；损坏字段可按原合同寻找有效备份。旧 D2-A 读写器遇非初始发现内容仍会明确阻断，不能回退覆盖。

## 权威字段

| 位置 | 字段与约束 |
| --- | --- |
| state 基础 | `time/remainder/next_id/next_batch/generated/completed/delivered/delivered_batch/kits/bag/actor/entities` 沿基础数量、身份和空间检查；kits 加 `power_source=2`、`power_junction=12` 总预算 |
| 物品映射 | bag、仓储、采集缓冲、反应输入 / 输出 / 在制投入均以物品 ID 到非负整数的稀疏映射编码；零项省略；已知物品为 crystal、catalyst、crust_sample、crust_solvent、rich_crystal |
| 采集器 | `mineral/buffer/progress/power_node_id`；mineral 由固定矿点决定为 crystal / rich_crystal；周期 1 秒，缓冲 50 |
| 反应器 | `recipe_id/input/output/invested/processing/progress/active_batch/output_batch/power_node_id`；recipe_id 取专题四配方；输入最多一批、输出最多一批（1 / 3 件），在制投入严格等于该配方完整输入或空，进度严格小于该配方周期 |
| 电力实体 | 共用 id/type/x/z/dir；仅 power_source 有 `enabled: bool`，不存额定容量 |
| state.power_links | 规范化 `[小ID,大ID]` 排序数组；最多 91 条，拒绝重复、自环、缺引用、超距、穿封闭格；每台用电设备仅一个 power_node_id，0 表示未接线 |
| state.discovery | `surveyed/sample_taken/trial_completed/passages`；passages 为 `outer/inner` 布尔映射。sample_taken 必须 surveyed，trial_completed 必须 sample_taken，outer 必须试制完成，inner 必须 outer；样本全世界持有量加研究消耗严格等于取得次数（0 / 1） |
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

实现入口：`discovery_rules.gd`、`discovery_model.gd`、`power_grid.gd`、`statistics.gd`、`save/codec_v2.gd` 与 `save/statistics_validator.gd`。D2-B 运行时和 codec 共用物品映射，未知配方拒绝且阻断备份回退；原 schema 1 codec 不变。

## D2-B 多物料与命令边界

- 四配方严格沿发现专题：基础 2 晶体 → 1 催化剂（10s / 40kW）；试制 1 样本 + 2 催化剂 → 1 制剂（10s / 40kW）；常规 2 催化剂 → 1 制剂（8s / 60kW）；富集 1 富集晶体 → 3 催化剂（12s / 80kW）。试制仅能完成一次，完成时解锁后两配方。
- `generated` 为累计两类原矿件数之和；`completed` 为累计完成批数，包含三种生产及一次试制；`delivered` 仍是物流催化剂入仓件数。累计各物品件数以 statistics 为权威，不再假定完成批数等于催化剂件数。
- 以 consumed.crystal / 2 推导基础批数，以 consumed.rich_crystal 推导富集批数，以 produced.crust_solvent 推导制剂批数；三者之和等于 completed。催化剂产量等于基础批数 + 3×富集批数，催化剂消耗等于 2×制剂批数。开路制剂消耗严格等于已开矿道的 4 / 8 之和。每物品 `produced − consumed + acquired = held`，held 含在制原投入；另核晶体等价值守恒。
- 在制批次唯一，不能同时出现在输出或在途。同一产物批次可以分布在输出和多条带；普通 / 制剂上限 1，富集催化剂上限 3。已全部进入背包 / 仓储的历史批次不保留无限日志；批次数量、产物统计与持有量共同校验。D2-A 空输出留下的旧 output_batch 继续接受，非空输出必须有合法批次。
- 取放、配方切换及取消使用人物到足印最近点的距离 ≤2 格，并检查与该点之间不经过封闭地形；仓与背包总容量各 200，取 / 放全部按双方容量截断。样本只能手动进入仓或试制输入，不能上带。调查遇满包可留下调查事实，但样本仍在地面；其他拒绝命令保持零变更。
- 开路要求人物在入口西侧，与四格入口段距离 ≤2 格，西侧接近线不穿封闭格；库存、前置和未开启全部通过才提交。地形、人物碰撞、建设和电线超覆盖检查均读同一 passages 事实。开启不自动供电。
- 最大瞬时负荷上界按 8×20 + 16×80 = 1440kW 校验；取消已消耗的电量保留。D2-B 定向验证包括自然采矿原料生成、自动串联制剂、样本各位置、事务拒绝、多件出料独立进程恢复及保留 D2-A 档兼容。完整玩家路径和统计页仍属 D3。
