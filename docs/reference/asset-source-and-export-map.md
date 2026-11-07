# Asset Source And Export Map

更新时间：2026-11-01

用途：配合[资产盘点](asset-inventory-and-transition-v1.md)，说明当前资源从哪里制作、哪个入口会写哪里、哪些入口不能直接重跑。本篇只记录和规划，不授权导出、下载、处理或覆盖资产。

## 正式 3D 与对照的制作链

```text
tools/visual-studies/web-topdown-3d/ 的自有几何 / 材质 / 生产定义
    ├→ production/export-web-assets.mjs（位于独立 topdown-3d 工程）
    │     → tools/visual-studies/topdown-3d/production/assets/（14 GLB，对照）
    │     → 经来源 / 字节核对复制至 client/assets/factory/（正式）
    └→ tools/factory-content/export-*.mjs
          → client/assets/factory/<内容族>/ + 部分 icons/（正式或独立样板）
正式运行：client 导入 GLB / Node3D，不运行导出器或读取 tools/ 模型。
```

基础生产源为 `parts.mjs`、`factory.mjs`、`production/scene.mjs` 和 `production/model.mjs`；来源清单的短路径按 Web 目录解释。导出器使用既有 Web 工程的 Three.js / GLTFExporter。文件 / package hash 当前匹配只证明来源链一致，不代表已经实际重导出或工具在任意机器上可用；缺依赖或源图须显式报告，不自动安装。

| 输出族 | 制作入口（仓库根相对路径） | 来源 / 实际写入 / 处理 |
| --- | --- | --- |
| 基础 14 GLB | `tools/visual-studies/topdown-3d/production/export-web-assets.mjs` | Web 自有几何；写独立 `production/assets/` 与 `manifest.json`，不直接写正式目录；正式复制是需明确记录的发布步骤 |
| power 2 GLB | `tools/factory-content/export-power-assets.mjs` | 同仓库材质 / 几何，写 `client/assets/factory/power/` 与来源清单 |
| routing 2 GLB | `tools/factory-content/export-routing-assets.mjs` | 分流 / 汇合自有几何，写 `factory/routing/`；图标若未列入其 manifest，不推定由该工具生成 |
| admission 1 GLB | `tools/factory-content/export-admission-asset.mjs` | 写 `factory/admission/`；入口 / 出口与足印约束沿真实定义 |
| expansion 5 GLB + 8 SVG | `tools/factory-content/export-expansion-assets.mjs` | 写 `factory/expansion/` 与 `icons/`，包括加工机与铁 / 炭矿源 |
| energy 1 GLB + 1 SVG | `tools/factory-content/export-energy-assets.mjs` | 写 `factory/energy/` 与工业电芯图标；更换外观不自动改变燃烧规则 |
| refinement 2 GLB | `tools/factory-content/export-refinement-assets.mjs` | 写 `factory/refinement/`，独立 prototype 消费；不是正式根目录两件模型的更新入口 |
| R1-B core outline 1 GLB | `tools/factory-content/export-core-outline.mjs <new-batch> [--publish-prototype]` | 自有轮廓源；先写 `assets/art-intake/2026-11-01-core-outline/<batch>/`，显式发布只写 `client/assets/prototypes/base_core_outline/`，仅 R1-B 样板读取；`outline-06` 四面端口与四角装饰已获轮廓认可；用途限独立样板 |
| D2 core outline 1 GLB | `tools/factory-content/export-core-outline.mjs <new-batch> --grid-controls` | 复用四面轮廓和 16 锚点，加 III 模块。导出证据在 `tools/runtime-intake/design-references/factory-grid-controls/`，运行模型写 `client/assets/factory/grid-controls/`，由支持核心 III 的 D2 隔离档加载 |
| D2 grid buffer 1 GLB | `node tools/factory-content/export-grid-buffer.mjs` | 自有三模块储能模型，2×2 足印与独立来源清单写入 `client/assets/factory/grid-controls/`，随 E2 加载 |
| 其余工厂图标 8 SVG | 已跟踪可编辑 SVG，未找到覆盖这些当前文件的独立导出清单 | `item_slot`、建造 / 准入口各自读取；以当前资源为编辑源，作者历史 / 新导出器缺口不补猜测 |

执行形式为 `node <上述 .mjs 路径>`，均可能覆盖输出，本轮未执行。核对后续模型替换时还须记录 GLB 内节点名 / 材质、Godot 导入配置及 UID；角色视图按节点名绑定身体 / 四肢，外形相近不能保证动画接线相容。

R0 盘点时 27 个客户端 GLB 元数据均未包含图像、纹理或法线贴图条目；后续新增的 R1-B 轮廓也无贴图。当前候选含 16 命名端口与 I / II 变体，共 5 网格 / 4 材质、每级 4 可见表面；可编辑源、GLB、命令 / 依赖与哈希随来源清单保存，Godot 导入配置独立提交。R1-C 贴图单独绑定，保留原 GLB 与 UV。

R1-C 独立样板材质由 `python3 tools/factory-content/export-representative-materials.py <batch> --copy-to-study` 生成。每批先保存在 `assets/art-intake/2026-11-07-factory-representative-assets/<batch>/`，样板副本位于 `client/assets/prototypes/factory_material_study/`。当前 `material-02` 有四张 sRGB 颜色贴图和一张 +Y 法线图，均为 256²，启用 mipmaps。来源和文件哈希随清单保存。

## 共用与工程资源

| 资产 | 当前来源 / 消费证据 | 重制 / 替换要求 |
| --- | --- | --- |
| `fonts/NotoSansSC-wght.ttf` | 字体 README 给出 google/fonts revision `523d033d6cb47f4a80c58a35753646f5c3608a78`；当前 SHA-256 匹配，OFL 在目录内 | 继续用，不按旧切片归档；未来更新另获依赖 / 下载授权 |
| `themes/*.tres` | 自身为可编辑资源，Theme / StyleBox / Font 资源相互引用；`startup_menu.gd` 明确使用三个 `slice_ui_system_*` | 先按实际消费方分辨共用和二维专属；不得因名称或相同字节批量合并 |
| `ui/system/startup_world_backdrop.png` | [P2-E](../features/slice-game-ui-visual-finalization-v1.md)记载从 `assets/reference/visual-direction/target-world-v01.png` 无 HUD 裁切 | 来源已知，精确裁切 / 发布脚本未在已跟踪工具中定位；改图前补步骤，不把原目标稿当新 3D 定稿 |
| `client/icon.svg` / `default_bus_layout.tres` | 工程图标与默认音频总线配置，原文件可编辑 | 与玩法美术分别维护；无音频素材不等于总线资源无用 |

## 保留二维：当前源与旧工具的覆盖关系

当前内容不能通过“按 pack1→pack2→pack3→L3 全跑一遍”复原。其后有定向接入、短口整改与局部片；下表把已证来源和历史候选分开。

| 当前资产 / 族 | 来源或入口证据 | 重跑状态 / 缺口 |
| --- | --- | --- |
| `collector.png` / `storage.png` / `power_relay.png` | `assets/art-intake/2026-08-05-batch12-support-device-native-normalization/{collector_native_v1,storage_native_v1,power_relay_native_v2}.png`；三项均与当前字节匹配 | 同批 `build_support_device_normalization.py` 在本机存在但未跟踪；输入继续依赖 batch10 / 11。不是七月 pack 的当前输出 |
| `outpost_core_repaired.png` | batch09 `core_native_redraw_v1.png` 与当前字节匹配；[设备接入专题](../features/slice-world-device-family-integration-v1.md)记载短口恢复 | 同批 `build_native_redraw.py` 为本地制作入口；pack1 / 2 会覆盖同名文件，不能回滚式重跑 |
| `reactor.png` | 上述专题记录 8 月 11 日从 V10 去除烘焙外段并换短口，当前 SHA-256 为 `6aa89a4bc5a6efe9bb1b803e97b1d91d0af396151db3292fb02f85322978c5b5`，与记录一致 | Gate A V10 不是当前逐字节复制源；精确整改 / 发布工具与中间产物链仍待补全，不能用早期 L3-D 覆盖 |
| 核心 / 反应器 connected patch | `sprites/slice/docking_*_connected_patch.png`，`slice_core_visual.gd` / `slice_storage.gd` 及接驳合同继续消费 | 贴片为独立运行依赖；整理 / 设计新模型时不能误当无用碎片删除 |
| 角色 idle / 方向行走 | `tools/normalize_slice_pack3.py` 为历史当前角色归一候选，固定七月 side / up / down / idle 源；动态 / 场景引用见逐文件报告 | 源在忽略目录，存在性不证明全参数重放结果一致；需要重制时按当期哈希复核 |
| 立绘 | `normalize_slice_pack1.py` 的 portrait job；原始 batch04、参考锚点、运行立绘有明确复制关系；锚点与当前运行图字节相同 | 立绘保留二维 UI 用途，不用作 3D 世界角色；只运行相关 job 的授权与参数须另核 |
| 地板 / 中继旧态 / 反应器方向帧 / 储物箱方向帧 / 带 / 货物 | `normalize_l3a`、`l3b`、`l3c`、`l3d`、`l3e`、`l4a`、`l4b`、`l5a` 各工具有固定源 / 输出 / 哈希或确定性派生 | 历史四向帧与当前固定正面不是同一语义；脚本有依赖顺序和覆盖风险，逐项选择而非批量链跑 |
| L3-F 采集器候选 | `tools/normalize_l3f_collector.py` 当前写 `assets/art-intake/` 候选与 QA 图 | 不直接发布 `client/assets/sprites/slice/collector.png`，不能作为现行采集器生产入口 |
| 其余二维 PNG / tile `.tres` / 旧图标 | 各场景、目录定义与生成工具提及保留在逐文件 JSON / CSV | 无确证逐文件来源的标为待补证；可编辑 `.tres` / SVG 本身可维护，不伪造一个统一导出器 |

已跟踪 `normalize_*.py` 中静态识别出 34 条原图 / 预览 PNG 路径候选，本机均存在；另三组像素实验源图的清单哈希均匹配。这不是所有历史生成原图的全量来源证明，也不等于这些脚本已运行成功。

## 旧路线、实验与参考

| 族 | 制作 / 引用证据 | 保留与替换计划 |
| --- | --- | --- |
| 旧首屏 10 PNG | `tools/generate_demo_first_screen_raster_assets.py` 为确定性低保真绘制入口，直接写 `sprites/demo_first_screen/` | 历史路线专用，不用它制作新 3D 主体；旧 branch / 检查退役后才评估删除 |
| 同目录 15 SVG、晶体工作面 4 SVG | 已跟踪文本图形可编辑，旧地图 / 检查提及可追 | 未找到统一生成器，不把它们算作上述 10 PNG 生成器产物 |
| 呈现重建 PNG / tiles | [W27](../devlogs/2026-W27.md)记载 7 月批次经裁切 / 去底 / tile 处理；`tools/prepare_art_asset.py` 是通用处理器 | 通用工具不是逐文件配方；源与处理参数不全的保留待补。部分角色 / 地板被 Web / 像素样板跨用 |
| industrial / transparent / raised 像素实验 | `normalize_industrial_volume_study.py` / `normalize_pipe_visual_study.py` / `normalize_raised_pipe_modules.py`；三个各自 `manifest.json` 保存源图与产物哈希 | 当前全部匹配；只服务样板，不是新 3D 材质或设备来源 |
| 独立 Godot / Web 对照 | 14 GLB 源如首节；Web 样式 3 PNG 由 `server.mjs` 动态路由、`renderer.mjs` 读取 | 对照副本保留；3 PNG 未确证独立生产脚本，现有图为样板输入，不能自动宣称可重建 |
| 概念 / 三锚点 / 5 视觉目标 | `assets/` 自身是已跟踪参考；README 与相关专题记录其适用范围，失败图不作为生成母图 | 像素锚点仅限保留二维，旧写实 / RPG / UI 目标不得默认为新 3D 定稿 |
| 本地缓存 / 第三方 | `assets/art-intake/` 有生成源、制作脚本和运行证据；`assets/third-party/` 当前无素材包目录 | 不搬迁 / 清理；没有本地原包不证明历史来源合规或不合规，后续实际采用前核对来源与许可 |

## 下次替换前需要补的实施材料

对拟替换的一件资产给出：当前路径 / 使用入口、真实制作源及许可、生成或编辑版本、可重放命令与依赖、输出哈希 / 尺寸或 GLB 结构、正式发布步骤 / 导入配置、足印 / 端口 / 动画节点不变量、匹配的静态与窗口验证、失败时保留原资产的方式。

上述材料随 R1 / R2 样板和实际功能包补齐，不以“整理旧资产”为由提前执行所有导出或复制工具。R0 盘点没有制作 / 导入资产；R1-B 仅新增自有原型核心，未重导出、重归一、重导入或变更任何既有运行资产。
