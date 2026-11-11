extends Node
## TikTok promo director: a 24-second vertical (9:16) film of the game,
## played from the real scenes with scripted decorating, candle lighting, a
## story montage and an end card.
##
## Render (Movie Maker, fixed 30 fps, captures the game audio too):
##   godot --path . --resolution 1080x1920 --fixed-fps 30 \
##     --write-movie trailer.avi res://tools/trailer/trailer.tscn -- --no-adapt
## Check stills first:
##   godot --path . --resolution 1080x1920 --fixed-fps 30 \
##     res://tools/trailer/trailer.tscn -- --no-adapt --stills=0.6,7,13,16,19,22

const LENGTH := 24.0
const COLUMN := Vector2i(608, 1080)   # the 9:16 view onto the 1920x1080 world

var parlour: Parlour
var cam: Camera2D
var story: StoryScene
var story_cam: Camera2D
var overlay: Control
var black: ColorRect
var t := 0.0
var stills: Array = []
var _plan: Array = []      # [time, kind, data]
var _plan_i := 0
var _captions: Array = []  # [t0, t1, text, y]
var _end_alpha := 0.0
var _montage_stage := -1


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--stills="):
			for s in a.substr(9).split(","):
				stills.append(float(s))
	get_tree().root.content_scale_size = COLUMN
	GameState.settings["painterly"] = 2
	GameState.settings["snow"] = true
	GameState.settings["music_volume"] = 0.75
	GameState.settings["ambience_volume"] = 0.55
	GameState.settings["sfx_volume"] = 0.8
	GameState.settings_changed.emit()
	GameState.clear_arrangement(GameState.current_arrangement)
	AudioDirector.finish_jobs()
	parlour = Parlour.new(false)
	add_child(parlour)
	parlour.ui.visible = false
	parlour.decor.enabled = false
	cam = Camera2D.new()
	parlour.add_child(cam)
	cam.make_current()
	_build_overlay()
	_build_plan()
	AudioDirector.music_locked = false
	AudioDirector.start_music_now("parlour")
	AudioDirector.music_locked = true
	_captions = [
		[0.3, 4.6, "POV: you're dressing\na Christmas tree\nin 1901", 210.0],
		[5.0, 10.0, "54 Edwardian ornaments.\nNo timers. No scores.", 210.0],
		[10.8, 14.8, "Then dim the lamps\nand light the candles...", 210.0],
		[15.1, 19.3, "Every tree\nhas a story", 210.0],
	]


func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	overlay = Control.new()
	overlay.size = Vector2(COLUMN)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.draw.connect(_draw_overlay)
	layer.add_child(overlay)
	black = ColorRect.new()
	black.color = Color(0.02, 0.01, 0.01)
	black.size = Vector2(COLUMN)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black.modulate.a = 1.0
	layer.add_child(black)


func _build_plan() -> void:
	var tree := parlour.tree
	# Poisson-ish spread of hanging spots over the boughs
	var rng := RandomNumberGenerator.new()
	rng.seed = 1901
	var pts: Array = []
	var tries := 0
	while pts.size() < 44 and tries < 8000:
		tries += 1
		var local := Vector2(rng.randf_range(-285, 285), rng.randf_range(-600, -60))
		if not tree.contains_local(local, 24.0):
			continue
		var ok := true
		for q in pts:
			if (q as Vector2).distance_to(local) < 56.0:
				ok = false
				break
		if ok:
			pts.append(local)
	pts.shuffle()
	var ids := ["bauble_red", "bauble_gold", "dresden_star", "glass_bird", "apple", "bauble_silver", "candy_cane",
		"gingerbread", "bauble_green", "teardrop_gold", "pomander", "icicle", "bauble_blue", "scrap_angel",
		"kugel_grapes", "teardrop_red", "cornucopia", "gilded_walnut", "bauble_amethyst", "pinecone", "sugar_mouse", "paper_fan"]
	# Ornaments arrive faster and faster: 0.6s apart at first, ~0.12s by the end
	var time := 0.45
	for i in pts.size():
		var id: String = ids[i % ids.size()]
		if i % 3 == 1:
			id = "candle_white" if i % 2 == 0 else "candle_beeswax"
		var p: Vector2 = tree.position + pts[i]
		_plan.append([time, "fly", {"id": id, "x": p.x, "y": p.y}])
		time += lerpf(0.55, 0.12, minf(1.0, float(i) / 24.0))
	_plan.append([3.6, "garland", {"id": "tinsel_gold", "x": 860.0, "y": 380.0, "x2": 1060.0, "y2": 410.0}])
	_plan.append([5.4, "garland", {"id": "glass_beads", "x": 800.0, "y": 545.0, "x2": 1120.0, "y2": 580.0}])
	_plan.append([7.0, "garland", {"id": "popcorn", "x": 742.0, "y": 700.0, "x2": 1178.0, "y2": 732.0}])
	_plan.append([8.2, "garland", {"id": "electric_lights", "x": 705.0, "y": 818.0, "x2": 1215.0, "y2": 842.0}])
	_plan.append([8.7, "fly", {"id": "present_red", "x": 840.0, "y": 912.0}])
	_plan.append([8.95, "fly", {"id": "present_brown", "x": 1090.0, "y": 922.0}])
	_plan.append([9.2, "fly", {"id": "teddy", "x": 760.0, "y": 940.0}])
	_plan.append([9.4, "fly", {"id": "present_tartan", "x": 1170.0, "y": 870.0}])
	_plan.append([9.75, "fly", {"id": "topper_angel", "x": tree.position.x, "y": tree.position.y + tree.apex.y + 8}])
	_plan.append([10.9, "lamps_off", {}])
	_plan.append([11.4, "candles", {}])
	_plan.append([15.0, "montage", 0])
	_plan.append([16.5, "montage", 1])
	_plan.append([18.0, "montage", 2])
	_plan.append([19.5, "end", {}])
	_plan.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])


func _process(delta: float) -> void:
	t += delta
	# Opening fade
	black.modulate.a = clampf(1.0 - t / 0.35, 0.0, 1.0)
	if t > LENGTH - 0.7:
		black.modulate.a = clampf((t - (LENGTH - 0.7)) / 0.6, 0.0, 1.0)
	while _plan_i < _plan.size() and float(_plan[_plan_i][0]) <= t:
		_run(_plan[_plan_i])
		_plan_i += 1
	_update_cameras()
	if t > 19.5:
		_end_alpha = clampf((t - 19.7) / 0.8, 0.0, 1.0)
	overlay.queue_redraw()
	if not stills.is_empty() and t >= float(stills[0]):
		var s: float = stills.pop_front()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tests/out/trailer_%04.1f.png" % s)
		print("still ", s)
		if stills.is_empty():
			get_tree().quit()
	if t >= LENGTH and stills.is_empty():
		get_tree().quit()


func _update_cameras() -> void:
	if story == null:
		# Start close on the boughs, ease out to the whole tree, then a gentle
		# push-in while the candles are lit.
		var z := lerpf(1.32, 1.0, smoothstep(0.0, 9.5, t))
		var cy := lerpf(560.0, 540.0, smoothstep(0.0, 9.5, t))
		if t > 10.6:
			z = lerpf(1.0, 1.1, smoothstep(10.6, 15.0, t))
			cy = lerpf(540.0, 500.0, smoothstep(10.6, 15.0, t))
		if t > 19.5:
			z = 1.0
			cy = 540.0
		cam.zoom = Vector2(z, z)
		cam.position = Vector2(960, cy)
	elif story_cam:
		var u := fmod(t - 15.0, 1.5) / 1.5
		match _montage_stage:
			0:
				story_cam.position = Vector2(980, lerpf(600.0, 570.0, u))
				story_cam.zoom = Vector2.ONE * lerpf(1.0, 1.08, u)
			1:
				story_cam.position = Vector2(980, 560)
				story_cam.zoom = Vector2.ONE * lerpf(1.04, 1.0, u)
			_:
				story_cam.position = Vector2(lerpf(1200.0, 1260.0, u), 600)
				story_cam.zoom = Vector2.ONE


func _run(step: Array) -> void:
	match step[1]:
		"fly":
			_fly(step[2])
		"garland":
			var d := Catalogue.get_item(step[2]["id"])
			var node := parlour.decor._spawn(d, (step[2] as Dictionary).duplicate())
			parlour.decor._drag_def = d
			parlour.decor._celebrate(node, Vector2(step[2]["x"], step[2]["y"]).lerp(Vector2(step[2]["x2"], step[2]["y2"]), 0.5))
		"lamps_off":
			parlour.set_lamps(false, true)
		"candles":
			parlour.set_candles(true, true)
		"montage":
			_show_story(int(step[2]))
		"end":
			_end_story()


func _fly(data: Dictionary) -> void:
	## An ornament sails in from the trunk (bottom right) and pops into place.
	var d := Catalogue.get_item(data["id"])
	var target := Vector2(data["x"], data["y"])
	var ghost := Decoration.new().setup(d, data.duplicate())
	var start := Vector2(1330 + randf_range(-20, 40), 1180)
	ghost.position = start
	ghost.scale = Vector2.ONE * 1.25
	parlour.decor.layer_drag.add_child(ghost)
	var ctrl := (start + target) * 0.5 + Vector2(-120, -160)
	var dur := 0.42
	var move := func(u: float) -> void:
		var e := 1.0 - pow(1.0 - u, 3.0)
		ghost.position = start.lerp(ctrl, e).lerp(ctrl.lerp(target, e), e)
		ghost.rotation = sin(u * PI) * -0.4
	var tw := create_tween()
	tw.tween_method(move, 0.0, 1.0, dur)
	tw.tween_callback(func() -> void:
		ghost.queue_free()
		var node := parlour.decor._spawn(d, data.duplicate())
		parlour.decor._drag_def = d
		parlour.decor._celebrate(node, target)
	)


func _show_story(stage: int) -> void:
	_montage_stage = stage
	if story:
		story.queue_free()
	match stage:
		0:
			story = StorySeedling.new()
		1:
			story = StoryYears.new()
		_:
			story = StoryChoosing.new()
	add_child(story)
	story._ui.visible = false
	story.t = [12.2, 17.5, 16.3][stage]
	story_cam = Camera2D.new()
	story.add_child(story_cam)
	story_cam.make_current()
	parlour.visible = false
	_flash()


func _end_story() -> void:
	if story:
		story.queue_free()
	story = null
	story_cam = null
	parlour.visible = true
	cam.make_current()
	AudioDirector.set_scene_ambience("parlour")
	_flash()


func _flash() -> void:
	# A quick dip to black hides each cut.
	var r := ColorRect.new()
	r.color = Color(0.02, 0.01, 0.01)
	r.size = Vector2(COLUMN)
	overlay.add_child(r)
	var tw := create_tween()
	tw.tween_property(r, "modulate:a", 0.0, 0.22)
	tw.tween_callback(r.queue_free)


func _draw_overlay() -> void:
	var W := float(COLUMN.x)
	for c in _captions:
		var t0: float = c[0]
		var t1: float = c[1]
		if t < t0 or t > t1:
			continue
		var a := clampf((t - t0) / 0.35, 0.0, 1.0) * clampf((t1 - t) / 0.35, 0.0, 1.0)
		var rise := (1.0 - clampf((t - t0) / 0.35, 0.0, 1.0)) * 18.0
		var lines: PackedStringArray = (c[2] as String).split("\n")
		var y: float = c[3] + rise
		# A soft dark ribbon behind the words
		var h := lines.size() * 58.0 + 30.0
		var band := Rect2(0, y - 46, W, h)
		overlay.draw_rect(band, Color(0.03, 0.015, 0.01, 0.42 * a))
		UIKit.divider(overlay, Vector2(W * 0.5, band.end.y - 10), 90, Color(UIKit.GOLD_LIGHT, 0.8 * a))
		for i in lines.size():
			_text(Vector2(W * 0.5, y + i * 58.0), lines[i], 48, a)
	if _end_alpha > 0.0:
		var a := _end_alpha
		overlay.draw_rect(Rect2(0, 0, W, 1080), Color(0.02, 0.01, 0.005, 0.5 * a))
		var card := Rect2(34, 250, W - 68, 470)
		_paper_card(card, a)
		_gilt(Vector2(W * 0.5, 350), "A Timeless", 66, a)
		_gilt(Vector2(W * 0.5, 424), "Christmas Tree", 66, a)
		UIKit.divider(overlay, Vector2(W * 0.5, 472), 150, Color(UIKit.GOLD_DARK, a))
		UIKit.text_centered(overlay, UIKit.font("title_italic"), Vector2(W * 0.5, 516), "An Edwardian Yuletide", 34, Color(UIKit.INK, a), false)
		UIKit.text_centered(overlay, UIKit.font("caps"), Vector2(W * 0.5, 600), "Play it in your browser", 30, Color(UIKit.BURGUNDY, a), false)
		UIKit.text_centered(overlay, UIKit.font("body_italic"), Vector2(W * 0.5, 650), "Every picture, carol & crackle made in code", 21, Color(UIKit.INK, 0.75 * a), false)
		_text(Vector2(W * 0.5, 776), "Link in bio", 44, a)


func _paper_card(r: Rect2, a: float) -> void:
	overlay.draw_rect(Rect2(r.position + Vector2(6, 10), r.size), Color(0, 0, 0, 0.45 * a))
	overlay.draw_texture_rect(Tex.paper(), r, true, Color(1, 1, 1, a))
	overlay.draw_rect(r.grow(-12), Color(UIKit.GOLD_DARK, a), false, 2.0)
	overlay.draw_rect(r.grow(-17), Color(UIKit.GOLD_DARK, 0.6 * a), false, 1.0)
	var holly := Catalogue.get_item("holly")
	for p in [r.position + Vector2(52, 50), Vector2(r.end.x - 52, r.position.y + 50)]:
		overlay.draw_set_transform(p, 0.0, Vector2(1.25, 1.25))
		DecorArt.draw_item(overlay, holly, 2)
	overlay.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _text(c: Vector2, s: String, size: int, a: float) -> void:
	var f := UIKit.font("title")
	var sz := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var base := Vector2(c.x - sz.x * 0.5, c.y + (f.get_ascent(size) - f.get_descent(size)) * 0.5)
	overlay.draw_string_outline(f, base + Vector2(0, 3), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 10, Color(0, 0, 0, 0.55 * a))
	overlay.draw_string_outline(f, base, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 6, Color(0.12, 0.05, 0.02, 0.9 * a))
	overlay.draw_string(f, base, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(1.0, 0.92, 0.7, a))


func _gilt(c: Vector2, s: String, size: int, a: float) -> void:
	var f := UIKit.font("title")
	var sz := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var base := Vector2(c.x - sz.x * 0.5, c.y + (f.get_ascent(size) - f.get_descent(size)) * 0.5)
	overlay.draw_string_outline(f, base + Vector2(0, 3), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 6, Color(0, 0, 0, 0.5 * a))
	overlay.draw_string_outline(f, base, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(UIKit.GOLD_DARK.darkened(0.4), a))
	overlay.draw_string(f, base, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(UIKit.GOLD, a))
	overlay.draw_string(f, base + Vector2(0, -1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(UIKit.GOLD_LIGHT, 0.45 * a))
