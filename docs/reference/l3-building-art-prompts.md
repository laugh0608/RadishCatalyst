# L3 Building Art Prompts

更新时间：2026-07-24

## 用途

本文承载 L3 建造放置 + 扩展供电网阶段的像素素材增量提示词和首轮硬判据，避免把阶段资产持续堆入全局提示词库。

执行规则：

- 每条提示词前完整粘贴 [AI Art Prompt Library V2](ai-art-prompts.md) 的全局风格块。
- 双状态、帧表和多对象图把全局块末尾的单体构图改成“对象横向分离排列、互不接触、纯深色背景”。
- 网格、目标尺寸、色板、光向和归一管线以 [Pixel Art And Grid Standard](pixel-art-and-grid-standard.md) 为准。
- 当前玩家路径、L3 / L4 / L5 边界和验收以 [Slice Building Placement And Power Grid V1](../features/slice-building-placement-and-power-grid-v1.md) 为准。
- 单会话生成次数、图片读取数量、落盘和会话拆分继续遵守 `AGENTS.md` / `CLAUDE.md`。

## L3-B 电力中继

接全局风格块，按多对象规则调整结尾：

```text
the same slender upright utility power-relay pole shown twice side by side,
identical geometry and straight screen-aligned orientation: a narrow one-cell
base, a tall thin vertical mast, one compact horizontal crossarm and two small
insulators; total height at least 1.5 times the base width; left unpowered
with cyan fully dark and one red fault lamp, right powered with red off and a
steady cyan lamp plus one short pulse between insulators; no squat platform
machine, transformer box, reactor body, wide equipment base, diagonal yaw,
leaning mast or front-facing facade
```

L3-B 已于 2026-07-24 完成 V5 归一接入；本段保留为定稿来源与后续同族参照，不据此追加生成。

## L3-C 传送带四向直段

接全局风格块，按多对象规则调整结尾：

```text
the exact same compact one-cell straight industrial conveyor segment shown
four times in one horizontal row as four separate non-touching direction
frames, ordered left to right by transport direction: toward the top,
toward the right, toward the bottom, toward the left of the screen; every
frame is the same machine rotated on the cardinal gameplay grid, with an
identical square footprint, identical low side rails, identical short belt
bed, identical materials, wear, lighting and pixel density; north and south
frames have a perfectly vertical belt centerline, east and west frames have
a perfectly horizontal belt centerline; the base remains screen-axis aligned
with no diagonal yaw or diamond footprint; use repeated physical chevron belt
slats pointing toward the output end, a subdued amber drive roller at the
output end and a dark idler roller at the intake end so all four transport
directions remain unmistakable after normalization to 32 by 32 pixels; dark
desaturated teal-gray metal, restrained cyan status accents and small
yellow-black hazard marks shared with the existing machine family; a
low-profile floor conveyor with readable top surface and a narrow side-wall
height band, not a tall machine; no cargo, crystals, items, animation frames,
motion blur, glow trail, curved belt, corner, turn, T-junction, crossing,
splitter, merger, branch, loader arm, pipe, cable, text, letters, numbers,
labels, UI arrows or four different machine designs
```

首轮硬判据：

- 必须是同一台 `1×1` 直段传送带的四个基数方向帧，不是四台不同设备；左到右方向固定为上、右、下、左。
- 纵向帧中心线严格屏幕竖直，横向帧中心线严格屏幕水平；任何斜向摆放、菱形 / 平行四边形足印或等距偏航直接判废。
- 方向由 belt slat、驱动滚筒和输入 / 输出端结构读出；缩至 32px 后仍不能区分四向则失败，不能靠文字、UI 标记或流动物品补读法。
- 只生成直段静态空带；出现物品、转角、合流、分流、交叉或搬运动画即越过 L3 边界。

## 后续条目

L3-D 反应器四向端口和 L3-E 储物箱四向端口在各自独立生成会话开工前补齐；不得在 L3-C 会话中顺带生成。
