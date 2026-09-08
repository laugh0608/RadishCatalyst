# Factory Assets

本目录是正式三维工厂的运行资产，含 14 个 GLB 及 Godot 导入配置。资源从仓库内已认可的 [Godot 产线 Demo](../../../tools/visual-studies/topdown-3d/production/README.md)复制，原几何由同仓库 Web 产线导出；未下载第三方资产。

[source-manifest.json](source-manifest.json) 保留各 GLB 的字节数、SHA-256、原 Web 源文件哈希和原三机参考位置。参考位置描述导出来源，不是正式 64×64 地图或矿点配置；现行配置以 `client/data/factory/rules.gd` 为准。

正式视图只加载本目录资源，不在运行时引用 `tools/`。后续修改模型时同步来源清单和导入结果，并按首包合同审阅真实像素截图；不因正式资源独立落盘而宣称量产美术规范已经完成。
