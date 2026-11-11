class_name StoryYears
extends StoryScene
## Chapter II — Growing in the Forest. A montage through the seasons from
## 1894 to 1901: summer sun, autumn gales, winter snow and spring rain,
## while the little tree grows tall at the heart of its clearing.

const SEGMENTS := [
	["summer", 1894], ["autumn", 1894], ["winter", 1894], ["spring", 1895],
	["summer", 1896], ["autumn", 1897], ["winter", 1899], ["spring", 1900],
	["summer", 1901], ["autumn", 1901],
]
const SEG_LEN := 2.7
const TREE_BASE := Vector2(980, 880)
const SEASONS := ["summer", "autumn", "winter", "spring"]

var _backs: Dictionary = {}
var _trees: Array = []       # [{node, snowy}]
var _snow: Snowfall
var _rain: CPUParticles2D
var _leaves: CPUParticles2D
var _year_label: Control
var _year := 1894
var _sun: LightGlow


func _init() -> void:
	stage = 1
	duration = SEGMENTS.size() * SEG_LEN + 1.6
	ambience = "summer"
	caption_hold = 3.6
	lines = [
		"The seasons turned, as seasons do.",
		"Summer sun. Autumn gales. Winter snow. Spring rain.",
		"And year by year, our little tree grew straight and strong.",
	]


func build_world() -> void:
	for s in SEASONS:
		var p := Painter.new(_paint_season.bind(s))
		p.modulate.a = 0.0
		add_child(p)
		_backs[s] = p
	_sun = LightGlow.new(Color(1.0, 0.9, 0.6), 0.5, 380.0, 0.0)
	_sun.position = Vector2(1500, 180)
	add_child(_sun)
	# Three growth stages, each in a green and a snowy version
	var specs := [[260.0, 150.0, 11], [420.0, 240.0, 12], [560.0, 330.0, 13]]
	for spec in specs:
		for snowy in [false, true]:
			var tr := TreeArt.new()
			tr.height = spec[0]
			tr.width = spec[1]
			tr.seed_value = spec[2]
			tr.palette = "winter" if snowy else "summer"
			tr.snow = 0.9 if snowy else 0.0
			tr.detail = 0.8
			tr.position = TREE_BASE
			tr.modulate.a = 0.0
			add_child(tr)
			_trees.append({"node": tr, "snowy": snowy, "h": spec[0]})
	add_child(Painter.new(_paint_near_ground))
	_snow = Snowfall.new()
	_snow.count = 160
	_snow.visible = false
	add_child(_snow)
	_rain = CPUParticles2D.new()
	_rain.position = Vector2(960, -20)
	_rain.amount = 220
	_rain.lifetime = 0.9
	_rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_rain.emission_rect_extents = Vector2(1100, 10)
	_rain.direction = Vector2(0.15, 1)
	_rain.spread = 2.0
	_rain.gravity = Vector2(0, 0)
	_rain.initial_velocity_min = 1100.0
	_rain.initial_velocity_max = 1300.0
	_rain.scale_amount_min = 1.0
	_rain.scale_amount_max = 1.5
	_rain.color = Color(0.8, 0.85, 0.95, 0.45)
	_rain.texture = Tex.streak()
	_rain.particle_flag_align_y = true
	_rain.emitting = false
	add_child(_rain)
	_leaves = CPUParticles2D.new()
	_leaves.position = Vector2(960, -30)
	_leaves.amount = 60
	_leaves.lifetime = 5.0
	_leaves.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_leaves.emission_rect_extents = Vector2(1100, 10)
	_leaves.direction = Vector2(0.6, 1)
	_leaves.spread = 25.0
	_leaves.gravity = Vector2(30, 60)
	_leaves.initial_velocity_min = 60.0
	_leaves.initial_velocity_max = 140.0
	_leaves.angular_velocity_min = -200.0
	_leaves.angular_velocity_max = 200.0
	_leaves.scale_amount_min = 4.0
	_leaves.scale_amount_max = 7.0
	var lg := Gradient.new()
	lg.set_color(0, Color(0.85, 0.45, 0.12))
	lg.set_color(1, Color(0.65, 0.3, 0.1))
	_leaves.color_initial_ramp = lg
	_leaves.emitting = false
	add_child(_leaves)
	_year_label = Control.new()
	_year_label.size = Vector2(1920, 1080)
	_year_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_year_label.draw.connect(func() -> void:
		var f := UIKit.font("title")
		UIKit.text_centered(_year_label, f, Vector2(1700, 120), str(_year), 72, Color(0.25, 0.18, 0.12, 0.65), false)
		UIKit.divider(_year_label, Vector2(1700, 168), 70, Color(0.35, 0.25, 0.15, 0.5))
	)
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	layer.add_child(_year_label)


func update(time: float, _delta: float) -> void:
	var seg_f := clampf(time / SEG_LEN, 0.0, SEGMENTS.size() - 0.001)
	var seg := int(seg_f)
	var frac := seg_f - seg
	var cur: Array = SEGMENTS[seg]
	var nxt: Array = SEGMENTS[mini(seg + 1, SEGMENTS.size() - 1)]
	var blend := smooth(0.7, 1.0, frac)
	# Backdrop crossfade between seasons
	for s in SEASONS:
		var a := 0.0
		if s == cur[0]:
			a += 1.0 - blend
		if s == nxt[0]:
			a += blend
		(_backs[s] as CanvasItem).modulate.a = clampf(a, 0.0, 1.0)
	if _year != int(cur[1]):
		_year = int(cur[1])
		_year_label.queue_redraw()
		AudioDirector.sfx("page", 1.3, -14.0)
	var winter_w := ((1.0 - blend) if cur[0] == "winter" else 0.0) + (blend if nxt[0] == "winter" else 0.0)
	_snow.visible = winter_w > 0.3
	_rain.emitting = cur[0] == "spring" and frac < 0.85
	_leaves.emitting = cur[0] == "autumn"
	_sun.dim = ((1.0 - blend) if cur[0] == "summer" else 0.0) + (blend if nxt[0] == "summer" else 0.0)
	# Growth: from a knee-high sapling to a fine young fir
	var g := lerpf(0.42, 1.0, smooth(0.0, duration - 2.0, time))
	var target_h := g * 560.0
	for e in _trees:
		var tr: TreeArt = e["node"]
		var h: float = e["h"]
		tr.scale = Vector2.ONE * (target_h / h)
		# Pick the stage whose natural height is closest
		var stage_w := clampf(1.0 - absf(target_h - h) / 150.0, 0.0, 1.0)
		var snow_w := winter_w if e["snowy"] else 1.0 - winter_w
		tr.modulate.a = stage_w * snow_w
		if cur[0] == "autumn" and not e["snowy"]:
			tr.modulate = Color(1.05, 0.98, 0.85, tr.modulate.a)
		elif not e["snowy"]:
			tr.modulate = Color(1, 1, 1, tr.modulate.a)


func _paint_season(ci: CanvasItem, season: String) -> void:
	var sky_top: Color
	var sky_mid: Color
	var sky_hz: Color
	var hill: Color
	var ground: Color
	var far: Color
	match season:
		"summer":
			sky_top = Color(0.5, 0.68, 0.85)
			sky_mid = Color(0.78, 0.86, 0.9)
			sky_hz = Color(0.96, 0.92, 0.75)
			hill = Color(0.45, 0.55, 0.42)
			ground = Color(0.5, 0.62, 0.3)
			far = Color(0.28, 0.4, 0.28)
		"autumn":
			sky_top = Color(0.55, 0.6, 0.7)
			sky_mid = Color(0.85, 0.78, 0.65)
			sky_hz = Color(0.95, 0.8, 0.55)
			hill = Color(0.55, 0.45, 0.32)
			ground = Color(0.6, 0.45, 0.22)
			far = Color(0.42, 0.3, 0.2)
		"winter":
			sky_top = Color(0.55, 0.6, 0.72)
			sky_mid = Color(0.78, 0.8, 0.86)
			sky_hz = Color(0.9, 0.9, 0.92)
			hill = Color(0.82, 0.85, 0.9)
			ground = Color(0.92, 0.94, 0.97)
			far = Color(0.4, 0.45, 0.5)
		_:
			sky_top = Color(0.55, 0.62, 0.68)
			sky_mid = Color(0.72, 0.76, 0.76)
			sky_hz = Color(0.82, 0.84, 0.78)
			hill = Color(0.45, 0.55, 0.45)
			ground = Color(0.4, 0.55, 0.3)
			far = Color(0.25, 0.35, 0.28)
	paint_sky(ci, sky_top, sky_mid, sky_hz, 700)
	if season == "summer":
		ci.draw_circle(Vector2(1500, 180), 46, Color(1, 0.97, 0.85))
	if season == "spring" or season == "winter":
		# Soft cloud banks
		for k in 7:
			ci.draw_colored_polygon(DecorArt.ellipse_pts(Vector2(150 + k * 280, 140 + (k % 3) * 30), 210, 60), Color(1, 1, 1, 0.25))
	# The Mournes on the horizon
	paint_hills(ci, 600, 70, hill.lerp(sky_hz, 0.45), 1.3, 1.6)
	paint_hills(ci, 690, 40, hill, 2.8, 2.4)
	var snow_col := Color(0.95, 0.96, 1.0, 0.9) if season == "winter" else Color(0, 0, 0, 0)
	paint_fir_silhouettes(ci, 740, 120, 230, far.lerp(sky_hz, 0.25), snow_col, 5, 70)
	# Deciduous neighbours: oaks that turn with the seasons
	var oak_col := {"summer": Color(0.3, 0.45, 0.22), "autumn": Color(0.8, 0.45, 0.15), "winter": Color(0.4, 0.35, 0.33, 0.0), "spring": Color(0.5, 0.65, 0.3)}[season] as Color
	for ox in [320.0, 1600.0]:
		ci.draw_line(Vector2(ox, 860), Vector2(ox + 10, 560), Color(0.3, 0.22, 0.16), 26.0)
		for k in 5:
			var a := -PI * 0.5 + (k - 2) * 0.5
			ci.draw_line(Vector2(ox + 10, 640), Vector2(ox + 10, 640) + Vector2(cos(a), sin(a)) * 170, Color(0.3, 0.22, 0.16), 9.0, true)
		if oak_col.a > 0.0:
			for k in 9:
				var c := Vector2(ox + 10 + cos(k * 0.7) * 150, 500 + sin(k * 1.3) * 70)
				ci.draw_colored_polygon(DecorArt.ellipse_pts(c, 120, 80), oak_col.lightened(0.05 * (k % 3)))
		elif season == "winter":
			for k in 5:
				var a := -PI * 0.5 + (k - 2) * 0.5
				var e := Vector2(ox + 10, 640) + Vector2(cos(a), sin(a)) * 170
				ci.draw_line(e - Vector2(cos(a), sin(a)) * 60, e, Color(0.95, 0.96, 1.0), 4.0, true)
	# Ground of the clearing
	var g := PackedVector2Array([Vector2(0, 1080)])
	for i in 25:
		var x := i * 80.0
		g.append(Vector2(x, 840 + sin(x * 0.005) * 20))
	g.append(Vector2(1920, 1080))
	ci.draw_colored_polygon(g, ground)
	UIKit.vgrad(ci, Rect2(0, 860, 1920, 220), Color(ground, 0.0), ground.darkened(0.25))
	var rng := RandomNumberGenerator.new()
	rng.seed = 20
	match season:
		"summer":
			for k in 16:
				var b := Vector2(rng.randf_range(100, 1850), rng.randf_range(850, 1000))
				if absf(b.x - TREE_BASE.x) < 160.0:
					continue
				ci.draw_line(b, b + Vector2(0, -110), Color(0.3, 0.45, 0.2), 3.0)
				for j in 6:
					ci.draw_colored_polygon(DecorArt.ellipse_pts(b + Vector2(5, -40 - j * 12), 6, 8), Color(0.8, 0.35, 0.6))
		"autumn":
			for k in 40:
				var b := Vector2(rng.randf_range(0, 1920), rng.randf_range(850, 1060))
				ci.draw_colored_polygon(DecorArt.ellipse_pts(b, 8, 4, 10, rng.randf() * TAU), Color(0.8, 0.4, 0.1, 0.8))
		"spring":
			for k in 30:
				var b := Vector2(rng.randf_range(0, 1920), rng.randf_range(860, 1060))
				ci.draw_circle(b, 4, Color(0.4, 0.42, 0.8))
			for k in 4:
				var c := Vector2(rng.randf_range(200, 1700), rng.randf_range(930, 1030))
				ci.draw_colored_polygon(DecorArt.ellipse_pts(c, 90, 12), Color(0.7, 0.78, 0.85, 0.6))
		"winter":
			for k in 12:
				var c := Vector2(rng.randf_range(0, 1920), rng.randf_range(880, 1060))
				ci.draw_colored_polygon(DecorArt.ellipse_pts(c, 140, 18), Color(1, 1, 1, 0.5))


func _paint_near_ground(ci: CanvasItem) -> void:
	# A soft shadow at the foot of the tree, common to all seasons
	ci.draw_colored_polygon(DecorArt.ellipse_pts(TREE_BASE + Vector2(0, 6), 160, 18), Color(0.1, 0.12, 0.08, 0.25))
