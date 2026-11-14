# C3 开工联锁存档合同

更新时间：2026-11-14

萝卜SAMA已确认隔离 schema 16。冷父档已通过 Store 严格解码和首态比对。产品联锁首轮成对短测样本无效，状态见 [W46](../devlogs/2026-W46.md#d2-c3-interlock-preflight)。

## 身份与字段

| 字段 | 值 |
| --- | --- |
| `world_kind` / `save_schema_version` | `factory_3d` / `16` |
| `ruleset_id` | `factory_integrated_load_interlocks_v1` |
| `map_id` | `factory_integrated_frontier_yard_64_v1` |
| `supply_id` | `factory_integrated_load_interlocks_starter_v1` |
| `definitions_sha256` | `723a749cb7c5731cc99afa32d9880a0d76f438da7e7342dc3e18b4c12bba8b08` |

定义摘要绑定 [schema 15](factory-load-groups-save-v15.md) 和联锁条件、候选预算、状态更新及引用规则。正式 Boot 仅在测控隔离上下文显示「测控工厂 · C3 开工联锁隔离复核」。隔离入口可按原核心 I 零物料流程新建；普通 Store 拒绝此身份。schema 15 及更早身份继续使用原模型、字段、摘要和备份边界。

- 每台储能的 `load_group` 新增必填 `interlocks`，默认空数组。条目仅含 `member_id`、`source_id`、`condition`，按成员 ID 严格升序，每位成员至多一条，条件为 `finished_and_stopped`。
- 每台加工设备新增必填 `batch_outcome`，值为 `none`、`completed` 或 `cancelled`。放置、重新启用和新批开始置 `none`，正常完工写 `completed`，成功取消写 `cancelled`。在制只接受 `none`。停机保留最后结果和原在制字段。
- 来源必须是存在的组外加工设备。应用时必须同网。布线变化导致的分网可存读，依赖该来源的成员继续等待。来源回收前先解除或改绑；成员移除、清组和切到排除配方时清理相关条件。
- Store 严格校验字段、枚举、引用和身份；恢复设备状态及 C3 原决定与倒计时后，在下一固定步重新判断联锁。最终许可、状态文案和界面草稿均由当前状态派生。

预检专用派生先严格解码 v4 的 schema 15 冷父档和原 Store 副本，再为加工设备初始化 `none`、为储能初始化空条件，保持其他世界状态。派生档另存至隔离批次，并记录两个档的 SHA-256。该入口仅用于 [O5 / L5 预检](../features/factory-d2-production-comparison.md#d2-c3-interlock-preflight)。
