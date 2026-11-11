class_name TitleScreen
extends Node2D
## The title page: a snowy village on Christmas Eve seen through a gilt
## Christmas card, with the way into the story or straight to the parlour.

signal begin_story
signal go_parlour

var _card: Control
var _t := 0.0
var _modal: ModalPanel
var _root: Control


func _ready() -> void:
	add_child(Painter.new(_paint_village))
	var tree := TreeArt.new()
	tree.position = Vector2(1500, 900)
	tree.height = 380.0
	tree.width = 230.0
	tree.seed_value = 13
	tree.palette = "dusk"
	tree.snow = 0.9
	add_child(tree)
	var robin := Robin.new()
	robin.position = Vector2(1530, 905)
	robin.size = 1.6
	add_child(robin)
	var snow := Snowfall.new()
	snow.count = 150
	add_child(snow)
	for p in [Vector2(226, 700), Vector2(314, 700), Vector2(226, 780), Vector2(314, 780)]:
		var g := LightGlow.new(Color(1.0, 0.7, 0.35), 0.45, 70.0, 0.4)
		g.position = p
		add_child(g)
	add_child(PostFX.new("watercolour"))
	_build_ui()
	AudioDirector.set_scene_ambience("title")
	AudioDirector.play_music_for("title")


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var root := Control.new()
	root.size = Vector2(1920, 1080)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UIKit.theme()
	layer.add_child(root)
	_root = root
	_card = Control.new()
	_card.position = Vector2(560, 150)
	_card.size = Vector2(800, 760)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.draw.connect(_draw_card)
	root.add_child(_card)
	var y := 470.0
	var has_save := GameState.has_save()
	var begin := OrnateButton.new("Begin the Story" if not has_save else "Watch the Story Again", "plaque")
	begin.font_size = 32
	begin.custom_minimum_size = Vector2(440, 74)
	begin.size = begin.custom_minimum_size
	begin.position = Vector2(400 - 220, y)
	begin.pressed.connect(func() -> void: begin_story.emit())
	_card.add_child(begin)
	var parlour := OrnateButton.new("Return to the Parlour" if has_save else "Go Straight to the Parlour", "plaque")
	parlour.font_size = 26
	parlour.custom_minimum_size = Vector2(440, 64)
	parlour.size = parlour.custom_minimum_size
	parlour.position = Vector2(400 - 220, y + 92)
	parlour.pressed.connect(func() -> void:
		GameState.reach_stage(3)
		go_parlour.emit()
	)
	_card.add_child(parlour)
	if has_save:
		# Returning players see the parlour button first.
		_card.move_child(parlour, 0)
		parlour.position.y = y
		begin.position.y = y + 92
		begin.font_size = 26
		begin.custom_minimum_size = Vector2(440, 64)
		begin.size = begin.custom_minimum_size
	var settings := OrnateButton.new("", "round", "music")
	settings.tooltip_text = "Settings"
	settings.custom_minimum_size = Vector2(60, 60)
	settings.size = settings.custom_minimum_size
	settings.position = Vector2(1840, 1000)
	settings.pressed.connect(_open_settings)
	root.add_child(settings)
	_card.modulate.a = 0.0
	create_tween().tween_property(_card, "modulate:a", 1.0, 1.6).set_delay(0.4)


func _open_settings() -> void:
	if _modal:
		return
	var s := SettingsPanel.new()
	s.show_actions = false
	_modal = s
	s.closed.connect(func() -> void: _modal = null)
	_root.add_child(s)


func _process(delta: float) -> void:
	_t += delta
	_card.queue_redraw()


func _draw_card() -> void:
	var r := Rect2(Vector2.ZERO, _card.size)
	UIKit.paper_panel(_card, r)
	# Holly in the top corners
	var holly := Catalogue.get_item("holly")
	for p in [Vector2(70, 64), Vector2(r.size.x - 70, 64)]:
		_card.draw_set_transform(p, 0.0, Vector2(1.5, 1.5))
		DecorArt.draw_item(_card, holly, 2)
	_card.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	UIKit.text_centered(_card, UIKit.font("caps"), Vector2(r.size.x * 0.5, 96), "A Christmas Entertainment", 24, UIKit.INK.lerp(UIKit.BURGUNDY, 0.5), false)
	UIKit.gilt_text(_card, UIKit.font("title"), Vector2(r.size.x * 0.5, 190), "A Timeless", 84)
	UIKit.gilt_text(_card, UIKit.font("title"), Vector2(r.size.x * 0.5, 280), "Christmas Tree", 84)
	UIKit.divider(_card, Vector2(r.size.x * 0.5, 340), 220, UIKit.GOLD_DARK)
	UIKit.text_centered(_card, UIKit.font("title_italic"), Vector2(r.size.x * 0.5, 392), "An Edwardian Yuletide", 40, UIKit.INK, false)
	var shimmer := 0.5 + 0.5 * sin(_t * 1.4)
	UIKit.text_centered(_card, UIKit.font("body_italic"), Vector2(r.size.x * 0.5, 680), "No timers. No scores. Only the joy of making.", 24, Color(UIKit.INK, 0.6 + shimmer * 0.2), false)
	UIKit.text_centered(_card, UIKit.font("body"), Vector2(r.size.x * 0.5, 716), "Every picture, carol and crackle is made in code.", 18, Color(UIKit.INK, 0.5), false)


func _paint_village(ci: CanvasItem) -> void:
	StoryScene.paint_sky(ci, Color(0.07, 0.09, 0.24), Color(0.3, 0.3, 0.52), Color(0.82, 0.62, 0.62), 680)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for k in 90:
		ci.draw_circle(Vector2(rng.randf_range(0, 1920), rng.randf_range(0, 380)), rng.randf_range(0.7, 2.0), Color(1, 1, 0.95, rng.randf_range(0.3, 0.9)))
	StoryScene.paint_hills(ci, 620, 90, Color(0.55, 0.55, 0.72), 0.4, 1.3)
	StoryScene.paint_hills(ci, 720, 50, Color(0.75, 0.76, 0.88), 1.9, 2.0)
	StoryScene.paint_fir_silhouettes(ci, 780, 90, 200, Color(0.18, 0.22, 0.34), Color(0.9, 0.92, 1.0, 0.8), 21, 58)
	# The family's house: a gabled Edwardian villa with warm windows
	var h := Vector2(170, 840)
	ci.draw_rect(Rect2(h + Vector2(0, -230), Vector2(200, 230)), Color(0.36, 0.22, 0.2))
	ci.draw_colored_polygon(PackedVector2Array([h + Vector2(-24, -228), h + Vector2(224, -228), h + Vector2(100, -330)]), Color(0.86, 0.9, 1.0))
	ci.draw_colored_polygon(PackedVector2Array([h + Vector2(-10, -232), h + Vector2(210, -232), h + Vector2(100, -318)]), Color(0.25, 0.2, 0.24))
	ci.draw_rect(Rect2(h + Vector2(150, -360), Vector2(26, 80)), Color(0.32, 0.2, 0.18))
	ci.draw_rect(Rect2(h + Vector2(146, -366), Vector2(34, 10)), Color(0.88, 0.9, 1.0))
	for wp in [Vector2(30, -170), Vector2(118, -170), Vector2(30, -90), Vector2(118, -90)]:
		ci.draw_rect(Rect2(h + wp, Vector2(52, 60)), Color(1.0, 0.78, 0.42))
		ci.draw_line(h + wp + Vector2(26, 0), h + wp + Vector2(26, 60), Color(0.3, 0.18, 0.12), 3.0)
		ci.draw_line(h + wp + Vector2(0, 30), h + wp + Vector2(52, 30), Color(0.3, 0.18, 0.12), 3.0)
		ci.draw_rect(Rect2(h + wp + Vector2(-4, 58), Vector2(60, 6)), Color(0.9, 0.92, 1.0))
	ci.draw_rect(Rect2(h + Vector2(84, -60), Vector2(32, 60)), Color(0.2, 0.1, 0.08))
	ci.draw_circle(h + Vector2(100, -40), 10, Color(0.15, 0.35, 0.18))
	# Smoke from the chimney
	for k in 6:
		ci.draw_circle(h + Vector2(163 + k * 12, -380 - k * 30), 14 + k * 5, Color(0.8, 0.8, 0.88, 0.18 - k * 0.025))
	# Snow
	var g := PackedVector2Array([Vector2(0, 1080)])
	for i in 25:
		var x := i * 80.0
		g.append(Vector2(x, 840 + sin(x * 0.003) * 16))
	g.append(Vector2(1920, 1080))
	ci.draw_colored_polygon(g, Color(0.84, 0.87, 0.96))
	UIKit.vgrad(ci, Rect2(0, 860, 1920, 220), Color(0.9, 0.92, 1.0, 0.0), Color(0.6, 0.64, 0.82))
	# Light spilling from the windows onto the snow
	ci.draw_texture_rect(Tex.glow(), Rect2(h + Vector2(-80, -20), Vector2(360, 120)), false, Color(1.0, 0.75, 0.4, 0.3))
