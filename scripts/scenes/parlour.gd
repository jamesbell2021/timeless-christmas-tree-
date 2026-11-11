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

var lamps_on := true
var candles_lit := false
var first_visit := false

var _thumbs: Dictionary = {}
var _perf_t := 0.0
var _perf_frames := 0
var _perf_done := false


func _init(p_first_visit: bool = false) -> void:
	first_visit = p_first_visit


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
	GameState.set_lighting(lamps_on, candles_lit)
	ui.refresh_toggles()


func set_candles(on: bool, animate: bool = true) -> void:
	candles_lit = on
	decor.set_candles_lit(on, animate)
	_tween_ambient(animate)
	GameState.set_lighting(lamps_on, candles_lit)
	ui.refresh_toggles()
	if on and animate and decor.light_count() == 0:
		ui.toast("There are no candles on the tree yet. Find them in the trunk.")


func _tween_ambient(animate: bool) -> void:
	var c := _ambient_color()
	if animate:
		create_tween().tween_property(darkness, "color", c, 0.9).set_trans(Tween.TRANS_SINE)
	else:
		darkness.color = c


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
