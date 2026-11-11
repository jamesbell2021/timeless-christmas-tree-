class_name ItemSlot
extends Control
## One velvet compartment in the trunk, showing a decoration. Press to pick
## it up (the drag itself is run by DecorManager).

signal pressed_item(id: String)

var def: Dictionary
var _hover := false
var _tip := ""


func _init(p_def: Dictionary = {}) -> void:
	def = p_def
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	_tip = "%s\n%s" % [def.get("name", ""), def.get("desc", "")]
	tooltip_text = _tip
	set_process(false)


func _ready() -> void:
	mouse_entered.connect(func() -> void:
		_hover = true
		queue_redraw()
	)
	mouse_exited.connect(func() -> void:
		_hover = false
		queue_redraw()
	)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Hide the tooltip while the item is being carried away.
		tooltip_text = ""
		set_process(true)
		pressed_item.emit(str(def.get("id", "")))
		accept_event()


func _process(_delta: float) -> void:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		tooltip_text = _tip
		set_process(false)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size).grow(-3)
	# Recessed velvet cell
	UIKit.vgrad(self, r, Color(0.16, 0.03, 0.04), Color(0.3, 0.06, 0.07))
	draw_rect(r, Color(0, 0, 0, 0.6), false, 2.0)
	draw_line(Vector2(r.position.x, r.end.y), r.end, Color(1, 0.7, 0.5, 0.12), 1.5)
	if _hover:
		draw_texture_rect(Tex.glow(), r.grow(10), false, Color(1, 0.85, 0.5, 0.22))
		draw_rect(r, UIKit.GOLD_LIGHT, false, 1.5)
	DecorArt.draw_preview(self, def, r.grow(-6))
