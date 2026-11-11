class_name AlbumCard
extends Control
## One page in the Album: a mounted photograph of that arrangement.

signal chosen(index: int)

var index := 0
var thumb: Texture2D
var _hover := false


func _init(p_index: int = 0, p_thumb: Texture2D = null) -> void:
	index = p_index
	thumb = p_thumb
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


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
		chosen.emit(index)
		accept_event()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var current := index == GameState.current_arrangement
	var a: Dictionary = GameState.arrangements[index]
	draw_rect(Rect2(r.position + Vector2(4, 6), r.size), Color(0, 0, 0, 0.25))
	draw_rect(r, Color(0.2, 0.12, 0.08) if not current else UIKit.BURGUNDY)
	var photo := Rect2(14, 14, r.size.x - 28, (r.size.x - 28) * 9.0 / 16.0)
	photo.size.y = minf(photo.size.y, r.size.y - 84)
	draw_rect(photo.grow(4), Color(0.95, 0.92, 0.85))
	var empty := GameState.is_arrangement_empty(index)
	if thumb and not empty:
		draw_texture_rect(thumb, photo, false, Color(1.0, 0.95, 0.85))
	else:
		UIKit.vgrad(self, photo, Color(0.25, 0.2, 0.16), Color(0.12, 0.09, 0.07))
		UIIcons.draw(self, "sapling", Rect2(photo.get_center() - Vector2(34, 34), Vector2(68, 68)), Color(UIKit.GOLD, 0.6))
	# Photo corners
	for c in [photo.position, Vector2(photo.end.x, photo.position.y), Vector2(photo.position.x, photo.end.y), photo.end]:
		var dx := 1.0 if c.x < photo.get_center().x else -1.0
		var dy := 1.0 if c.y < photo.get_center().y else -1.0
		draw_colored_polygon(PackedVector2Array([c + Vector2(-4 * dx, -4 * dy), c + Vector2(18 * dx, -4 * dy), c + Vector2(-4 * dx, 18 * dy)]), Color(0.1, 0.06, 0.04))
	var name_txt: String = a.get("name", "")
	var n := (a.get("items", []) as Array).size()
	var sub := "A bare tree" if n == 0 else ("%d decoration%s" % [n, "" if n == 1 else "s"])
	if current:
		sub += "  (open now)"
	UIKit.text_centered(self, UIKit.font("title"), Vector2(r.size.x * 0.5, photo.end.y + 26), name_txt, 25, UIKit.GOLD_LIGHT)
	UIKit.text_centered(self, UIKit.font("body_italic"), Vector2(r.size.x * 0.5, photo.end.y + 52), sub, 18, Color(UIKit.TEXT_LIGHT, 0.8))
	draw_rect(r, UIKit.GOLD_LIGHT if (_hover or current) else UIKit.GOLD_DARK, false, 2.0 if _hover else 1.5)
