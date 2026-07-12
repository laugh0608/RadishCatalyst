# Assets

可提交的项目源资产目录，例如设定图、源音频、可编辑美术文件和资产说明。

大型二进制资产在提交前应确认是否适合进入 Git，必要时再引入 Git LFS 或外部资产管理方案。

## Current Folders

- `art-intake/`：AI 生成原始候选批次，本地审阅缓存，不进版本库。
- `concept-art/`：项目视觉方向、世界观氛围和 UI 参考概念图。
- `reference/`：风格锚点和稳定参考图，内容进版本库。
- `third-party/`：下载评估的第三方素材包，本地缓存，不进版本库。

审定后用于游戏运行的素材不留在 `assets/art-intake/`，统一处理到 `client/assets/` 后提交。
