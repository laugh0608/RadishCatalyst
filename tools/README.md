# Tools

项目辅助脚本目录，用于数据处理、构建、导出、检查和自动化任务。

## 像素归一管线（零依赖）

- `normalize_pixel_asset.py`：像素素材归一基础库与 CLI（仅 Python 标准库）。能力：整数块降采样（块内逐通道中位数）、近黑底去背（边界泛洪 + 封闭孔判定）、限定调色板量化（median cut 上限 + 标准锚点吸附）、地面 128x128 宏块（4x4 个 32px tile）、横版多对象切分、明度基线匹配、2x2 拼贴与接缝比率自查。机械口径见 `docs/reference/pixel-art-and-grid-standard.md`。
- `normalize_slice_pack1.py`：切片包 1 批处理驱动，把证据轮定稿素材从 `assets/art-intake/`（不入库）归一到 `client/assets/sprites/slice/`、`client/assets/tiles/slice/` 与 `client/assets/portraits/`，并输出 QA 预览。仅在持有 art-intake 源图的机器上可复跑：

```bash
python3 tools/normalize_slice_pack1.py            # 全量
python3 tools/normalize_slice_pack1.py --only grounds   # 单类
```

## 美术素材处理（旧，Pillow）

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
