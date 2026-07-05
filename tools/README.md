# Tools

项目辅助脚本目录，用于数据处理、构建、导出、检查和自动化任务。

## 美术素材处理

- `prepare_art_asset.py`：把审阅通过的 PNG 素材裁切、去底、缩放到 `client/assets/`，并可写入 Godot `.import` sidecar。
- `requirements-art.txt`：美术素材处理所需的本地 Python 依赖。不要把依赖装进系统 Python；需要处理素材时使用项目本地虚拟环境。

推荐流程：

```bash
python3 tools/prepare_art_asset.py --check-env
python3 -m venv .venv-art
.venv-art/bin/python -m pip install -r tools/requirements-art.txt
.venv-art/bin/python tools/prepare_art_asset.py --input assets/art-intake/.../source.png --output client/assets/sprites/.../asset.png --trim-background --max-size 320 --write-godot-import
```

地面 tile 不去底，通常使用：

```bash
.venv-art/bin/python tools/prepare_art_asset.py --input assets/art-intake/.../tile.png --output client/assets/tiles/.../tile.png --mode tile --tile-size 512 --write-godot-import
```
