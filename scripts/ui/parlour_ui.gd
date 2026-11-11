class_name ParlourUI
extends CanvasLayer
## Everything you touch in the parlour that isn't the room itself: the title
## plaque, the tool roundels, the bottom bar (trunk, timeline, settings,
## share), the trunk drawer, cursor hints, toasts and modal cards.

var parlour: Parlour
var root: Control
var trunk: TrunkPanel
var timeline: TimelineBar
var trunk_btn: OrnateButton
var undo_btn: OrnateButton
var candle_btn: OrnateButton
var lamp_btn: OrnateButton
var restore_btn: OrnateButton

var _hint: CursorHint
var _toast: Label
var _toast_tw: Tween
var _fade: ColorRect
var _modal: ModalPanel
var _tutorial := false
var _pulse := 0.0
var _bar: Control
var _hidden := false
var _caption: Caption


func _init(p_parlour: Parlour) -> void:
	parlour = p_parlour
	layer = 10


func _ready() -> void:
	root = Control.new()
	root.size = Vector2(1920, 1080)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UIKit.theme()
	add_child(root)
	_build_plaque()
	_build_tools()
	_build_bar()
	_build_trunk()
	_hint = CursorHint.new()
	root.add_child(_hint)
	_toast = Label.new()
	_toast.add_theme_font_override("font", UIKit.font("title_italic"))
	_toast.add_theme_font_size_override("font_size", 34)
	_toast.add_theme_color_override("font_color", UIKit.GOLD_LIGHT)
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.01, 0.85))
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.position = Vector2(360, 118)
	_toast.size = Vector2(1200, 50)
	_toast.modulate.a = 0.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_toast)
	_caption = Caption.new()
	root.add_child(_caption)
	_fade = ColorRect.new()
	_fade.color = Color(0.03, 0.02, 0.015, 1.0)
	_fade.size = Vector2(1920, 1080)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	root.add_child(_fade)
	refresh_toggles()
	_tutorial = GameState.is_arrangement_empty(GameState.current_arrangement) and not trunk.open


# ------------------------------------------------------------------ build

func _build_plaque() -> void:
	var c := Control.new()
	c.position = Vector2(730, 6)
	c.size = Vector2(460, 74)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func() -> void:
		var r := Rect2(Vector2.ZERO, c.size)
		UIKit.wood_panel(c, r, "dark")
		UIKit.gilt_text(c, UIKit.font("title"), Vector2(r.size.x * 0.5, 30), "A Timeless Christmas Tree", 32)
		UIKit.text_centered(c, UIKit.font("title_italic"), Vector2(r.size.x * 0.5, 56), "An Edwardian Yuletide", 18, UIKit.TEXT_LIGHT)
	)
	root.add_child(c)


func _round(icon: String, tip: String, pos: Vector2, toggle: bool = false) -> OrnateButton:
	var b := OrnateButton.new("", "round", icon)
	b.custom_minimum_size = Vector2(64, 64)
	b.size = Vector2(64, 64)
	b.position = pos
	b.tooltip_text = tip
	b.toggle_mode = toggle
	root.add_child(b)
	return b


func _build_tools() -> void:
	var x := 1904.0 - 64.0
	var y := 18.0
	var gap := 70.0
	var hide_btn := _round("eye", "Admire the view (hide the interface) [H]", Vector2(x, y))
	hide_btn.pressed.connect(set_ui_hidden.bind(true))
	var album := _round("album", "The Album: six pages, six trees", Vector2(x - gap, y))
	album.pressed.connect(open_album)
	lamp_btn = _round("lamp", "Dim or light the lamps [L]", Vector2(x - gap * 2, y), true)
	lamp_btn.toggled.connect(func(on: bool) -> void:
		if on != parlour.lamps_on:
			parlour.set_lamps(on)
	)
	candle_btn = _round("flame", "Light the tree [C]", Vector2(x - gap * 3, y), true)
	candle_btn.toggled.connect(func(on: bool) -> void:
		if on != parlour.candles_lit:
			parlour.set_candles(on)
	)
	undo_btn = _round("undo", "Undo [Ctrl+Z]", Vector2(x - gap * 4, y))
	undo_btn.pressed.connect(func() -> void: parlour.decor.undo())
	var music := _round("music", "Music on or off [M]", Vector2(x - gap * 5, y), true)
	music.button_pressed = GameState.settings["music_volume"] > 0.01
	music.toggled.connect(func(on: bool) -> void:
		GameState.set_setting("music_volume", 0.65 if on else 0.0)
	)
	restore_btn = _round("eye", "Show the interface again [H]", Vector2(x, y))
	restore_btn.visible = false
	restore_btn.modulate.a = 0.55
	restore_btn.pressed.connect(set_ui_hidden.bind(false))


func _build_bar() -> void:
	_bar = Control.new()
	_bar.position = Vector2(0, RoomLayout.UI_BAR_TOP)
	_bar.size = Vector2(1920, 1080 - RoomLayout.UI_BAR_TOP)
	_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_bar.draw.connect(_draw_bar)
	root.add_child(_bar)
	trunk_btn = OrnateButton.new("Open the Trunk", "plaque", "trunk")
	trunk_btn.toggle_mode = true
	trunk_btn.font_size = 28
	trunk_btn.position = Vector2(40, 36)
	trunk_btn.custom_minimum_size = Vector2(376, 60)
	trunk_btn.size = Vector2(376, 60)
	trunk_btn.tooltip_text = "Your box of decorations [T]"
	trunk_btn.toggled.connect(func(on: bool) -> void: set_trunk_open(on))
	_bar.add_child(trunk_btn)
	timeline = TimelineBar.new()
	timeline.position = Vector2(470, 4)
	timeline.size = Vector2(980, 124)
	timeline.current = 4
	timeline.stage_selected.connect(func(i: int) -> void: parlour.request_story(i))
	_bar.add_child(timeline)
	var settings := OrnateButton.new("Settings", "plaque")
	settings.font_size = 28
	settings.position = Vector2(1484, 26)
	settings.custom_minimum_size = Vector2(164, 80)
	settings.size = Vector2(164, 80)
	settings.pressed.connect(open_settings)
	_bar.add_child(settings)
	var share := OrnateButton.new("Share Your Design", "plaque")
	share.font_size = 23
	share.subtext = "as a Christmas card"
	share.position = Vector2(1660, 26)
	share.custom_minimum_size = Vector2(246, 80)
	share.size = Vector2(246, 80)
	share.pressed.connect(open_share)
	_bar.add_child(share)


func _draw_bar() -> void:
	var r := Rect2(Vector2.ZERO, _bar.size)
	UIKit.vgrad(_bar, r, Color(0.2, 0.1, 0.05), Color(0.07, 0.035, 0.02))
	_bar.draw_texture_rect(Tex.wood(), r, true, Color(1, 1, 1, 0.5))
	_bar.draw_line(Vector2(0, 1), Vector2(1920, 1), UIKit.GOLD_DARK, 3.0)
	_bar.draw_line(Vector2(0, 5), Vector2(1920, 5), Color(UIKit.GOLD, 0.6), 1.0)
	# Inset fields
	for f in [Rect2(16, 14, 424, 110), Rect2(460, 10, 1000, 116), Rect2(1474, 14, 440, 110)]:
		_bar.draw_rect(f, Color(0, 0, 0, 0.3))
		_bar.draw_rect(f, UIKit.GOLD_DARK, false, 1.5)
		UIKit.filigree_corner(_bar, f.position + Vector2(6, 6), 1, 1, 14)
		UIKit.filigree_corner(_bar, Vector2(f.end.x - 6, f.position.y + 6), -1, 1, 14)
	UIKit.text_centered(_bar, UIKit.font("caps"), Vector2(228, 24), "The Living Chronicle", 20, UIKit.GOLD)
	UIKit.text_centered(_bar, UIKit.font("body_italic"), Vector2(228, 112), GameState.STAGES[4]["chapter"], 19, Color(UIKit.TEXT_LIGHT, 0.85))
	if _tutorial:
		var g := 0.5 + 0.5 * sin(_pulse * 3.0)
		_bar.draw_texture_rect(Tex.glow(), Rect2(10, -10, 436, 150), false, Color(1, 0.8, 0.4, 0.25 + g * 0.35))


func _build_trunk() -> void:
	trunk = TrunkPanel.new()
	trunk.position = Vector2(1960, 124)
	trunk.visible = false
	trunk.drag_started.connect(func(id: String) -> void: parlour.decor.begin_new_drag(id))
	trunk.closed.connect(func() -> void: trunk_btn.button_pressed = false)
	root.add_child(trunk)


# ------------------------------------------------------------- behaviour

func trunk_rect() -> Rect2:
	if trunk and trunk.open and trunk.visible:
		return Rect2(trunk.position, trunk.size)
	return Rect2()


func set_trunk_open(on: bool) -> void:
	if trunk.open == on:
		return
	trunk.open = on
	trunk_btn.text = "Close the Trunk" if on else "Open the Trunk"
	trunk_btn.queue_redraw()
	AudioDirector.sfx("trunk_open" if on else "trunk_close")
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if on:
		trunk.visible = true
		tw.tween_property(trunk, "position:x", 1904.0 - trunk.size.x, 0.35)
		if _tutorial:
			_tutorial = false
			_bar.queue_redraw()
			toast("Drag a decoration onto the tree")
	else:
		tw.tween_property(trunk, "position:x", 1960.0, 0.3)
		tw.tween_callback(func() -> void: trunk.visible = trunk.open)


func refresh_toggles() -> void:
	if candle_btn == null:
		return
	candle_btn.set_pressed_no_signal(parlour.candles_lit)
	lamp_btn.set_pressed_no_signal(parlour.lamps_on)
	candle_btn.tooltip_text = ("Snuff the candles" if parlour.candles_lit else "Light the tree") + " [C]"
	lamp_btn.tooltip_text = ("Dim the lamps" if parlour.lamps_on else "Light the lamps") + " [L]"
	undo_btn.disabled = not parlour.decor.can_undo()
	candle_btn.queue_redraw()
	lamp_btn.queue_redraw()
	undo_btn.queue_redraw()


func show_hint(text: String, valid: bool) -> void:
	_hint.set_hint(text, valid)


func show_hover(text: String) -> void:
	_hint.set_hover(text)


func toast(text: String) -> void:
	_toast.text = text
	if _toast_tw:
		_toast_tw.kill()
	_toast_tw = create_tween()
	_toast_tw.tween_property(_toast, "modulate:a", 1.0, 0.3)
	_toast_tw.tween_interval(2.6)
	_toast_tw.tween_property(_toast, "modulate:a", 0.0, 0.8)


func intro_caption() -> void:
	_caption.play(["Christmas Eve, 1901.", "That evening, in the parlour, our tree stood waiting."], 3.4)


func fade(to_black: bool, time: float = 0.35) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0 if to_black else 0.0, time)
	await tw.finished


func set_ui_hidden(h: bool) -> void:
	_hidden = h
	for c in root.get_children():
		if c == restore_btn or c == _fade:
			continue
		if c is Control:
			(c as Control).visible = not h
	trunk.visible = trunk.open and not h
	restore_btn.visible = h
	parlour.decor.hover_changed.emit("")
	AudioDirector.sfx("page")


func open_settings() -> void:
	if _modal:
		return
	var s := SettingsPanel.new()
	s.replay_story.connect(func() -> void: parlour.request_story(0))
	s.to_title.connect(func() -> void: parlour.request_title())
	s.clear_tree.connect(func() -> void: parlour.decor.clear_all())
	_open_modal(s)


func open_album() -> void:
	if _modal:
		return
	await parlour.capture_thumbnail()
	var a := AlbumPanel.new(parlour)
	a.choose.connect(func(i: int) -> void: parlour.switch_arrangement(i))
	a.duplicate_to.connect(func(i: int) -> void:
		GameState.copy_arrangement(GameState.current_arrangement, i)
		parlour.switch_arrangement(i)
	)
	a.clear_current.connect(func() -> void: parlour.decor.clear_all())
	_open_modal(a)


func open_share() -> void:
	if _modal:
		return
	AudioDirector.sfx("shutter")
	var img := await parlour.capture_image(true)
	# Magnesium flash
	var flash := ColorRect.new()
	flash.color = Color(1, 0.98, 0.9)
	flash.size = Vector2(1920, 1080)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, 0.6)
	tw.tween_callback(flash.queue_free)
	_open_modal(ShareOverlay.new(img))


func _open_modal(m: ModalPanel) -> void:
	_modal = m
	parlour.decor.enabled = false
	m.closed.connect(func() -> void:
		_modal = null
		parlour.decor.enabled = true
	)
	root.add_child(m)
	root.move_child(_fade, -1)


func _process(delta: float) -> void:
	if _tutorial:
		_pulse += delta
		_bar.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if _modal:
		return
	var k := event as InputEventKey
	if k.keycode == KEY_Z and (k.ctrl_pressed or k.meta_pressed):
		parlour.decor.undo()
	elif k.keycode == KEY_H:
		set_ui_hidden(not _hidden)
	elif k.keycode == KEY_T:
		trunk_btn.button_pressed = not trunk_btn.button_pressed
	elif k.keycode == KEY_L:
		parlour.set_lamps(not parlour.lamps_on)
	elif k.keycode == KEY_C:
		parlour.set_candles(not parlour.candles_lit)
	elif k.keycode == KEY_M:
		var on := float(GameState.settings["music_volume"]) < 0.01
		GameState.set_setting("music_volume", 0.65 if on else 0.0)
	elif k.keycode == KEY_ESCAPE:
		if _hidden:
			set_ui_hidden(false)
		elif trunk.open:
			trunk_btn.button_pressed = false
	else:
		return
	get_viewport().set_input_as_handled()
