# Free Asset Pack Candidates

更新时间：2026-07-12

## 用途与筛选标准

本文是像素美术管线可用的 CC0 免费素材包候选清单，与 [Pixel Art And Grid Standard](pixel-art-and-grid-standard.md) 的归一管线配合。像素路线下，CC0 像素包与 AI 出稿是并列基底，而非单纯兜底。

筛选标准：

- 授权允许免费商用；优先 CC0（无需署名、可修改）。
- 像素或低分辨率俯视 / 近俯视，能归一到 32px 网格与限定调色板。
- 题材接近工业科幻、基地建设或至少风格中性可调色。
- 明确排除：NC（禁商用）、ND（禁修改，和统一调色 / 归一流程冲突）。

## 首选候选（按用途）

### 整体兜底与设备补位

- Kenney Sci-Fi RTS：<https://kenney.nl/assets/sci-fi-rts>
  - CC0，120+ 资产：俯视科幻建筑、载具、单位、地形 tile，含矢量源文件。
  - 与本项目基地设备语言最接近；AI 批次失败时可整体兜底一版首屏。
- Kenney 全站 30000+ 资产均为 CC0：<https://kenney.nl/assets>

### 角色与动画补位（AI 管线最大缺口）

- CHROME DISTRICT（booliebuilds）：<https://booliebuilds.itch.io/chrome-district>
  - CC0，20 个像素角色、8 方向 6 帧行走、含 top-down 视图，56x84 单元格透明底。
  - 赛博朋克配色偏霓虹，引入前需统一调色向锚点色域靠拢。
- Kenney Top-down Shooter：<https://www.kenney.nl/assets/top-down-shooter>
  - CC0，580+ 正俯视角色与武器 sprite，可作玩家 / 敌人临时形象。

### 特效与 UI

- Kenney Particle Pack：<https://kenney.nl/assets/particle-pack>，CC0 特效贴图。
- Kenney UI Pack Sci-Fi：<https://kenney.nl/assets/ui-pack-sci-fi>，CC0 科幻 HUD 皮肤，后续 HUD 正式化可用。

### 备选与观察

- Sci-Fi Facility Asset Pack（OpenGameArt）：<https://opengameart.org/content/sci-fi-facility-asset-pack>
  - CC0，16px 像素设施内景与 4 方向角色；像素路线下由“分辨率不匹配”升为可归一候选，按整数倍放大对齐 32px 网格。
- FoozleCC Sci-fi Lab tileset（OpenGameArt / itch）：像素实验室内景 tile，引入前需逐包核对 license。
- helleworld Industrial/SciFi top-down tileset：<https://helleworld.itch.io/industrialscifi-top-down-tileset>
  - 免费商用但 CC-BY-ND 禁止修改，与统一调色 / 归一流程冲突，不作主用；仅可原样参考构图。

## 浏览入口（继续挖掘时使用）

- itch.io 免费 2D 科幻俯视：<https://itch.io/game-assets/free/tag-2d/tag-science-fiction/tag-top-down>
- itch.io 全站 CC0 资产：<https://itch.io/game-assets/assets-cc0>
- OpenGameArt CC0 合集：<https://opengameart.org/content/cc0-resources>

下载前逐包确认 license 页；itch 上同名包可能多版本授权不同。

## 使用策略

- 像素路线下 CC0 像素包与 AI 出稿并列作为世界层基底；角色行走动画优先由像素素材包承担，AI 出稿补题材专属设备与地貌。
- 同一画面层级只用一个来源家族，避免混搭观感；素材包资产引入前必须过一次归一（整数缩放到 32px 网格 + 调色板量化），向限定调色板靠拢。
- 下载由萝卜SAMA 在浏览器完成，zip 解压到 `assets/third-party/<pack-name>/`，保留包内 license 文件；该目录不进版本库。
- 实际用到的文件经去底、归一、调色后拷贝进 `client/assets/`，并在本文记录来源与授权；CC-BY 类素材同时在 credits 记名。
