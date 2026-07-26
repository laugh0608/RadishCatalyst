# Godot Runtime Verification Guide (For AI Agents)

更新时间：2026-07-21

## 用途与定位

本文沉淀"命令行启动 Godot → 自动跑真实场景 → 断言 + 截图复核"的通用方法，供任何执行会话 / AI Agent 做运行时验证使用。方法在 2026-07 切片各专题（存档闭环、建造放置、视角修正换装）中反复实证。

**硬约束入口**：`AGENTS.md` 与 `CLAUDE.md` 已将本指南列为玩家可见功能的强制验证流程；默认 `check-client` 或纯 headless 断言不能替代正式入口、有窗口输入链、自动截图与截图实际审阅。

- 定位：玩家可见目标以**实机截图与运行时路径复核为主证据**，`check-client` 静态检查只兜底；本方法就是产出主证据的机械化手段。
- 约束：启动 Godot 属 `CLAUDE.md` 中"需要先告知用户再执行"的操作，跑之前先在回复中告知萝卜SAMA。
- 平台：macOS 下 Godot 可执行文件为 `/Applications/Godot.app/Contents/MacOS/Godot`；以下记为 `$GODOT`。

## 核心机制

Godot 4 的 `--script` 参数接受一个 `extends SceneTree` 的 GDScript，**它会替代工程主循环**：

```bash
"$GODOT" --path client --script /tmp/my_check.gd --no-header
```

- `--path client` 加载完整工程上下文：全局类（`class_name`）、输入映射、工程设置全部可用，脚本里可直接 `preload("res://scenes/boot/Boot.tscn")`。
- 脚本自己决定做什么、何时 `quit(exit_code)`；exit code 即检查结果（0 过 / 1 挂）。
- 有窗口运行可渲染可截图；加 `--headless` 则无渲染（快，适合纯逻辑断言，**不能截图**）。

## 标准流程

1. **先导入**（新增素材 / 场景 / 脚本后必做，否则资源缺失）：
   `"$GODOT" --headless --path client --import --quit --no-header`
2. **纯逻辑断言**用 `--headless` 跑（快）；**需要截图**的用有窗口跑。
3. 输出重定向到日志文件，过滤真实错误（macOS 有 `noErr` / 证书类噪声）：
   `grep -E "passed|SCRIPT ERROR|ERROR:" log | grep -v noErr | grep -v certificate`
4. 检查脚本放 `/tmp/`（不进仓库、不触发 uid sidecar 检查），跑完删除。
5. 截图落到 git 忽略的 `assets/art-intake/<日期>-<主题>-preview/`，供人工 / 视觉复核，结论记入当周周志。脚本可以生成多张原图，但 Codex 单会话默认最多读取 3 张；多图审阅前先运行 `./scripts/create-screenshot-contact-sheet.sh <output.png> <inputs...>` 在磁盘生成一张带编号的联系表，优先只读取联系表；达到默认上限后先报告，萝卜SAMA明确要求当前会话继续时可按每次至多 3 张追加读取。

## 脚本骨架模板

```gdscript
extends SceneTree

const BootScene := preload("res://scenes/boot/Boot.tscn")
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
	root.add_child(boot)
	await process_frame
	(boot.get_node("StartupMenu") as StartupMenu).new_game_button.pressed.emit()
	await process_frame
	# 3. 拿到世界引用后逐项断言……

func _screenshot(file_name: String) -> void:
	await process_frame
	await process_frame  # 等两帧确保画面已渲染
	var image := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	image.save_png(SHOT_DIR.path_join(file_name))
```

## 常用手法

- **真实入口链路**：从 `Boot` 实例化、用 `button.pressed.emit()` 触发菜单信号进入游戏，验证的是真实接线；不要绕过入口直接搭内部场景（那验证不了 wiring）。
- **输入模拟**：`Input.action_press("move_up")` → 若干 `await physics_frame` → `Input.action_release(...)`，走真实物理与动画路径。**用完必须 release**，Input 状态跨段残留。
- **传送 + 真实交互结合**：跨图赶路可以直接设 `player.position`（省时），但被验证的机制本身（交互、碰撞、放置）必须走真实路径。
- **位置里程碑而非定帧计时**：断言"走到某处"用位置条件 + 帧数上限兜底；固定帧数在高刷新率下失真（W29 经验）。
- **显式 delta 驱动时间逻辑**：验证计时产出类逻辑时直接调 `world._tick_production(INTERVAL)` 传显式 delta，确定性且不用真等墙钟；墙钟等待既慢又受帧率干扰。
- **存档闭环**：同脚本内 `boot.free()` → 再实例化新 `Boot` 走"载入存档"，可验证读档还原；要更严格的进程隔离就分两次 godot 调用（存档进程 + 读档进程），断言中间落盘 JSON。
- **截图时机**：状态就位后 `await process_frame` 两次再抓 `root.get_texture().get_image()`；相机跟随玩家时把玩家挪到构图点即可控制取景。
- **窗口分辨率**：`--resolution WxH` 控制窗口；注意 Retina 下帧缓冲是物理像素（截图尺寸 ≠ 逻辑窗口尺寸），验证拉伸/填充行为时按物理像素取样四角与中心颜色。

## 踩过的坑（案例索引见 W29 周志）

1. **帧时序**：父节点 `_physics_process` 先于子节点跑——世界根用玩家"上一帧"位置算目标格，断言前多 `await physics_frame` 一两帧。
2. **自占几何**：放置类校验会被玩家自己的碰撞盒挡住——测试里让角色走过头就会"自己挡自己"，这是规则正确而非缺陷；断言前算清脚部盒与目标区域的间隙。
3. **物理查询上下文**：`direct_space_state.intersect_shape` 在 `_physics_process` 上下文调用安全；别在树外或构造期调。
4. **`--headless` 无渲染**：截不了图；只在纯逻辑断言时用它提速。
5. **测试脚本类型转换**：`Array[Vector2i]` 等 typed array 的比较/转换在脚本里容易 parse error，逐元素断言更稳。
6. **噪声过滤**：macOS 日志里 `noErr`、证书行不是错误；只认 `SCRIPT ERROR` / `ERROR:` 与自己的失败输出。
7. **信号驱动的按钮**：`button.pressed.emit()` 等价于点击且无需坐标；比合成鼠标事件可靠。

## 断言与产物规范

- 失败收集进数组、最后统一 `push_error` 并 `quit(1)`；调用侧看 exit code 判定，不靠肉眼扫日志。
- 每包验证的断言数、截图文件名、结论写入当周周志；截图目录不入库（`art-intake` 已忽略），复核图（放大对比等）用完即删。
- Codex 单会话内所有图片工具结果合计不得超过 3 张；自动化产生更多截图时，原图留在磁盘，以联系表和非图像元数据完成首轮核对，超额细看交由新会话。
- Bash 调用侧记得设超时（本仓库经验：单次带窗口运行 < 60 秒，卡住通常是脚本没 `quit()`）。
