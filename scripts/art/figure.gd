class_name Figure
extends Node2D
## An Edwardian family member, painted from simple shapes at storybook scale.
## Origin is between the feet. Roles: father, mother, girl, boy, dog.
## Poses: "walk", "stand", "point", "clasp", "raise", "shake" (head).

@export var role := "father"
@export var facing := 1.0
var pose := "stand"
var walk_phase := 0.0
var walking := false
var lantern_lit := true
var height_scale := 1.0

var _t := 0.0
var _breath: Array = []   # [pos, age]
var _breath_timer := 0.0
var lantern_glow: LightGlow


func _ready() -> void:
	_t = randf() * 3.0
	_breath_timer = randf() * 1.5
	if role == "father":
		lantern_glow = LightGlow.new(Color(1.0, 0.68, 0.32), 0.75, 170.0, 0.6)
		add_child(lantern_glow)


func _process(delta: float) -> void:
	_t += delta
	if walking:
		walk_phase += delta * (9.0 if role != "dog" else 13.0)
	_breath_timer -= delta
	if _breath_timer <= 0.0 and role != "dog":
		_breath_timer = randf_range(1.4, 2.4)
		_breath.append([_mouth(), 0.0])
	for b in _breath:
		b[1] += delta
	_breath = _breath.filter(func(b: Array) -> bool: return b[1] < 1.6)
	if lantern_glow:
		lantern_glow.position = _lantern_pos()
		lantern_glow.dim = 1.0 if lantern_lit else 0.0
		lantern_glow.energy = 0.95 if pose == "raise" else 0.75
	queue_redraw()


func _bob() -> float:
	return -absf(sin(walk_phase)) * 4.0 * height_scale if walking else sin(_t * 1.6) * 0.8


func _mouth() -> Vector2:
	var h := _head_pos()
	return h + Vector2(8 * facing * height_scale, 4 * height_scale)


func _head_pos() -> Vector2:
	var s := height_scale
	var tilt := 0.0
	if pose == "shake":
		tilt = sin(_t * 9.0) * 3.0
	match role:
		"father": return Vector2(tilt, -122 * s + _bob())
		"mother": return Vector2(tilt, -114 * s + _bob())
		"girl": return Vector2(tilt, -80 * s + _bob())
		"boy": return Vector2(tilt, -84 * s + _bob())
	return Vector2(18 * facing, -26 + _bob())


func _lantern_pos() -> Vector2:
	var s := height_scale
	if pose == "raise":
		return Vector2(30 * facing * s, -150 * s + _bob())
	var sw := sin(walk_phase) * 6.0 if walking else sin(_t * 1.2) * 1.5
	return Vector2(26 * facing * s + sw * facing, -46 * s + _bob())


func _draw() -> void:
	draw_colored_polygon(DecorArt.ellipse_pts(Vector2(0, 2), 34 * height_scale, 6 * height_scale), Color(0.1, 0.12, 0.25, 0.3))
	match role:
		"father": _draw_father()
		"mother": _draw_mother()
		"girl": _draw_girl()
		"boy": _draw_boy()
		"dog": _draw_dog()
	for b in _breath:
		var age: float = b[1]
		var p: Vector2 = b[0] + Vector2(facing * age * 14.0, -age * 18.0)
		draw_circle(p, (3.0 + age * 6.0) * height_scale, Color(0.95, 0.97, 1.0, 0.35 * (1.0 - age / 1.6)))


# ------------------------------------------------------------- pieces

func _legs(col: Color, hip_y: float, len_: float, w: float, boot: Color) -> void:
	var s := height_scale
	var sw := sin(walk_phase) * 0.45 if walking else 0.0
	for k in 2:
		var ph := sw if k == 0 else -sw
		var hip := Vector2((k * 2 - 1) * 4 * s, hip_y + _bob())
		var foot := hip + Vector2(sin(ph) * len_ * facing, cos(ph) * len_)
		draw_line(hip, foot, col, w * s, true)
		draw_colored_polygon(DecorArt.ellipse_pts(foot + Vector2(4 * facing * s, -1), 7 * s, 3.5 * s), boot)


func _arm(shoulder: Vector2, hand: Vector2, col: Color, w: float, glove: Color) -> void:
	draw_line(shoulder, hand, col, w * height_scale, true)
	draw_circle(hand, w * 0.45 * height_scale, glove)


func _face(h: Vector2, r: float, skin: Color) -> void:
	var s := height_scale
	draw_circle(h, r * s, skin)
	# Rosy cheek and a soft smile, turned toward the facing side
	draw_circle(h + Vector2(4 * facing * s, 2 * s), 2.2 * s, Color(0.95, 0.5, 0.5, 0.5))
	draw_circle(h + Vector2(3.5 * facing * s, -1.5 * s), 1.0 * s, Color(0.15, 0.08, 0.05))
	draw_arc(h + Vector2(4 * facing * s, 3 * s), 2.5 * s, 0.3, PI - 0.3, 6, Color(0.5, 0.2, 0.15), 1.0, true)


func _draw_father() -> void:
	var s := height_scale
	var coat := Color(0.2, 0.15, 0.13)
	var rim := Color(1.0, 0.7, 0.4, 0.35)
	_legs(Color(0.12, 0.11, 0.12), -40 * s, 40 * s, 7.0, Color(0.06, 0.05, 0.05))
	var b := _bob()
	# Greatcoat to the calves
	var coat_pts := PackedVector2Array([Vector2(-15 * s, -104 * s + b), Vector2(15 * s, -104 * s + b), Vector2(22 * s, -26 * s + b), Vector2(-21 * s, -26 * s + b)])
	draw_colored_polygon(coat_pts, coat)
	draw_line(Vector2(16 * facing * s, -100 * s + b), Vector2(22 * facing * s, -28 * s + b), rim, 2.5 * s, true)
	for k in 4:
		draw_circle(Vector2(3 * facing * s, (-92 + k * 14) * s + b), 1.6 * s, Color(0.6, 0.5, 0.3))
	# Tartan scarf
	draw_line(Vector2(-10 * s, -104 * s + b), Vector2(10 * s, -104 * s + b), Color(0.65, 0.1, 0.12), 6 * s)
	draw_line(Vector2(-4 * facing * s, -104 * s + b), Vector2(-8 * facing * s, -82 * s + b), Color(0.65, 0.1, 0.12), 5 * s)
	# Arms: one carrying the lantern
	var lp := _lantern_pos()
	var shoulder := Vector2(12 * facing * s, -100 * s + b)
	_arm(shoulder, lp + Vector2(0, -12 * s), coat.lightened(0.05), 7.0, Color(0.15, 0.1, 0.08))
	var sw := sin(walk_phase) * 10.0 if walking else 0.0
	var other_hand := Vector2(-10 * facing * s - sw * facing, -60 * s + b)
	if pose == "point":
		other_hand = Vector2(36 * facing * s, -104 * s + b)
	_arm(Vector2(-12 * facing * s, -100 * s + b), other_hand, coat.darkened(0.15), 7.0, Color(0.15, 0.1, 0.08))
	# Head: moustache and bowler hat
	var h := _head_pos()
	_face(h, 9.5, Color(0.95, 0.78, 0.66))
	draw_line(h + Vector2(2 * facing * s, 3.5 * s), h + Vector2(9 * facing * s, 3.5 * s), Color(0.35, 0.22, 0.12), 2.2 * s)
	draw_colored_polygon(DecorArt.ellipse_pts(h + Vector2(0, -7 * s), 13 * s, 3 * s), Color(0.08, 0.07, 0.07))
	draw_colored_polygon(DecorArt.ellipse_pts(h + Vector2(0, -12 * s), 9 * s, 7 * s), Color(0.1, 0.09, 0.09))
	_draw_lantern(lp)


func _draw_lantern(p: Vector2) -> void:
	var s := height_scale
	draw_line(p + Vector2(0, -12 * s), p + Vector2(0, -16 * s), Color(0.4, 0.32, 0.2), 1.5)
	draw_rect(Rect2(p + Vector2(-6 * s, -12 * s), Vector2(12 * s, 16 * s)), Color(0.35, 0.27, 0.15))
	var glass := Color(1.0, 0.85, 0.5) if lantern_lit else Color(0.3, 0.28, 0.25)
	draw_rect(Rect2(p + Vector2(-4.5 * s, -10 * s), Vector2(9 * s, 12 * s)), glass)
	if lantern_lit:
		draw_circle(p + Vector2(0, -3 * s), 2.5 * s, Color(1, 1, 0.9))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-7 * s, -12 * s), p + Vector2(7 * s, -12 * s), p + Vector2(0, -18 * s)]), Color(0.3, 0.24, 0.14))


func _draw_mother() -> void:
	var s := height_scale
	var coat := Color(0.42, 0.08, 0.12)
	var fur := Color(0.86, 0.82, 0.76)
	var b := _bob()
	var sway := sin(walk_phase) * 4.0 * s if walking else 0.0
	# Long skirted coat to the ground, flaring
	var coat_pts := PackedVector2Array([Vector2(-13 * s, -96 * s + b), Vector2(13 * s, -96 * s + b), Vector2(28 * s + sway, -2 * s), Vector2(-28 * s + sway, -2 * s)])
	draw_colored_polygon(coat_pts, coat)
	draw_line(Vector2(14 * facing * s, -92 * s + b), Vector2(28 * facing * s, -4 * s), Color(1.0, 0.7, 0.45, 0.3), 2.5 * s, true)
	# Fur hem and collar
	draw_line(Vector2(-29 * s + sway, -4 * s), Vector2(29 * s + sway, -4 * s), fur, 6 * s, true)
	draw_colored_polygon(DecorArt.ellipse_pts(Vector2(0, -96 * s + b), 15 * s, 6 * s), fur)
	# Muff held in front
	var muff := Vector2(10 * facing * s, -62 * s + b)
	if pose == "clasp":
		muff = Vector2(8 * facing * s, -74 * s + b)
	draw_colored_polygon(DecorArt.ellipse_pts(muff, 10 * s, 7 * s), fur.darkened(0.05))
	_arm(Vector2(10 * facing * s, -92 * s + b), muff + Vector2(-4 * facing * s, 0), coat.lightened(0.05), 6.0, fur)
	# Head, hair up, wide hat with a feather
	var h := _head_pos()
	draw_circle(h + Vector2(-6 * facing * s, -2 * s), 6 * s, Color(0.4, 0.22, 0.1))
	_face(h, 9.0, Color(0.97, 0.82, 0.72))
	draw_colored_polygon(DecorArt.ellipse_pts(h + Vector2(0, -8 * s), 20 * s, 4 * s), Color(0.15, 0.1, 0.12))
	draw_colored_polygon(DecorArt.ellipse_pts(h + Vector2(-2 * facing * s, -13 * s), 10 * s, 6 * s), Color(0.18, 0.12, 0.14))
	var feather := PackedVector2Array()
	for i in 8:
		var tt := float(i) / 7.0
		feather.append(h + Vector2((-8 - tt * 18) * facing * s, (-14 - sin(tt * PI) * 10) * s))
	draw_polyline(feather, Color(0.9, 0.88, 0.82), 3.0 * s, true)


func _draw_girl() -> void:
	var s := height_scale
	var coat := Color(0.7, 0.1, 0.12)
	var fur := Color(0.95, 0.93, 0.9)
	_legs(Color(0.1, 0.08, 0.1), -24 * s, 24 * s, 5.0, Color(0.08, 0.05, 0.04))
	var b := _bob()
	var coat_pts := PackedVector2Array([Vector2(-10 * s, -66 * s + b), Vector2(10 * s, -66 * s + b), Vector2(17 * s, -24 * s + b), Vector2(-17 * s, -24 * s + b)])
	draw_colored_polygon(coat_pts, coat)
	draw_line(Vector2(-18 * s, -25 * s + b), Vector2(18 * s, -25 * s + b), fur, 4 * s, true)
	draw_colored_polygon(DecorArt.ellipse_pts(Vector2(0, -66 * s + b), 11 * s, 4 * s), fur)
	var hands := Vector2(8 * facing * s, -46 * s + b)
	if pose == "clasp":
		hands = Vector2(6 * facing * s, -60 * s + b + sin(_t * 6.0) * 1.5)
	elif pose == "point":
		hands = Vector2(26 * facing * s, -72 * s + b)
	_arm(Vector2(6 * facing * s, -62 * s + b), hands, coat.lightened(0.05), 5.0, fur)
	var h := _head_pos()
	# Long plait
	draw_line(h + Vector2(-5 * facing * s, 0), h + Vector2(-8 * facing * s, 22 * s), Color(0.75, 0.55, 0.25), 3.5 * s, true)
	_face(h, 8.0, Color(0.98, 0.84, 0.76))
	# Tam o' shanter with a bobble
	draw_colored_polygon(DecorArt.ellipse_pts(h + Vector2(-1 * facing * s, -7 * s), 11 * s, 5 * s), Color(0.95, 0.93, 0.9))
	draw_circle(h + Vector2(-2 * facing * s, -12 * s), 3 * s, Color(0.7, 0.1, 0.12))


func _draw_boy() -> void:
	var s := height_scale
	var jacket := Color(0.32, 0.35, 0.28)
	_legs(Color(0.25, 0.25, 0.22), -30 * s, 28 * s, 5.5, Color(0.08, 0.05, 0.04))
	var b := _bob()
	# Knickerbockers then Norfolk jacket
	draw_colored_polygon(PackedVector2Array([Vector2(-9 * s, -40 * s + b), Vector2(9 * s, -40 * s + b), Vector2(10 * s, -24 * s + b), Vector2(-10 * s, -24 * s + b)]), Color(0.35, 0.3, 0.25))
	draw_colored_polygon(PackedVector2Array([Vector2(-10 * s, -72 * s + b), Vector2(10 * s, -72 * s + b), Vector2(12 * s, -38 * s + b), Vector2(-12 * s, -38 * s + b)]), jacket)
	draw_line(Vector2(-11 * s, -50 * s + b), Vector2(11 * s, -50 * s + b), jacket.darkened(0.3), 2.0 * s)
	# Long striped scarf trailing behind
	var scarf := PackedVector2Array()
	for i in 8:
		var tt := float(i) / 7.0
		scarf.append(Vector2(-tt * 26 * facing * s, (-72 + tt * 18 + sin(tt * 4.0 + _t * 3.0) * 3) * s + b))
	draw_polyline(scarf, Color(0.15, 0.3, 0.55), 5 * s, true)
	for i in range(1, 7, 2):
		draw_circle(scarf[i], 2.6 * s, Color(0.9, 0.85, 0.75))
	var hand := Vector2(9 * facing * s, -46 * s + b)
	if pose == "point":
		hand = Vector2(28 * facing * s, -80 * s + b)
	_arm(Vector2(6 * facing * s, -68 * s + b), hand, jacket.lightened(0.05), 5.0, Color(0.95, 0.8, 0.7))
	var h := _head_pos()
	_face(h, 8.0, Color(0.97, 0.82, 0.72))
	# Flat cap
	draw_colored_polygon(DecorArt.ellipse_pts(h + Vector2(1 * facing * s, -6 * s), 10 * s, 4.5 * s), Color(0.3, 0.27, 0.22))
	draw_colored_polygon(DecorArt.ellipse_pts(h + Vector2(8 * facing * s, -4 * s), 6 * s, 2 * s), Color(0.25, 0.22, 0.18))


func _draw_dog() -> void:
	var s := height_scale
	var b := _bob()
	var brown := Color(0.45, 0.27, 0.14)
	var white := Color(0.93, 0.9, 0.84)
	var legs_sw := sin(walk_phase) * 0.5 if walking else 0.0
	for k in 4:
		var x := (-14 + k * 9) * s
		var ph := legs_sw if k % 2 == 0 else -legs_sw
		draw_line(Vector2(x, -12 * s + b), Vector2(x + sin(ph) * 8 * facing, 0), white if k % 2 == 0 else brown, 3.5 * s, true)
	draw_colored_polygon(DecorArt.ellipse_pts(Vector2(0, -16 * s + b), 20 * s, 9 * s), white)
	draw_colored_polygon(DecorArt.ellipse_pts(Vector2(-6 * facing * s, -18 * s + b), 10 * s, 7 * s), brown)
	var wag := sin(_t * 14.0) * 0.5
	draw_line(Vector2(-19 * facing * s, -18 * s + b), Vector2(-19 * facing * s, -18 * s + b) + Vector2(-10 * facing, -8).rotated(wag) * s, white, 3.0 * s, true)
	var h := Vector2(20 * facing * s, -26 * s + b)
	draw_circle(h, 7.5 * s, brown)
	draw_colored_polygon(DecorArt.ellipse_pts(h + Vector2(6 * facing * s, 2 * s), 5 * s, 3.5 * s), white)
	draw_circle(h + Vector2(10 * facing * s, 1 * s), 1.6 * s, Color(0.08, 0.05, 0.04))
	draw_circle(h + Vector2(2 * facing * s, -2 * s), 1.2 * s, Color(0.08, 0.05, 0.04))
	draw_colored_polygon(DecorArt.ellipse_pts(h + Vector2(-4 * facing * s, 4 * s), 3.5 * s, 7 * s), brown.darkened(0.25))
