extends Node
## Screenshot harness: visits every screen and saves PNGs to tests/out/.
## Run: godot --path . --rendering-driver opengl3 res://tests/shots.tscn

var out := "res://tests/out/"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7)
	if only == "" or only == "title":
		await _scene_shots(TitleScreen.new(), "title", [3.0])
	if only == "" or only == "story":
		await _scene_shots(StorySeedling.new(), "s1_seedling", [5.0, 14.0, 19.0])
		await _scene_shots(StoryYears.new(), "s2_years", [4.0, 9.0, 17.0, 26.0])
		await _scene_shots(StoryArrival.new(), "s3_arrival", [7.0, 17.0])
		await _scene_shots(StoryChoosing.new(), "s4_choosing", [5.0, 11.0, 21.0])
	if only == "title_save":
		GameState.stage_reached = 4
		GameState.story_complete = true
		await _scene_shots(TitleScreen.new(), "title_save", [3.0])
		get_tree().quit()
		return
	if only == "showcase":
		await _showcase()
		get_tree().quit()
		return
	if only == "" or only == "ui":
		var p := Parlour.new(true)
		add_child(p)
		await _wait(2.0)
		await _shot("p_intro")
		p.ui.open_settings()
		await _wait(0.6)
		await _shot("p_settings")
		p.ui._modal.close_panel()
		await _wait(0.5)
		p.decor.load_items([{"id": "bauble_red", "x": 960.0, "y": 600.0}, {"id": "topper_star", "x": 960.0, "y": 192.0}])
		await p.ui.open_album()
		await _wait(0.6)
		await _shot("p_album")
		p.ui._modal.close_panel()
		await _wait(0.5)
		await p.ui.open_share()
		await _wait(1.2)
		await _shot("p_share")
		p.queue_free()
	get_tree().quit()


func _showcase() -> void:
	## A fully dressed parlour for the README.
	GameState.clear_arrangement(GameState.current_arrangement)
	var p := Parlour.new(false)
	add_child(p)
	await get_tree().process_frame
	var t := p.tree
	var items: Array = []
	var ids := ["bauble_red", "bauble_gold", "dresden_star", "bauble_silver", "apple", "glass_bird", "bauble_green", "teardrop_gold",
		"candy_cane", "gingerbread", "bauble_blue", "icicle", "pomander", "bauble_amethyst", "scrap_angel", "kugel_grapes",
		"gilded_walnut", "teardrop_red", "cornucopia", "pinecone", "sugar_mouse", "paper_fan"]
	var pts: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 1901
	var tries := 0
	while pts.size() < 54 and tries < 6000:
		tries += 1
		var local := Vector2(rng.randf_range(-290, 290), rng.randf_range(-600, -50))
		if not t.contains_local(local, 22.0):
			continue
		var ok := true
		for q in pts:
			if (q as Vector2).distance_to(local) < 58.0:
				ok = false
				break
		if ok:
			pts.append(local)
	for i in pts.size():
		var id: String = ids[i % ids.size()]
		if i % 4 == 0:
			id = "candle_beeswax" if i % 8 == 0 else "candle_white"
		items.append({"id": id, "x": t.position.x + pts[i].x, "y": t.position.y + pts[i].y})
	items.append({"id": "topper_angel", "x": t.position.x, "y": t.position.y + t.apex.y + 8})
	items.append({"id": "tinsel_gold", "x": 870.0, "y": 360.0, "x2": 1050.0, "y2": 392.0})
	items.append({"id": "glass_beads", "x": 800.0, "y": 520.0, "x2": 1120.0, "y2": 556.0})
	items.append({"id": "popcorn", "x": 742.0, "y": 680.0, "x2": 1178.0, "y2": 712.0})
	items.append({"id": "electric_lights", "x": 700.0, "y": 812.0, "x2": 1220.0, "y2": 836.0})
	items.append({"id": "mantel_garland", "x": 340.0, "y": 442.0})
	items.append({"id": "stocking_red", "x": 150.0, "y": 448.0, "hook": 0})
	items.append({"id": "stocking_cream", "x": 240.0, "y": 448.0, "hook": 1})
	items.append({"id": "stocking_green", "x": 440.0, "y": 448.0, "hook": 2})
	items.append({"id": "stocking_red", "x": 530.0, "y": 448.0, "hook": 3})
	items.append({"id": "candlestick", "x": 190.0, "y": 420.0})
	items.append({"id": "candlestick", "x": 490.0, "y": 420.0})
	items.append({"id": "holly", "x": 340.0, "y": 150.0})
	items.append({"id": "wreath", "x": 1645.0, "y": 206.0})
	items.append({"id": "christmas_cards", "x": 1830.0, "y": 652.0})
	items.append({"id": "present_red", "x": 830.0, "y": 908.0})
	items.append({"id": "present_brown", "x": 1100.0, "y": 920.0})
	items.append({"id": "present_tartan", "x": 1190.0, "y": 868.0})
	items.append({"id": "present_green", "x": 760.0, "y": 870.0})
	items.append({"id": "teddy", "x": 670.0, "y": 935.0})
	items.append({"id": "rocking_horse", "x": 1330.0, "y": 930.0})
	items.append({"id": "noahs_ark", "x": 560.0, "y": 905.0})
	items.append({"id": "drum", "x": 1240.0, "y": 940.0})
	items.append({"id": "mistletoe", "x": 640.0, "y": 210.0})
	p.decor.load_items(items)
	Input.warp_mouse(Vector2(1440, 330))
	p.set_candles(true, false)
	await _wait(1.6)
	await _shot("showcase_lamps")
	p.set_lamps(false, false)
	await _wait(1.6)
	await _shot("showcase_candlelight")
	p.ui.set_ui_hidden(true)
	await _wait(0.6)
	await _shot("showcase_clean")
	p.ui.set_ui_hidden(false)
	p.set_fireside(true)
	await _wait(5.0)
	await _shot("showcase_fireside_a")
	await _wait(22.0)
	await _shot("showcase_fireside_b")
	p.set_fireside(false)
	await _wait(1.2)
	await _shot("showcase_after_fireside")
	p.ui.open_settings()
	await _wait(0.6)
	await _shot("showcase_settings")
	p.ui._modal.close_panel()
	await _wait(0.5)
	p.set_lamps(true, false)
	await _wait(0.8)
	await p.ui.open_share()
	await _wait(1.0)
	await _shot("showcase_share")


func _scene_shots(node: Node, name: String, times: Array) -> void:
	add_child(node)
	var elapsed := 0.0
	for t in times:
		await _wait(float(t) - elapsed)
		elapsed = float(t)
		await _shot("%s_%02d" % [name, int(t)])
	node.queue_free()
	await get_tree().process_frame


func _wait(secs: float) -> void:
	if secs > 0.0:
		await get_tree().create_timer(secs).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out + name + ".png")
	print("shot ", name)
