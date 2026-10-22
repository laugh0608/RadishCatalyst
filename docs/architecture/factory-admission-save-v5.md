# Factory Admission Save V5

更新时间：2026-10-17

## 范围与身份

对应已确认的[准入口 B](../features/factory-item-admission-v1.md)：`factory_3d / 5 / factory_discovery_admission_v1 / factory_discovery_yard_64_v1 / factory_discovery_admission_starter_v1`。普通供给加 `admission_gate=8`、总预算 326；原物品、配方、发现、电网、时钟和 A 调度保持，旧 V4 不静默升级。

共用字段 / 文件发布沿 [V2](factory-discovery-save-v2.md)、[V3](factory-discovery-save-v3.md)、[V4](factory-routing-save-v4.md)与[共用保存合同](factory-world-state-and-save-v1.md)。本篇只记录 V5 增量，工程批次与失败保留见 [W42](../devlogs/2026-W42.md)。

## 工程身份增量

10 月 17 日已接入独立[工程规模合同](factory-engineering-scale-v1.md)：仍为 `factory_3d / 5`，三元组为 `factory_engineering_admission_v1 / factory_engineering_yard_64_v1 / factory_engineering_load_100_v1`。它复用 V5 字段与准入口语义，采用独立地图和 1,280 实体供给；本篇的 326 预算与 4→5 增发八件仅适用于普通身份，工程世界没有普通升级 / 转换入口。

- `codec_v5.gd` 仅接受两套完整身份，错配 / 未知组合致命拒绝；构造相应模型后，矿点 / 通行按地图身份查询，普通六矿点与工程二十矿点各自校验。
- `codec_v2.gd` 的连接列表上限普通为 91、工程为 1,770；统计装机 / 请求上限普通为 240 / 1,440 kW、工程为 4,800 / 3,600 kW。只对工程身份应用对应上界，不放宽普通坏档校验。
- 默认 Store / 正式菜单拒绝工程创建与继续；只有显式工程上下文且保存根不为默认根时才允许，检查 runner 另行保证仓库内双根隔离。工程上下文不跳过严格解码、锁、读回和发布流程。
- Store 在可读主档 / 候选声明身份时检查同 schema 的备份身份，普通与工程不互相回退；持有会话身份后也拒绝保存时互换。主档损坏到无法取得身份时仍沿严格候选校验，不声称能从不可解析 JSON 还原原身份。

## 准入口权威字段

共用 `id/type/x/z/dir/cargo/progress/entry/batch`，type=`admission_gate`，1×1、后入前出、容量 1、不用电。dir 整数 0–3；entry 必须后方，空槽为 progress=0 / batch=0。cargo / 半程 / 原矿与加工 batch 校验、跨设备同批总件数沿 A，准入口纳入在途与持有量，不新增产消事件。

| 字段 | 严格约束 |
| --- | --- |
| filter_item | `crystal / catalyst / crust_solvent / rich_crystal` 或未配置空串；样本与未知物品拒绝 |
| quota_mode | 仅 `unlimited / quota` |
| quota_limit / quota_used | 不限量规范两个值均为 0；有限模式 limit 整数 1..1,000,000，used 整数 0..limit |
| accepting | 严格 bool，仅控制新接收，关闭后已有货物继续排空 |

未配置规范为空槽、不限量、数量字段为 0、停止接收；拒绝半配置。持货必须与白名单相同；有限模式始终 `quota_used + held_count <= quota_limit`。used 在成功送出与清空槽位同一提交中加一；接收只占剩余额度，不提前计数。未知字段、错误物品、越额、非整数、非法 batch、布局 / 构件不守恒均拒绝，不清货或夹取修复。

空载改白名单 / 模式 / 限额会开始新一轮，完全相同设置不重置；显式重置仅限空载、已配置、有限模式。开关、读档、暂停与失焦不重置。旋转保留配置 / used，持货拒绝；回收遵循完整返料、满包整体拒绝。配置候选、派生剩余额度、端口图、请求与工作集不保存。

## 显式 4→5 升级

1. 菜单提供继续 V4 或单独升级；说明增加 8 件准入口、筛选与总配额、保留独立原档。取消不持锁、不写世界。V5 不再提供重复领取入口。
2. 持锁准备来源，用 V4 完整严格解码；在内存改变 ruleset / supply / schema，新增 8 件 kits，再用 V5 严格解码。其余实体、货物、进度、batch、游标、背包、发现、统计、电网、时间、世界 ID / 名称保持。
3. 场景重建后复核来源与主档哈希，保留来源原文至 `backups/pre-admission-v4-<sequence>-<hash>.json` 并读回核验；与普通三槽备份分开。
4. 沿共用临时写入、严格读回、哈希及原子发布提交一次新 sequence。备份、重建、写入、读回或发布失败保持原主档 / 来源，关闭失败会话并释放自己的锁。
5. 旧 2→3、3→4、4→5 分别明确选择；schema 1 / 旧二维 10 不迁移。V5 主档不能被 V4 / V3 候选自动回退覆盖，未来版本和未知规则阻断全部回退。

## 必须证明

无准入口的 V5 与 V4 在相同命令 / 步数下逐步一致；有准入口时独立恢复保留第 3 件已出 / 第 4 件半程的配额和 batch，后续只再出一件。限额最后一件堵塞、关闭排空、重置 / 配置同帧、顺序 / FPS 一致、满包回收、未知未来版本与真实文件故障单列证据。全部测试双根隔离，不批量改玩家正式目录。

10 月 12 日状态 461、独立进程 2、升级菜单 10 项通过；正式 Boot 自然定量路径 write 120 / 独立 read 40 项通过，关闭恢复只排出第 4 件，开关不重置、显式重置后送第 5 件。UI / 原图与亲测入口见[准入口专题](../features/factory-item-admission-v1.md#playtest)，不扩展为 C、用户体验或 Windows 验收。
