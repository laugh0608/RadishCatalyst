# Third-Party Asset Packs

本目录存放下载的第三方素材包原件，目录内容不进版本库（见根 `.gitignore`），只有本 README 提交。

## 使用方式

1. 每个素材包解压为一个子目录：`<pack-name>/`，保留包内 license 或说明文件。
2. 候选清单与授权口径见 `docs/reference/free-asset-pack-candidates.md`；只引入 CC0 或允许修改的免费商用包。
3. 实际用到的文件经去底、缩放、统一调色后拷贝进 `client/assets/`，原包不直接被工程引用。
4. 引入时在候选清单文档记录来源与授权；CC-BY 类素材同时在 credits 记名。
