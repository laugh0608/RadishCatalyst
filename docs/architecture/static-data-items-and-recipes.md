# Static Data Schema - 物品与配方

返回：[Static Data Schema](static-data-schema.md)

## 物品数据

用于固体资源、材料、部件、任务物品和制造产物。

建议字段：

```text
id
display_name_key
description_key
category
tags
stack_size
mass
rarity
source_refs
used_by_refs
public_level
```

首版必需物品：

- 晶体矿物。
- 基础零件。
- 污染沉积物。
- 异常样本。
- 基础过滤模块材料。
- 地基材料。

规则：

- 物品定义不保存数量。
- 数量只存在于库存和存档中。
- 来源和用途可以先作为引用列表，后续由工具自动反查。

## 流体数据

用于污染液、溶剂、燃料、冷却剂和反应介质。

建议字段：

```text
id
display_name_key
description_key
category
tags
storage_unit
default_color
hazard_type
public_level
```

可选扩展：

- 温度范围。
- 压力范围。
- 腐蚀性。
- 毒性。
- 稳定性。
- 挥发性。

首版可以只使用数量和污染属性，但字段设计应允许后续扩展。

## 配方数据

配方是连接基地与外勤的核心。

建议字段：

```text
id
display_name_key
description_key
category
required_building_id
inputs
outputs
byproducts
duration
energy_cost
pollution_delta
unlock_conditions
public_level
```

`inputs`、`outputs`、`byproducts` 应引用物品或流体 ID。

`unlock_conditions` 当前用于说明配方由哪些任务解锁，并必须与任务定义中的 `unlock_effects` 保持一致；`scripts/check-client-data.ps1` 会校验这种对应关系，避免配方显示条件、任务奖励和运行时解锁来源分叉。

首版配方至少包括：

- 晶体矿物加工。
- 污染沉积物处理。
- 基础过滤模块制造。
- 抗性药剂或净化剂制造。
- 基础地板 / 地基制造。

规则：

- 配方不要写死在设备脚本中。
- 设备只声明可执行哪些配方类型或配方 ID。
- 任务解锁只改变配方是否可用，不改变配方定义本身。
