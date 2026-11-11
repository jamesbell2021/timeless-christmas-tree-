class_name Robin
extends Node2D
## The robin — the little companion who appears in every chapter. Hops,
## bobs and occasionally tilts its head. Facing: +1 right, -1 left.

@export var facing := 1.0
@export var size := 1.0
@export var hop_interval := 3.5

var _t := 0.0
var _hop := 0.0
var _next_hop := 2.0
var _tilt := 0.0


func _ready() -> void:
	_t = randf() * 3.0


func _process(delta: float) -> void:
	_t += delta
	_next_hop -= delta
	if _next_hop <= 0.0:
		_next_hop = hop_interval + randf() * 2.5
		_hop = 1.0
		if randf() < 0.35:
			facing = -facing
	_hop = maxf(0.0, _hop - delta * 3.0)
	_tilt = sin(_t * 0.8) * 0.15 if fmod(_t, 7.0) < 2.0 else lerpf(_tilt, 0.0, delta * 4.0)
	queue_redraw()


func _draw() -> void:
	var s := size
	var f := facing
	var lift := -sin(_hop * PI) * 10.0 * s
	var o := Vector2(0, lift)
	# Shadow
	draw_colored_polygon(DecorArt.ellipse_pts(Vector2(0, 1), 9 * s, 2.5 * s), Color(0, 0, 0, 0.25 * (1.0 - _hop * 0.5)))
	# Legs
	draw_line(o + Vector2(-2 * s, -4 * s), Vector2(-2 * s, 0), Color(0.35, 0.25, 0.2), 1.2 * s)
	draw_line(o + Vector2(2 * s, -4 * s), Vector2(2 * s, 0), Color(0.35, 0.25, 0.2), 1.2 * s)
	# Tail
	draw_colored_polygon(PackedVector2Array([o + Vector2(-8 * f * s, -9 * s), o + Vector2(-17 * f * s, -13 * s), o + Vector2(-16 * f * s, -8 * s)]), Color(0.36, 0.25, 0.16))
	# Body: brown back, red-orange breast, pale belly
	draw_colored_polygon(DecorArt.ellipse_pts(o + Vector2(0, -10 * s), 10 * s, 8 * s), Color(0.45, 0.32, 0.2))
	draw_colored_polygon(DecorArt.ellipse_pts(o + Vector2(3 * f * s, -9 * s), 6.5 * s, 6 * s), Color(0.88, 0.36, 0.12))
	draw_colored_polygon(DecorArt.ellipse_pts(o + Vector2(1 * f * s, -5 * s), 5 * s, 3 * s), Color(0.92, 0.88, 0.8))
	# Head
	var head := o + Vector2(6 * f * s, -17 * s)
	draw_circle(head, 5.5 * s, Color(0.45, 0.32, 0.2))
	draw_circle(head + Vector2(1.5 * f * s, 2 * s), 3.6 * s, Color(0.88, 0.36, 0.12))
	draw_circle(head + Vector2(2 * f * s, -1 * s).rotated(_tilt), 1.2 * s, Color(0.05, 0.03, 0.02))
	draw_circle(head + Vector2(1.6 * f * s, -1.4 * s).rotated(_tilt), 0.4 * s, Color(1, 1, 1))
	draw_colored_polygon(PackedVector2Array([head + Vector2(5 * f * s, 0), head + Vector2(9 * f * s, 1 * s), head + Vector2(5 * f * s, 2 * s)]), Color(0.2, 0.15, 0.1))
	# Wing
	draw_colored_polygon(DecorArt.ellipse_pts(o + Vector2(-2 * f * s, -11 * s), 6 * s, 3.5 * s, 16, 0.3 * f), Color(0.38, 0.26, 0.16))
