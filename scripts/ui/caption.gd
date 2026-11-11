class_name Caption
extends Control
## Storybook captions: one line at a time, faded in and out on a soft dark
## ribbon in the lower third, like the text plate of an illustrated book.

signal finished

var _text := ""
var _alpha := 0.0
var _queue: Array = []
var _hold := 3.0
var _tw: Tween
var y_center := 870.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(1920, 1080)


func play(lines: Array, hold: float = 3.2) -> void:
	_queue = lines.duplicate()
	_hold = hold
	_next()


func _next() -> void:
	if _queue.is_empty():
		finished.emit()
		return
	_text = str(_queue.pop_front())
	if _tw:
		_tw.kill()
	_tw = create_tween()
	_tw.tween_method(_set_alpha, 0.0, 1.0, 0.9)
	_tw.tween_interval(_hold)
	_tw.tween_method(_set_alpha, 1.0, 0.0, 0.8)
	_tw.tween_callback(_next)


func stop() -> void:
	_queue.clear()
	if _tw:
		_tw.kill()
	_set_alpha(0.0)


func _set_alpha(a: float) -> void:
	_alpha = a
	queue_redraw()


func _draw() -> void:
	if _alpha <= 0.001 or _text == "":
		return
	var f := UIKit.font("title_italic")
	var fs := 44
	var sz := f.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var c := Vector2(960, y_center)
	var band := Rect2(c.x - sz.x * 0.5 - 120, c.y - 46, sz.x + 240, 92)
	# Soft ribbon: fades out at both ends
	var left := Rect2(band.position, Vector2(120, band.size.y))
	var right := Rect2(Vector2(band.end.x - 120, band.position.y), Vector2(120, band.size.y))
	var mid := Rect2(band.position + Vector2(120, 0), Vector2(band.size.x - 240, band.size.y))
	var dark := Color(0.04, 0.025, 0.015, 0.55 * _alpha)
	UIKit.hgrad(self, left, Color(dark, 0.0), dark)
	draw_rect(mid, dark)
	UIKit.hgrad(self, right, dark, Color(dark, 0.0))
	UIKit.divider(self, Vector2(960, band.end.y - 12), minf(sz.x * 0.4, 260), Color(UIKit.GOLD, 0.7 * _alpha))
	var base := Vector2(c.x - sz.x * 0.5, c.y + (f.get_ascent(fs) - f.get_descent(fs)) * 0.5 - 6)
	draw_string_outline(f, base, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(0, 0, 0, 0.5 * _alpha))
	draw_string(f, base, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.95, 0.84, _alpha))
