# AI Art Prompt Library V2

更新时间：2026-07-12

## 用途与关联

本文是像素资产的提示词与生成流程真相源，服务介质证据轮与后续像素资产生产。

- 机械口径（网格、调色板、虚拟分辨率、光向、尺寸、归一管线）以 [Pixel Art And Grid Standard](pixel-art-and-grid-standard.md) 为准，本文不重复参数。
- 生成素材接收目录与命名规则：`assets/art-intake/README.md`。
- CC0 像素素材包候选：[Free Asset Pack Candidates](free-asset-pack-candidates.md)。
- V1（写实 AI 整景 / 独立切图管线）已废止；其提示词库随写实路线归档，仅作历史证据。项目级复盘期间图像生成暂停，本库先作介质证据轮的执行规范。

## 像素管线的提示词定位

像素路线下，提示词只负责“出稿”一段；一致性主要靠仓库侧归一（整数缩放到 32px 网格 + 调色板量化 + 对齐）机械保证，不指望提示词稳定控制精确几何。因此：

- 提示词求“像素风、俯视、题材正确、剪影清楚”，不苛求 AI 直接输出精确 tile 尺寸或精确透视。
- 出稿分辨率放大若干倍便于点修，最终由归一环节压到目标尺寸。
- 废稿直接重出或人工点修，不在写实图上做局部修补式返工。

## 全批次统一规则（生成前先读）

1. 整批使用同一工具生成；中途换工具就重开一批，不混批。
2. 先生成风格锚点（第一批基础反应器），定稿 1 张后续资产挂它做图像参考。
3. 每个资产生成 2 到 4 个候选；不满意直接重出，不在原图上局部修补。
4. 单体资产要求纯色深灰背景或透明背景；地面贴图要求 seamless tileable。
5. 锚点未定稿前只生成第一批，不批量往后跑。
6. 图像会话稳定性约束（单会话最多 3 张、生成与接入分离、立即复制到 art-intake、中断先清点）以 `CLAUDE.md` / `AGENTS.md` 为准。

## 全局风格块（每条提示词前完整粘贴）

```text
top-down 3/4 view pixel art game sprite, industrial sci-fi chemical
outpost on a hostile alien planet, limited palette, clean readable
pixel clusters, dark desaturated teal-gray metal and rock, glowing cyan
energy accents, warm amber work lights, crisp pixel edges, strong
readable silhouette, light from top-left, muted colors, no dithering
noise, no text, no watermark, no UI, single centered subject on a plain
dark background
```

要点中文对照：俯视 3/4 视角、像素风、限定调色板、干净可读的像素块、工业科幻化工前哨、暗青灰主色 + 青色发光 + 琥珀工作灯、像素边缘清晰、剪影清楚、光源固定左上、无文字水印。

调色板锚点与尺寸口径见 [Pixel Art And Grid Standard](pixel-art-and-grid-standard.md)；审阅时以“主色是否落在限定调色板色域内、缩到目标尺寸剪影是否可读”为判据。

## 风格边界

首颗星球和第一章不是西方炼金术、奇幻工坊或魔法遗迹风格；异常、遗迹和稳定工程通过工业结构、异星地貌、几何设施、管线、传感器和能量读数表达，不使用符文、法阵、药剂瓶、羊皮纸、蜡封、黄铜古董仪器、哥特 / 中世纪纹样或蒸汽朋克装饰作为主读法。

## 负面提示（Stable Diffusion 类工具使用）

```text
blurry, photorealistic, 3D render, painterly, smooth gradients, isometric
room interior, side view, horizon line, sky, text, letters, watermark, UI
frame, border, multiple unrelated objects, human face closeup,
oversaturated, alchemy, alchemist, occult symbols, magic circle, runes,
potion bottles, parchment, wax seal, medieval, gothic, brass steampunk,
fantasy workshop
```

## 生成顺序

像素证据轮优先按“一屏所需最小集”生成，而非一次铺满全资产表。

### 第一批：风格锚点

#### A0 基础反应器（风格锚点）

```text
a squat cylindrical chemical reactor with reinforced metal frame, round
glowing cyan reaction chamber window, amber status lights, short pipe
stubs on both sides, mounted on a dark metal base plate
```

- 生成 4 到 6 个候选。
- 交萝卜SAMA审阅，共同定稿 1 张为像素风格锚点存 `assets/reference/`，后续批次挂锚点图生成。

### 第二批：首屏核心设备（锚点定稿后）

#### B1 / B2 前哨核心（同图双状态，一张出两态）

```text
the same hexagonal outpost core machine shown twice side by side, two
separate objects, not touching: left version damaged with cracked casing,
exposed wiring, dim flickering cyan core; right version fully repaired
with sealed clean casing, bright steady cyan core, subtle amber running
lights; identical machine design and identical viewing angle
```

#### B3 储存单元 / B4 整备台 / B5 污染过滤器（可 2x2 整版一张出多台）

```text
industrial machines for a top-down pixel game, arranged separately, not
touching, no connecting pipes between them: a bank of connected storage
silos with fill-level strips; a field outfitting workbench with tool racks
and a glowing cyan terminal; a boxy pollution filter with vent grilles,
intake and exhaust pipes and faint yellow-green residue stains
```

### 第三批：地面 tile（tileable 变体）

#### C1 异星岩地 / C2 金属平台 / C3 晶体区 / C4 污染区

在对应描述后追加：`seamless tileable pixel texture, top-down view, uniform lighting, no borders`。地面主色以限定调色板为准（浅暖砂岩地表、平台暖灰、晶体青、污染黄绿）。

### 第四批：角色与敌人

行走动画优先用像素素材包补位（见候选清单）；AI 出稿先要单张俯视静态形象，需要动画帧时用“同一角色一整版帧表”方式出。

```text
top-down pixel sprite of a lone engineer in a sealed exosuit with a small
backpack reactor, helmet with glowing cyan visor, one amber shoulder
light, seen from above and slightly in front, full body, single character
```

### 第五批：资源与点缀

晶体簇、残骸堆、岩石散件、异星植被、污染贴花，按需一张图分开摆放多个尺寸，主色收敛到限定调色板。

## 特效说明

发光、烟雾、火花、粒子用 Godot 粒子系统和 shader 实现，不用 AI 生成；只有污染贴花这类地面贴图走生成管线。

## 产出提交与审阅流程

1. 一个素材类别一个会话；单会话最多 3 次生成，每次 1 张；超出另开会话。
2. 每批建目录 `assets/art-intake/YYYY-MM-DD-batchNN/`；项目用图每次生成后即复制到该批次。
3. 命名 `编号_名称_v候选号.png`；整版把编号连写。
4. 生成会话只生成与落盘，并在本批 `_manifest.md` 记录 thread ID、源路径、候选编号和未完成清单；审阅、归一、接入在独立执行会话进行。中断后先清点再补，不盲目重试。
5. 审阅清单（对执行 agent 说“审阅 art-intake 最新一批”）：
   - 视角是否统一为 3/4 俯视、正面略可见。
   - 光源是否来自左上。
   - 主色是否落在限定调色板色域内。
   - 缩到目标尺寸后剪影是否可读、像素块是否干净不糊。
   - 是否可被归一环节干净压到 32px 网格。
   - 复核方法：缩到目标尺寸看剪影（`sips -Z` 或 ImageMagick `-resize`）；地面做 2x2 拼贴看接缝；结论写入当周周志。
6. 通过素材由仓库侧归一后接入：去底、整数缩放到目标尺寸、调色板量化、对齐网格；存 `client/assets/` 按类别子目录与英文资产名命名，原始批次不进版本库。
7. 网格、调色板、光向、尺寸是架构级口径，执行 agent 按其生成与审阅，不自行修改；变更升级点见 [Development Decision Gates](../process/development-decision-gates.md)。

## 工具备注

- 像素专向：Retro Diffusion、PixelLab 等直接出像素；通用工具出稿后必须过归一做像素量化。
- Midjourney / GPT-4o：锚点定稿后挂参考图保持风格；要求 pixel art、limited palette、透明背景。
- Stable Diffusion：配合上方负面提示；可叠像素风 LoRA；地面贴图开 tiling。
- 即梦 / 豆包 / 可灵：中文界面可直接粘贴英文提示词，用“参考图”功能挂锚点。
