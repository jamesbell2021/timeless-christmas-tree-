class_name ModalPanel
extends Control
## Base for the paper "cards" that open over the parlour (settings, album,
## share). Dims the room, draws an aged card with a gilt title and a close
## button, and fades in/out. Subclasses build content in _build().

signal closed

var panel_size := Vector2(900, 640)
var title := ""
var panel_rect: Rect2
var content: Control


func _init(p_title: String = "", p_size: Vector2 = Vector2(900, 640)) -> void:
	title = p_title
	panel_size = p_size


func _ready() -> void:
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_STOP
	panel_rect = Rect2((Vector2(1920, 1080) - panel_size) * 0.5, panel_size)
	content = Control.new()
	content.position = panel_rect.position
	content.size = panel_rect.size
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	var close := OrnateButton.new("", "round", "close")
	close.custom_minimum_size = Vector2(54, 54)
	close.size = Vector2(54, 54)
	close.position = panel_rect.position + Vector2(panel_rect.size.x - 40, -14)
	close.tooltip_text = "Close"
	close.pressed.connect(close_panel)
	add_child(close)
	_build()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
	AudioDirector.sfx("page")


func _build() -> void:
	pass


func close_panel() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func() -> void:
		closed.emit()
		queue_free()
	)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and not panel_rect.grow(20).has_point(event.position):
		close_panel()
		accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_panel()
		get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.01, 0.0, 0.55))
	UIKit.paper_panel(self, panel_rect)
	if title != "":
		UIKit.text_centered(self, UIKit.font("title"), Vector2(panel_rect.get_center().x, panel_rect.position.y + 56), title, 46, UIKit.INK, false)
		UIKit.divider(self, Vector2(panel_rect.get_center().x, panel_rect.position.y + 92), 180, UIKit.GOLD_DARK)


func add_label(text: String, pos: Vector2, font_kind: String = "body", font_size: int = 26, col: Color = UIKit.INK, width: float = -1.0) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", UIKit.font(font_kind))
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	if width > 0.0:
		l.size.x = width
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(l)
	return l
