class_name Garland
extends Node2D
## A swag draped between two points on the tree. The curve is a catenary-like
## parabola whose sag grows with the span, sampled at the spacing of whatever
## is threaded on it (beads, popcorn, bulbs...).

const SPACING := {"tinsel": 6.0, "popcorn": 8.5, "cranberry": 7.5, "beads": 7.0, "paper_chain": 9.0, "electric": 7.0}

var def: Dictionary = {}
var data: Dictionary = {}
var points := PackedVector2Array()   # local to position (= end A)
var show_handles := false:
	set(v):
		if show_handles != v:
			show_handles = v
			queue_redraw()
var hovered := false:
	set(v):
		if hovered != v:
			hovered = v
			modulate = Color(1.2, 1.15, 1.02) if v else Color.WHITE
var lit := false

var _t := 0.0
var _redraw_acc := 0.0
var _bulb_glows: Array[LightGlow] = []
var _sway := 0.0
var _sway_v := 0.0


func setup(p_def: Dictionary, p_data: Dictionary) -> Garland:
	def = p_def
	data = p_data
	if not data.has("seed"):
		data["seed"] = randi() % 100000
	return self


func _ready() -> void:
	rebuild()


func end_a() -> Vector2:
	return Vector2(data["x"], data["y"])


func end_b() -> Vector2:
	return Vector2(data["x2"], data["y2"])


func set_ends(a: Vector2, b: Vector2) -> void:
	data["x"] = a.x
	data["y"] = a.y
	data["x2"] = b.x
	data["y2"] = b.y
	rebuild()


func rebuild() -> void:
	var a := end_a()
	var b := end_b()
	position = a
	var span := a.distance_to(b)
	var sag := 12.0 + span * 0.11 + _sway
	var spacing: float = SPACING.get(def.get("draw", ""), 7.0)
	var n := maxi(4, int(span / spacing))
	points = PackedVector2Array()
	for i in n + 1:
		var t := float(i) / n
		var p := a.lerp(b, t) + Vector2(0, 4.0 * sag * t * (1.0 - t))
		points.append(p - a)
	_rebuild_bulbs()
	queue_redraw()


func _rebuild_bulbs() -> void:
	if def.get("draw", "") != "electric":
		return
	var wanted := range(1, points.size(), 3)
	if wanted.size() == _bulb_glows.size():
		# Same number of bulbs: just follow the curve.
		for k in wanted.size():
			_bulb_glows[k].position = points[wanted[k]] + Vector2(0, 7)
		return
	for g in _bulb_glows:
		g.queue_free()
	_bulb_glows.clear()
	var bulb_cols := [Color(1, 0.35, 0.25), Color(1, 0.8, 0.35), Color(0.45, 0.75, 1.0), Color(0.55, 1, 0.55)]
	for i in wanted:
		var g := LightGlow.new(bulb_cols[(i / 3) % 4], 0.5, 26.0, 0.05)
		g.position = points[i] + Vector2(0, 7)
		g.dim = 1.0 if lit else 0.0
		add_child(g)
		_bulb_glows.append(g)


func set_lit(on: bool) -> void:
	lit = on
	for g in _bulb_glows:
		g.dim = 1.0 if on else 0.0
	queue_redraw()


func impulse(v: float) -> void:
	_sway_v += v * 20.0
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	var animated: bool = def.get("draw", "") == "tinsel"
	# Gentle bounce when brushed
	var acc := -30.0 * _sway - 3.0 * _sway_v
	_sway_v += acc * delta
	_sway += _sway_v * delta
	var moving := absf(_sway) > 0.05 or absf(_sway_v) > 0.05
	if moving:
		rebuild()
	elif animated:
		_redraw_acc += delta
		if _redraw_acc > 0.08:
			_redraw_acc = 0.0
			queue_redraw()


func _draw() -> void:
	DecorArt.draw_garland(self, def, points, _t, int(data.get("seed", 0)), lit)
	if show_handles and points.size() > 1:
		for p in [points[0], points[points.size() - 1]]:
			draw_circle(p, 9, Color(0, 0, 0, 0.35))
			draw_arc(p, 8, 0, TAU, 20, UIKit.GOLD_LIGHT, 2.5, true)
			draw_circle(p, 3, UIKit.GOLD)


func hit_end(global_p: Vector2) -> int:
	## Returns 0 for end A, 1 for end B, -1 if neither is under the pointer.
	if global_p.distance_to(end_a()) < 16.0:
		return 0
	if global_p.distance_to(end_b()) < 16.0:
		return 1
	return -1


func hit_test(global_p: Vector2) -> bool:
	var local := global_p - position
	for i in points.size() - 1:
		var q := Geometry2D.get_closest_point_to_segment(local, points[i], points[i + 1])
		if q.distance_to(local) < 10.0:
			return true
	return false
