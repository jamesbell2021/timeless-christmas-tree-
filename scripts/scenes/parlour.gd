class_name Parlour
extends Node2D
## Act II — the decorating sandbox in the Edwardian parlour.
## Composes the painted room, the tree, the decoration manager, the lighting
## states and the UI, and keeps GameState in sync with what the player makes.

signal story_requested(stage: int)
signal title_requested

const L = preload("res://scripts/art/room_layout.gd")

var tree: TreeArt
var decor: DecorManager
var fireplace: RoomFireplace
var furniture: RoomFurniture
var bay_window: RoomWindow
var side_window: RoomWindow
var ui: ParlourUI
var darkness: ColorRect

var twinkle: Twinkle

## Fireside mode: the parlour as a screensaver. The interface goes away, the
## lamps are dimmed, the view drifts slowly round the room and, if the Album
## holds more than one decorated tree, it turns the page every few minutes.
const IDLE_SECONDS := 300.0
const FIRESIDE_PAGE_SECONDS := 150.0
const FIRESIDE_SHOTS := [
	[Vector2(960, 540), 1.0],      # the whole room
	[Vector2(960, 420), 1.16],     # the tree
	[Vector2(330, 470), 1.2],      # the hearth
	[Vector2(960, 620), 1.07],     # parcels under the boughs
	[Vector2(1520, 470), 1.15],    # the armchair and the snowy window
]

var fireside := false
var start_fireside := false
var _fs_tween: Tween
var _fs_origin := 0
var _fs_lamps := true
var _fs_candles := false
var _fs_cycle := 0.0
var _fs_breeze := 0.0
var _fs_busy := false
var _idle := 0.0

var lamps_on := true
var candles_lit := false
var first_visit := false

var _thumbs: Dictionary = {}
var _perf_t := 0.0
var _perf_frames := 0
var _perf_done := false


func _init(p_first_visit: bool = false, p_start_fireside: bool = false) -> void:
	first_visit = p_first_visit
	start_fireside = p_start_fireside


func _ready() -> void:
	_build_room()
	_build_lighting()
	add_child(PostFX.new("oil"))
	ui = ParlourUI.new(self)
	add_child(ui)
	decor.trunk_rect_provider = ui.trunk_rect
	decor.hint_changed.connect(ui.show_hint)
	decor.hover_changed.connect(ui.show_hover)
	decor.items_changed.connect(_on_items_changed)
	GameState.reach_stage(4)
	_load_current(false)
	GameState.settings_changed.connect(_apply_settings)
	_apply_settings()
	AudioDirector.set_scene_ambience("parlour")
	AudioDirector.play_music_for("parlour")
	if first_visit:
		ui.intro_caption()
	if start_fireside:
		get_tree().create_timer(2.2).timeout.connect(func() -> void: set_fireside(true))


func _build_room() -> void:
	add_child(RoomWalls.new())
	bay_window = RoomWindow.new()
	bay_window.rect = L.WINDOW
	bay_window.pelmet = L.PELMET
	add_child(bay_window)
	side_window = RoomWindow.new()
	side_window.rect = L.WINDOW_R
	side_window.pelmet = L.PELMET_R
	side_window.view_seed = 8
	side_window.upper_cols = 2
	side_window.lower_cols = 2
	add_child(side_window)
	var robin := Robin.new()
	robin.position = Vector2(L.WINDOW_R.position.x + 70, L.WINDOW_R.end.y + 8)
	robin.size = 1.1
	robin.facing = 1.0
	add_child(robin)
	fireplace = RoomFireplace.new()
	add_child(fireplace)
	furniture = RoomFurniture.new()
	add_child(furniture)
	tree = TreeArt.new()
	tree.height = L.TREE_HEIGHT
	tree.width = L.TREE_WIDTH
	tree.seed_value = 1901
	tree.palette = "parlour"
	tree.position = L.TREE_BASE
	tree.z_index = 10
	add_child(tree)
	var stand := Painter.new(func(ci: CanvasItem) -> void: RoomFurniture.paint_tree_stand(ci, L.TREE_BASE))
	stand.z_index = 11
	add_child(stand)
	decor = DecorManager.new()
	add_child(decor)
	decor.setup(tree)
	twinkle = Twinkle.new()
	twinkle.decor = decor
	add_child(twinkle)


func _build_lighting() -> void:
	darkness = ColorRect.new()
	darkness.size = Vector2(1920, 1080)
	darkness.mouse_filter = Control.MOUSE_FILTER_IGNORE
	darkness.material = Tex.mul_material()
	darkness.z_index = 50
	darkness.z_as_relative = false
	darkness.color = _ambient_color()
	add_child(darkness)


func _ambient_color() -> Color:
	if lamps_on:
		return Color(0.84, 0.8, 0.76) if candles_lit else Color(0.9, 0.86, 0.82)
	return Color(0.4, 0.35, 0.34) if candles_lit else Color(0.34, 0.3, 0.3)


func _process(delta: float) -> void:
	_perf_check(delta)
	if fireside:
		_fs_breeze -= delta
		if _fs_breeze <= 0.0:
			_fs_breeze = randf_range(22.0, 40.0)
			decor.breeze(0.16)
		_fs_cycle += delta
		if _fs_cycle >= FIRESIDE_PAGE_SECONDS and not _fs_busy:
			_fs_cycle = 0.0
			_fireside_turn_page()
	elif bool(GameState.settings["idle_fireside"]) and not ui.has_modal() and not decor.is_dragging():
		_idle += delta
		if _idle >= IDLE_SECONDS:
			set_fireside(true)
	else:
		_idle = 0.0


func _input(event: InputEvent) -> void:
	var press: bool = (event is InputEventKey and event.pressed and not event.echo) \
			or (event is InputEventMouseButton and event.pressed) \
			or (event is InputEventScreenTouch and event.pressed)
	if fireside:
		if press:
			set_fireside(false)
			get_viewport().set_input_as_handled()
	elif press or event is InputEventMouseMotion or event is InputEventScreenDrag:
		_idle = 0.0


func _perf_check(delta: float) -> void:
	# Adaptive brushwork: if the full oil-paint filter can't hold a smooth
	# frame rate on this machine, step down once and say so.
	if _perf_done:
		return
	if "--no-adapt" in OS.get_cmdline_user_args():
		_perf_done = true
		return
	_perf_t += delta
	if _perf_t < 1.5:
		return
	_perf_frames += 1
	if _perf_t > 6.5:
		_perf_done = true
		var fps := _perf_frames / (_perf_t - 1.5)
		if fps < 38.0 and int(GameState.settings["painterly"]) == 2:
			GameState.set_setting("painterly", 1)
			ui.toast("Using lighter brushwork for smoother play (see Settings)")


func _apply_settings() -> void:
	twinkle.visible = bool(GameState.settings["twinkle"])
	var snow: bool = GameState.settings["snow"]
	bay_window.snow.visible = snow
	side_window.snow.visible = snow


# ------------------------------------------------------------ lighting

func set_lamps(on: bool, animate: bool = true) -> void:
	lamps_on = on
	fireplace.set_sconces_lit(on)
	furniture.set_lamp_lit(on)
	_tween_ambient(animate)
	if animate:
		AudioDirector.sfx("lamp" if on else "snuff")
	if not fireside:
		GameState.set_lighting(lamps_on, candles_lit)
	ui.refresh_toggles()


func set_candles(on: bool, animate: bool = true) -> void:
	candles_lit = on
	decor.set_candles_lit(on, animate)
	_tween_ambient(animate)
	if not fireside:
		GameState.set_lighting(lamps_on, candles_lit)
	ui.refresh_toggles()
	if on and animate and decor.light_count() == 0:
		ui.toast("There are no candles on the tree yet. Find them in the trunk.")


func _tween_ambient(animate: bool) -> void:
	if twinkle:
		twinkle.energy = 1.0 if candles_lit else (0.55 if lamps_on else 0.7)
	var c := _ambient_color()
	if animate:
		create_tween().tween_property(darkness, "color", c, 0.9).set_trans(Tween.TRANS_SINE)
	else:
		darkness.color = c


# ------------------------------------------------------------ fireside

func set_fireside(on: bool) -> void:
	if fireside == on or (on and (ui.has_modal() or decor.is_dragging())):
		return
	_idle = 0.0
	if on:
		_fs_origin = GameState.current_arrangement
		_fs_lamps = lamps_on
		_fs_candles = candles_lit
		_fs_cycle = 0.0
		_fs_breeze = 9.0
		ui.set_fireside(true)
		decor.enabled = false
		decor.hover_changed.emit("")
		fireside = true
		_fireside_lighting(true)
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		_keep_screen_awake(true)
		_fs_drift(1)
		return
	if _fs_tween:
		_fs_tween.kill()
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "scale", Vector2.ONE, 0.8)
	tw.tween_property(self, "position", Vector2.ZERO, 0.8)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_keep_screen_awake(false)
	fireside = false
	decor.enabled = true
	ui.set_fireside(false)
	ui.fade(false, 0.3)
	if GameState.current_arrangement != _fs_origin:
		# The Album page was turned while we were away: come back to the
		# tree the player was working on.
		GameState.switch_arrangement(_fs_origin)
		_load_current(false)
	else:
		set_lamps(_fs_lamps, false)
		set_candles(_fs_candles, false)


func _fireside_lighting(animate: bool) -> void:
	# Candlelight if the tree has any; otherwise leave the lamps burning so
	# the tree can still be seen.
	if decor.light_count() > 0:
		set_lamps(false, animate)
		set_candles(true, animate)


func _fs_drift(i: int) -> void:
	var shot: Array = FIRESIDE_SHOTS[i % FIRESIDE_SHOTS.size()]
	var z: float = shot[1]
	var focus: Vector2 = shot[0]
	_fs_tween = create_tween()
	_fs_tween.set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_fs_tween.tween_property(self, "scale", Vector2(z, z), 26.0)
	_fs_tween.tween_property(self, "position", -focus * (z - 1.0), 26.0)
	_fs_tween.chain().tween_interval(7.0)
	_fs_tween.chain().tween_callback(_fs_drift.bind(i + 1))


func _fireside_turn_page() -> void:
	var next := -1
	for k in range(1, GameState.ARRANGEMENT_COUNT):
		var idx := (GameState.current_arrangement + k) % GameState.ARRANGEMENT_COUNT
		if not GameState.is_arrangement_empty(idx):
			next = idx
			break
	if next < 0:
		return
	_fs_busy = true
	await ui.fade(true, 1.4)
	if fireside:
		GameState.switch_arrangement(next)
		var a := GameState.current()
		decor.reset_undo()
		decor.candles_lit = false
		decor.load_items(a.get("items", []))
		set_lamps(true, false)
		set_candles(false, false)
		_fireside_lighting(false)
		await ui.fade(false, 1.8)
	_fs_busy = false


func _keep_screen_awake(on: bool) -> void:
	if OS.has_feature("web"):
		if on:
			JavaScriptBridge.eval("(function(){window.__tctWakeWanted=true;function req(){if(!window.__tctWakeWanted||!navigator.wakeLock){return;}navigator.wakeLock.request('screen').then(function(l){window.__tctWake=l;}).catch(function(){});}if(!window.__tctWakeHooked){window.__tctWakeHooked=true;document.addEventListener('visibilitychange',function(){if(!document.hidden){req();}});}req();})()", true)
		else:
			JavaScriptBridge.eval("(function(){window.__tctWakeWanted=false;if(window.__tctWake){try{window.__tctWake.release();}catch(e){}window.__tctWake=null;}})()", true)
	else:
		DisplayServer.screen_set_keep_on(on)


# ------------------------------------------------------- arrangements

func _load_current(animate: bool) -> void:
	var a := GameState.current()
	decor.reset_undo()
	decor.candles_lit = bool(a.get("candles_lit", false))
	decor.load_items(a.get("items", []))
	set_lamps(bool(a.get("lamps_on", true)), false)
	set_candles(bool(a.get("candles_lit", false)), false)
	if animate:
		ui.toast(str(a.get("name", "")))


func _on_items_changed() -> void:
	GameState.set_current_items(decor.serialize())
	ui.refresh_toggles()


func switch_arrangement(index: int) -> void:
	if index == GameState.current_arrangement:
		return
	await capture_thumbnail()
	await ui.fade(true)
	GameState.switch_arrangement(index)
	_load_current(true)
	AudioDirector.sfx("page")
	await ui.fade(false)


func capture_image(hide_ui: bool = true) -> Image:
	## Renders the painted room without the interface and returns it.
	if DisplayServer.get_name() == "headless":
		# No renderer when running automated tests: hand back a blank canvas.
		await get_tree().process_frame
		return Image.create(1920, 1080, false, Image.FORMAT_RGB8)
	var was_visible := ui.visible
	if hide_ui:
		ui.visible = false
		decor.enabled = false
		decor.hover_changed.emit("")
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if hide_ui:
		ui.visible = was_visible
		decor.enabled = true
	# The window may be any size or shape: crop away letterbox bars and
	# normalise to the 1920x1080 canvas.
	var sz := Vector2(img.get_size())
	var k := minf(sz.x / 1920.0, sz.y / 1080.0)
	var content := Vector2(1920.0, 1080.0) * k
	var off := ((sz - content) * 0.5).floor()
	if off.x >= 1.0 or off.y >= 1.0:
		img = img.get_region(Rect2i(Vector2i(off), Vector2i(content)))
	if img.get_width() != 1920:
		img.resize(1920, 1080, Image.INTERPOLATE_BILINEAR)
	return img


func capture_thumbnail() -> void:
	var img := await capture_image(true)
	img.resize(384, 216, Image.INTERPOLATE_BILINEAR)
	var idx := GameState.current_arrangement
	_thumbs[idx] = ImageTexture.create_from_image(img)
	img.save_png(GameState.thumb_path(idx))


func thumbnail(index: int) -> Texture2D:
	if _thumbs.has(index):
		return _thumbs[index]
	var path := GameState.thumb_path(index)
	if FileAccess.file_exists(path) and not GameState.is_arrangement_empty(index):
		var img := Image.load_from_file(path)
		if img:
			_thumbs[index] = ImageTexture.create_from_image(img)
			return _thumbs[index]
	return null


func request_story(stage: int) -> void:
	await capture_thumbnail()
	story_requested.emit(stage)


func request_title() -> void:
	await capture_thumbnail()
	title_requested.emit()
