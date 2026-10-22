extends "res://scripts/checks/factory_expansion_boot_check.gd"

const PowerStatus := preload("res://scripts/factory/power_status.gd")
const QuotaNotice := preload("res://scripts/factory/quota_notice.gd")


func _review() -> void:
	world.view.inspection_target = Vector3(-17, 0, -4)
	world.view.zoom = 0.9
	await driver.settle(20)
	driver.expect(world.ui.show_power_links and world.view.wiring.get_child_count() > 0, "unselected world shows power links by default")
	var notice: Control = world.hud.quota_notice
	driver.expect(notice.visible and "余料仍在加工" in notice.title.text, "natural half batch reports completed quota with work remaining")
	var before := _snapshot()
	await native_click(world.hud.buttons.power_links)
	driver.expect(not world.ui.show_power_links and world.view.wiring.get_child_count() == 0, "real toggle hides all power links")
	for e in world.model.entities:
		if PowerStatus.supports(e):
			driver.expect(world.view.models[e.id].power_icon.visible and world.view.models[e.id].power_kind == "connected", "status persists with hidden links %d" % e.id)
	driver.expect(Compare.equivalent(before, Codec.snapshot(world.model, world.store.world_id, world.store.world_name, before.sequence)), "display toggle changes no authoritative state")
	await driver.shot("01-links-hidden-status-visible")
	await native_click(world.hud.buttons.power_links)
	for dimensions in [Vector2i(1100, 720), Vector2i(1440, 900)]:
		root.size = dimensions
		await driver.settle(25)
		driver.expect(root.get_visible_rect().encloses(world.hud.footer.get_global_rect()), "feedback footer fits " + str(dimensions))
		driver.expect(world.hud.world_slot.get_global_rect().encloses(notice.get_global_rect()), "quota notice fits " + str(dimensions))
		driver.expect(notice.get_global_rect().encloses(notice.locate_button.get_global_rect()), "quota action stays within notice")
		await driver.shot("02-partial-%dx%d" % [dimensions.x, dimensions.y])
	var position := Vector2(world.actor.x, world.actor.z)
	await native_click(notice.locate_button)
	driver.expect(Vector2(world.actor.x, world.actor.z) == position and world.actor.target == null, "quota locate moves camera only")
	driver.expect(Compare.equivalent(before, Codec.snapshot(world.model, world.store.world_id, world.store.world_name, before.sequence)), "locating never resets quota or changes stored state")
	world.view.inspection_target = Vector3(-22, 0, -5)
	await driver.settle(15)
	await native_click(world.hud.buttons.pause)
	await driver.world_click(Vector2i(-26, -6))
	await active(0.5, "empty ground click cannot drive walking")
	driver.expect(Vector2(world.actor.x, world.actor.z) == position and world.actor.target == null, "empty ground click leaves actor stationary while time runs")
	world.view.inspection_target = Vector3(2.5, 0, 3.5)
	await driver.settle(15)
	var sample_at: Vector2 = world.hud.viewport_to_screen(world.view.sample_screen())
	driver.expect(world.hud.world_point(sample_at) != null, "distant sample click is unobstructed")
	await driver.motion(sample_at)
	await driver.mouse(sample_at, true)
	await driver.mouse(sample_at, false)
	await active(0.5, "distant sample click cannot drive walking")
	driver.expect(Vector2(world.actor.x, world.actor.z) == position and world.actor.target == null and not world.model.discovery.sample_taken, "distant sample never auto-walks or auto-picks")
	world.view.inspection_target = null
	await walk(Vector2(-27, -9))
	driver.expect(Vector2(world.actor.x, world.actor.z).distance_to(position) > 0.5, "routed WASD still moves actor")
	check_failures()
	if finished: return
	await wait_for(func(): return world.model.by_id(ids.T).items.get("construction_pack", 0) == 2, 100, "half batch naturally finishes two packs")
	if finished: return
	await native_click(world.hud.buttons.pause)
	world.view.inspection_target = Vector3(-17, 0, -4)
	await driver.settle(20)
	driver.expect(not QuotaNotice.summary(world.model).remaining and "已空闲" in notice.title.text and notice.candidates.size() == 3, "finished natural line explicitly reports three completed quotas and idle transport")
	for name in ["C", "F", "R", "A"]:
		driver.expect(world.view.models[int(ids[name])].power_kind == "connected", "idle machine remains electrically available " + name)
	await driver.shot("03-complete-quota-idle-powered")
	stage("feedback-complete", "natural partial restore; real line toggle/locate, ground and sample clicks, routed WASD; natural completion; no actor/material/time injection")
	await _save_checkpoint("feedback-complete")
