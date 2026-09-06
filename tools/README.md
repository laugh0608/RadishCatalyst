# Tools

项目辅助脚本目录，用于数据处理、构建、导出、检查和自动化任务。

## 局部视觉研究与产线试玩

`visual-studies/` 保存独立 Demo；正式 Godot 客户端仍在 `client/`。启动命令均从仓库根执行，范围和证据见专题，开窗前遵守告知要求。

| 入口 | 用途与合同 |
| --- | --- |
| `sh tools/run-web-topdown-3d-demo.sh` | 本机 `4318`：`/play/` 为[首条三维产线](../docs/features/web-first-production-line-v1.md)，`/` 为[七机视觉样场](../docs/design/web-topdown-3d-demo-v1.md)；已有 Node 与局部锁定 Three.js，无游戏存档 |
| `sh tools/run-web-style-demo.sh` | 本机 `4317`：[手绘 / 像素 Canvas 对照](../docs/design/web-style-comparison-demo-v1.md)，只需已有 Node |
| `sh tools/run-topdown-3d-demo.sh` | [独立 Godot 3D](../docs/design/topdown-3d-comparison-demo-v1.md)，不借用正式 Boot |
| `sh tools/run-pipe-visual-study.sh` | [透明管道样板](../docs/design/transparent-pipe-module-visual-validation-v1.md)，正式 Boot 隔离世界 |
| `sh tools/run-industrial-volume-study.sh` | [像素体积样板](../docs/design/industrial-volume-visual-study-v1.md)，正式 Boot 隔离世界 |
| `sh tools/run-raised-pipe-modules.sh` | [架空管道模块](../docs/design/raised-pipe-module-visual-validation-v1.md)，正式 Boot 隔离世界 |

四个 Godot 入口均支持 `--verify`；使用已安装 Godot，允许 `GODOT_EXE` 指定路径。Web 仅监听 loopback；若服务已经运行，直接访问，不重复启动或重装依赖。三维 Demo 内的 `npm test` 只覆盖原样场，完整产线定向检查命令见产线专题。

本轮像素处理入口为 `normalize_pipe_visual_study.py`、`normalize_industrial_volume_study.py`、`normalize_raised_pipe_modules.py`，均依赖已有零依赖归一基础库、固定源图及 SHA-256 校验。它们会写入对应 `client/assets/sprites/visual_studies/`，不能把“打开样板”误作重新归一素材；没有对应忽略目录源图的机器不可复跑。日志 / 隔离存档在 `tools/runtime-intake/`，原图 / 截图在 `assets/art-intake/`，具体子目录由专题约定。

## 像素归一管线（零依赖）

- `normalize_pixel_asset.py`：像素素材归一基础库与 CLI（仅 Python 标准库）。能力：整数块降采样（块内逐通道中位数）、近黑底去背（边界泛洪 + 封闭孔判定）、限定调色板量化（median cut 上限 + 标准锚点吸附）、地面 128x128 宏块（4x4 个 32px tile）、横版多对象切分、明度基线匹配、2x2 拼贴与接缝比率自查。机械口径见 `docs/reference/pixel-art-and-grid-standard.md`。
- `normalize_slice_pack1.py`：切片包 1 批处理驱动，把证据轮定稿素材从 `assets/art-intake/`（不入库）归一到 `client/assets/sprites/slice/`、`client/assets/tiles/slice/` 与 `client/assets/portraits/`，并输出 QA 预览。仅在持有 art-intake 源图的机器上可复跑：
- `normalize_l3a_industrial_floor.py`：校验 L3-A V2 源哈希，逐格裁切 16 个 terrain tile，共享色板归一为 32px 后编排 128x128 atlas，并输出 3x3、6x4 和带内角开孔的平台拼接预览。
- `normalize_l3b_power_relay.py`：校验 L3-B V5 双态源哈希，以断电杆体作为唯一公共几何归一到 32×64，再受控派生红灯断电态、青灯与短脉冲通电态。
- `normalize_l3c_conveyor.py`：校验 L3-C V1 四向源哈希，以统一 384×384 源窗口和 12 倍整数块降采样归一为四个 32×32 方向帧，共享限定色板并输出工业地板联系表。
- `normalize_l3d_reactor_ports.py`：锁定现有 96px 反应器为唯一不可变主体，只在四个基数连接位受控派生琥珀出料 / 青色缺口入料端口，输出四向静态帧与工业地板联系表。
- `normalize_l3e_storage_hatch.py`：锁定现有 87×88 四罐储存设备为唯一不可变主体，每帧只在一个基数连接位覆盖带青色缺口与琥珀锁扣的双向舱口，输出四向静态帧与工业地板联系表。
- `normalize_l4a_crystal_cargo.py`：锁定已审定小型晶体簇哈希，以固定逐行掩码分离中央单晶，输出 `10×12` 货物 sprite 与四向带面联系表。
- `normalize_l4b_conveyor_topology.py`：锁定 L3-C 四向直段哈希，离线派生 8 张正交转角、源 / 目标端点各 4 张及双 / 三路合流 16 张 `32×32` 固定帧；运行时只选图，不旋转或绘制轨道。

```bash
python3 tools/normalize_slice_pack1.py            # 全量
python3 tools/normalize_slice_pack1.py --only grounds   # 单类
python3 tools/normalize_l3c_conveyor.py           # L3-C 四向传送带
python3 tools/normalize_l3d_reactor_ports.py      # L3-D 反应器四向端口
python3 tools/normalize_l3e_storage_hatch.py      # L3-E 储物箱四向舱口
python3 tools/normalize_l4a_crystal_cargo.py       # L4-A 单晶货物
python3 tools/normalize_l4b_conveyor_topology.py  # L4-B 转角 / 端点
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
