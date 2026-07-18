# Pixel Evidence Round Prompts (Handoff Sheet)

更新时间：2026-07-13

## 使用说明（先读）

本文是介质证据轮的**拼装完成执行副本**，可整篇丢给生图 AI。规则与批次定义的真相源是 [AI Art Prompt Library](ai-art-prompts.md) 与 [Pixel Art And Grid Standard](pixel-art-and-grid-standard.md)，两处冲突以真相源为准。

给萝卜SAMA：

- 一次生成会话只执行一个 `S` 段落；把本文丢给生图 AI 时，告诉它“本次只执行 S1”（或对应段落）。
- `S1` 已定稿锚点（2026-07-13：`a0_reactor_px_v1`）；`S2` 起每个会话开始先上传 `assets/reference/pixel-style-anchor.png` 作为参考图，并附一句 `match the style, palette and lighting of the attached reference image`。
- 每张图生成后立即保存到该会话的 `assets/art-intake/YYYY-MM-DD-batchNN/`，按段落里给的文件名命名；会话结束在批次目录写 `_manifest.md`（工具、会话 ID、候选编号、未完成项）。
- 生成完成后交执行会话审阅归一，不要自己判定通过。

给生图 AI 的指令：

- 本次会话只执行人类指定的一个 `S` 段落，按顺序逐张生成，每次只生成 1 张，本会话总数不超过 3 张，完成后停止，不要继续其他段落。
- 每张图完整使用对应代码块内的英文提示词，不要自行增删风格词或改变构图要求。
- 画幅：未标注的用方形（1024x1024 或工具默认高清）；标注【横版】的用横向宽画幅。
- 图内不得出现文字、水印或 UI。

负面提示（仅 Stable Diffusion 类工具需要，每张通用）：

```text
blurry, photorealistic, 3D render, painterly, smooth gradients, isometric
room interior, side view, horizon line, sky, text, letters, watermark, UI
frame, border, multiple unrelated objects, human face closeup,
oversaturated, alchemy, magic circle, runes, potion bottles, medieval,
gothic, brass steampunk, fantasy workshop
```

## S3'' 设备重出（视角修正轮包 2，已完成，2026-07-18）

> 三张一次过并经萝卜SAMA实机确认：核心双态 / 储存 + 整备台 / 采集器已归一同名换装入库，采集器足印提 2x2。本段完整提示词见 batch03 manifest 与提示词库；留档勿再执行。

## S4'' / S7'' 角色重出首轮（部分达标，2026-07-18）

> 首轮一个会话跨段生成 3 张：背面帧表 `d1wu` 朝向零偏斜**达标留用**（强朝向词成功对照组）；静态与侧向帧表俯角达标但身体斜向 7-8 点钟方向判不达标（朝向词弱于 3/4 先验），正面帧表因额度用尽未生成。落盘 `2026-07-18-batch04/`；重出走下方 S4''-R 段。

## S4''-R 角色重出二轮（已执行，部分达标，2026-07-18；闸门触发详见周志）

> 结果：侧向帧表纯侧位达标留用；静态与正面均出成背面（背面参考图形象先验压过 facing 词），静态两轮闸门触发停手上报萝卜SAMA裁决。本段提示词留档，后续按裁决执行。

挂新锚点 + 首轮达标的背面帧表 `assets/art-intake/2026-07-18-batch04/d1wu_walk_up_sheet_oblique_px_v1.png` 作角色一致性参考，附 `same character as the attached engineer back-view sheet, keep suit, colors and proportions identical; the anchor machine image is style reference only`。本会话 3 张，只执行本段。

**闸门警示：静态与侧向本段为第二轮，仍出现斜向 / 3/4 转体则触发两轮停手规则，停止生成上报萝卜SAMA（退 CC0 角色基底或人工点修裁决）。**

第 1 张，文件名：`d1_engineer_oblique_px_v2.png`

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

第 2 张，文件名：`d1w_walk_sheet_oblique_px_v2.png`

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

第 3 张，文件名：`d1wd_walk_down_sheet_oblique_px_v1.png`

```text
pixel art sprite sheet of the same character in 4 walk cycle frames,
arranged in one horizontal row, equal spacing, not touching: a lone
engineer in a sealed exosuit with a small backpack reactor, helmet with
glowing cyan visor, one amber shoulder light, high-angle top-down view
seen from steeply above, walking downward toward the bottom edge of the
frame, facing straight at the viewer with the body axis perfectly
vertical, both shoulders equally visible, glowing cyan visor centered,
top of the helmet and shoulders dominant, not turned to either side, no
three-quarter view, no eye-level view, limited palette, clean readable
pixel clusters, crisp pixel edges, light from top-left, muted colors,
plain dark background, no text, no watermark
```

审阅判据（执行会话）：在首轮判据（同角色跨帧稳定、俯拍头肩主导脚在身下、循环连贯、48x64 剪影、色域同族）之上追加朝向判据——静态与正面帧表躯干轴垂直、左右对称、双肩等宽可见、面罩居中；侧向帧表为纯侧面（只见近侧肩、面罩指向画面左缘、无 3/4 转体）；与已达标背面帧表读作同一角色。

## S1'' 视角修正锚点重出：高度增强反应器（已完成，2026-07-18）

> `v2` 已由萝卜SAMA定稿为新锚点并入库 `assets/reference/pixel-style-anchor.png`（高斜角俯视口径）；本段留档。后续段落所说"挂锚点参考图"一律指新锚点。

## S1 风格锚点：基础反应器（同一提示词生成 3 张候选）

> 历史段落（2026-07-13 旧 3/4 立面口径），已被上方 S1'' 高斜角口径取代，仅留档；勿用于新生成。

文件名：`a0_reactor_px_v1.png`、`a0_reactor_px_v2.png`、`a0_reactor_px_v3.png`

```text
top-down 3/4 view pixel art game sprite, industrial sci-fi chemical
outpost on a hostile alien planet, limited palette, clean readable
pixel clusters, dark desaturated teal-gray metal and rock, glowing cyan
energy accents, warm amber work lights, crisp pixel edges, strong
readable silhouette, light from top-left, muted colors, no dithering
noise, no text, no watermark, no UI, single centered subject on a plain
dark background

a squat cylindrical chemical reactor with reinforced metal frame, round
glowing cyan reaction chamber window, amber status lights, short pipe
stubs on both sides, mounted on a dark metal base plate
```

## S2 地面 tile（先挂锚点参考图；3 张各用各的提示词）

第 1 张，文件名：`c1_rock_ground_px_v1.png`

```text
top-down pixel art seamless tileable ground texture, light warm sandy-gray
alien rock and compacted dust with fine dark cracks and scattered pebbles,
limited palette, clean readable pixel clusters, subtle color variation,
low contrast, uniform lighting, crisp pixel edges, muted colors, no text,
no watermark, no borders, no large landmarks
```

第 2 张，文件名：`c2_metal_platform_px_v1.png`

```text
top-down pixel art seamless tileable industrial metal platform floor,
medium warm-gray riveted panels clearly darker than sandy ground, subtle
wear, faint amber hazard line accents, limited palette, clean readable
pixel clusters, low contrast, uniform lighting, crisp pixel edges, muted
colors, no text, no watermark, no borders
```

第 3 张，文件名：`c3_crystal_ground_px_v1.png`

```text
top-down pixel art seamless tileable ground texture, light warm sandy-gray
alien rock with faint embedded cyan crystal veins glowing subtly through
pale stone, fine dark cracks for depth, limited palette, clean readable
pixel clusters, low contrast, uniform lighting, crisp pixel edges, muted
colors, no text, no watermark, no borders
```

## S3 首屏设备（先挂锚点参考图；3 张各用各的提示词）

第 1 张【横版】，文件名：`b1b2_core_states_px_v1.png`

```text
top-down 3/4 view pixel art game sprite, industrial sci-fi chemical
outpost on a hostile alien planet, limited palette, clean readable
pixel clusters, dark desaturated teal-gray metal and rock, glowing cyan
energy accents, warm amber work lights, crisp pixel edges, strong
readable silhouette, light from top-left, muted colors, no dithering
noise, no text, no watermark, no UI, two objects arranged side by side,
not touching, on a plain dark background

the same hexagonal outpost core machine shown twice side by side, two
separate objects, not touching: left version damaged with cracked casing,
exposed wiring, dim flickering cyan core visible through broken panels,
scorch marks and small debris at the base; right version fully repaired
with sealed clean casing, bright steady cyan core, subtle amber running
lights; identical machine design and identical viewing angle
```

第 2 张，文件名：`b3_storage_px_v1.png`

```text
top-down 3/4 view pixel art game sprite, industrial sci-fi chemical
outpost on a hostile alien planet, limited palette, clean readable
pixel clusters, dark desaturated teal-gray metal and rock, glowing cyan
energy accents, warm amber work lights, crisp pixel edges, strong
readable silhouette, light from top-left, muted colors, no dithering
noise, no text, no watermark, no UI, single centered subject on a plain
dark background

a bank of three connected industrial storage silos with fill-level
indicator strips, cyan and amber lights, on a shared dark metal base
```

第 3 张，文件名：`b4_workbench_px_v1.png`

```text
top-down 3/4 view pixel art game sprite, industrial sci-fi chemical
outpost on a hostile alien planet, limited palette, clean readable
pixel clusters, dark desaturated teal-gray metal and rock, glowing cyan
energy accents, warm amber work lights, crisp pixel edges, strong
readable silhouette, light from top-left, muted colors, no dithering
noise, no text, no watermark, no UI, single centered subject on a plain
dark background

a field outfitting workbench with tool racks, hanging gear, a small
terminal screen glowing cyan, one amber work lamp on a pole
```

## S4 角色（先挂锚点参考图；2 张，剩 1 次额度留给失败重出）

第 1 张，文件名：`d1_engineer_px_v1.png`

```text
top-down 3/4 view pixel art game sprite, industrial sci-fi chemical
outpost on a hostile alien planet, limited palette, clean readable
pixel clusters, dark desaturated teal-gray metal and rock, glowing cyan
energy accents, warm amber work lights, crisp pixel edges, strong
readable silhouette, light from top-left, muted colors, no dithering
noise, no text, no watermark, no UI, single centered subject on a plain
dark background

a lone engineer in a sealed exosuit with a small backpack reactor, helmet
with glowing cyan visor, one amber shoulder light, seen from above and
slightly in front, full body, single character, standing pose
```

第 2 张【横版】，文件名：`d1w_walk_sheet_px_v1.png`

```text
pixel art sprite sheet of the same character in 4 walk cycle frames,
arranged in one horizontal row, equal spacing, not touching: a lone
engineer in a sealed exosuit with a small backpack reactor, helmet with
glowing cyan visor, one amber shoulder light, top-down 3/4 view walking
toward the viewer, limited palette, clean readable pixel clusters, crisp
pixel edges, light from top-left, muted colors, plain dark background,
no text, no watermark
```

## S5 二三屏增量（先挂锚点参考图；3 张各用各的提示词）

第 1 张，文件名：`b6_collector_px_v1.png`

```text
top-down 3/4 view pixel art game sprite, industrial sci-fi chemical
outpost on a hostile alien planet, limited palette, clean readable
pixel clusters, dark desaturated teal-gray metal and rock, glowing cyan
energy accents, warm amber work lights, crisp pixel edges, strong
readable silhouette, light from top-left, muted colors, no dithering
noise, no text, no watermark, no UI, single centered subject on a plain
dark background

an automated resource collector machine with a wide intake hopper, short
conveyor stub, partially visible rotating drum, amber hazard stripes
```

第 2 张，文件名：`c4_polluted_ground_px_v1.png`

```text
top-down pixel art seamless tileable ground texture, light warm sandy-gray
cracked soil stained by muted sickly yellow-green residue patches, readable
but not oversaturated, limited palette, clean readable pixel clusters, low
contrast, uniform lighting, crisp pixel edges, muted colors, no text,
no watermark, no borders
```

第 3 张【横版】，文件名：`e1_crystal_clusters_px_v1.png`

```text
top-down 3/4 view pixel art game sprite, industrial sci-fi chemical
outpost on a hostile alien planet, limited palette, clean readable
pixel clusters, dark desaturated teal-gray metal and rock, glowing cyan
energy accents, warm amber work lights, crisp pixel edges, strong
readable silhouette, light from top-left, muted colors, no dithering
noise, no text, no watermark, no UI, objects arranged separately in a row,
not touching, on a plain dark background

clusters of glowing cyan alien crystals growing from dark rock bases,
three separate clusters small medium large, arranged in a row, not
touching
```

## S6 主角立绘（不挂像素锚点；同一提示词生成 2 到 3 张候选）

文件名：`p1_protagonist_portraits_v1.png` 起顺延。【横版】

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

要指定主角性别或发型，直接改 `young engineer` 与 `short dark hair` 措辞（例如 `young female engineer`）。

## S7 方向帧增补（先挂锚点参考图 + d1 静态与侧向帧表作角色参考；2 张，剩 1 次额度留给失败重出）

2026-07-16 包 3.5 增补段落。参考图：`assets/reference/pixel-style-anchor.png`（风格）、`assets/art-intake/2026-07-14-batch02/d1_engineer_px_v1.png` 与 `d1w_walk_sheet_px_v1.png`（角色）。左右朝向由侧向帧表水平翻转承担，本段只出背面与正面。

第 1 张【横版】，文件名：`d1wu_walk_up_sheet_px_v1.png`

```text
pixel art sprite sheet of the same character in 4 walk cycle frames,
arranged in one horizontal row, equal spacing, not touching: a lone
engineer in a sealed exosuit with a small backpack reactor, helmet with
glowing cyan visor, one amber shoulder light, top-down 3/4 back view
walking straight away from the viewer, back of the helmet and the
backpack reactor fully visible, no face visible, limited palette, clean
readable pixel clusters, crisp pixel edges, light from top-left, muted
colors, plain dark background, no text, no watermark
```

第 2 张【横版】，文件名：`d1wd_walk_down_sheet_px_v1.png`

```text
pixel art sprite sheet of the same character in 4 walk cycle frames,
arranged in one horizontal row, equal spacing, not touching: a lone
engineer in a sealed exosuit with a small backpack reactor, helmet with
glowing cyan visor, one amber shoulder light, top-down 3/4 front view
walking straight toward the viewer, glowing cyan visor facing the
camera, limited palette, clean readable pixel clusters, crisp pixel
edges, light from top-left, muted colors, plain dark background, no
text, no watermark
```

## 失败与重出规则

- 某张不满意：先完成本会话其余条目，失败项集中进同类别第二轮会话（文件名候选号顺延）。
- 同类别两轮仍不成：停止，交萝卜SAMA触发决策闸门（退扁平几何风或 CC0 像素包基底），不开第三轮。
- 行走帧表两轮不成只影响动画项（改用 CC0 包），不算证据轮整体失败。
