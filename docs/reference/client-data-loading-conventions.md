# Client Data Dictionary - 装载约定

返回：[Client Data Dictionary](client-data-dictionary.md)

## 目的

这份文档用于说明当前 `client/data/` 下静态数据表的实际字段、运行时用途和跨表约束。

它面向两类工作：

- 内容编写：新增任务、配方、区域、敌人和交互对象时，先确认字段和约束。
- 工程维护：判断某个字段目前只是说明性信息，还是已经被脚本、场景检查或存档校验当成真相源。

它描述的是**当前 Godot 原型的已接入口径**，不是最终数据 schema 承诺。

## 真相源

当前客户端数据字典的直接真相源是：

- `client/data/*.json`
- `client/scripts/core/data_registry.gd`
- `scripts/check-client-data.ps1`
- `scripts/check-client-scenes.ps1`
- `client/scripts/save/save_content_validator.gd`

如果本文与代码不一致，以代码和检查脚本为准，然后回头修本文。

## 通用装载约定

所有静态数据文件当前都采用：

```json
{
  "schema_version": 1,
  "entries": []
}
```

通用约束：

- 每条 `entry` 必须有唯一 `id`。
- `id` 必须符合 `category.name_variant` 风格，例如 `item.crystal_ore`。
- `display_name_key` 和 `description_key` 必须存在，并能在 `client/data/localization/zh_cn.json` 中找到。
- `public_level` 当前用于区分玩家可公开程度，已有值主要是 `public` 和 `spoiler`。

`DataRegistry` 当前对所有表统一要求的字段只有：

- `id`
- `display_name_key`
- `description_key`
- `public_level`

这意味着很多更细字段是由后续运行时、检查脚本或约定共同约束的，而不是由 `DataRegistry` 单独校验。
