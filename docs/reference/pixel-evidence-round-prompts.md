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

## S4''-R2 正面帧表二轮重出（已完成，2026-07-18）

> 参考链修正一次过（1/2 额度）：每帧面罩清晰居中、无背包、躯干轴垂直、四帧连贯。四方向帧表集齐并已归一换装入库；本段提示词留档。

## S5'' 三向站立帧（当前活跃，2026-07-18 萝卜SAMA裁决：方向性 idle 收尾）

背景：实机复核发现停止移动后朝向丢失且 idle 为迈步姿态；裁决生成三向站立帧接方向性 idle，随包 3 收尾。八方向斜向帧另记后续专题，本段不涉及。

本会话 3 张，每张挂新锚点 `assets/reference/pixel-style-anchor.png`（只借风格）+ 对应方向的达标帧表作角色与朝向参考，附 `same character as the attached engineer walk sheet, keep suit, colors, proportions and facing direction identical; standing still, not walking`。朝向词沿用三方向已验证模板，只把行走改为站立。单张不达标记录后另开会话重出（每张两轮闸门）。

第 1 张（挂正面帧表 `2026-07-18-batch06/d1wd_walk_down_sheet_oblique_px_v2.png`），文件名：`d1s_idle_down_oblique_px_v1.png`

```text
high-angle top-down pixel art game sprite of a lone engineer in a sealed
exosuit standing perfectly still, both feet together planted on the
ground, legs straight, arms relaxed at the sides, no walking, no
mid-step pose, helmet with a large glowing cyan visor clearly visible
and centered on the helmet facing the viewer, one amber shoulder light,
the backpack reactor completely hidden behind the body, not a back view,
no backpack visible, seen from steeply above, facing straight toward the
viewer with the body axis perfectly vertical, both shoulders equally
visible, not turned to either side, no three-quarter view, no eye-level
view, full body, single character, limited palette, clean readable pixel
clusters, crisp pixel edges, strong readable silhouette, light from
top-left, muted colors, plain dark background, no text, no watermark
```

第 2 张（挂侧向帧表 `2026-07-18-batch05/d1w_walk_sheet_oblique_px_v2.png`），文件名：`d1s_idle_side_oblique_px_v1.png`

```text
high-angle top-down pixel art game sprite of a lone engineer in a sealed
exosuit standing perfectly still in strict left side profile, both feet
together planted on the ground, legs straight, arms relaxed, no walking,
no mid-step pose, body seen exactly from its left side, helmet visor
pointing at the left edge of the frame, only the near shoulder visible,
small backpack reactor visible behind the back, torso not rotated toward
the camera, no three-quarter view, no front view, one amber shoulder
light, high-angle top-down view seen from steeply above, full body,
single character, limited palette, clean readable pixel clusters, crisp
pixel edges, strong readable silhouette, light from top-left, muted
colors, plain dark background, no text, no watermark
```

第 3 张（挂背面帧表 `2026-07-18-batch04/d1wu_walk_up_sheet_oblique_px_v1.png`），文件名：`d1s_idle_up_oblique_px_v1.png`

```text
high-angle top-down pixel art game sprite of a lone engineer in a sealed
exosuit standing perfectly still, both feet together planted on the
ground, legs straight, arms relaxed at the sides, no walking, no
mid-step pose, seen from steeply above, facing straight away from the
viewer, back of the helmet and the small backpack reactor fully visible,
no face visible, body axis perfectly vertical, both shoulders equally
visible, not turned to either side, no three-quarter view, no eye-level
view, full body, single character, one amber shoulder light, limited
palette, clean readable pixel clusters, crisp pixel edges, strong
readable silhouette, light from top-left, muted colors, plain dark
background, no text, no watermark
```

审阅判据（执行会话）：双脚并拢站定（无迈步）、朝向与对应帧表一致（正面面罩居中 / 侧面纯侧位 / 背面无脸见背包）、与帧表读作同一角色、48x64 剪影可读、色域同族。

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

## 历史段落归档

2026-07-13 旧 3/4 立面口径的 S1 至 S7 段落已整体归档至 [docs/archive/pixel-evidence-round-prompts-legacy.md](../archive/pixel-evidence-round-prompts-legacy.md)，仅作历史证据，勿用于新生成。
