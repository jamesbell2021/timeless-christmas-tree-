class_name SettingsPanel
extends ModalPanel
## Settings card: volumes, the painterly filter, snow, fullscreen, and ways
## back into the story or to the title page.

signal replay_story
signal to_title
signal clear_tree

const PAINT_NAMES := ["Plain", "Light Brushwork", "Full Oil Painting"]

var _paint_btn: OrnateButton
var show_actions := true


func _init() -> void:
	super("Settings", Vector2(860, 840))


func _build() -> void:
	var x0 := 90.0
	var y := 130.0
	for row in [["Music", "music_volume"], ["Fireside & Wind", "ambience_volume"], ["Ornament Sounds", "sfx_volume"]]:
		add_label(row[0], Vector2(x0, y), "caps", 28)
		var s := HSlider.new()
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.01
		s.value = float(GameState.settings[row[1]])
		s.position = Vector2(x0 + 330, y + 8)
		s.size = Vector2(340, 28)
		s.value_changed.connect(func(v: float) -> void: GameState.set_setting(row[1], v))
		s.drag_ended.connect(func(_c: bool) -> void: AudioDirector.sfx("glass"))
		content.add_child(s)
		y += 62
	y += 6
	add_label("Painted Look", Vector2(x0, y), "caps", 28)
	_paint_btn = OrnateButton.new(PAINT_NAMES[int(GameState.settings["painterly"])], "paper")
	_paint_btn.font_size = 24
	_paint_btn.position = Vector2(x0 + 330, y - 6)
	_paint_btn.custom_minimum_size = Vector2(340, 50)
	_paint_btn.size = Vector2(340, 50)
	_paint_btn.tooltip_text = "The oil-paint filter is beautiful but asks more of older computers and tablets."
	_paint_btn.pressed.connect(_cycle_paint)
	content.add_child(_paint_btn)
	y += 70
	_toggle_row("Falling Snow", "snow", x0, y)
	y += 62
	_toggle_row("Ornament Twinkle", "twinkle", x0, y)
	y += 62
	_toggle_row("Fireside When Idle", "idle_fireside", x0, y).tooltip_text = "After five quiet minutes the parlour becomes a screensaver. Click or press a key to come back."
	y += 62
	_toggle_row("Mischievous Cat", "cat_mischief", x0, y).tooltip_text = "Now and then Marmalade wakes up and bats at the lowest ornaments. Turn off for a tidier tree."
	y += 62
	if not OS.has_feature("web_android") and not OS.has_feature("web_ios"):
		_toggle_row("Full Screen", "fullscreen", x0, y)
	y += 84
	if not show_actions:
		add_label("Your trees are saved automatically.", Vector2(0, y + 20), "body_italic", 22, Color(UIKit.INK, 0.7), panel_size.x).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return
	var bx := x0 - 10.0
	for b in [["Replay the Story", "replay"], ["Clear This Tree", "clear"], ["Title Page", "title"]]:
		var btn := OrnateButton.new(b[0], "paper")
		btn.font_size = 22
		btn.position = Vector2(bx, y)
		btn.custom_minimum_size = Vector2(220, 52)
		btn.size = Vector2(220, 52)
		var which: String = b[1]
		btn.pressed.connect(func() -> void:
			match which:
				"replay": replay_story.emit()
				"clear": clear_tree.emit()
				"title": to_title.emit()
			close_panel()
		)
		content.add_child(btn)
		bx += 236
	add_label("Your trees are saved automatically.", Vector2(0, y + 74), "body_italic", 22, Color(UIKit.INK, 0.7), panel_size.x).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _toggle_row(label: String, key: String, x0: float, y: float) -> OrnateButton:
	add_label(label, Vector2(x0, y), "caps", 28)
	var b := OrnateButton.new("On" if GameState.settings[key] else "Off", "paper")
	b.toggle_mode = true
	b.button_pressed = bool(GameState.settings[key])
	b.font_size = 24
	b.position = Vector2(x0 + 330, y - 6)
	b.custom_minimum_size = Vector2(140, 50)
	b.size = Vector2(140, 50)
	b.toggled.connect(func(on: bool) -> void:
		GameState.set_setting(key, on)
		b.text = "On" if on else "Off"
		b.queue_redraw()
	)
	content.add_child(b)
	return b


func _cycle_paint() -> void:
	var q := (int(GameState.settings["painterly"]) + 1) % 3
	GameState.set_setting("painterly", q)
	_paint_btn.text = PAINT_NAMES[q]
	_paint_btn.queue_redraw()
