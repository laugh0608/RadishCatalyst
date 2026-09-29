extends RefCounted

static func text(model: RefCounted) -> String:
	var d: Dictionary = model.discovery
	if not d.sample_taken:
		return "发现矿壳的用途\n晶体 → 催化剂\n\n先给采集器与反应器接电，建立首线。也可先到外矿道 (2, 2) 调查并拾取样本。\n\n矿壳阻挡新矿区；样本可用于试制开路材料。"
	if not d.trial_completed:
		var held: Dictionary = model.material_balance().held
		return "试制开路材料\n1 样本 + 2 催化剂\n\n靠近空闲反应器，选择「矿壳试制」并放入材料，接电后完成试制。\n\n催化剂总持有 %d，尚缺 %d；材料可能在仓库、背包或设备内，可从统计定位。\n试制成功将掌握稳定量产方法。" % [held.get("catalyst", 0), maxi(0, 2 - held.get("catalyst", 0))]
	if not d.passages.outer:
		return "量产并打开外矿道\n催化剂 → 解壳剂\n\n把催化剂输出接入解壳剂反应器，再送到仓库。\n背包解壳剂 %d / 4，尚需携带 %d。靠近外矿道西侧使用。\n\n试制产物也能开路；用统计查原料、出料与供电。" % [model.bag.get("crust_solvent", 0), maxi(0, 4 - model.bag.get("crust_solvent", 0))]
	if not d.passages.inner:
		return "让新矿区反哺生产\n富集晶体 → 3 催化剂\n\n外矿道已开通。在内矿区布电、采集富集晶体并接入富集催化剂线。开路不会自动接电。\n\n用统计找到并改善瓶颈，再携带 8 份解壳剂到内矿道西侧。\n背包 %d / 8，尚需携带 %d。" % [model.bag.get("crust_solvent", 0), maxi(0, 8 - model.bag.get("crust_solvent", 0))]
	return "工艺已经可以复用\n两段矿道均已打通\n\n深处新增两个富集矿点和建设空间。继续扩建供电与产线，用统计比较调整前后的实际产出。\n\n保存后可继续经营这个世界。"
