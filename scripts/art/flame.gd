class_name Flame
extends Node2D
## A single candle flame: a flickering teardrop with a hot core and a blue
## root, plus its own additive halo. Drawn above the room's darkness layer.

@export var height := 13.0
@export var halo := 70.0
@export var halo_energy := 0.55

var lit := true:
	set(v):
		lit = v
		if _glow:
			_glow.dim = 1.0 if v else 0.0
		queue_redraw()

var _t := 0.0
var _sway := 0.0
var _glow: LightGlow
var _noise := FastNoiseLite.new()


func _ready() -> void:
	z_index = 61
	z_as_relative = false
	_noise.seed = randi()
	_noise.frequency = 2.0
	_t = randf() * 50.0
	_glow = LightGlow.new(Color(1.0, 0.68, 0.32), halo_energy, halo, 0.8)
	_glow.position = Vector2(0, -height * 0.5)
	add_child(_glow)
	_glow.dim = 1.0 if lit else 0.0


func nudge(amount: float) -> void:
	## A draught: called when the player brushes past or places something near.
	_sway += amount


func _process(delta: float) -> void:
	if not lit:
		return
	_t += delta
	_sway = lerpf(_sway, 0.0, delta * 3.0)
	queue_redraw()


func _draw() -> void:
	if not lit:
		return
	var n := _noise.get_noise_1d(_t * 3.0)
	var n2 := _noise.get_noise_1d(_t * 9.0 + 40.0)
	var h := height * (1.0 + n2 * 0.18)
	var lean := (n * 0.18 + _sway) * h
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in 18:
		var a := TAU * i / 18.0
		var y := -cos(a)          # -1 = top, 1 = bottom
		var up := (1.0 - (y * 0.5 + 0.5))  # 1 at top
		var widen := 0.5 + 0.5 * (1.0 - up)
		var x := sin(a) * h * 0.26 * widen + lean * up * up
		outer.append(Vector2(x, -h * 0.5 + y * h * 0.5))
		inner.append(Vector2(x * 0.5 + lean * 0.1, -h * 0.32 + y * h * 0.3))
	draw_colored_polygon(outer, Color(1.0, 0.55, 0.15, 0.92))
	draw_colored_polygon(inner, Color(1.0, 0.96, 0.78))
	draw_circle(Vector2(0, -1.5), h * 0.1, Color(0.4, 0.55, 1.0, 0.7))
