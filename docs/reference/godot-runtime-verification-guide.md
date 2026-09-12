# Godot Runtime Verification Guide (For AI Agents)

更新时间：2026-09-12

## 用途与定位

本文沉淀"命令行启动 Godot → 自动跑真实场景 → 断言 + 截图复核"的通用方法，供任何执行会话 / AI Agent 做运行时验证使用。方法在 2026-07 切片各专题（存档闭环、建造放置、视角修正换装）中反复实证。

**硬约束入口**：`AGENTS.md` 与 `CLAUDE.md` 已将本指南列为玩家可见功能的强制验证流程；默认 `check-client` 或纯 headless 断言不能替代正式入口、有窗口输入链、自动截图与截图实际审阅。

- 定位：玩家可见目标以**实机截图与运行时路径复核为主证据**，`check-client` 静态检查只兜底；本方法就是产出主证据的机械化手段。
- 约束：启动 Godot 属 `CLAUDE.md` 中"需要先告知用户再执行"的操作，跑之前先在回复中告知萝卜SAMA。
- 平台：macOS 下 Godot 可执行文件为 `/Applications/Godot.app/Contents/MacOS/Godot`；以下记为 `$GODOT`。

## 焦点与用户桌面

- 有窗口验证不得循环调用 `grab_focus()`、强制置顶或在失焦后自动切回。萝卜SAMA切换窗口时停止采样或中断检查，不能抢占桌面来凑前台时长。
- 用户关闭测试窗口后不自动重开；需要连续前台占用的长测，应在用户方便的时段另行安排。中断结果保持未完成，不能把后台时间或短测拼成连续前台通过。

## 核心机制

Godot 4 的 `--script` 参数接受一个 `extends SceneTree` 的 GDScript，**它会替代工程主循环**：

```bash
repo_root="$PWD"
"$GODOT" --path "$repo_root/client" \
  --script "$repo_root/tools/runtime-intake/YYYY-MM-DD-topic/my-check.gd" \
  --no-header
```

- `--path client` 加载完整工程上下文：全局类（`class_name`）、输入映射、工程设置全部可用，脚本里可直接 `preload("res://scenes/boot/Boot.tscn")`。
- 脚本自己决定做什么、何时 `quit(exit_code)`；exit code 即检查结果（0 过 / 1 挂）。
- 有窗口运行可渲染可截图；加 `--headless` 则无渲染（快，适合纯逻辑断言，**不能截图**）。

## 标准流程

1. **先导入**（新增素材 / 场景 / 脚本后必做，否则资源缺失）：
   `"$GODOT" --headless --path client --import --quit --no-header`
2. **纯逻辑断言**用 `--headless` 跑（快）；**需要截图**的用有窗口跑。
3. 将输出写入日志，核对退出码并定位真实错误；仅排除已确认的 macOS `ret != noErr` 噪声：
   `rg '^(SCRIPT ERROR|ERROR:)' log | rg -v 'Condition "ret != noErr"'`
4. 一次性检查脚本放仓库内忽略提交的 `tools/runtime-intake/YYYY-MM-DD-<topic>/`；形成稳定通用回归价值后，再迁入正式 `scripts/` 或客户端检查入口。
5. 自动检查、临时验证和人工复测存档一律放在仓库内忽略提交的 `tools/runtime-intake/`，不得写入 `/tmp`、系统临时目录或工作区外：自动运行使用 `check-runs/<topic>/`，稳定人工档使用 `review-worlds/current/` 或 `review-worlds/<topic>/`，专题正式入口也可继续使用同批次 `save-root/`。开跑前可清理自己的隔离目录，但通过后不得删除最终主档 / 备份档；纯破坏性 / 迁移失败测试使用独立子目录并可清理，任何测试都不得覆盖生产版 `user://saves/slice/` 或 `user://saves/factory/`。
6. 截图落到 git 忽略的 `assets/art-intake/<日期>-<主题>-preview/`，供人工 / 视觉复核，结论记入当周周志。多图可以用 `./scripts/create-screenshot-contact-sheet.sh <output.png> <inputs...>` 生成带编号联系表辅助导航，但视觉结论必须按任务风险审阅足够的原生尺寸截图；联系表不能替代文字、材质、构图和整体观感判断。

## 脚本骨架模板

```gdscript
extends SceneTree

const BootScene := preload("res://scenes/boot/Boot.tscn")
const BATCH_DIR := "tools/runtime-intake/YYYY-MM-DD-topic"
const SHOT_DIR := "/绝对路径/assets/art-intake/YYYY-MM-DD-topic-preview"

var failures: Array[String] = []

func _init() -> void:
	# 构造期不做事，等树就绪后再执行
	call_deferred("_execute")

func _execute() -> void:
	await _run()
	if failures.is_empty():
		print("My checks passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, context: String) -> void:
	if not condition:
		failures.append(context)

func _run() -> void:
	# 1. 清基线（如删存档文件，保证从新档开始）
	# 2. 走真实入口链路，不直接实例化内部场景：
	var boot := BootScene.instantiate()
	var repo_root := ProjectSettings.globalize_path("res://").path_join(
		".."
	).simplify_path()
	boot.slice_save_catalog = SliceSaveCatalog.new(
		repo_root.path_join(BATCH_DIR).path_join("save-root")
	)
	root.add_child(boot)
	await process_frame
	var menu := boot.startup_menu as StartupMenu
	menu.new_game_button.pressed.emit()
	await process_frame
	menu.world_name_input.text = "专项复核世界"
	menu.create_world_button.pressed.emit()
	await process_frame
	# 3. 拿到世界引用后逐项断言……
	# 4. 验证通过后保留最终隔离存档，供萝卜SAMA直接载入复核

func _screenshot(file_name: String) -> void:
	await process_frame
	await process_frame  # 等两帧确保画面已渲染
	var image := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	image.save_png(SHOT_DIR.path_join(file_name))
```

## 常用手法

- **真实入口链路**：从 `Boot` 实例化，先注入独立 `SliceSaveCatalog` 根，再用“新游戏 → 输入名称 → 创建并进入”或“载入存档 → 选择世界 → 载入”按钮信号进入游戏；只按 `new_game_button` 现在仅打开世界列表，不会直接实例化世界。不要绕过入口直接搭内部场景（那验证不了 wiring）。
- **输入模拟**：`Input.action_press("move_up")` → 若干 `await physics_frame` → `Input.action_release(...)`，走真实物理与动画路径。**用完必须 release**，Input 状态跨段残留。
- **传送 + 真实交互结合**：跨图赶路可以直接设 `player.position`（省时），但被验证的机制本身（交互、碰撞、放置）必须走真实路径。
- **位置里程碑而非定帧计时**：断言"走到某处"用位置条件 + 帧数上限兜底；固定帧数在高刷新率下失真（W29 经验）。
- **模型时间与运行时钟分别验证**：显式传入时间可以定向验证配方、守恒与状态推进，但不能证明实际主循环没有丢失活动时间。持续验证需同时记录单调墙钟、暂停 / 失焦时段、模型已推进时间与待处理余量；不得用加速模型检查替代真实持续生产。
- **存档闭环**：同脚本内 `boot.free()` → 再实例化新 `Boot` 走"载入存档"，可验证读档还原；要更严格的进程隔离就分两次 godot 调用（存档进程 + 读档进程），断言中间落盘 JSON。
- **人工复核存档**：自动链可以在启动时删除自己上一次的隔离目录，结束时必须停在最有复核价值的通过状态并保留存档。若一个包需要人工检查多个互斥状态，为每个状态使用独立隔离目录；报告目录、载入后预期状态和是否保留备份档。
- **截图时机**：状态就位后 `await process_frame` 两次再抓 `root.get_texture().get_image()`；相机跟随玩家时把玩家挪到构图点即可控制取景。
- **窗口分辨率**：`--resolution WxH` 控制窗口；注意 Retina 下帧缓冲是物理像素（截图尺寸 ≠ 逻辑窗口尺寸），验证拉伸/填充行为时按物理像素取样四角与中心颜色。

## 踩过的坑（案例索引见 W29 周志）

1. **帧时序**：父节点 `_physics_process` 先于子节点跑——世界根用玩家"上一帧"位置算目标格，断言前多 `await physics_frame` 一两帧。
2. **自占几何**：放置类校验会被玩家自己的碰撞盒挡住——测试里让角色走过头就会"自己挡自己"，这是规则正确而非缺陷；断言前算清脚部盒与目标区域的间隙。
3. **物理查询上下文**：`direct_space_state.intersect_shape` 在 `_physics_process` 上下文调用安全；别在树外或构造期调。
4. **`--headless` 无渲染**：截不了图；只在纯逻辑断言时用它提速。
5. **测试脚本类型转换**：`Array[Vector2i]` 等 typed array 的比较/转换在脚本里容易 parse error，逐元素断言更稳。
6. **噪声过滤**：当前 macOS `Condition "ret != noErr"` 已确认是系统证书查询噪声；不要据此忽略所有证书相关错误。其余 `SCRIPT ERROR` / `ERROR:` 与检查失败均须核对。
7. **信号驱动的按钮**：`button.pressed.emit()` 可以验证信号后的业务连接，但不覆盖鼠标命中、遮挡、焦点和禁用状态；与真实输入及用户亲测分别记录。

## 断言与产物规范

- 失败收集进数组、最后统一 `push_error` 并 `quit(1)`；调用侧同时核对退出码与 `SCRIPT ERROR` / `ERROR:` 日志，因为脚本解析失败可能返回 0。只精确排除已确认的平台噪声，不忽略真实错误。
- 每包验证的断言数、截图文件名、结论写入当周周志；截图目录不入库（`art-intake` 已忽略），复核图（放大对比等）用完即删。
- 自动化产生多张截图时保留原图；联系表用于快速定位，最终判断按风险直接检查必要原图，不设置单会话图片张数上限。
- 调用侧按场景设置超时；普通窗口检查保持短时，真实生产 / 长测明确时长、进度和取消路径。长测不能因用户失焦而自动抢回窗口，不能将超时或中断写成通过。

## 正式三维工厂验证路由

工厂已接入同一 Boot，旧示例的 `SliceSaveCatalog` 注入不足以隔离全部存档；还须在加入场景树前设置 `boot.factory_save_root`。使用 `factory-foundation-v1` 的 `check-runs/` / `review-worlds/`，操作与截图规则见[首包专题](../features/factory-foundation-and-persistence-v1.md)。

临时前台诊断若需要“点击开始”准备页，复用 `client/scripts/checks/factory_diagnostic_gate.gd`，不要复制窗口初始化代码：

```gdscript
var gate := preload("res://scripts/checks/factory_diagnostic_gate.gd")
if not await gate.wait_for_start(self, "异星催化 · 诊断准备", "本次负载、时长与取消条件"):
	quit(1)
	return
await super._run() # 仅在派生诊断脚本中进入原检查流程。
```

准备页保持最大化，不同时写入小窗口尺寸；仅在准备页使用自适应铺满，结束时恢复原内容比例与关闭策略。显示按钮前检查原生窗口、实际渲染图像和控件布局已同步，并跨渲染帧确认尺寸稳定；超时明确失败。`ViewportTexture.get_size()` 带有拉伸变换，不能替代 `get_image().get_size()` 的实际像素证据。准备页验证不算正式 Boot、工厂画面或性能验收；正式检查仍按原有路径与预算执行。

- `tools/check-factory-foundation.sh` 的 `state` / `clock` / `view-state` / `interruption` / `process` / `legacy` / `scale` / `scale-process` / `scale-merge` 为无窗口检查；`boot` / `operation-write` / `operation-read` / `performance` / `sustained` 会开窗口。`clock` 使用隔离 Boot 与真实停顿，焦点和弹窗按钮信号注入单列；`interruption` 检查准备 / 采样中断，不算性能通过。各模式单独运行，Godot 可由既有 `GODOT_EXE` 指定，不自动安装。
- `performance` / `sustained` 依赖 `scale` 生成的满载快照；后者另外用正式命令生成空物料工程线再真实生产。负载供给必须明确标记，不能进入普通新世界选项。
- 完整与中断采样均保留帧记录、逐帧模拟耗时、模拟步、保存耗时及采样分辨率；中断原因单列 `focus_lost` / `window_closed` / `focus_unavailable`。旧批次缺失的字段不能据新格式补猜；中断记录不计作完整性能通过。
- 正式检查中的逐帧模拟耗时只围绕 `model.advance`，不代表整帧 CPU 或 GPU。额外视口 CPU / GPU 与节点处理计时来自单列的一次性诊断；GPU 全零读数记为不可用，分位数不能直接相加或相减来推算未测开销。临时同步开 / 关对照须保留设置、恢复过程和中断边界，不改写正式验收结果。
- `check-client` 默认只做静态检查；Shell / PowerShell 的 Godot 路径已纳入工厂 `state` / `save` / `clock` / `view_state`，不因此覆盖全部跨进程、规模、原生窗口或持续性能模式。具体执行范围以脚本与当批日志为准。
- 操作存读使用同一唯一 batch 的两个独立进程；同一进程销毁再建 Boot 只作为较窄的恢复证据。旧世界入口 / schema 回归继续独立执行。
- 2026-09-09 已补单调时钟、准备 / 采样中断和规模定向证据；窗口计时、原生保存返回 / 重进及后台长测已有通过记录，前台性能仍待诊断与完整重跑。时钟一致性按同一已处理帧边界比较墙钟与“推进 + 余量变化”；原始帧、模拟步和保存记录分别保留，注入故障 / 保存与正常自动保存须区分。批次事实见 [W37 周志](../devlogs/2026-W37.md)。

- 2026-09-12 系统关闭保存与独立 Boot 重进已补 17 / 15 项证据。性能诊断完成同状态同步开 / 关 / 恢复与有效调用栈；Metal GPU 仍不可用，临时 Vulkan 对照取得 GPU 时间。驱动或效果诊断只影响测试进程，不代表默认 Metal 配置通过；详情见 W37 周志。
