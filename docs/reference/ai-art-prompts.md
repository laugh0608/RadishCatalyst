# AI Art Prompt Library V2

更新时间：2026-08-04

## 用途与关联

本文是像素资产的提示词与生成流程真相源，服务介质证据轮与后续像素资产生产。

- 机械口径（网格、调色板、虚拟分辨率、光向、尺寸、归一管线）以 [Pixel Art And Grid Standard](pixel-art-and-grid-standard.md) 为准，本文不重复参数。
- 生成素材接收目录与命名规则：`assets/art-intake/README.md`。
- CC0 像素素材包候选：[Free Asset Pack Candidates](free-asset-pack-candidates.md)。
- V1（写实 AI 整景 / 独立切图管线）已废止；其提示词库随写实路线归档，仅作历史证据。项目级复盘期间图像生成暂停，本库先作介质证据轮的执行规范。
- 当前核心 / 反应器重设计以 [视觉层级与色彩分离 V1](../features/slice-visual-hierarchy-and-color-separation-v1.md) 和最新 `assets/art-intake/*/_manifest.md` 为准；下方 A0、B1 / B2 是 7 月历史提示，不得作为当前造型母参考或图像输入。

## 像素管线的提示词定位

像素路线下，提示词只负责“出稿”一段；一致性主要靠仓库侧归一（整数缩放到 32px 网格 + 调色板量化 + 对齐）机械保证，不指望提示词稳定控制精确几何。因此：

- 提示词求“像素风、俯视、题材正确、剪影清楚”，不苛求 AI 直接输出精确 tile 尺寸或精确透视。
- 出稿分辨率放大若干倍便于点修，最终由归一环节压到目标尺寸。
- 废稿直接重出或人工点修，不在写实图上做局部修补式返工。

## 全批次统一规则（生成前先读）

1. 整批使用同一工具生成；中途换工具就重开一批，不混批。
2. 先生成风格锚点（第一批基础反应器），定稿 1 张后续资产挂它做图像参考。
3. 每个资产生成 2 到 4 个候选；首张必须先过“主体原型 + 投影方向”硬判据，任一不符就先修提示词，不沿原提示继续消耗候选额度；不满意直接重出，不在原图上局部修补。
4. 单体资产要求纯色深灰背景或透明背景；地面贴图要求 seamless tileable。
5. 锚点未定稿前只生成第一批，不批量往后跑。
6. 图像会话稳定性约束（默认每轮至多 3 次、明确授权后可按轮追加、默认生成与后续阶段分离、点名授权可在原会话切换阶段、立即复制到 art-intake、中断先清点）以 `CLAUDE.md` / `AGENTS.md` 为准。
7. 帧表、双状态、多表情等一图多对象时，把全局风格块末尾的 `single centered subject on a plain dark background` 换成 `objects arranged separately in a row, not touching, on a plain dark background`。

## 全局风格块（每条提示词前完整粘贴）

2026-07-18 视角修订并二次校准：投影口径为高斜角俯视（顶面最大 + 侧壁高度带可见，参照 Factorio / Mindustry 机器；见像素标准投影口径节）。首轮 near-overhead 近垂直俯视压平了高度，已回调；旧 3/4 立面与近垂直俯视两个极端均判不合格。设备族带底部黄黑警示条与侧壁高度带。

```text
high oblique top-down view pixel art game sprite, camera looking down at
a steep angle like Factorio and Mindustry machine sprites, the top
surface is the largest visible face but a clear band of side walls is
visible to convey solid height and volume, a chunky machine sitting on
the ground with readable vertical thickness, not a flat overhead
blueprint, not an eye-level facade, not a low side view, industrial
sci-fi chemical outpost on a hostile alien planet, limited palette, clean
readable pixel clusters, dark desaturated teal-gray metal and rock,
glowing cyan energy accents, warm amber work lights, crisp pixel edges,
strong readable silhouette, fixed screen-axis-aligned camera azimuth,
the base front edge horizontal with no diagonal three-quarter yaw or
downward-facing chassis, light from top-left, muted colors, no dithering
noise, no text, no watermark, no UI, single centered subject on a plain
dark background
```

要点中文对照：高斜角俯视（顶面最大面 + 一圈可见侧壁高度带、有厚度、参照 Factorio / Mindustry；既不做纯平俯视蓝图、也不做平视立面 / 低角度侧视）、像素风、限定调色板、干净可读的像素块、工业科幻化工前哨、暗青灰主色 + 青色发光 + 琥珀工作灯、像素边缘清晰、剪影清楚、光源固定左上、无文字水印。

调色板锚点与尺寸口径见 [Pixel Art And Grid Standard](pixel-art-and-grid-standard.md)；审阅时以“主色是否落在限定调色板色域内、缩到目标尺寸剪影是否可读”为判据。

## 风格边界

首颗星球和第一章不是西方炼金术、奇幻工坊或魔法遗迹风格；异常、遗迹和稳定工程通过工业结构、异星地貌、几何设施、管线、传感器和能量读数表达，不使用符文、法阵、药剂瓶、羊皮纸、蜡封、黄铜古董仪器、哥特 / 中世纪纹样或蒸汽朋克装饰作为主读法。

## 负面提示（Stable Diffusion 类工具使用）

```text
blurry, photorealistic, 3D render, painterly, smooth gradients, isometric
room interior, diagonal three-quarter yaw, downward-facing chassis,
side view, horizon line, sky, text, letters, watermark, UI
frame, border, multiple unrelated objects, human face closeup,
oversaturated, alchemy, alchemist, occult symbols, magic circle, runes,
potion bottles, parchment, wax seal, medieval, gothic, brass steampunk,
fantasy workshop
```

## 阶段增量提示词

L3 建造放置阶段的电力中继、传送带及后续设备方向素材提示词见 [L3 Building Art Prompts](l3-building-art-prompts.md)。执行时仍须完整复用本文全局风格块与多对象排版规则；若两份文档冲突，以本文的全局机械口径和 L3 子库的具体资产约束共同收紧，不得放宽任一方。

## 介质证据轮执行清单

状态：提示词已就绪，启动由萝卜SAMA决定。启动后按本清单逐会话执行：默认每轮至多 3 次生成、每次 1 张、一个素材类别一个会话；每轮结束或切换素材类别都必须先停手，只有经萝卜SAMA分别明确授权才能在原会话继续。切换后的新类别使用独立批次目录与 manifest，并从自己的首轮 `0 / 3` 计数。成功 / 失败判据见 [Pixel Art And Grid Standard](pixel-art-and-grid-standard.md)「介质证据轮」。

拼装完成、可整篇丢给生图 AI 的执行副本：[Pixel Evidence Round Prompts](pixel-evidence-round-prompts.md)；副本与本库冲突时以本库为准，改提示词先改本库再同步副本。

### 会话拆分总表

| 会话 | 类别 | 生成内容 | 使用提示词 |
| --- | --- | --- | --- |
| S1 | 风格锚点 | A0 像素反应器 3 张候选 | 全局风格块 + A0 |
| S2 | 地面 tile | C1 岩地、C2 平台、C3 晶体地各 1 张 | C 批完整提示词（不用全局块） |
| S3 | 首屏设备 | B1B2 核心双态、B3 储存、B4 整备台各 1 张 | 全局风格块 + B 批（双态按多对象规则） |
| S4 | 角色 | D1 静态 1 张 + 行走 4 帧帧表 1 张（留 1 次重出额度） | 全局风格块 + D1；帧表用 D1-W 整段 |
| S5 | 二三屏增量 | B6 采集器、C4 污染地、E1 晶体簇各 1 张 | 全局块 + B6 / C4 完整 / 全局块 + E1 |
| S6 | 立绘小样 | 同角色三表情差分版 2 到 3 张候选 | 立绘整段提示词（不用像素块） |

执行规则：

- 顺序：S1 定稿锚点后才开 S2 到 S4（后续批次全部挂锚点图做参考）；S2 到 S4 归一审阅通过后才开 S5；S6 独立，任意时点可做。
- 每会话落盘 `assets/art-intake/YYYY-MM-DD-batchNN/`，命名 `编号_名称_v候选号.png`，写 `_manifest.md`；生成后立即复制落盘。
- 某张不满意：先完成本会话其余条目，失败项集中进同类别第二轮会话；同类别两轮仍不成即触发决策闸门（该类别退扁平几何风或 CC0 像素包基底），不开第三轮。
- 行走帧表是已知最高风险项；两轮不成即改由 CC0 像素包承担行走动画，静态形象仍可用 AI 稿，不算证据轮整体失败。

### 每会话完成后的审阅与归一

1. 执行会话按「产出提交与审阅流程」审阅：视角、左上光、调色板色域、缩到目标尺寸后剪影。
2. 像素稿归一：整数缩放到目标尺寸（tile 32px、设备 64 到 96px、角色 48 到 64px）+ 调色板量化；地面做 2x2 拼贴查接缝。
3. S2 到 S4 定稿后，执行会话用归一素材拼一张“第一屏拼合预览”（图像拼合，不进引擎），同图出 960x540 与 640x360 两版取景，交萝卜SAMA定细腻档位。
4. S5 定稿后拼第二 / 三屏并排图作重复性证据；审阅结论、定稿与失败记录写入当周周志。

## 生成顺序

像素证据轮优先按“一屏所需最小集”生成，而非一次铺满全资产表。

### 第一批：风格锚点

#### A0 基础反应器（7 月历史锚点，当前禁用）

```text
a squat cylindrical chemical reactor with reinforced metal frame, round
glowing cyan reaction chamber window, amber status lights, short pipe
stubs on both sides, mounted on a dark metal base plate
```

- 生成 4 到 6 个候选。
- 交萝卜SAMA审阅，共同定稿 1 张为像素风格锚点存 `assets/reference/`，后续批次挂锚点图生成。
- 2026-07-13 已定稿：`2026-07-13-batch01` 的 `a0_reactor_px_v1`，存 `assets/reference/pixel-style-anchor.png`；96px 目标尺寸复核其剪影、色域与密度全胜，`v2` 侧管黄铜偏出色域、`v3` 密度过高缩小糊并（留档作后续大型建筑体量参考）。

### 第二批：首屏核心设备（锚点定稿后）

#### B1 / B2 前哨核心（7 月历史提示，当前禁用）

```text
the same hexagonal outpost core machine shown twice side by side, two
separate objects, not touching: left version damaged with cracked casing,
exposed wiring, dim flickering cyan core; right version fully repaired
with sealed clean casing, bright steady cyan core, subtle amber running
lights; identical machine design and identical viewing angle
```

#### B3 储存单元 / B4 整备台 / B5 污染过滤器（可 2x2 整版一张出多台）

```text
industrial machines for a high oblique top-down pixel game, seen at a
steep camera angle with the top surface largest but a clear band of side
walls visible for solid height and volume, each a chunky machine sitting
on the ground, arranged separately, not touching, no connecting pipes
between them: a bank of connected storage silos with fill-level strips; a
field outfitting workbench with tool racks and a glowing cyan terminal; a
boxy pollution filter with vent grilles, intake and exhaust pipes and
faint yellow-green residue stains; each machine base carries a yellow-and-
black hazard stripe as a shared family trait
```

单台重出时，取上面对应从句接全局风格块即可。

#### B6 自动采集器（接全局风格块）

```text
an automated resource collector machine with a wide intake hopper, short
conveyor stub, partially visible rotating drum, amber hazard stripes
```

### 第三批：地面 tile（完整提示词，不叠全局风格块）

#### C1 异星岩地

```text
top-down pixel art seamless tileable ground texture, light warm sandy-gray
alien rock and compacted dust with fine dark cracks and scattered pebbles,
limited palette, clean readable pixel clusters, subtle color variation,
low contrast, uniform lighting, crisp pixel edges, muted colors, no text,
no watermark, no borders, no large landmarks
```

#### C2 金属平台地面

```text
top-down pixel art seamless tileable industrial metal platform floor,
medium warm-gray riveted panels clearly darker than sandy ground, subtle
wear, faint amber hazard line accents, limited palette, clean readable
pixel clusters, low contrast, uniform lighting, crisp pixel edges, muted
colors, no text, no watermark, no borders
```

#### C3 晶体区地面变体

```text
top-down pixel art seamless tileable ground texture, light warm sandy-gray
alien rock with faint embedded cyan crystal veins glowing subtly through
pale stone, fine dark cracks for depth, limited palette, clean readable
pixel clusters, low contrast, uniform lighting, crisp pixel edges, muted
colors, no text, no watermark, no borders
```

#### C4 污染区地面变体

```text
top-down pixel art seamless tileable ground texture, light warm sandy-gray
cracked soil stained by muted sickly yellow-green residue patches, readable
but not oversaturated, limited palette, clean readable pixel clusters, low
contrast, uniform lighting, crisp pixel edges, muted colors, no text,
no watermark, no borders
```

### 第四批：角色与敌人

行走动画优先用像素素材包补位（见候选清单）；AI 出稿先要单张俯视静态形象，需要动画帧时用“同一角色一整版帧表”方式出。

#### D1 玩家工程师（静态；2026-07-18 裁决：不再单独生成，由正面帧表定稿后取帧派生，本段提示词留档）

```text
high-angle top-down pixel art game sprite of a lone engineer in a sealed
exosuit with a small backpack reactor, helmet with glowing cyan visor,
one amber shoulder light, seen from steeply above, facing straight
toward the viewer with the body axis perfectly vertical, head at the top
and feet at the bottom of the frame, both shoulders equally visible, not
turned to either side, no three-quarter body rotation, head and
shoulders dominant with feet visible below the body, no eye-level view,
full body, single character, industrial sci-fi style, limited palette,
clean readable pixel clusters, dark desaturated teal-gray metal, glowing
cyan energy accents, warm amber work lights, crisp pixel edges, strong
readable silhouette, light from top-left, muted colors, no dithering
noise, no text, no watermark, no UI, single centered subject on a plain
dark background
```

#### D1-W 行走帧表（整段直接使用，不叠全局块）

```text
pixel art sprite sheet of the same character in 4 walk cycle frames,
arranged in one horizontal row, equal spacing, not touching: a lone
engineer in a sealed exosuit with a small backpack reactor, helmet with
glowing cyan visor, one amber shoulder light, high-angle top-down view
seen from steeply above, strict side profile walking toward the left
edge of the frame, body seen exactly from its left side, helmet visor
pointing at the left edge, only the near shoulder visible, torso not
rotated toward the camera, no three-quarter view, no front view, feet
visible below the body, limited palette, clean readable pixel clusters,
crisp pixel edges, light from top-left, muted colors, plain dark
background, no text, no watermark
```

#### D1-WU 背面行走帧表（包 3.5 增补，整段直接使用，不叠全局块）

```text
pixel art sprite sheet of the same character in 4 walk cycle frames,
arranged in one horizontal row, equal spacing, not touching: a lone
engineer in a sealed exosuit with a small backpack reactor, helmet with
glowing cyan visor, one amber shoulder light, high-angle top-down view
seen from steeply above, walking upward away from the viewer, back of
the helmet and the backpack reactor visible, no face visible, no
eye-level view, limited palette, clean readable pixel clusters, crisp
pixel edges, light from top-left, muted colors, plain dark background,
no text, no watermark
```

#### D1-WD 正面行走帧表（包 3.5 增补，整段直接使用，不叠全局块）

```text
pixel art sprite sheet of the same character in 4 walk cycle frames,
arranged in one horizontal row, equal spacing, not touching: a lone
engineer in a sealed exosuit, helmet with a large glowing cyan visor
clearly visible and centered on the helmet facing the viewer, one amber
shoulder light, the backpack reactor completely hidden behind the body,
not a back view, no backpack visible, high-angle top-down view seen from
steeply above, walking downward toward the bottom edge of the frame,
body axis perfectly vertical, both shoulders equally visible, top of the
helmet and the cyan visor dominant, not turned to either side, no
three-quarter view, no eye-level view, limited palette, clean readable
pixel clusters, crisp pixel edges, light from top-left, muted colors,
plain dark background, no text, no watermark
```

- 方向帧增补（2026-07-16 包 3.5）：生成时挂 `assets/reference/pixel-style-anchor.png` 风格参考，并以已定稿 `d1_engineer_px_v1.png` 与 `d1w_walk_sheet_px_v1.png` 作角色参考；审阅三点——四帧同一角色且与 d1 同族、行走循环连贯、朝向正确（背面见背包反应器不见脸，正面见青面罩）。左右仍由侧向帧表水平翻转承担，不生成 8 方向。

### 第五批：资源与点缀

晶体簇、残骸堆、岩石散件、异星植被、污染贴花，按需一张图分开摆放多个尺寸，主色收敛到限定调色板。

#### E1 晶体簇（接全局风格块，按多对象规则调整结尾）

```text
clusters of glowing cyan alien crystals growing from dark rock bases,
three separate clusters small medium large, arranged in a row, not
touching
```

#### D1-S 三向站立帧（2026-07-18 增补，方向性 idle 素材）

站立帧提示词由对应方向帧表提示词机械改写：去掉 sprite sheet / 4 walk cycle frames / walking 相关短语，朝向词块与对应方向帧表完全一致（这是三方向已实证的朝向控制模板，不得改动），并加入统一站立词块：

```text
standing perfectly still, both feet together planted on the ground, legs
straight, arms relaxed at the sides, no walking, no mid-step pose, full
body, single character
```

每张挂新锚点（只借风格）+ 对应方向达标帧表（角色与朝向参考）。拼装完成版见交接副本 S5'' 段；产出接入为方向性 idle（`idle_down` / `idle_side` + 翻转 / `idle_up`）。


### 第六批：主角立绘（UI 层，不用像素风格块）

立绘只用于对话与角色界面，不进世界层、不做像素归一。整段直接使用：

```text
anime style character portrait sheet, the same young engineer shown three
times side by side, bust-up, equal spacing, not touching, identical face
hairstyle and outfit in all three: wearing a white and teal-gray sealed
exosuit with the helmet clipped to the chest, short dark hair, a faint
cyan glow at the collar seal, one small amber shoulder light; left calm
neutral expression, middle confident slight smile, right alert serious
expression; clean sharp lineart, soft cel shading, muted industrial
sci-fi palette with cyan and amber accents, plain dark gray background,
no text, no watermark
```

- 主角人设未定：要指定性别、发型或气质，直接改 `young engineer` 与 `short dark hair` 等措辞；定稿 1 张后作为主角立绘基准，后续表情差分挂它做参考。
- 2026-07-14 已定稿：`S6` 会话 `p1_protagonist_portraits_v2`（年轻亲和向、三表情辨识度最高），存 `assets/reference/protagonist-portrait-anchor.png`；后续表情差分与角色界面立绘挂它做参考。
- 审阅只看三点：三个表情是否同一人、线稿是否干净、色调是否与世界层青 / 琥珀语义呼应。

## 特效说明

发光、烟雾、火花、粒子用 Godot 粒子系统和 shader 实现，不用 AI 生成；只有污染贴花这类地面贴图走生成管线。

## 产出提交与审阅流程

1. 默认一个素材类别一个会话、每轮至多 3 次生成且每次 1 张；每轮结束先停手并更新 manifest。萝卜SAMA明确授权后可在原会话追加一轮，或在前一类别收口后切换到点名的新类别；新类别必须独立落盘并从首轮 `0 / 3` 计数。
2. 每批建目录 `assets/art-intake/YYYY-MM-DD-batchNN/`；项目用图每次生成后即复制到该批次。
3. 命名 `编号_名称_v候选号.png`；整版把编号连写。
4. 生成会话默认只生成与落盘，并在本批 `_manifest.md` 记录 thread ID、源路径、候选编号和未完成清单；审阅、归一、接入默认在独立执行会话进行。萝卜SAMA明确指定当前会话继续某个命名阶段时，可在 manifest 更新后切换到该阶段，授权不自动覆盖后续阶段；中断后先清点再补，不盲目重试。
5. 审阅清单（对执行 agent 说“审阅 art-intake 最新一批”）：
   - 视角是否统一为高斜角俯视：设备顶面最大 + 一圈可见侧壁高度带（有厚度、不扁平、不回立面）；角色为俯拍头肩主导读法。
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
