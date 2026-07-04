# AI Art Prompt Library V1

更新时间：2026-07-04

## 用途与关联

本文是 Demo 表现层重建的提示词库与风格规范真相源，服务 [Demo Presentation Rebuild V1](../features/demo-presentation-rebuild-v1.md)。

- 生成素材接收目录与命名规则：`assets/art-intake/README.md`。
- 免费素材包候选：[Free Asset Pack Candidates](free-asset-pack-candidates.md)。
- 风格锚点图定稿后存放在 `assets/reference/`。

## 全批次统一规则（生成前先读）

1. 整批使用同一个工具生成；中途换工具就重开一批，不混批。
2. 先生成"风格锚点"（第一批的基础反应器），定稿 1 张后，后续所有资产都挂它做图像参考（Midjourney `--sref`、GPT 传图参照、即梦 / 豆包"参考图"）。
3. 每个资产生成 2 到 4 个候选；不满意直接重新生成，不在原图上局部修补。
4. 生成分辨率用 1024x1024 或工具默认高清；缩放到游戏尺寸由仓库侧统一处理，不需要自己缩。
5. 单体资产要求纯色深灰背景或透明背景；支持透明输出的工具（GPT-4o）直接要求 transparent background。
6. 地面贴图必须带 seamless tileable；单体设备必须带 single object, centered。
7. 锚点未定稿前，只生成第一批，不要批量往后跑。

## 全局风格块（每条提示词前都要完整粘贴）

```text
top-down 3/4 view game sprite, industrial sci-fi chemical outpost on a
hostile alien planet, dark desaturated teal-gray metal and rock, glowing
cyan energy accents, warm amber work lights, painted flat shading with
soft ambient occlusion, strong readable silhouette, light from top-left,
crisp clean edges, muted colors, no text, no watermark, no UI, single
centered subject on a plain dark background
```

要点中文对照：俯视 3/4 视角（正面略可见）、工业科幻化工前哨、暗青灰主色 + 青色发光 + 琥珀工作灯、平涂 + 柔和环境光遮蔽、剪影清晰、光源固定左上、无文字水印。

地面贴图使用变体结尾：把最后一句换成 `seamless tileable texture, top-down view, uniform lighting, no borders`。

## 调色板锚点

| 用途 | HEX |
| --- | --- |
| 岩地暗底 | `#151C1E` |
| 金属结构中间调 | `#2E4145` |
| 金属高光 | `#4A6165` |
| 青色能量 / 状态 | `#56C8C4` |
| 晶体亮青 | `#7FD8E8` |
| 琥珀工业灯 | `#E0A43C` |
| 警示红（敌人 / 故障） | `#C7503F` |
| 污染黄绿 | `#B7B646` |

不要求 AI 严格按 HEX 输出；审阅时以"主色是否落在这组色域内"为判据，通过的素材后续再做统一调色。

## 尺寸口径

| 类别 | 游戏内目标尺寸 | 说明 |
| --- | --- | --- |
| 地面 tile | 64px | 贴图按 512 或 1024 生成，可整除切分 |
| 玩家 | 约 56px 高 | 首版只要静态俯视姿 |
| 敌人 | 约 64px | 同上 |
| 一般设备 | 128 到 192px | 反应器、储存、整备台、过滤器、采集器 |
| 前哨核心 | 约 192px | 受损 / 修复两个状态 |
| 核心稳定站 | 约 288px | 全场最大单体 |
| 资源 / 小件 | 32 到 96px | 晶体、残骸、道具 |
| 贴花 | 128 到 256px | 污染渗漏等 |

## 整版与单张出图规则

2026-07-04 起生效：能整版的资产优先整版（一次生成多个对象），省生成次数，且同图内风格、视角、光照天然一致；整版同样出 2 到 3 个候选版。

优先整版：

- 成套小件：B7 管线、B8 小件、E1 晶体簇、E3 岩石、E4 植被（提示词已按整版设计）。
- 状态对：B1 / B2 前哨核心两状态合出一张，同图保证两态同机。
- 中型设备：B3 到 B6 用 2x2 合版；1024 级整版单元格约 500 到 600px，对 128 到 192px 游戏目标仍有约 3 倍余量。

整版约束：

- 设备类密度上限 2x2；对象之间留明显空隙，提示词带上 `arranged separately, not touching, no connecting pipes or cables between objects`。
- 整版允许部分过审：过审单元格由仓库侧裁切定稿，只对未过审对象重出一张更小整版，不因单格失败整版重 roll。
- 拆分、对齐、缩放全部由仓库侧处理，生成侧不需要自己切图。

必须单张：

- 地面贴图 C1 到 C4：可平铺性要求整幅画面本身就是一块 tile。
- B9 核心稳定站：全场最大英雄单体，吃满整幅分辨率。
- 角色 D1 / D2 静态形象；若未来试验 AI 动画帧，必须用"同一角色一整版帧表"方式出（素材包补位优先级不变）。

## 负面提示（Stable Diffusion 类工具使用）

```text
blurry, photorealistic, 3D render, isometric room interior, side view,
horizon line, sky, text, letters, watermark, UI frame, border, multiple
unrelated objects, human face closeup, oversaturated
```

## 第一批：风格锚点（今天只生成这一组）

### A0 基础反应器（风格锚点）

```text
a squat cylindrical chemical reactor with reinforced metal frame, round
glowing cyan reaction chamber window, amber status lights, short pipe
stubs on both sides, mounted on a dark metal base plate
```

- 生成 6 个候选，命名 `a0_reactor_v1.png` 到 `a0_reactor_v6.png`。
- 交给 Claude 审阅，共同定稿 1 张为风格锚点，存 `assets/reference/style-anchor.png`。
- 2026-07-04 已定稿：`2026-07-02-batch01` 的 `a0_reactor_v4`，`v1` 为备选风格参照；后续批次一律挂锚点图生成。

## 第二批：首屏核心设备（锚点定稿后）

### B1 / B2 前哨核心（同图双状态，一张出两态）

```text
the same hexagonal outpost core machine shown twice side by side, two
separate objects, not touching: left version damaged with cracked casing,
exposed wiring, dim flickering cyan core visible through broken panels,
scorch marks and small debris at the base; right version fully repaired
with sealed clean casing, bright steady cyan core, subtle amber running
lights; identical machine design and identical viewing angle
```

同图双状态直接保证两态同机。候选里两台走形不一致就整张重出，不做单边拼补；多次失败再退回两步法：先单出受损态定稿，再挂它生成修复态。

### B3 储存单元

```text
a bank of three connected industrial storage silos with fill-level
indicator strips, cyan and amber lights, on a shared dark metal base
```

### B4 整备台

```text
a field outfitting workbench with tool racks, hanging gear, a small
terminal screen glowing cyan, one amber work lamp on a pole
```

### B5 污染过滤器

```text
an industrial pollution filter unit, boxy machine with layered vent
grilles, one intake pipe and one exhaust pipe, faint yellow-green residue
stains near the intake, cyan status panel
```

### B6 自动采集器

```text
an automated resource collector machine with a wide intake hopper, short
conveyor stub, partially visible rotating drum, amber hazard stripes
```

### B3 到 B6 整版（优先，2x2 一张出四台）

```text
four separate industrial machines arranged in a 2x2 grid, equal spacing,
not touching, no connecting pipes or cables between them: top-left a bank
of three connected storage silos with fill-level indicator strips;
top-right a field outfitting workbench with tool racks, hanging gear and a
small glowing cyan terminal screen; bottom-left a boxy pollution filter
unit with layered vent grilles, one intake pipe, one exhaust pipe and
faint yellow-green residue stains; bottom-right an automated resource
collector with a wide intake hopper, short conveyor stub and amber hazard
stripes
```

四台属性混淆（残渍跑错机器、部件互借）或某台走形时，退回上方单张提示词逐台出。

### B7 管线组（一张图内分开摆放）

```text
modular industrial pipe segments for a top-down game: one straight
segment, one 90-degree corner, one T-junction, one valve unit, arranged
separately in a grid, not touching each other, matching dark metal
material with small cyan fluid windows
```

### B8 小件组（一张图内分开摆放）

```text
small industrial prop set: work light pole, cable spool, toolbox,
pressure barrel, supply crate, arranged separately in a grid, not
touching each other
```

### B9 核心稳定站（P2 用，可后置）

```text
a large core stabilization station, tall central pylon with rotating
stabilizer rings, intense cyan energy column, heavy armored base with
anchor bolts, amber warning lights
```

## 第三批：地面贴图（全部用 tileable 变体结尾）

### C1 异星岩地

```text
top-down alien rocky ground, dark desaturated teal-gray basalt with fine
cracks and scattered pebbles, subtle color variation, low contrast, no
large landmarks
```

### C2 金属平台地面

```text
top-down industrial metal platform floor, dark riveted panels with subtle
wear, faint amber hazard line accents, low contrast
```

### C3 晶体区地面变体

```text
top-down alien ground with faint embedded cyan crystal veins glowing
subtly through dark rock
```

### C4 污染区地面变体

```text
top-down contaminated wasteland ground, sickly yellow-green residue
patches over dark cracked soil
```

平台边缘条优先在引擎内用 C2 切片加深色描边拼装，不单独生成。

## 第四批：角色与敌人（难度最高，允许失败）

AI 出多方向动画帧的一致性很差。本批只要单张俯视静态形象；行走动画优先用素材包补位（见候选清单），引擎内先用旋转加轻微摆动表达移动。

### D1 玩家工程师

```text
top-down view of a lone engineer in a sealed exosuit with a small
backpack reactor, helmet with glowing cyan visor, one amber shoulder
light, standing pose seen from above and slightly in front, full body,
single character
```

### D2 污染爬行体（敌人）

```text
top-down view of an alien pollution crawler creature, low segmented body
with many short legs, dull red-orange carapace, sickly yellow-green
glowing pustules, single creature
```

## 第五批：资源与点缀

### E1 晶体簇（一张图三个尺寸）

```text
clusters of glowing cyan alien crystals growing from dark rock bases,
three separate clusters small medium large, arranged in a row
```

### E2 残骸回收堆

```text
a pile of salvageable metal debris and broken machine parts, dark
scorched metal with a few amber highlights
```

### E3 岩石散件（一张图分开摆放）

```text
a set of alien boulders and small rock formations, dark teal-gray basalt,
arranged separately in a grid
```

### E4 异星植被小件（一张图分开摆放）

```text
small alien flora set: low bioluminescent fungi and spiky plants with
faint cyan glow, arranged separately in a grid
```

### E5 污染渗漏贴花

```text
top-down pollution seep stain decal, sickly yellow-green toxic residue
spreading in an irregular organic blob, soft edges, single blob
```

## 特效说明

发光、烟雾、火花、粒子一律用 Godot 粒子系统和 shader 实现，不用 AI 生成；只有 E5 这类地面贴花走生成管线。

## 产出提交与审阅流程

1. 每批建一个目录：`assets/art-intake/2026-07-02-batch01/`（日期加批次号）。
2. 文件命名：`编号_名称_v候选号.png`，例如 `a0_reactor_v3.png`、`c1_rock_ground_v2.png`；整版把编号连写，例如 `b1b2_core_states_v1.png`、`b3-b6_devices_sheet_v2.png`。
3. 放好后让当前执行 agent 审阅：对它说"审阅 art-intake 最新一批"，按以下清单给出保留 / 重 roll / 修改意见：
   - 视角是否统一为 3/4 俯视、正面略可见。
   - 光源是否来自左上。
   - 主色是否落在调色板锚点色域内。
   - 缩小到游戏目标尺寸后剪影是否仍可读。
   - 细节密度是否过高（AI 常见问题，缩小后会糊成噪声）。
   - 复核方法：设备 / 角色先缩到游戏目标尺寸再看剪影（macOS 用 `sips -Z 160 in.png --out out.png`，或 ImageMagick `magick in.png -resize 160x160 out.png`）；地面贴图做 2x2 拼贴看接缝；审阅结论与定稿记录写入当周周志。
4. 通过的素材由仓库侧统一处理后接入：去底（纯色深底抠图；支持透明输出的工具优先直接出透明 PNG）、按"尺寸口径"表缩放（Lanczos 或工具默认高质量缩放）、明显偏色时按调色板锚点微调；产出存 `client/assets/sprites/` 按类别子目录与英文资产名命名，原始批次不进版本库。
5. 风格锚点、调色板、视角与尺寸口径是架构级口径，执行 agent 只按其生成与审阅，不自行修改；变更升级点见 `docs/process/development-decision-gates.md`。

## 工具备注

- Midjourney：锚点定稿后用 `--sref 锚点图URL` 保持风格；追加 `--no text, watermark`。
- GPT-4o / ChatGPT：直接上传锚点图并说明"参照这张的风格、视角和光源"；可要求透明背景 PNG。
- Stable Diffusion：配合上方负面提示；地面贴图开 tiling 选项。
- 即梦 / 豆包 / 可灵：中文界面可直接粘贴英文提示词，用"参考图"功能挂锚点。
