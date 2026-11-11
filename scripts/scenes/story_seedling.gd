class_name StorySeedling
extends StoryScene
## Chapter I — The Tiny Seedling. Spring, 1893: a close, low view of the
## woodland floor beneath the Mournes. A seed cracks open, a stem rises,
## the seed-husk drops and the first needles unfurl. A robin comes to look.

const SEED_POS := Vector2(980, 800)

var _seedling: Painter
var _shafts: Painter
var _butterfly: Painter
var _robin: Robin
var _husk_fall := 0.0


func _init() -> void:
	stage = 0
	duration = 21.0
	ambience = "spring"
	lines = [
		"Spring, 1893.",
		"In a quiet wood beneath the Mourne Mountains, a single seed wakes.",
		"It is very small. It is in no hurry at all.",
	]


func build_world() -> void:
	add_child(Painter.new(_paint_backdrop))
	_shafts = Painter.new(_paint_shafts)
	_shafts.material = Tex.add_material()
	add_child(_shafts)
	add_child(Painter.new(_paint_floor))
	_seedling = Painter.new(_paint_seedling)
	_seedling.position = SEED_POS
	_seedling.scale = Vector2(2.3, 2.3)
	add_child(_seedling)
	add_child(Painter.new(_paint_foreground))
	_robin = Robin.new()
	_robin.size = 3.2
	_robin.facing = -1.0
	_robin.position = Vector2(2100, 812)
	_robin.hop_interval = 2.2
	add_child(_robin)
	_butterfly = Painter.new(_paint_butterfly)
	add_child(_butterfly)
	var motes := CPUParticles2D.new()
	motes.position = Vector2(1100, 300)
	motes.amount = 40
	motes.lifetime = 8.0
	motes.preprocess = 8.0
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(600, 300)
	motes.gravity = Vector2(4, 3)
	motes.initial_velocity_min = 2.0
	motes.initial_velocity_max = 8.0
	motes.scale_amount_min = 1.0
	motes.scale_amount_max = 2.5
	motes.color = Color(1, 0.97, 0.8, 0.55)
	motes.material = Tex.add_material()
	add_child(motes)


func update(time: float, delta: float) -> void:
	_seedling.queue_redraw()
	_shafts.queue_redraw()
	_butterfly.queue_redraw()
	if time > 9.0:
		_husk_fall = minf(1.0, _husk_fall + delta * 0.8)
	# The robin hops in to inspect the newcomer
	if time > 11.0 and _robin.position.x > SEED_POS.x + 260.0:
		_robin.position.x -= delta * 150.0
		_robin.facing = -1.0


func _paint_backdrop(ci: CanvasItem) -> void:
	paint_sky(ci, Color(0.72, 0.82, 0.8), Color(0.92, 0.9, 0.74), Color(0.86, 0.88, 0.7), 760)
	# Hazy distant trunks and canopy
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	for layer in 3:
		var a := 0.25 + layer * 0.18
		var col := Color(0.45, 0.55, 0.45, a).lerp(Color(0.25, 0.32, 0.22, a), layer / 2.0)
		for k in 9:
			var x := rng.randf_range(-50, 1970)
			var w := 26.0 + layer * 22.0 + rng.randf_range(0, 20)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.5, 820), Vector2(x + w * 0.5, 820), Vector2(x + w * 0.3, -10), Vector2(x - w * 0.3, -10)]), col)
		for k in 14:
			var c := Vector2(rng.randf_range(-100, 2020), rng.randf_range(-60, 260 - layer * 40))
			ci.draw_colored_polygon(DecorArt.ellipse_pts(c, rng.randf_range(120, 260), rng.randf_range(70, 140)), Color(0.4 - layer * 0.08, 0.55 - layer * 0.08, 0.3, 0.22 + layer * 0.1))
	# The great mother pine at the left, roots and all
	var tx := 260.0
	ci.draw_colored_polygon(PackedVector2Array([Vector2(tx - 120, 900), Vector2(tx + 110, 900), Vector2(tx + 60, -20), Vector2(tx - 70, -20)]), Color(0.32, 0.22, 0.16))
	for k in 14:
		var y := rng.randf_range(0, 860)
		ci.draw_line(Vector2(tx - 70 + rng.randf_range(0, 20), y), Vector2(tx + 40 + rng.randf_range(0, 30), y + rng.randf_range(-12, 12)), Color(0.2, 0.13, 0.09, 0.6), rng.randf_range(2, 6))
	ci.draw_line(Vector2(tx + 50, -20), Vector2(tx + 100, 900), Color(0.9, 0.8, 0.55, 0.25), 8.0)
	for side in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(tx + side * 40, 860), Vector2(tx + side * 220, 930), Vector2(tx + side * 40, 930)]), Color(0.3, 0.2, 0.14))


func _paint_shafts(ci: CanvasItem) -> void:
	for k in 4:
		var x := 700.0 + k * 260.0
		var a := 0.06 + 0.04 * sin(t * 0.7 + k * 1.3)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, -10), Vector2(x + 120, -10), Vector2(x + 380, 900), Vector2(x + 180, 900)]), Color(1, 0.95, 0.7, a))


func _paint_floor(ci: CanvasItem) -> void:
	# Mossy, leaf-littered forest floor
	var pts := PackedVector2Array([Vector2(0, 1080)])
	for i in 25:
		var x := i * 80.0
		pts.append(Vector2(x, 790 + sin(x * 0.004) * 24 + sin(x * 0.013) * 8))
	pts.append(Vector2(1920, 1080))
	ci.draw_colored_polygon(pts, Color(0.36, 0.42, 0.22))
	UIKit.vgrad(ci, Rect2(0, 820, 1920, 260), Color(0.4, 0.46, 0.24, 0.0), Color(0.24, 0.24, 0.14))
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	# Old needles and leaf litter
	for k in 260:
		var p := Vector2(rng.randf_range(0, 1920), rng.randf_range(810, 1080))
		var a := rng.randf_range(0, TAU)
		ci.draw_line(p, p + Vector2(cos(a), sin(a) * 0.4) * rng.randf_range(6, 16), Color(0.55, 0.4, 0.22, 0.7), 2.0, true)
	# Bluebells
	for k in 34:
		var base := Vector2(rng.randf_range(420, 1900), rng.randf_range(790, 880))
		if absf(base.x - SEED_POS.x) < 120.0:
			continue
		var h := rng.randf_range(50, 90)
		var stem := PackedVector2Array()
		for i in 7:
			var tt := float(i) / 6.0
			stem.append(base + Vector2(sin(tt * 2.0) * 12.0 * tt, -tt * h))
		ci.draw_polyline(stem, Color(0.3, 0.45, 0.22), 2.5, true)
		for i in range(3, 7):
			ci.draw_colored_polygon(DecorArt.ellipse_pts(stem[i] + Vector2(6, 4), 4.5, 6.5, 10, 0.4), Color(0.36, 0.4, 0.78))
		ci.draw_line(base, base + Vector2(-20, -40), Color(0.28, 0.45, 0.2), 4.0, true)
	# Primroses
	for k in 12:
		var c := Vector2(rng.randf_range(400, 1900), rng.randf_range(850, 1040))
		for p in 5:
			var a := TAU * p / 5.0
			ci.draw_circle(c + Vector2(cos(a), sin(a)) * 7.0, 6.0, Color(0.98, 0.94, 0.62))
		ci.draw_circle(c, 3.5, Color(0.95, 0.7, 0.25))
	# The mother's fallen cone beside the seed
	var cone := SEED_POS + Vector2(-150, 30)
	ci.draw_colored_polygon(DecorArt.ellipse_pts(cone, 52, 26, 24, -0.2), Color(0.42, 0.28, 0.16))
	for row in 5:
		for k in 6:
			var p := cone + Vector2(-40 + k * 15 + row * 2, -14 + row * 7).rotated(-0.2)
			ci.draw_arc(p, 7, 0.2, PI - 0.2, 6, Color(0.6, 0.44, 0.26), 3.0, true)


func _paint_seedling(ci: CanvasItem) -> void:
	# Drawn at 2.3x around the seed: a close, low "macro" view of the miracle.
	var p := Vector2.ZERO
	var crack := smooth(1.5, 4.0, t)
	var rise := smooth(3.5, 9.5, t)
	var unfurl := smooth(9.0, 13.0, t)
	var grow := smooth(13.0, 20.0, t)
	var sway := sin(t * 1.3) * 3.0 * rise
	# Soil mound with a widening crack
	ci.draw_colored_polygon(DecorArt.ellipse_pts(p + Vector2(0, 6), 40, 12), Color(0.3, 0.22, 0.14))
	if crack > 0.0:
		ci.draw_line(p + Vector2(-14 * crack, 2), p + Vector2(14 * crack, 4), Color(0.12, 0.08, 0.05), 3.0, true)
	var h := rise * 120.0 + grow * 40.0
	var tip := p + Vector2(sway, -h)
	if rise > 0.0:
		# Stem: a pale pink-green hook straightening as it rises
		var stem := PackedVector2Array()
		for i in 12:
			var tt := float(i) / 11.0
			var hook := (1.0 - unfurl) * sin(tt * PI) * 14.0 * (1.0 - smooth(0.6, 1.0, rise))
			stem.append(p.lerp(tip, tt) + Vector2(hook, 0))
		ci.draw_polyline(stem, Color(0.7, 0.55, 0.45).lerp(Color(0.45, 0.6, 0.3), unfurl), 6.0, true)
		ci.draw_polyline(stem, Color(1, 0.95, 0.85, 0.35), 2.0, true)
	# Cotyledons: a little star of needles opening around the tip
	if unfurl > 0.0:
		for k in 9:
			var a := -PI * 0.5 + (k - 4) * 0.36 * unfurl + (0.0 if k % 2 == 0 else 0.1)
			var L := 46.0 * unfurl + grow * 14.0
			var end := tip + Vector2(cos(a), sin(a)) * L
			ci.draw_line(tip, end, Color(0.35, 0.58, 0.28), 4.0, true)
			ci.draw_line(tip, end, Color(0.7, 0.85, 0.5, 0.5), 1.5, true)
		# First true needles in the centre
		if grow > 0.0:
			for k in 7:
				var a2 := -PI * 0.5 + (k - 3) * 0.22
				ci.draw_line(tip, tip + Vector2(cos(a2), sin(a2)) * 26.0 * grow, Color(0.25, 0.5, 0.25), 3.0, true)
		# A dewdrop that catches the light
		var dew := tip + Vector2(cos(-PI * 0.5 + 0.72 * unfurl), sin(-PI * 0.5 + 0.72 * unfurl)) * 40.0 * unfurl
		ci.draw_circle(dew, 4.0, Color(0.85, 0.95, 1.0, 0.8))
		ci.draw_circle(dew + Vector2(-1.2, -1.2), 1.4, Color(1, 1, 1))
	# Seed husk: carried up on the tip, then dropped
	if rise > 0.05:
		var hp := tip + Vector2(0, -8)
		var rot := 0.0
		if _husk_fall > 0.0:
			hp = tip.lerp(p + Vector2(46, 2), _husk_fall) + Vector2(0, -sin(_husk_fall * PI) * 30.0)
			rot = _husk_fall * 3.0
		ci.draw_set_transform(hp, rot, Vector2.ONE)
		ci.draw_colored_polygon(DecorArt.ellipse_pts(Vector2.ZERO, 8, 13), Color(0.4, 0.27, 0.17))
		ci.draw_line(Vector2(0, -10), Vector2(0, 10), Color(0.25, 0.16, 0.1), 1.5)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _paint_foreground(ci: CanvasItem) -> void:
	# Out-of-focus fern fronds framing the view
	for f in 2:
		var base := Vector2(-40.0 if f == 0 else 1960.0, 1100)
		var dir := 1.0 if f == 0 else -1.0
		for k in 3:
			var stem := PackedVector2Array()
			var ang := -1.2 + k * 0.25
			for i in 14:
				var tt := float(i) / 13.0
				stem.append(base + Vector2(dir * tt * 420.0, -tt * 380.0 + tt * tt * 160.0).rotated(dir * (ang + 1.0) * 0.4))
			ci.draw_polyline(stem, Color(0.18, 0.3, 0.14, 0.9), 6.0, true)
			for i in range(1, 13):
				var tt := float(i) / 13.0
				var leaf_len := 60.0 * (1.0 - tt)
				var nrm := (stem[i + 1] - stem[i]).normalized().orthogonal()
				for sgn in [-1.0, 1.0]:
					ci.draw_colored_polygon(PackedVector2Array([stem[i], stem[i] + nrm * leaf_len * sgn + (stem[i + 1] - stem[i]) * 1.5, stem[i + 1]]), Color(0.2, 0.36, 0.15, 0.9))


func _paint_butterfly(ci: CanvasItem) -> void:
	# A brimstone butterfly, first sign of spring
	if t < 4.0 or t > 18.0:
		return
	var u := (t - 4.0) / 14.0
	var p := Vector2(lerpf(1800, 300, u), 380 + sin(u * 9.0) * 120 + sin(t * 3.0) * 20)
	var flap := absf(sin(t * 14.0))
	for sgn in [-1.0, 1.0]:
		ci.draw_colored_polygon(DecorArt.ellipse_pts(p + Vector2(sgn * 10 * flap, -6), 12 * flap + 2, 10, 14, sgn * 0.5), Color(0.98, 0.92, 0.45))
		ci.draw_colored_polygon(DecorArt.ellipse_pts(p + Vector2(sgn * 7 * flap, 6), 8 * flap + 1.5, 7, 12, sgn * -0.4), Color(0.95, 0.88, 0.4))
	ci.draw_line(p + Vector2(0, -9), p + Vector2(0, 9), Color(0.3, 0.25, 0.15), 2.0)
