# Art Intake

本目录接收 AI 生成素材的原始批次，供审阅定稿；目录内容不进版本库（见根 `.gitignore`），只有本 README 提交。

审阅通过的主候选必须处理到 `client/assets/` 后提交，不能只停留在本目录。

## 使用方式

1. 每批一个子目录，命名 `YYYY-MM-DD-batchNN/`，例如 `2026-07-02-batch01/`。
2. 文件命名 `编号_名称_v候选号.png`，例如 `a0_reactor_v3.png`；编号见 `docs/reference/ai-art-prompts.md`。
3. 放好后请当前执行 agent "审阅 art-intake 最新一批"。
4. 审阅通过的素材由仓库侧统一去底、缩放、调色后接入 `client/assets/`；定稿的风格锚点存入 `assets/reference/`。
5. 淘汰的候选可以整批删除，不需要保留历史。

## 处理入口

素材整理优先使用 `tools/prepare_art_asset.py`，先用系统 Python 执行环境诊断：

```bash
python3 tools/prepare_art_asset.py --check-env
```

如需实际裁切、去底或缩放，使用项目本地虚拟环境安装 `tools/requirements-art.txt`，不要依赖系统 Python 自带 Pillow。
