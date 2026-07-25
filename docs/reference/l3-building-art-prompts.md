# L3 Building Art Prompts

更新时间：2026-07-25

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

L3-C 已于 2026-07-25 使用 V1 通过硬判据和 32px 工业地板审阅，并归一为上 / 右 / 下 / 左四个 32×32 运行时帧；本段保留为定稿来源与后续同族参照，不据此追加生成。

## L3-D 反应器四向端口

`assets/reference/pixel-style-anchor.png` 是已批准反应器母版，不只作风格参考；当前 96px `reactor.png` 只补运行时剪影参照。使用 precise-object-edit 口径，先像素级复制母版四次，再只添加端口：

```text
duplicate the approved reactor master four times pixel-identically in one
horizontal row; do not reinterpret, redraw, upscale-detail, heighten, simplify
or redesign any part of the body; add exactly two small flush docking modules
to the visible top surface of each base outside the cylinder, one amber output
and one dark-teal input with one cyan notch; the two modules form one rigid
straight 180-degree-opposed pair and rotate together around the unchanged body;
copy 1 output at screen top and input at screen bottom; copy 2 output at screen
right and input at screen left; copy 3 output at screen bottom and input at
screen top; copy 4 output at screen left and input at screen right; exactly one
output and one input per reactor, both visible, no third permanent front port;
all four bodies retain identical silhouette, proportions, side-wall height,
base, frame, cyan chamber pixels and brightness, structural lights, hazard
stripe, wear, camera and top-left lighting; do not rotate the body or lighting;
no arrows, text, cargo, connected conveyor, pipe network, cable, animation,
processing-state change, open tank or extra modules
```

首轮硬判据：

- 四帧必须是现有定稿反应器的同一主体，青色顶腔、框架、底座、状态灯、比例和机位不得漂移；四台不同反应器直接判废。
- 每帧恰好两个端口并作为刚性对置端口对一起旋转：左到右固定为琥珀出料口朝上 / 右 / 下 / 左，暗青入料口在严格对侧；不得保留固定屏幕下缘的第三服务口，端口不得斜向或藏在主体后。
- 缩至约 96px 后，必须仅凭端口颜色和结构区分四向；不得依赖文字、UI 箭头、货物、连接管线或传送带。
- 只生成静态空载端口差分；反应腔亮度、设备状态、外壳开合或加工表现发生变化即越过 L3 边界。

2026-07-25 V1 判废：四帧主体相互接近但相较母版被增高并重设计；琥珀出料口大致按四向变化，青色入料口却固定在屏幕下缘或缺失，未形成严格对置端口对。V2 使用编辑式提示词后端口基数、对置关系和上 / 右 / 下 / 左顺序通过，但青色顶腔、结构灯和机身细节仍逐帧重绘，主体像素不变量失败。

经萝卜SAMA路线复盘，L3-D 不再消耗 V3：改用 `tools/normalize_l3d_reactor_ports.py` 锁定现有 `96×90` 运行时反应器，只在四个受控连接位派生两个严格对置端口。四张运行时 sprite 的主体像素机械一致，96px 与工业地板联系表视觉复核通过；本段提示词保留为失败证据，不再用于追加生成。

## L3-E 储物箱四向舱口

`client/assets/sprites/slice/storage.png` 是当前 `87×88` 运行时身份与比例主参考；`assets/art-intake/2026-07-18-batch03/b3b4_storage_workbench_oblique_px_v1.png` 只补左侧四罐 `2×2` 储存组的高分辨率材质细节，右侧整备台不得进入结果。使用 precise-object-edit 口径：

```text
show the exact same approved compact 2-by-2 bank of exactly four distinct
cylindrical storage silos four times in one horizontal row as four separate
non-touching cardinal docking frames; every copy has one rear-left silo, one
rear-right silo, one front-left silo and one front-right silo, with all four
circular tank tops visible in a square 2-by-2 layout, never a triangular
three-silo cluster; order frames left to right by the direction of one
bidirectional logistics hatch: toward the screen top, right, bottom, left;
preserve the same four tanks in the same 2-by-2 layout, shared screen-axis-aligned base, proportions,
side-wall height, closed lids, fill-level strips and brightness, cyan status
lights, amber structural lights, hazard stripe, wear, camera and top-left
lighting in all four frames; add exactly one compact recessed dark-teal
bidirectional docking hatch per storage bank, with one restrained cyan notch
and one small amber mechanical latch, flush to the specified cardinal edge of
the shared base outside the tanks and fully visible; only the hatch location
changes between frames; the hatch is one physical module, not separate input
and output ports; no second fixed port, no arrow, text, cargo, item, connected
conveyor, pipe, cable, open lid, changing fill level, empty/full state change,
animation or four different storage designs
```

首轮硬判据：

- 四帧必须是同一组四罐 `2×2` 储存设备，储罐数量、共用底座、填充条、状态灯、比例、机位和开合状态不得漂移；右侧整备台或四台近似新设计直接判废。
- 每帧恰好一个带青色缺口与小型琥珀锁扣的暗青双向舱口；左到右固定为上、右、下、左，不得斜向、遮挡或保留固定第二舱口。
- 缩至 `87–96px` 后必须仅凭舱口位置和结构区分四向；不得依赖文字、UI 箭头、货物、连接传送带或管线。
- 只生成静态关闭、内容状态不变的方向差分；开盖、填充条亮度变化、空 / 满状态或搬运动画即越过 L3 边界。

2026-07-25 V1 判废：四帧舱口基数与上 / 右 / 下 / 左顺序正确，但主体把批准的四罐 `2×2` 布局简化为三罐三角布局。V2 改用独立裁出的高分辨率四罐储存参考，并逐一锁定后左、后右、前左、前右四个罐位，仍重复生成三罐三角主体。

L3-E 已触发两次失败停手规则，不生成 V3；经萝卜SAMA确认换为 `storage.png` 不可变主体的确定性离线派生。`normalize_l3e_storage_hatch.py` 锁定源哈希，四帧只在上 / 右 / 下 / 左中的一个受控区域覆盖双向舱口，主体其余像素保持一致；`2026-07-25-batch03` manifest 保留两次生成源、完整提示词、失败证据与最终静态资产哈希。

## L3-F 采集器正位重出

2026-07-25 人工复核判定现有 `collector.png` 虽来自视角修正轮，仍朝屏幕右下偏航；它是废稿，不得作为形体或朝向参考。生成时只挂 `assets/reference/pixel-style-anchor.png` 约束家族材质、色板、俯角和左上光：

```text
a single automated alien-crystal collector game sprite on one uniform
near-black background; a compact 2-by-2-tile machine with a perfectly square,
screen-axis-aligned base and exact 90-degree rotational symmetry: one centered
circular crystal intake well on the dominant visible top surface, surrounded
by four identical short cardinal support housings at screen top, right, bottom
and left; no front side, no rear side and no preferred travel direction; high
oblique top-down projection with the top surface as the largest visible plane
and one clear side-wall height band around the base so the machine reads as a
solid volume standing on the ground, not a flat platform decal; dark
desaturated teal-gray metal, restrained cyan intake glow, two small amber
status lights, one narrow yellow-black hazard band, crisp controlled pixel
clusters and top-left lighting matching the approved reactor family; full
machine visible with generous padding; no diagonal yaw, diamond footprint,
isometric rotation, front-facing facade, conveyor stub, output chute, docking
port, pipe, cable, crystal cargo, text, UI, cast scene, floor or watermark
```

首轮硬判据：

- 方形底座边缘必须严格平行于屏幕水平 / 垂直轴；任何右下偏航、菱形足印或单一正面直接判废。
- 主体必须 90° 旋转对称，四个逻辑旋转可映射同一帧；出现传送带短头、出料槽、单侧舱口等方向部件即失败。
- 顶面最大且侧壁高度带明确；近垂直俯视压成贴花、或正立面占主导均失败。
- 目标归一约 96px、2×2 足印，左上光与反应器同族；L4 端口与出料行为不在本图生成。

2026-07-25 V1 判废：方形足印、屏幕轴和四向同构成立，但“中央青色发光采集井 + 厚重环形机身”首先读作反应器，且没有可见钻冠、钻轴、钻孔或液压进给机构。V2 将首要身份硬判据改为钻探采集剪影：大型裸露齿形钻冠围绕中央暗色钻孔，短钻轴明确向下，四个同构液压进给臂从上 / 右 / 下 / 左指向钻头；中央不得使用发光液池、玻璃顶腔、反应釜或能源核心读法。

V2 的齿形钻冠、暗孔、短钻轴和四向液压进给机构形成明确钻探剪影，方形基座屏幕轴对齐且四个机构同构；但人工复核确认大面积平顶、极窄侧墙和全部水平铺开的机构仍使设备像贴地平台，缩至约 96px 后高度会进一步消失，故判废。经萝卜SAMA路线复盘后明确授权 V3 最后一次调用：改为“厚底座高侧墙 + 四向竖直承重塔 / 液压立柱 + 架高钻机头 + 明确向下钻轴”的四级垂直结构，并缩小平顶面积。

V3 的中央螺旋钻轴、架高机头、四座进给塔和厚底座解决了钻探身份与设备高度，但生成结果把方形底座旋成正面角朝下的等距菱形，屏幕轴硬判据失败。本类别首轮 `3 / 3` 已用满，三张均不进入归一或换装；完整提示词、生成源、尺寸和哈希记录在 `assets/art-intake/2026-07-25-batch04/_manifest.md`。

萝卜SAMA明确授权第二轮后，V4 换为 `precise-object-edit`：以 V3 为编辑目标，锁定其钻探身份、厚底座、四座高立柱、架高机头与长钻轴，只把相机从 45° 等距偏航重投影为零水平偏航的屏幕轴高斜角俯视。V4 的基座前后边水平、左右深度边垂直，身份、高度和轴向成立；但人工复核发现支撑落在设备内缘且没有经高位承重框连接中央钻机头，受力路径不可信，故不进入归一。

V5 继续以 V4 为 `precise-object-edit` 目标，只修正支撑结构：四根同构主立柱锚定方形底座后左、后右、前左、前右四个外角，经屏幕轴对齐的高位方框和正交横梁连接中央滑台，钻机头与钻轴位于滑台正下方；钻孔与所有立柱之间保留清楚空隙。V5 同时通过钻探身份、设备高度、屏幕轴足印和连续承重路径四项首轮硬判据；累计调用 `5`、第二轮停在 `2 / 3`。

独立归一以锁定源哈希和主体边界生成 `99×120`、`89×108`、`81×98` 三档透明候选，共享不超过 32 色的量化色板，并在深色隔离底、晶体地与工业地板联系表中比较。`89×108` 中档保留钻头、四角框架、状态灯与高度，同时宽度接近现有 `87×88` 储物箱，获选为运行时换装候选；sprite 替换与 Godot 验证未执行。
