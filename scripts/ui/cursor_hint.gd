class_name CursorHint
extends Control
## A small slip of card that follows the pointer: placement guidance while
## dragging, or the name of the decoration under the pointer.

var _hint := ""
var _valid := true
var _hover := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(10, 10)
	z_index = 5


func set_hint(t: String, valid: bool) -> void:
	if t == _hint and valid == _valid:
		return
	_hint = t
	_valid = valid
	queue_redraw()


func set_hover(t: String) -> void:
	if t == _hover:
		return
	_hover = t
	queue_redraw()


func _process(_delta: float) -> void:
	if _hint == "" and _hover == "":
		return
	position = get_global_mouse_position() + Vector2(26, 22)
	queue_redraw()


func _draw() -> void:
	var text := _hint if _hint != "" else _hover
	if text == "":
		return
	var f := UIKit.font("body_italic")
	var fs := 23 if _hint != "" else 21
	var sz := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var r := Rect2(Vector2.ZERO, sz + Vector2(28, 16))
	# Keep the slip on screen
	var gp := get_global_mouse_position() + Vector2(26, 22)
	if gp.x + r.size.x > 1910:
		r.position.x -= r.size.x + 44
	if gp.y + r.size.y > 1070:
		r.position.y -= r.size.y + 40
	draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.35))
	var bg := UIKit.PAPER if _valid or _hint == "" else Color(0.95, 0.82, 0.76)
	draw_rect(r, bg)
	draw_texture_rect(Tex.paper(), r, true, Color(1, 1, 1, 0.6))
	draw_rect(r, UIKit.GOLD_DARK if _valid else UIKit.BURGUNDY, false, 1.5)
	var col := UIKit.INK if _valid else UIKit.BURGUNDY
	draw_string(f, r.position + Vector2(14, 8 + f.get_ascent(fs)), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
