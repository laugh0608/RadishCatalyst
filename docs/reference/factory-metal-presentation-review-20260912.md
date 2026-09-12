# Factory Metal Presentation Review — 2026-09-12

用途：记录工厂 P3 原生 Metal 呈现链路的已证事实、错误关联复盘与取证边界。
何时阅读：需要判断下一项性能诊断是否能带来新信息时；当前顺位见 [Daily Start](../planning/daily-start.md)。
细节去向：原始轨迹和一次性分析脚本保留在忽略的诊断目录；本文件承接 [W37 周志](../devlogs/2026-W37.md) 的原生轨迹及限帧批次细节。

## 本轮结论

- 既有轨迹的离线核对已收口：确认 drawable 等待存在，并校正呈现回调时间的导出异常；没有证明某个 drawable 的回收导致某次等待结束。继续导出同类无标识事件不能补齐此缺口。
- 下述屏幕延迟与帧间隔是不同指标。流水线可以在约三个刷新周期后显示较早提交的帧，同时继续每周期产出新帧；不能把提交至显示延迟当成每帧串行阻塞，或据此认定三缓冲是故障。
- 原配置短测仍超 16.7 毫秒预算，60 FPS 上限未改善。没有依据修改驱动、同步、缓冲数量、画质或生产规则；四档长测仍待短测稳定后执行。

## 数据、时钟与对象核对

本轮仅分析已有 `native-capture-20260912-201839/metal.trace`，没有启动 Godot 或重新采集。批次根为 `tools/runtime-intake/check-runs/factory-foundation-v1/gpu-breakdown-20260912/`，目标 PID 30668；引擎为 Godot 4.7 stable official，构建 hash `5b4e0cb0fd279832bbdd69fed5354d4e5ad26f88`。原采集范围与失败预算见后文历史批次。

| 核对 | 结果 | 可以支持的判断 |
| --- | --- | --- |
| 原始 CoreAnimation `0x50` 等待 START / END | 按线程重建 581 对，与导出等待区间逐条相等；另有首端 1 个 END、末端 1 个 START | 等待时长可信；事件四个参数均为 0，没有 drawable 身份 |
| 原始 `0x51` 呈现回调时间 | 581 个原始呈现时间换算后与最近显示交换时刻差值最大 83.704ns | 时钟换算通过交叉验证；时间重合不建立 drawable 与物理 surface 的身份关系 |
| 回调抵达与呈现时刻差 | p50 0.326ms、p95 4.524ms、最大 6.815ms | 不能把回调抵达时间直接当成屏幕呈现时刻 |
| Instruments 显示依赖与命令提交 | 361 条包含目标帧 / surface 的显示标签中，319 条的帧号、surface 与提交时刻完全匹配；42 条提交时刻不一致，保留并排除 | 319 条已核对子集的提交至显示 p50 49.066ms、p95 56.919ms、最大 65.178ms；不代表全部帧，不是回收或纯 GPU 时长 |

`handlers.xml` 的 `at-time` 导出值不在正确的轨迹时间范围。原始第三参数按 IEEE754 double 解码为秒，采用记录中的 `time-info`：原点 `7019367029282` Mach ticks，timebase `125/3`，转换为 `raw_seconds × 1e9 − origin_ticks × 125/3` 纳秒。浮点换算使用有理数中间值，与 `swaps.xml` 交叉核对。此前帧间隔、GPU 活动与等待统计未使用该异常字段，不受此项修正影响。

本机 Instruments 建模源位于 `Instruments.app/Contents/Packages/GPU.instrdst/Contents/Extensions/`。`com.apple.metalsystrace-common.dtac/modeling-rules/rules-0002.clp` 定义回调解码及时间转换；`com.apple.metalsystrace-display.dtac/modeling-rules/rules-0003.clp` 定义目标进程依赖选择与 CPU-to-display latency 为显示开始减 commit time。本次还用 `frame-assignment.xml` 的目标 PID、present 标记、frame、surface 和 commit time 逐条核对；42 条不符项未强行纳入。模型标签与所选最新依赖可能不同，不能仅解析标签就声称全部已关联。

[Apple 的呈现回调文档](https://developer.apple.com/documentation/metal/mtldrawable/addpresentedhandler(_:))建议按 drawable 的呈现时间测量；原始时间也符合 [present(at:) 的 Mach 绝对秒时钟契约](https://developer.apple.com/documentation/metal/mtldrawable/present(at:))。这里记录的是本机导出字段异常，不推广为所有版本工具都有相同问题。

## 否决的关联与失败复盘

Present 请求中的 Surface ID 为 295 / 410 / 426；回调 Drawable ID 为递增对象标识；CAMetalLayer signpost ID 是队列标识；合成后物理显示 surface 又是另一组 ID。这些命名空间不能直接连接。

曾试用 `0x55` 合成事件 seed 数值等于 Drawable ID，并选取同 surface 最近的先前请求。虽然有 580 个数值重合、578 条候选满足时间先后和唯一性，但 361 条能与显示标签比较的候选 surface 全部不一致。例如回调 drawable 1410 对应候选 surface 295，而 481928750ns 的显示模型记录目标 Frame 3 / Surface 426。此候选已否决，推算的请求至显示延迟已从最终结果撤回；数值相等和时间有序不等于身份正确。

一次性脚本初次读取显示标签时未兼容空格且取错延迟列，终止于空列表错误；依据导出结构修正正则与字段列后重跑成功。最终脚本明确检查错误候选的独立反例，不将早期中间值作为诊断结论。

最终新增证据：`handlers.xml`、`surfaces.xml`、`swaps.xml`、`ca-kdebug.xml`、`frame-assignment.xml`、`drawable-audit.json`、逐条核对的 `display-frame-audit.json`；脚本为批次根下 `audit-drawable.py`。它验证 581 对等待、581 个换算时刻、否决候选及 319 条提交 / 显示对应，42 条不符项完整保留。全部产物继续忽略提交，不复制原始环境信息到正式文档。

## 实际构建源码审计（接续完成）

只读取得上述构建的 12 个相关源码文件，共 912,950 字节，存于同一忽略诊断目录；`source-audit-manifest.json` 记录文件大小与 SHA-256。只读比较 4.7.2 的 `rendering_device.cpp`、`rendering_context_driver_metal.cpp`、`rendering_device_driver_metal3.cpp`，三份均逐字相同。这只排除这三处已有直接改动，不能推断所有版本行为相同或升级绝无收益。未下载完整源码、安装构建依赖或修改引擎。

### 正常窗口的调用顺序

| 层次与具体位置（本次固定构建） | 已核实行为 |
| --- | --- |
| 项目 `client/scripts/factory/hud.gd:47` | 一个独立 3D SubViewport 输出给 TextureRect，保留 4× MSAA；项目没有主动强制绘帧或原生 drawable 持有代码 |
| `RendererViewport::draw_viewports`，`renderer_viewport.cpp:979` | 收集视口输出后调用窗口合成；常规 RD 路径此处未提交渲染图 |
| `RendererCompositorRD::blit_render_targets_to_screen`，`renderer_compositor_rd.cpp:42` | 先调用 `screen_prepare_for_drawing`，再记录窗口 blit |
| `RenderingDevice::screen_prepare_for_drawing`，`rendering_device.cpp:5377` | 调用 swap-chain acquire；常规非 resize 路径没有提前 `_end_frame` / `_execute_frame`。注释的“提交之后”不能代替实际调用证据 |
| `SurfaceLayer::acquire_next_frame_buffer`，`rendering_context_driver_metal.cpp:181` | 直接调用 `layer->nextDrawable()`，再保存 texture 指针；此处没有延迟取得的代理 |
| `RenderingServerDefault::_draw`，`rendering_server_default.cpp:109`；`RenderingDevice::swap_buffers`，`rendering_device.cpp:7868` | 在视口 / 窗口 blit 之后调用帧末处理；`_end_frame` 执行 `draw_graph.end`，随后 `_execute_frame` 提交 |
| 默认 `_execute_and_present`，`rendering_device_driver_metal3.cpp:297` | 最后一个命令缓冲注册 present，随后 commit；不是默认等 GPU 完成回调后才注册呈现 |

源码链接：[RenderingDevice](https://github.com/godotengine/godot/blob/5b4e0cb0fd279832bbdd69fed5354d4e5ad26f88/servers/rendering/rendering_device.cpp)、[窗口 Surface](https://github.com/godotengine/godot/blob/5b4e0cb0fd279832bbdd69fed5354d4e5ad26f88/drivers/metal/rendering_context_driver_metal.cpp)、[Metal 提交](https://github.com/godotengine/godot/blob/5b4e0cb0fd279832bbdd69fed5354d4e5ad26f88/drivers/metal/rendering_device_driver_metal3.cpp)、[视口调度](https://github.com/godotengine/godot/blob/5b4e0cb0fd279832bbdd69fed5354d4e5ad26f88/servers/rendering/renderer_viewport.cpp)、[窗口合成](https://github.com/godotengine/godot/blob/5b4e0cb0fd279832bbdd69fed5354d4e5ad26f88/servers/rendering/renderer_rd/renderer_compositor_rd.cpp)。

因此已形成具体假设：窗口 drawable 等待位于本帧渲染图最终编码 / 提交之前，可能压缩后续 CPU 编码和 GPU 执行的时间余量。这是可测的提交顺序问题，不等于已证唯一瓶颈；不能直接把等待的 19.225ms 当成可节省的时间。[Apple 的 drawable 指南](https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/Drawables.html)建议在离屏编码之后、屏幕编码之前尽晚获取。指南本身不要求每个离屏 pass 单独 commit，不能据此盲目拆分命令缓冲。

### 生命周期与运行证据边界

- `SurfaceLayer::present` 在登记 present 前清空 frame-buffer texture 和 drawables 槽位；`MDFrameBuffer::unset_texture` 只是 raw pointer 清零，不是 Objective-C release。`MDCommandBuffer::commit` 在 commit 后 reset 自身 SharedPtr。`os_macos.mm:1133` 的主循环迭代在 autorelease pool 内，不能把指针清零时刻当成系统实际回收时刻。
- `GODOT_MTL_OFF_SCREEN=1` 选择另外的 SurfaceOffscreen；`GODOT_MTL_FORCE_BARRIERS=1` 才允许实验 barrier 分支，后者有 completed-handler 呈现路径。这两个变量均不在本次 TOC 环境记录内，启动脚本也未设置；正常分支是本轮源码假设，后续诊断须显式记录实际分支值。未启用这些变量进行试验。
- 原始等待事件发生在 Main Thread，但 user stack 为缺失值；既有 sample 的 Godot 地址未符号化，`nm -C` 未解析出目标函数。不能声称已有实机堆栈已逐函数证明源码链路，或已排除二进制与源码的所有差异。
- 既有提交记录按连续等待时间分段：580 个完整间隙中，526 段有 2 次目标命令提交，27 段有 4 次，27 段没有；等待区间内未记录目标命令提交。`commit-order-audit.json` 保留逐段数据，只支持时间顺序，不代表这些命令一定是离屏 / 屏幕拆分。
- 首次按 Instruments frame number 配对等待未通过一一对应断言，已否决该关联方式；最终分段只使用原始 commit 时间与等待时间。没有把一帧两个 command buffer 自动解释为“离屏工作已提前提交”。

## 下一步：隔离引擎诊断构建方案（待授权）

源码审计已完成，没有足够依据修改项目玩法 / 渲染配置。下一项应检验上述顺序假设；不再重复现有原生轨迹的身份推算或限帧值扫描。此方案只增加诊断标记，第一轮不改获取顺序、不换驱动、不拆分命令缓冲。

### 改动点与输出

1. 在 `SurfaceLayer::acquire_next_frame_buffer` 的 `nextDrawable` 前后记录统一单调时间、线程、frame / acquisition 序号，以及返回对象的 drawable ID 和 texture 身份；开始事件不伪造尚未知的 drawable ID。记录实际 Surface / barrier 分支和构建 hash。
2. 在 `RenderingDevice::_end_frame` 的 `draw_graph.end` 前后、Metal command commit 前后记录相同帧序号及 command 身份，以分清图记录、实际编码、提交和系统等待。标记用运行期开关控制，关闭时不输出；使用现有日志基础和标量 ID，不新增对象持有。
3. 在注册 present 与清空应用槽位处记录事件，明确它们不等于系统回收。若需要呈现回调，单列 callback 抵达与 `presentedTime`，不捕获额外 drawable 强引用；无法验证安全生命周期时先不加该回调，复用原生呈现事件。
4. 禁止逐帧同步写盘或用回调延长资源生命周期；先验证事件完整性与开销。保留现有采样失焦即停、双存档根隔离和用户点击准备页的规则。

### 命令、落盘与成本边界

- 使用固定构建 hash 的源码归档，获取命令为 `curl --fail --location --max-time 120 https://codeload.github.com/godotengine/godot/tar.gz/5b4e0cb0fd279832bbdd69fed5354d4e5ad26f88 --output source.tar.gz`。源码、构建目录、虚拟环境与日志全部限定到 `tools/runtime-intake/check-runs/factory-foundation-v1/engine-diagnostic-20260912/`，不写兄弟仓库，不替换 `/Applications/Godot.app`。
- 本机已找到 clang++ 与完整 Xcode 路径，PATH 中未找到 SCons；这些只说明工具存在，尚未验证构建兼容性。授权后执行 `python3 -m venv .venv` 和 `.venv/bin/python -m pip install 'scons>=4.0,<5'`，记录实际解析版本 / 包 hash，不安装全局依赖。
- 预定构建命令为 `.venv/bin/scons platform=macos arch=arm64 target=editor dev_build=no debug_symbols=yes -j6`；执行前按该提交 SConstruct 核实选项，输出独立诊断二进制。使用项目原有功能配置，不通过裁剪渲染功能缩短构建来改变负载。
- 源码下载体积与编译峰值尚未测量；预留上限为 512MiB 源码归档、20GiB 隔离目录，超限先停下说明。编译会持续占用 CPU、可能需要数十分钟，这是估计，不承诺完成时间。本机当前可用空间约 469GiB。
- 此次请求的授权仅覆盖取得源码、隔离 SCons 安装、诊断标记实现与本地构建；不涵盖系统配置、依赖升级、正式引擎替换、发布或推送。窗口验证仍先告知，并使用已有准备页等待用户点击。

### 验证与停止条件

- 先验证编译、事件序号 / 时钟和无资源持有增加；同快照原图与状态必须一致。依次比较当前官方二进制、诊断构建标记关闭、标记开启，构建差异与采样开销分开，不以诊断帧时间代替验收。
- 首轮只回答：实际分支是否符合上述调用链、等待前后实际编码 / 提交在何处、迟交付是否对应 GPU 队列空隙。若不符，否决假设并保留数据；若只有显示节奏等待而无可获益空隙，不继续拆分提交。
- 只有这些证据支持后，才提出延迟获取或离屏提前编码 / 提交的具体引擎补丁及同步风险；不在同一轮边测边改以混淆原因。系统回收事件若仍不可观测，保留因果缺口。

本轮未执行构建或窗口验证。帧预算、四档前台长测、完整客户端 Godot 套件、Windows 和亲测状态保持不变。

## 历史批次记录

以下两轮记录从 W37 周志移入，保留当时的验证与待办状态；当前接续以上文为准。

## 2026-09-12：原生 Metal 轨迹取得与等待链路收窄

- 萝卜SAMA要求继续后，自动入口 `performance-1789215271-30213` 在启动阶段收到失焦事件，未进入生产；记录为失败准备，不推断由用户切窗导致。随后提出手动开始，但聊天确认选项未被用户看到，当时确实没有游戏窗口。说明清楚后实际打开共用准备页，由用户点击；不把聊天确认或准备页等待记为采样。
- `native-capture-20260912-201839` 启动日志确认准备页约 80 毫秒就绪；用户点击后经隔离正式 Boot 进入 PID 30668，暂停预热 15 秒，再运行原配置生产。`capture-native.py` 在预热结束后附加实际 PID，不请求焦点、不修改系统设置，也未使用全进程附加或跳过隐私提示参数。
- `xcrun xctrace record --template 'Metal System Trace' --attach 30668 --time-limit 10s` 实际执行并保存 `metal.trace`，退出码 0；TOC 核实目标 PID 与采集时间为 Asia/Shanghai `20:19:05.245–20:19:16.151`，持续 `10.905949s`。命令从 UTC `12:19:03.163` 运行到 `12:20:54.109`，后续整理 / 写盘不算采集时长。轨迹对应正式生产约 `2.058–12.964s`，Godot 日志保留生产起止的单调时间与系统时间用于对齐。
- 轨迹、TOC、GPU / 提交 / 等待 / 显示导出 XML、原始命令日志、`native-summary.json` 与分析脚本均保留在 `tools/runtime-intake/check-runs/factory-foundation-v1/gpu-breakdown-20260912/` 对应批次；原生 GPU 时间不再是缺失项。即使单 PID 附加，系统轨迹仍含共享 GPU / 显示事件，分析按 Godot PID 筛选；未将其他进程事件当成 Godot 工作。

| 同一轨迹内的观察 | 样本与结果 | 解释边界 |
| --- | --- | --- |
| Godot GPU 活动区间 | 13,293 条目标事件；剔除首尾边界帧后 581 个帧组，并行通道 / 重叠层级求并集，逐帧 p50 `10.293ms`、p95 `15.073ms`、最大 `20.686ms` | 这是轨迹标记的 GPU 活动，不含整帧所有 CPU / 显示等待；不替代性能验收 |
| 每帧首个至最后 GPU 事件跨度 | 同 581 帧，p95 `15.889ms`、最大 `22.818ms` | 含事件之间空隙，与活动区间并集分别记录 |
| 等待可用 drawable | 581 次，p50 `13.075ms`、p95 `19.225ms`、最大 `27.687ms` | 与 GPU 工作存在并行重叠，不能与上述分位数相加或相减 |
| 等待与活动的时间交叠 | 等待并集 `6.913s`，其中与 Godot GPU 活动重叠 `2.984s`；与轨迹记录的全部 GPU 活动重叠 `5.768s` | 不能把目标 GPU 未执行的全部时间都称作硬件空闲；也不能由交叠证明其他应用导致卡顿 |

- [Apple 的 nextDrawable 契约](https://developer.apple.com/documentation/QuartzCore/CAMetalLayer/nextDrawable())说明它等待可用 drawable；本次等待事件使帧提交 / 显示链路成为明确的后续验证对象。GPU 本身仍有长事件，原生采样也增加开销，不能断言问题全部属于同步、某个效果或驱动。另一导出记录到目标的最短显示请求为 4 毫秒，但该参数不是实际帧间隔，也不据此修改系统刷新率或引擎。
- 完整生产批次 `performance-1789215524-30668` 实际 `90.003363s`，8 项中仅帧预算 1 项失败，无中断；完成 1,800 步、交付 225 件，余量 `<0.05s`，计时差额约 `9.63e-12s`。3 次采样内自动保存全部成功，耗时 `112.367 / 108.375 / 117.544ms`；最终保存 `96.718ms`。帧 p95 `21.227ms`、模拟步 p95 `3.329ms`、绘制调用 p95 494；这些是该 90 秒生产轨迹的观察，不直接归因于代码变化。
- 按轨迹时间选取的正式帧间隔 p95 为 `28.649ms`，轨迹结束后为 `20.986ms`；后续 Instruments 整理仍在运行，不将后段声称为独立无干扰对照。完整结果保留所有保存停顿和受采样影响帧，不删除失败数据以过线。
- 正式采样窗口报告 `1920×1080`、3D `1728×894`，基准内容图 `1728×1080`；默认 Metal / Forward+、4× MSAA、VSync 和缩放保留。`native-metal.png` 原图已审阅，SHA-256 仍为 `a8c0538d8f84e167101c61c62f856cf231d3c70bcef3422bbc9e131a4497fee2`；本轮无产品代码、画质或存档格式变更。
- 后续一次性 `frame-cap.gd` 已准备并通过 Godot 无窗口 `--check-only`：同一快照按原不限帧 / 临时 60 FPS / 恢复三段，各预热 15 秒、生产 45 秒；只修改测试进程的 `Engine.max_fps`，VSync 和画质不变，结束或中断后恢复原值，不启用额外 GPU 时间戳。对照尚未运行；主动限制提交能否改善等待仍是假设，不直接修改正式配置。[Godot Engine 文档](https://docs.godotengine.org/en/4.7/classes/class_engine.html#class-engine-property-max-fps)作为该参数契约参考。
- 本轮关闭了“尚无有效原生 Metal 轨迹”的缺口，下一步入口与当前规划同步；四档长测、完整客户端 Godot 套件、Windows 和用户亲测保持未完成。窗口已自动结束，不继续自动开窗；分析在本地进行，未推送或发布。
- 收口验证：临时限帧入口无窗口语法检查、文档预算、仓库治理（1,746 文件）和 `git diff --check` 通过；本轮产品代码未改，不宣称完整客户端运行时回归通过。正式文档保存为本地提交，轨迹与临时入口继续留在忽略目录。

## 2026-09-12：60 FPS 对照完成，暂不采用主动限帧

- 首次 `frame-cap-a.log` / `performance-1789217009-33155` 经点击进入正式工厂，在首段准备时失焦；2 项中 1 项中断失败，`phases=[]`，尚未进入 60 FPS 段。萝卜SAMA随后明确是不小心切换其他窗口，并要求重跑；该批次无需归因于准备页或修改焦点策略。原 `max_fps=0`、VSync 1 已恢复，失败记录保留。
- 按明确要求启动 `frame-cap-b.log`，用户点击准备页后完成 `performance-1789217214-33714`。22 项中仅三段帧预算失败，无中断；全部来自双根隔离的正式 Boot、同一合法 90 秒模型快照，每段暂停预热 15 秒后真实生产 45 秒，未启用 Instruments 或额外 GPU 时间戳。
- A1 / 临时 60 FPS / A2 的活动时长分别为 `45.014159 / 45.005854 / 45.013485s`；帧 p95 `20.131 / 20.772 / 18.104ms`，模拟步 p95 `3.506 / 3.808 / 3.804ms`；采样内自动保存 `108.324 / 108.938 / 116.186ms`。逐帧数据与完整分位数保留在同批次结果，不在周志重复展开。
- 每段完成 900 步、交付 125 件，余量 `<0.05s`，计时差额约 `5.3–7.1e-13s`；每段一次采样内自动保存成功，最终保存亦成功。完整帧保留保存尖峰，不能只按平均接近 60 FPS 判定通过；本轮三个中位数也略高于 16.7 毫秒。
- `profile.json` 明确记录三段上限 `0 / 60 / 0`、全程 VSync 1，结束恢复 `max_fps=0` / VSync 1。实际 3D `1728×894`，窗口报告 `1920×1080`，4× MSAA、缩放 1 与画质不变；绘制调用 p95 三段都是 508。三张基准图 SHA-256 同为 `a8c0538d8f84e167101c61c62f856cf231d3c70bcef3422bbc9e131a4497fee2`，限帧段原图已审阅。
- 临时 60 FPS 上限没有改善整帧 p95，恢复原设置后反而更低；保留运行时波动的限制，不归因于限帧的长期效果，也不声称测到了等待时间下降。本轮没有额外 GPU / drawable 计时，不能拿整帧差额充当该环节耗时。当前证据不支持采用主动限帧，正式代码 / 配置不改；该三段对照不重复列为待执行。
- 在已有 `native-capture-20260912-201839/present.xml` 上补离线关联：按相同 command-buffer ID 将目标 PID 30668 的 582 次 present 请求与完成事件匹配，581 次一一匹配、1 次无完成记录；已检查无重复完成或负间隔。请求至完成 p50 `10.751ms`、p95 `15.775ms`、最大 `22.545ms`，相邻请求间隔 p95 `22.103ms`。这些值包含命令排队和 GPU 工作，不是纯 GPU 执行或屏幕显示延迟，不与 drawable 等待分位数相减。脚本 `analyze-present-completion.py` 与逐条关联的 `present-completion-summary.json` 保留在忽略的诊断目录，未再启动窗口。
- 后续先核对同一 drawable 呈现 / 回收的对象标识和时钟语义，再与已取得的等待事件对应；不能靠猜测关联字段、调整缓冲数量或继续盲试参数来宣布根因。四档长测仍未启动，完整客户端 Godot 套件、Windows 和用户亲测保持待验；本轮未修改产品实现、系统或正式存档，未推送或发布。
- 收口检查：文档预算、仓库治理（1,746 文件）及 `git diff --check` 通过；完整对照日志只有三项已记录的帧预算失败，无脚本错误。结果与接续记录进入本地提交，临时入口和产物按规定留在忽略目录。
