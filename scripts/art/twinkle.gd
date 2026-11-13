class_name Twinkle
extends Node2D
## Little four-point glints of candlelight that catch on the glass, tinsel
## and gilt of whatever is hanging on the tree. Drawn additively above the
## room's darkness layer, so they shine brightest when the lamps are low.

const MAX_GLINTS := 26

var decor: DecorManager
var energy := 1.0            # the room raises this when the candles are lit
var _glints: Array = []      # each: {p, t, life, size, col}
var _spawn := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	z_index = 60
	z_as_relative = false
	material = Tex.add_material()
	_rng.randomize()


func _process(delta: float) -> void:
	if not visible or decor == null:
		return
	var n := decor.count()
	if n > 0 and _glints.size() < MAX_GLINTS:
		_spawn -= delta
		if _spawn <= 0.0:
			# More ornaments, more sparkle; never a blizzard of it.
			_spawn = _rng.randf_range(0.25, 0.7) / clampf(float(n) / 14.0, 0.35, 2.2)
			_add_glint()
	for i in range(_glints.size() - 1, -1, -1):
		_glints[i]["t"] += delta
		if _glints[i]["t"] >= _glints[i]["life"]:
			_glints.remove_at(i)
	queue_redraw()


func _add_glint() -> void:
	var pos: Variant = decor.random_glint_point(_rng)
	if pos == null:
		return
	var warm := _rng.randf()
	_glints.append({
		"p": pos,
		"t": 0.0,
		"life": _rng.randf_range(0.7, 1.5),
		"size": _rng.randf_range(7.0, 17.0),
		"col": Color(1.0, 0.86 + warm * 0.12, 0.55 + warm * 0.4),
	})


func _draw() -> void:
	for g in _glints:
		var k: float = g["t"] / g["life"]
		var a := sin(k * PI)
		a = a * a * 0.85 * energy
		var s: float = g["size"] * (0.6 + 0.4 * sin(k * PI))
		var c: Color = g["col"]
		var p: Vector2 = g["p"]
		draw_texture_rect(Tex.glow(), Rect2(p - Vector2(s, s) * 1.6, Vector2(s, s) * 3.2), false, Color(c, a * 0.55))
		draw_line(p - Vector2(s, 0), p + Vector2(s, 0), Color(c, a), 1.6, true)
		draw_line(p - Vector2(0, s * 1.25), p + Vector2(0, s * 1.25), Color(c, a), 1.6, true)
		var d := s * 0.42
		draw_line(p - Vector2(d, d), p + Vector2(d, d), Color(c, a * 0.5), 1.0, true)
		draw_line(p - Vector2(d, -d), p + Vector2(d, -d), Color(c, a * 0.5), 1.0, true)
