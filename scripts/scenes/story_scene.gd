class_name StoryScene
extends Node2D
## Base for the four illustrated chapters of Act I. A chapter is a little
## timed vignette: subclasses build their world, animate it in update(t) and
## supply captions. The base adds the watercolour filter, the chapter title,
## captions and the skip controls.

signal finished
signal skip_all

var single_chapter := false
var stage := 0
var duration := 20.0
var lines: Array = []
var caption_hold := 3.0
var caption_delay := 1.2
var ambience := "spring"
var t := 0.0

var caption: Caption
var _ui: CanvasLayer
var _done := false
var _title_alpha := 0.0


func _ready() -> void:
	build_world()
	add_child(PostFX.new("watercolour"))
	_build_ui()
	AudioDirector.set_scene_ambience(ambience)
	AudioDirector.play_music_for("story")
	get_tree().create_timer(caption_delay).timeout.connect(func() -> void:
		if is_instance_valid(caption):
			caption.play(lines, caption_hold)
	)


func build_world() -> void:
	pass


func update(_time: float, _delta: float) -> void:
	pass


func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 10
	add_child(_ui)
	var root := Control.new()
	root.size = Vector2(1920, 1080)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UIKit.theme()
	_ui.add_child(root)
	caption = Caption.new()
	caption.y_center = 900.0
	root.add_child(caption)
	var title := Control.new()
	title.size = Vector2(1920, 200)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.draw.connect(func() -> void:
		if _title_alpha <= 0.0:
			return
		var chapter: String = GameState.STAGES[stage]["chapter"]
		var parts := chapter.split(": ")
		var a := _title_alpha
		UIKit.text_centered(title, UIKit.font("caps"), Vector2(960, 70), parts[0], 30, Color(1, 0.95, 0.85, a))
		UIKit.divider(title, Vector2(960, 98), 150, Color(UIKit.GOLD_LIGHT, a))
		UIKit.text_centered(title, UIKit.font("title_italic"), Vector2(960, 132), parts[1] if parts.size() > 1 else "", 46, Color(1, 0.95, 0.85, a))
	)
	root.add_child(title)
	var set_alpha := func(v: float) -> void:
		_title_alpha = v
		title.queue_redraw()
	var tw := create_tween()
	tw.tween_method(set_alpha, 0.0, 1.0, 1.2)
	tw.tween_interval(2.4)
	tw.tween_method(set_alpha, 1.0, 0.0, 1.2)
	# Skip controls
	var skip := OrnateButton.new("Next  ›" if not single_chapter else "Back to the Parlour", "plaque")
	skip.font_size = 22
	skip.custom_minimum_size = Vector2(250 if single_chapter else 170, 54)
	skip.size = skip.custom_minimum_size
	skip.position = Vector2(1900 - skip.size.x, 1006)
	skip.modulate.a = 0.75
	skip.tooltip_text = "Skip this chapter"
	skip.pressed.connect(_finish)
	root.add_child(skip)
	if not single_chapter and not GameState.story_complete:
		var all := OrnateButton.new("Skip the Story", "plaque")
		all.font_size = 22
		all.custom_minimum_size = Vector2(220, 54)
		all.size = all.custom_minimum_size
		all.position = Vector2(skip.position.x - 236, 1006)
		all.modulate.a = 0.6
		all.tooltip_text = "Go straight to the parlour (you can watch the story later from the timeline)"
		all.pressed.connect(func() -> void:
			if not _done:
				_done = true
				skip_all.emit()
		)
		root.add_child(all)


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()


func _process(delta: float) -> void:
	t += delta
	update(t, delta)
	if t >= duration:
		_finish()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		_finish()
		get_viewport().set_input_as_handled()


# ------------------------------------------------------- shared painting

static func smooth(a: float, b: float, x: float) -> float:
	return smoothstep(a, b, x)


static func paint_sky(ci: CanvasItem, top: Color, mid: Color, horizon: Color, horizon_y: float = 640.0) -> void:
	UIKit.vgrad(ci, Rect2(0, 0, 1920, horizon_y * 0.55), top, mid)
	UIKit.vgrad(ci, Rect2(0, horizon_y * 0.55, 1920, horizon_y * 0.45 + 2), mid, horizon)


static func paint_hills(ci: CanvasItem, base_y: float, amp: float, col: Color, seed_v: float, freq: float = 2.0) -> void:
	var pts := PackedVector2Array([Vector2(0, 1080)])
	for i in 33:
		var x := i * 60.0
		var y := base_y - sin(x * 0.002 * freq + seed_v) * amp - sin(x * 0.0057 * freq + seed_v * 2.0) * amp * 0.4
		pts.append(Vector2(x, y))
	pts.append(Vector2(1920, 1080))
	ci.draw_colored_polygon(pts, col)


static func paint_fir_silhouettes(ci: CanvasItem, base_y: float, h_min: float, h_max: float, col: Color, snow_col: Color, seed_v: int, spacing: float = 60.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var x := -40.0
	while x < 1960.0:
		var h := rng.randf_range(h_min, h_max)
		var w := h * 0.42
		var by := base_y + rng.randf_range(-8, 8)
		for tier in 5:
			var ty := by - h + tier * h * 0.18
			var tw := w * (0.3 + tier * 0.19)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x, ty), Vector2(x + tw * 0.5, ty + h * 0.28), Vector2(x - tw * 0.5, ty + h * 0.28)]), col)
			if snow_col.a > 0.0:
				ci.draw_line(Vector2(x - tw * 0.48, ty + h * 0.27), Vector2(x + tw * 0.2, ty + h * 0.2), snow_col, maxf(1.5, h * 0.02))
		x += rng.randf_range(spacing * 0.6, spacing * 1.4)
