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

只读取得上述构建的 12 个相关源码文件，共 912,950 字节，存于同一忽略诊断目录；`source-audit-manifest.json` 记录文件大小与 SHA-256。只读比较 4.7.2 的 `rendering_device.cpp`、`rendering_context_driver_metal.cpp`、`rendering_device_driver_metal3.cpp`，三份均逐字相同。这只排除这三处已有直接改动，不能推断所有版本行为相同或升级绝无收益。该次只读审计未下载完整源码、安装构建依赖或修改引擎；后续授权构建见下文。

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

## 隔离引擎诊断构建方案（原范围已授权）

以下保留实施前方案与授权边界；9 月 13 日实际构建、失败复盘与对照结果见后续批次，不能把方案中的待办当作当前阻塞。方案依据是源码审计尚不足以修改项目玩法 / 渲染配置，需要检验上述顺序假设；不再重复现有原生轨迹的身份推算或限帧值扫描。此方案只增加诊断标记，第一轮不改获取顺序、不换驱动、不拆分命令缓冲。

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

该方案随后分两步获授权：先取得源码与 SCons，再补齐预检发现的三项依赖。构建与窗口对照现已完成，实际结果及剩余证据缺口见下文；四档前台长测、完整客户端 Godot 套件、Windows 和亲测仍未完成。

## 2026-09-13：下载、隔离环境与构建预检

萝卜SAMA在确认目录与空间用途后要求继续，授权原方案的源码下载、隔离 SCons、诊断标记和本地构建。产物继续位于 `engine-diagnostic-20260912/`，沿用方案日期，不替换系统 Godot。

- 固定 hash 源码归档实际 69,965,079 字节（66.7MiB），解压文件合计 336,223,626 字节（320.6MiB）。`source-manifest.json` 保存归档 SHA-256 和大小；预检后隔离目录实际占用约 468MiB，20GiB 是上限而非预分配或实测需求。
- `SConstruct` 要求 Python ≥3.9 / SCons ≥4.4，已将原安装范围下限收紧到 4.4。隔离 venv 实际使用 Xcode Python 3.9.6，SCons 4.11.1，wheel 4,123,659 字节；wheel 与 hash 保留。仓库根 PATH 查询曾显示 Python 3.14.5，不据此冒称 venv 版本。未升级 pip / 全局 Python。
- 原 pip 21.2.4 不支持 `--report`，该次未安装；后改为先下载 wheel、核对 hash、离线安装。下载最初受沙箱代理权限阻断，经审批重跑成功。`scons --version` 通过。
- 使用原定参数加 `--dry-run`；`build-preflight-confirmed.log` 与结果 JSON 记录真实退出码 255。AccessKit / ANGLE 缺失时配置脚本会关闭对应功能，MoltenVK 缺失直接失败；未把预检当成编译成功，也未采用裁剪构建。已核对 Xcode / clang 可用，该次预检尚未验证完整编译兼容性。

### 新增依赖方案（9 月 13 日已授权并完成）

以下依赖未包含在原来只列 SCons 的安装清单内；萝卜SAMA在补充说明后明确要求继续，已授权并完成下载和隔离解压。固定源码的 `misc/scripts/install_accesskit.py`、`install_angle.py` 分别指定 AccessKit 0.21.2 与 ANGLE chromium/7219；MoltenVK 使用上游发布的 v1.4.2 macOS 预编译包。它是否与官方二进制的 MoltenVK 版本一致尚未确认，须保留构建差异，当前性能诊断仍使用 Metal。

| 依赖 | 用途与许可 | 下载上限 |
| --- | --- | --- |
| AccessKit 0.21.2 | 屏幕阅读支持；固定源码版权清单标为 MIT / Expat，归档内附带许可继续保留 | 256MiB |
| ANGLE chromium/7219，仅 arm64-macos | 保留 OpenGL ES 驱动；BSD-3-Clause，附带许可继续保留 | 128MiB |
| MoltenVK v1.4.2，仅 macOS 常规包 | 保留 Vulkan 驱动；Apache-2.0；[上游资产页](https://github.com/KhronosGroup/MoltenVK/releases/expanded_assets/v1.4.2)标示约 56.8MB | 128MiB |

已在上述隔离目录创建 `downloads/` 与 `deps/` 并执行以下下载命令；三项下载总上限 512MiB，含源码、环境、中间文件和日志的整个目录仍受 20GiB 上限约束。实际下载体积见下文，未放宽上限。

```sh
curl --fail --location --max-time 180 --max-filesize 268435456 https://github.com/godotengine/godot-accesskit-c-static/releases/download/0.21.2/accesskit-c-0.21.2.zip --output downloads/accesskit-c-0.21.2.zip
curl --fail --location --max-time 180 --max-filesize 134217728 https://github.com/godotengine/godot-angle-static/releases/download/chromium/7219/godot-angle-static-arm64-macos-release.zip --output downloads/angle-arm64-macos-7219.zip
curl --fail --location --max-time 180 --max-filesize 134217728 https://github.com/KhronosGroup/MoltenVK/releases/download/v1.4.2/MoltenVK-macos.tar --output downloads/MoltenVK-macos-1.4.2.tar
```

授权后先记录 hash、检查归档路径和解压体积，再只向 `deps/` 解压；MoltenVK 与发布页 SHA-256 `f95765a6229cb7b915990a2890ce12ebe36a730b021545d3d52ae69ce4c4024e` 核对。使用 `accesskit_sdk_path`、`angle_libs`、`vulkan_sdk_path` 指向实际解压根；核实 arm64 静态库后重新预检并记录最终构建命令。任何缺失不静默关闭功能，若还有额外依赖或超限则停止说明。不运行会向系统安装完整 Vulkan SDK 的脚本，不修改系统配置。

## 2026-09-13：依赖补齐与诊断构建完成

- 三个归档合计 159,707,095 字节（约 152.3MiB），解压文件合计约 453.2MiB；归档、许可和全部 hash 见隔离目录 `dependency-manifest.json`。MoltenVK 与发布页 hash 一致；AccessKit、三份 ANGLE 静态库和 MoltenVK 均经 `lipo -info` 核实含 arm64，结果保留在 `dependency-architectures.json`。
- 补齐依赖后的原参数 dry-run 退出 0，没有再关闭 AccessKit / ANGLE 或缺失 MoltenVK。实际构建通过 `build-command.json` 固定参数，由 `build-diagnostic.py` 每 20 秒监控目录占用；20GiB 或单次构建一小时上限到达即停止并保留日志。
- 首轮 `build-20260913-202508.log` 在 Metal 模块编译处失败：SCons 的编译子进程未沿用外层 `CLANG_MODULE_CACHE_PATH`，Clang 尝试向用户缓存目录写模块被沙箱拒绝。已通过 `ccflags=-fmodules-cache-path=<隔离目录>/clang-cache` 显式指定缓存，再经命令审批重跑；失败日志和退出 2 保留，未改全局配置。
- 诊断补丁涉及 8 个隔离引擎文件，包括两份新记录器文件；原源码、补丁和 hash 清单分别保留于 `pristine/`、`instrumentation.patch`、`instrumentation-manifest.json`。只添加标记，不删除原可执行语句；保留 Metal 原获取 / 编码 / present / commit 顺序。
- 记录器使用有界内存缓冲（262,144 条、约 16MiB）、统一 Mach 时钟和线程 / 绘制调用 / 获取序号。drawable ID、texture 指针和带创建序号的命令身份分别保留；帧作用域外记录为 0，不猜测归属。关闭标记时不分配缓冲、不生成事件；渲染线程退出后才独占创建 CSV，溢出 / 写失败返回失败，不覆盖既有文件。没有增加 drawable / command 强引用或回调。
- 记录器独立 C++ 检查四种情形通过：关闭无文件；开启含两线程、嵌套帧和 2,007 个顺序事件；溢出明确失败；已有文件保持原字节并失败。Godot 官方二进制对共用同状态对照入口 `engine-comparison.gd` 的无窗口语法检查通过。上述结果不等于 GPU 事件、开销、原图或性能验收通过。
- 重跑 `build-20260913-203102.log` 退出 0，用时 507.428 秒；构建后目录实测 8,833,069,056 字节（约 8.23GiB）。独立二进制 221,299,608 字节，SHA-256 `8fe858c0d0bbf594aabd39e3ca2a6034ded73bb4576dc0851bd49f33a40e07d4`；版本为 `4.7.stable.radish_diagnostic`。源码归档不含 `.git`，运行时 hash 为 unknown，来源以源码 / 补丁清单为准，不伪装官方构建。构建警告 MoltenVK 最低 macOS 12 高于引擎目标 11，本机 macOS 26 可运行，不宣称旧系统兼容。
- 独立二进制版本检查、工厂状态 62 项和视图状态 15 项通过，命令与结果见 `binary-manifest.json`。无窗口日志保留已知系统证书读取 `ret != noErr` 错误，不将其隐去；本轮未运行完整客户端 Godot 套件。

### 五次同状态前台对照

每次独立进程均由用户实际点击共用准备页开始，经双存档根隔离的正式 Boot 加载相同 90 秒夹具快照；暂停预热 15 秒后真实生产 45 秒。负载 100 台设备 / 1,000 段带，窗口 `1920×1080`、3D `1728×894`，默认 Metal / Forward+、4× MSAA、VSync 1、不限帧，无额外 GPU 时间戳。夹具预推进不计生产时长；本轮没有中断或自动重开。

| 隔离目录内批次 | 帧 p95（ms） | 模拟步 p95（ms） | 8 项短测检查 |
| --- | ---: | ---: | --- |
| `official-20260913-204032` | 17.348 | 2.371 | 仅帧预算失败 |
| `off-20260913-204231` | 30.897 | 2.709 | 仅帧预算失败 |
| `on-20260913-204522` | 40.358 | 2.486 | 仅帧预算失败 |
| `off-20260913-205348` | 8.585 | 2.228 | 全部通过 |
| `official-20260913-205726` | 8.549 | 2.081 | 全部通过 |

- `comparison-summary.json` 关联正式 `performance-*` 结果、日志和原图；五组基准状态逐字相同，原图 SHA-256 均为 `a8c0538d8f84e167101c61c62f856cf231d3c70bcef3422bbc9e131a4497fee2`，与先前基准一致。已审阅开启组原图，官方预热画面另经窗口复核。
- 五组均完成 900 步、交付 125 件，生产约 45.000–45.015 秒，计时守恒误差 `<8e-13s`，余量 `<0.05s`；每组采样内一次自动保存和最终保存均成功。五次自动保存分别为 `101.852 / 100.626 / 107.480 / 100.699 / 89.675ms`，不剔除保存停顿。窗口日志除表中帧预算失败外无其他错误。
- 首次诊断构建加载较慢（Boot 加载 1,118.438ms，加载与稳定合计 4,795.066ms），两者单列，不将合计视为纯 IO。重复的官方 / 关闭组明显改善，说明运行条件波动尚未受控；不能把首三组差额全部算作构建差异或记录器开销，也不能用末两组通过代替四档 450 秒长测。

### CPU 事件完整性与结论边界

- 开启组 `events.csv` 共 78,142 条，丢弃、写入错误和关闭错误均为 0；官方 / 关闭组不生成事件文件。全程序号、时钟、线程、成对事件及命令创建身份检查通过；7,453 次实际命令创建最终均提交。实际执行分支全部为正常分支 0。
- 分析先后两次失败并保留日志：首次误把 `draw_graph.end` 前后 command ID 当成不变值，源码确认其引用参数会被替换，最终改以设备 / 片段 / 线程 / 帧配对并保留前后 ID（3,273 次替换）；第二次发现初始化有两次 nil native command 的 commit 调用，依源码作为空调用单列，仍配对但不计实际原生命令提交。最终 `analyze-trace.py` 检查通过，未改运行时行为或丢弃真实提交来消除断言。
- Mach 与 Godot 单调时钟锚点不确定度 2 微秒；保守筛选出与正式生产帧数一致的 2,194 次完整获取，全部先完成 `nextDrawable`，再进行同帧图编码 / 提交，等待期间没有任何线程的实际命令提交。获取等待 p50 `5.257ms`、p95 `14.575ms`、最大 `23.142ms`，详见 `on-20260913-204522/events.analysis.json`。
- 同批次逐帧端点分析 `draw-span-analysis.json` 显示：获取前跨度 p95 `1.932ms`，获取后至 `_draw` 结束 p95 `28.708ms`，完整 `_draw` 跨度 p95 `37.302ms`。这些是独立分布的墙钟跨度，可含驱动等待，不是纯 CPU / GPU 时间；通过同帧端点校验，未用分位数相减推算余量。获取后的长跨度也需要定位，不能只盯住 `nextDrawable`。
- 当前只确认诊断构建的 CPU 调用顺序。没有同轮原生 GPU 轨迹，未证明 GPU 空闲、系统 drawable 回收因果或调整顺序的可获益空间；开启组观察开销也未单独量清。因此本轮不进入原生 GPU 追加采样、调度补丁或四档长测。下一步先稳定官方 / 关闭对照并量清开关开销，再决定是否补同一时钟与命令身份的 GPU 轨迹；不重复无标识事件推算或盲试限帧值。


## 2026-09-13 晚间：开销对照与提交后跨度收窄

萝卜SAMA要求继续下一步。本轮沿原隔离诊断范围，未改引擎补丁、二进制、正式产品或采样脚本；二进制 SHA-256 与八份隔离源码 hash 再核对一致。新增一次性脚本和结果位于 `engine-diagnostic-20260912/overhead-20260913-211048/`。

- 独立 C++ 微测使用同一记录器源码，`xcrun clang++ -std=c++17 -O2 -pthread` 编译；按关闭 / 开启 / 开启 / 关闭顺序重复三轮，每个进程测 10,000 组、每组 24 条标记，首次初始化与最终写盘不计入热循环。关闭平均每组 `46.883–52.204ns`，开启 `339.458–382.137ns`；六个开启进程均写出 240,001 条事件且无丢弃。结果见 `benchmark.json`，只说明单线程循环成本，不代表真实引擎竞争、系统调度或 GPU 观察开销。
- 窗口计划采用同一二进制关闭 / 开启 / 开启 / 关闭四组。沿用原快照、15 秒预热和 45 秒真实生产、默认画质与隔离正式 Boot，每组实际点击准备页开始。`run-controlled.py` 每次仅启动一个进程；前一组中断则拒绝推进，不覆盖原结果。
- 运行前后只读记录电源、负载与进程快照，无逐帧系统采样。本轮均为 AC 电源、80% 电量、120Hz、VSync 1、max FPS 0；低处理器模式关闭。沙箱内首次 `pmset -g therm` 失败、`ps` 无权限，命令审批后快照成功；温控命令仅报告“没有已记录的警告 / CPU 电源状态”，不等于测到了温度或排除了降频。并发应用存在，端点进程快照不足以归因某个应用导致长帧。

| 实际批次 | 结果 | 证据边界 |
| --- | --- | --- |
| `off-20260913-211140` | 帧 p95 `8.564ms`、步 p95 `2.184ms`，8 项通过 | 45.007662 秒，5,390 帧 / 900 步、交付 125 件 |
| `on-20260913-211437` | 帧 p95 `8.548ms`、步 p95 `2.104ms`，8 项通过 | 45.007452 秒，5,390 帧 / 900 步、交付 125 件 |
| `on-20260913-211650` | `focus_lost` 中断，退出 1 | 最后完整原始帧位于 30.199131 秒；3,615 条原始帧保留，不生成完整阶段或性能通过结论 |
| 第四组关闭 | 未启动 | 第三组中断后停止整批，未自动重开 |

- 前两组各一次自动保存成功，耗时 `101.716 / 98.504ms`；最终保存 `89.046 / 89.229ms`，计时守恒误差 `<6e-13s`，积压余量 `<0.05s`，所有保存停顿保留。第三组保留 `interrupted-samples.json` 和事件 CSV，不混入完整对照。前三组基准状态和原图均一致，原图 hash 沿用上述 `a8c0538d…`，已审阅完成的开启组原图；汇总及精确路径见 `summary.json`。
- 完成的开启组 170,261 条事件无丢弃 / 写错，原分析器的时钟、身份、配对及正常执行分支检查通过；2.042 微秒锚点不确定度内保守选取 5,390 次生产获取，全部获取完成后才编码 / 提交，等待期间无其他线程的实际提交。中断组 129,566 条事件无丢弃 / 写错，但没有完整生产结束锚点，未当成同等生产分析通过。
- 一关一开两组结果接近，且本次开启组没有重现上一轮 40.358ms；完整四组对照仍未完成，不能声明记录器在所有运行条件下无可感知开销，不能将差值当作精确开销。

同一版标记同时捕获了上一轮慢样本与本轮快样本，`summarize-controlled.py` 按同一个绘制调用的端点求跨度并验证加和，结果保留于各组 `draw-span-comparison.json`：

| 墙钟跨度 p95 | 上轮开启慢样本（2,194 帧） | 本轮开启快样本（5,390 帧） |
| --- | ---: | ---: |
| 获取之前 | 1.932ms | 2.120ms |
| 获取 drawable | 14.575ms | 7.041ms |
| 获取后至 `_draw` 结束 | 28.708ms | 0.606ms |
| 最后实际 commit 返回至 `_draw` 结束 | 28.277ms | 0.0065ms |

分位数来自各自逐帧跨度，不相减或相加解释其他阶段；墙钟跨度可以包含系统 / 驱动等待。两批次相同调用顺序却有不同性能，说明顺序本身不足以解释卡顿，暂不提出延迟获取或拆提交补丁。

固定源码中 `swap_buffers` 执行提交后进入 `_begin_frame(true)`，后者先 `_stall_for_frame`，可能调用 Metal `fence_wait`；随后还有资源整理、可见性通知及绘制后回调。它们都可能落在当前宽跨度内，现有端点不能把 28.277ms 分配给某个函数。接续先补齐稳定开关对照；若仍需追慢帧，取证应覆盖提交后的帧等待与收尾边界，再与同轮 GPU 活动关联，不能只重复 `nextDrawable` 等待分析。窗口失焦后本轮不再启动原生 GPU 采样或长测。

## 2026-09-13 晚间接续：完整四组对照与基线波动

萝卜SAMA再次要求继续后，新建 `engine-diagnostic-20260912/overhead-20260913-213052/`，完整执行关闭 / 开启 / 开启 / 关闭四组。上一批第三组中断保持原样，不把跨批次结果拼成完整对照。`plan.json` 固定顺序、时长、原入口脚本 hash 与停止条件；每次实际点击准备页，四组均无中断。

| 批次 | 帧 p95（ms） | 步 p95（ms） | 检查与完整帧数 |
| --- | ---: | ---: | --- |
| `off-20260913-213449` | 8.506 | 2.043 | 8 项通过，5,390 帧 |
| `on-20260913-213611` | 8.533 | 2.094 | 8 项通过，5,390 帧 |
| `on-20260913-213740` | 8.597 | 2.132 | 8 项通过，5,390 帧 |
| `off-20260913-213931` | 24.155 | 2.585 | 仅帧预算失败，2,939 帧 |

- 四组实际生产约 `45.007–45.015s`，均完成 900 步、交付 125 件，计时守恒误差 `<8e-13s`，余量 `<0.05s`；各一次自动保存成功，耗时 `100.465 / 103.546 / 98.404 / 102.891ms`，最终保存均成功。没有剔除保存停顿或慢帧。前三组原始采样各 1 帧超过 16.7ms，最后一组 773 帧超过；原始墙钟帧与应用内部帧样本分别保留，不混用最大值。
- `summarize-controlled.py` / `summary.json` 核对四份快照与原图 hash 一致；图片仍为已审阅的 `a8c0538d…`。二进制与八份诊断源码 hash 未变，窗口 / 3D 像素、120Hz、VSync 1、max FPS 0、Metal / Forward+、画质均相同。电源快照均为 AC / 80%，温控仍只得到无历史警告记录，不能声称温度已测。
- 最后关闭组九个 5 秒区间的原始帧 p95 为 `23.583 / 26.441 / 25.791 / 32.488 / 24.226 / 22.502 / 22.378 / 22.730 / 21.247ms`，从采样开始即持续偏慢，不是约第 30 秒的单次自动保存导致整体 p95 失败。与首关闭组 `8.506ms` 的差异证明前后基线不稳定；标记记录不是本批次长帧发生的必要条件，也不能把两组开启与任一关闭组之差当作精确记录开销。
- 两组开启事件分别为 169,149 / 236,146 条，丢弃和写入错误均为 0；序号、时钟、对象身份、成对事件与正常执行分支检查通过。各 5,390 个完整生产帧均获取后编码 / 提交。最后实际 commit 返回至 `_draw` 结束的逐帧跨度 p95 为 `0.0065 / 0.0066ms`，快样本的提交后短跨度再次出现；最后关闭慢样本没有事件记录，不把前组事件套到它的慢帧上。
- 前后进程快照显示其他项目程序及桌面服务也在活动，最后一组后系统负载上升；快组也存在较高的其他进程 CPU 读数。这是运行条件未完全隔离的证据，不是某个应用或 GPU 竞争的因果证明。未关闭其他应用、修改系统电源 / 刷新率或操作其他项目。
- 本轮结论是“四组完整、稳定性未通过”，开销的精确估计仍未完成；不再无条件追加相同四组，不直接进入 GPU 采样、调度补丁或四档长测。已询问可否提供约 5 分钟、暂停其他项目构建 / 测试 / 窗口启动的时段，未收到明确时段答复前仅继续离线分析。条件明确后先作原配置对照；若仍有慢帧，再围绕提交后的 fence 等待、资源整理与绘制后回调补同帧证据及 GPU 关联。只读端点快照不足以替代采样期间的条件约束。

## 2026-09-13：约定时段对照与第二版分段诊断准备

萝卜SAMA同意按约 5 分钟较少并发干扰的时段继续。新批次 `engine-diagnostic-20260912/quiet-20260913-214756/` 使用官方 / 第一版标记开启 / 官方三组，各预热 15 秒、真实生产 45 秒，均实际点击准备页且完整结束。进程启动至最终退出为 `21:48:09–21:54:29`（约 6 分 20 秒，含组间审批 / 准备等待），不把全部墙钟算成生产或已经证明的独占桌面时间。

| 批次 | 帧 p95（ms） | 步 p95（ms） | 结果 |
| --- | ---: | ---: | --- |
| `official-20260913-214809` | 27.186 | 2.567 | 仅帧预算失败，2,647 帧 |
| `on-20260913-215047` | 8.555 | 2.281 | 8 项通过，5,390 帧 |
| `official-20260913-215324` | 8.584 | 2.324 | 8 项通过，5,390 帧 |

- 三组均 900 步、交付 125 件、计时误差 `<6e-13s`、余量 `<0.05s`；采样内各一次自动保存成功，耗时 `111.668 / 98.105 / 100.988ms`，最终保存均成功。基准快照、原图和渲染配置一致；二进制 hash 再核对，未调整产品设置。首组原始采样 1,009 帧超过 16.7ms，后两组各 1 帧，全部保留。
- 第一版开启组 170,586 条事件无丢弃 / 写错；5,390 个生产帧的身份与顺序分析通过，最后实际提交返回至 `_draw` 结束跨度 p95 `0.00654ms`，本组没有重现此前的长跨度。原始结果、事件与逐帧端点分别见 `summary.json` 和该开启组的 `events.analysis.json` / `draw-span-comparison.json`。
- 同一个官方版本前后仍然不同，不能精确估算记录开销，也不能根据用户约定或端点快照宣称已隔绝全部后台活动、已证明某个应用干扰。整体对照到此收口，不再追加同类开关批次，也不据后两组通过启动长测。

### 第二版：提交后等待与收尾的同帧分段

继续既有隔离诊断路线，依据旧慢 / 新快样本差异收窄计时位置，不更换产品介质、驱动、画质、验收预算或提交策略。第二版位于 `engine-diagnostic-20260912/postwait-v2/`；用 `cp -cpR` 克隆第一版源码与构建中间文件，依赖仍引用既有隔离版本。第一版原目录与二进制 hash 保持不变；最终总目录 `du` 约 14.80GiB，20GiB 上限未放宽，克隆的共享块不等于额外预分配相同物理空间。

- 修改四个隔离文件：`rendering_device.cpp`、`rendering_server_default.cpp`、`rendering_device_driver_metal3.cpp`、`radish_presentation_trace.cpp`。在原调用两侧增加记录；源码检查确认除容量 / 记录元数据外，旧可执行语句逐字保留，没有调整获取、编码、提交、等待或释放顺序，没有新增 GPU 资源强引用或回调。
- 分段覆盖：提交后的 `_begin_frame(true)`、其中 `_stall_for_frame` / 实际 `fence_wait` / `_free_pending_resources`，以及 rasterizer 结束、可见性通知、绘制后派发与实际回调、帧统计、显存统计。新增事件共享第一版 Mach 时钟 / 绘制作用域；派发与实际回调分开，延迟回调可能属于 frame 0，不附会到附近绘制帧。
- fence 创建使用新序号、销毁终止身份；信号记录保留 fence、原生命令指针、shared event 和值，等待返回另保留原函数已有布尔结果。后续必须通过 fence 创建 / 销毁及 command 创建 / 重置生命周期关联，不能跨指针复用拼接；信号编码请求不等于 GPU 已完成，初始值 0 不伪造前序命令。
- 记录条目增多，将容量从 262,144 提到 524,288（约 32MiB），头部标记 `revision=postwait-v2`。仍默认关闭、有界内存记录、退出后独占写入；溢出 / 写错明确失败。第二版新增标记的整体观察开销尚未实测，不复用第一版微测来声称开销已通过。
- 准备脚本两次唯一匹配保护拒绝了重复的 `_begin_frame(true)` / `_stall_for_frame(frame)` 语句，均在源码写入前停止；最终限定具体函数段再生成补丁。记录于 `preparation-failures.json`。预检退出 0，初次增量构建 `build-20260913-220118.log` 用时 19.774 秒、补齐 fence 生命周期后的最终构建 `build-20260913-220307.log` 用时 10.857 秒，均退出 0。Clang 临时目录提示与既有 MoltenVK macOS 12 / 引擎目标 11 链接警告保留，不扩展系统兼容结论。
- 最终二进制 221,244,360 字节，SHA-256 `11d33c50560b7e80281ea9901b622b824fe85e4f541111891bc9fbce6cc3fb1a`，版本仍为 `4.7.stable.radish_diagnostic`；通过 revision、源码 / 补丁清单和二进制 hash 区分两版，不仅凭版本字符串关联数据。命令、补丁与 hash 见第二版 `build-command.json`、`postwait.patch`、`instrumentation-manifest.json` 和 `binary-manifest.json`。
- 第二版无窗口状态 62 项、视图 15 项通过；已知系统证书读取错误保留，无其他运行错误。记录器关闭无文件、开启 2,007 条事件、524,288 容量溢出明确失败、已有文件不覆盖四种情形通过。入口 `run-postwait.py` 语法检查通过，仍复用原准备页、双存档根与 45 秒生产；本轮未启动第二版窗口、未取得第二版分段或 fence 配对实测，也未执行原生 GPU 采样 / 全量客户端 Godot / Windows 检查。

9 月 13 日日终复核发现：现有第一版 `analyze-trace.py` 未处理第二版新增的 shared event 等待、fence 生命周期、回调与统计事件；第二版目录仅有准备、构建与运行脚本，没有对应分析器。此前第一版分析通过不能替代第二版验证。明日先补齐新增区间配对与生命周期分析，以缺失事件、指针复用、等待超时等样本核对失败行为；初始值 0 和 frame 0 回调按原语义单列。今晚不实现、不启动窗口。

离线检查通过后，再使用 `postwait-v2/run-postwait.py on` 做一轮有界分段验证，先检查事件零丢弃、成对区间、fence / command 生命周期与画面 / 状态一致性。只在实际捕获慢帧时比较同帧各段及未覆盖余量；不能将嵌套跨度相加、分位数相减或快帧结果冒称慢帧根因。若仅捕获快帧，明确记为未复现，不继续以重复开关追求稳定结果；待分段证据指出具体等待后再决定是否需要同轮 GPU 关联。

## 历史批次记录

以下批次记录从 W37 周志移入，保留当时的验证与待办状态；当前接续以上文为准。

## 2026-09-12：重复短测与 GPU 采样干扰排查

- 萝卜SAMA确认继续 P3。开始时 `dev` 工作区干净，HEAD 为 `2e143811`；本轮未修改产品实现、画质、默认驱动、同步或预算。一次性入口与分析脚本保留在 `tools/runtime-intake/check-runs/factory-foundation-v1/gpu-breakdown-20260912/`，所有运行仍从双存档根隔离的正式 Boot 进入。
- 三组完整对照均重复两段原配置，每段从同一合法 `90s` 生产快照开始，暂停预热固定 15 秒后生产 45 秒。预热按墙钟计时，不因帧率不同改变预热时长；夹具预推进和暂停预热不计为真实生产。Vulkan 仅通过该进程启动参数选择；未关闭 SSAO、阴影或 MSAA。

| 批次 | 测量配置 | 两段帧 p95 ms | 两段模拟步 p95 ms | 两段 3D GPU p95 ms |
| --- | --- | --- | --- | --- |
| `performance-1789212421-22248` | Vulkan，视口计时及 `--gpu-profile` 分项时间戳 | 44.838 / 39.725 | 1.053 / 1.060 | 42.558 / 38.880 |
| `performance-1789212681-23133` | Vulkan，仅视口计时 | 24.281 / 21.934 | 1.204 / 1.117 | 23.757 / 21.661 |
| `performance-1789212910-25623` | 默认 Metal，无额外 GPU 计时 | 20.595 / 20.853 | 1.087 / 1.155 | 不可用 |

- 三组各 15 项检查中仅两段帧预算失败，无失焦或其他断言失败；不能将整组写成通过。每段完成 900 步、交付 125 件，余量 `<0.05s`，计时差额约 `6e-13s`；各发生一次采样内自动保存且成功。默认 Metal 两段自动保存为 `95.275 / 128.681ms`，仍包含在完整帧记录内，没有删除保存停顿以降低分位数。
- 窗口报告 `1920×1080`，正式采样实际内容图 `1728×1080`、3D `1728×894`，4× MSAA、VSync 1、缩放 1。六张同状态基准截图 SHA-256 均为 `a8c0538d8f84e167101c61c62f856cf231d3c70bcef3422bbc9e131a4497fee2`；已审阅 Vulkan 仅视口计时首段和默认 Metal 第二段原图，场景、阴影与 HUD 一致。启动早期 inventory 的视口尺寸不代替预热后的正式采样尺寸。
- 分项采样与仅视口计时的 Vulkan 帧时间差异明显，提示测量本身造成扰动；两组是独立进程，仍可能有运行时波动，不能将差额全部视为精确的采样开销。默认 Metal 移除额外 GPU 计时后仍重复超预算，说明问题不能仅归咎于诊断计时。
- 分项批次保留原始 GPU 标记、视口计时和 `gpu-summary.json`：两段分别有 170 / 172 个不同标记帧，未出现相邻负时间差。SSAO、阴影、opaque 与 resolve 标签耗时较高但波动明显，例如 SSAO 中位数两段为 `8.398 / 0.471ms`；这些受扰动数据不支持将 SSAO 定为唯一根因，也不能把分位数相加 / 相减推算未测耗时。渲染统计绘制调用 p95 保持 508，阴影绘制为 247，可见物体绘制 p95 为 230；统计口径分别保留。
- 核对 [Godot 渲染计时实现](https://github.com/godotengine/godot/blob/master/servers/rendering/rendering_server_default.cpp)：本机原始 GPU 时间按纳秒、CPU 按微秒换算毫秒，与实测数量级一致。上游 [Metal 时间戳接口](https://github.com/godotengine/godot/blob/master/drivers/metal/rendering_device_driver_metal.cpp) 的结果填零、写入为空实现，与本机 GPU 全零一致；这不是 GPU 开销为零或硬件不能采样的证据。运行时指南补充测量开销、原始单位与有效轨迹要求。

### 原生 Metal 采样接续边界

- 本机已有完整 Xcode / Instruments，`xcrun xctrace list templates` 确认存在 `Metal System Trace`；首次沙箱执行因 Instruments 缓存目录权限失败，经授权重跑查询成功，未安装依赖。已读取 record / export 帮助，尚未实际运行 record，不能把工具可用记作取得轨迹。
- `native-metal-a.log` 准备页约 79 毫秒就绪，但未成功点击开始，180 秒后 `PROFILE_START_TIMEOUT`；没有进入正式工厂，不算性能运行。原生工具在读取已退出应用时打开项目管理器，随后关闭，再启动自动进入正式 Boot 的一次性诊断入口。
- 自动入口 `performance-1789214427-28895` 已进入正式工厂，在 `native-metal` 暂停预热期间收到 `focus_lost`；3 项检查中 1 项中断失败，`phases=[]`，没有完成生产采样或生成有效 `.trace`。失焦原样保留，不推断原因；已停止自动重开并询问桌面是否方便，不能用中断记录填补原生采样缺口。
- 下一步仍是对实际 Godot PID 取得短时原生轨迹并记录对应生产时段，区分 GPU 执行、提交与显示等待；原配置短测稳定前不启动四档长测。已完成的三组对照可直接复用，不再凭受扰动分项值增加代码优化或降低画质。完整客户端 Godot 套件、Windows 与亲测仍待验。
- 本轮文档预算、仓库治理（1,746 文件）及 `git diff --check` 通过。三组完整运行日志仅有已记录的帧预算失败；初始 headless API 枚举日志另有系统证书读取错误，保留原日志，未将该枚举当成运行时通过证据。当前仅提交正式文档与接续记录，临时诊断与产物留在忽略目录；未推送或发布。

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
