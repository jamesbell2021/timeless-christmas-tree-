class_name RoomWalls
extends Node2D
## The parlour's shell: cornice, damask wallpaper, wainscoting, skirting,
## polished floorboards and a Persian rug. Drawn once and cached.

const L = preload("res://scripts/art/room_layout.gd")


func _draw() -> void:
	_wallpaper()
	_cornice()
	_wainscot()
	_floor()
	_rug()


func _wallpaper() -> void:
	var r := Rect2(0, L.CORNICE_H, 1920, L.DADO_Y - L.CORNICE_H)
	UIKit.vgrad(self, Rect2(r.position, Vector2(r.size.x, r.size.y * 0.5)), Color(0.06, 0.13, 0.09), Color(0.1, 0.2, 0.14))
	UIKit.vgrad(self, Rect2(r.position + Vector2(0, r.size.y * 0.5), Vector2(r.size.x, r.size.y * 0.5)), Color(0.1, 0.2, 0.14), Color(0.075, 0.15, 0.1))
	# Damask motifs, half-drop repeat
	var sx := 128.0
	var sy := 156.0
	var row := 0
	var y := L.PICTURE_RAIL_Y + 30.0
	while y < L.DADO_Y + sy:
		var x := -sx * 0.5 + (sx * 0.5 if row % 2 == 1 else 0.0)
		while x < 1920 + sx:
			_damask(Vector2(x, y))
			x += sx
		y += sy * 0.5
		row += 1
	# Picture rail
	UIKit.vgrad(self, Rect2(0, L.PICTURE_RAIL_Y - 5, 1920, 10), Color(0.32, 0.18, 0.09), Color(0.12, 0.06, 0.03))
	draw_line(Vector2(0, L.PICTURE_RAIL_Y - 5), Vector2(1920, L.PICTURE_RAIL_Y - 5), Color(1, 0.8, 0.5, 0.15), 1.0)
	# Shadow under the cornice
	UIKit.vgrad(self, Rect2(0, L.CORNICE_H, 1920, 60), Color(0, 0, 0, 0.45), Color(0, 0, 0, 0))


func _damask(c: Vector2) -> void:
	var hi := Color(0.17, 0.3, 0.2, 0.75)
	var gold := Color(0.62, 0.52, 0.28, 0.16)
	# Central bud
	draw_colored_polygon(DecorArt.ellipse_pts(c, 9, 20), hi)
	draw_colored_polygon(DecorArt.ellipse_pts(c + Vector2(0, -26), 5, 9), hi)
	# Sweeping leaves
	for side in [-1.0, 1.0]:
		var pts := PackedVector2Array()
		for i in 12:
			var t := float(i) / 11.0
			pts.append(c + Vector2(side * (6 + sin(t * PI) * 30.0), 18 - t * 52.0))
		for i in range(11, -1, -1):
			var t := float(i) / 11.0
			pts.append(c + Vector2(side * (6 + sin(t * PI) * 18.0), 14 - t * 46.0))
		draw_colored_polygon(pts, hi)
		draw_arc(c + Vector2(side * 22, 30), 9, PI * 1.2 if side < 0 else -PI * 0.2, PI * 2.0 if side < 0 else PI * 0.8, 10, gold, 1.5, true)
		draw_circle(c + Vector2(side * 34, -12), 3.0, hi)
	draw_line(c + Vector2(0, 20), c + Vector2(0, 44), hi, 2.0)
	draw_arc(c, 24, 0, TAU, 20, gold, 1.0, true)


func _cornice() -> void:
	UIKit.vgrad(self, Rect2(0, 0, 1920, L.CORNICE_H), Color(0.16, 0.12, 0.09), Color(0.3, 0.24, 0.18))
	# Dentil course
	for x in range(0, 1920, 18):
		draw_rect(Rect2(x, L.CORNICE_H - 18, 11, 10), Color(0.38, 0.31, 0.24))
		draw_rect(Rect2(x + 11, L.CORNICE_H - 18, 7, 10), Color(0.12, 0.09, 0.07))
	draw_rect(Rect2(0, L.CORNICE_H - 7, 1920, 7), Color(0.22, 0.17, 0.12))
	draw_line(Vector2(0, L.CORNICE_H - 7), Vector2(1920, L.CORNICE_H - 7), Color(0.5, 0.42, 0.32), 1.5)
	draw_line(Vector2(0, L.CORNICE_H), Vector2(1920, L.CORNICE_H), Color(0, 0, 0, 0.6), 2.0)


func _wainscot() -> void:
	var top := L.DADO_Y
	var bottom := L.SKIRTING_Y
	var r := Rect2(0, top, 1920, bottom - top)
	UIKit.vgrad(self, r, Color(0.2, 0.1, 0.05), Color(0.12, 0.06, 0.03))
	draw_texture_rect(Tex.wood(), r, true, Color(1, 1, 1, 0.35))
	# Raised panels
	var pw := 150.0
	var x := 14.0
	while x < 1920:
		var pr := Rect2(x, top + 24, pw - 22, bottom - top - 44)
		UIKit.vgrad(self, pr, Color(0.25, 0.13, 0.06), Color(0.15, 0.075, 0.035))
		draw_texture_rect(Tex.wood(), pr, true, Color(1, 1, 1, 0.25))
		draw_line(pr.position, Vector2(pr.end.x, pr.position.y), Color(0, 0, 0, 0.55), 3.0)
		draw_line(pr.position, Vector2(pr.position.x, pr.end.y), Color(0, 0, 0, 0.45), 3.0)
		draw_line(Vector2(pr.position.x, pr.end.y), pr.end, Color(1, 0.75, 0.45, 0.14), 2.0)
		draw_line(Vector2(pr.end.x, pr.position.y), pr.end, Color(1, 0.75, 0.45, 0.1), 2.0)
		var inner := pr.grow(-12)
		draw_rect(inner, Color(0, 0, 0, 0.18), false, 2.0)
		x += pw
	# Dado rail
	UIKit.vgrad(self, Rect2(0, top - 6, 1920, 18), Color(0.38, 0.21, 0.1), Color(0.12, 0.06, 0.03))
	draw_line(Vector2(0, top - 6), Vector2(1920, top - 6), Color(1, 0.8, 0.5, 0.22), 1.5)
	draw_line(Vector2(0, top + 12), Vector2(1920, top + 12), Color(0, 0, 0, 0.6), 2.0)
	# Skirting board
	UIKit.vgrad(self, Rect2(0, bottom, 1920, L.FLOOR_Y - bottom), Color(0.22, 0.11, 0.05), Color(0.08, 0.04, 0.02))
	draw_line(Vector2(0, bottom), Vector2(1920, bottom), Color(1, 0.8, 0.5, 0.18), 2.0)


func _floor() -> void:
	var r := Rect2(0, L.FLOOR_Y, 1920, 1080 - L.FLOOR_Y)
	UIKit.vgrad(self, r, Color(0.1, 0.05, 0.025), Color(0.2, 0.1, 0.05))
	draw_texture_rect(Tex.wood(), r, true, Color(1, 1, 1, 0.22))
	# Board seams converge on the vanishing point
	var rng := RandomNumberGenerator.new()
	rng.seed = 44
	var n := 46
	for i in n + 1:
		var u := float(i) / n
		var a := L.floor_point(u, 0.0)
		var b := L.floor_point(u, 1.0)
		draw_line(a, b, Color(0, 0, 0, 0.38), 1.5)
		# Staggered butt joints
		var u2 := float(i + 1) / n
		var depth := rng.randf_range(0.05, 0.9)
		draw_line(L.floor_point(u, depth), L.floor_point(u2, depth), Color(0, 0, 0, 0.3), 1.2)
	# Reflection of the bay window on the polished boards
	var w := L.WINDOW
	var refl := PackedVector2Array([
		Vector2(w.position.x + 30, L.FLOOR_Y + 4), Vector2(w.end.x - 30, L.FLOOR_Y + 4),
		Vector2(w.end.x + 40, 1080), Vector2(w.position.x - 40, 1080)])
	draw_polygon(refl, PackedColorArray([Color(0.45, 0.6, 0.8, 0.1), Color(0.45, 0.6, 0.8, 0.1), Color(0.45, 0.6, 0.8, 0.0), Color(0.45, 0.6, 0.8, 0.0)]))
	# Contact shadow along the skirting
	UIKit.vgrad(self, Rect2(0, L.FLOOR_Y, 1920, 26), Color(0, 0, 0, 0.5), Color(0, 0, 0, 0))


func _rug_pt(u: float, v: float) -> Vector2:
	# Rug occupies u in [0.2, 0.8] across, depth [0.08, 1.0]
	return L.floor_point(lerpf(0.21, 0.79, u), lerpf(0.09, 1.0, v))


func _rug_quad(u0: float, v0: float, u1: float, v1: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([_rug_pt(u0, v0), _rug_pt(u1, v0), _rug_pt(u1, v1), _rug_pt(u0, v1)]), col)


func _rug() -> void:
	var navy := Color(0.08, 0.1, 0.22)
	var crimson := Color(0.32, 0.05, 0.06)
	var madder := Color(0.4, 0.1, 0.07)
	var gold := Color(0.72, 0.55, 0.25)
	var ivory := Color(0.85, 0.78, 0.62)
	# Shadow
	draw_colored_polygon(PackedVector2Array([_rug_pt(0, 0) + Vector2(6, 4), _rug_pt(1, 0) + Vector2(6, 4), _rug_pt(1, 1) + Vector2(6, 4), _rug_pt(0, 1) + Vector2(6, 4)]), Color(0, 0, 0, 0.35))
	_rug_quad(0, 0, 1, 1, navy)
	_rug_quad(0.025, 0.035, 0.975, 0.965, gold.darkened(0.2))
	_rug_quad(0.035, 0.05, 0.965, 0.95, crimson.darkened(0.15))
	# Border lozenges
	for i in 30:
		var u := 0.05 + i * 0.03
		var c := _rug_pt(u, 0.085)
		var c2 := _rug_pt(u, 0.915)
		for cc in [c, c2]:
			var s: float = 5.0 * (1.0 + (cc.y - L.FLOOR_Y) / 300.0)
			draw_colored_polygon(PackedVector2Array([cc + Vector2(0, -s * 0.6), cc + Vector2(s, 0), cc + Vector2(0, s * 0.6), cc + Vector2(-s, 0)]), gold)
	_rug_quad(0.08, 0.13, 0.92, 0.87, ivory.darkened(0.35))
	_rug_quad(0.09, 0.145, 0.91, 0.855, madder)
	# Field motifs
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i in 70:
		var u := rng.randf_range(0.12, 0.88)
		var v := rng.randf_range(0.18, 0.82)
		var p := _rug_pt(u, v)
		var s := 4.0 * (1.0 + (p.y - L.FLOOR_Y) / 250.0)
		var col := [navy.lightened(0.15), gold, ivory.darkened(0.1), Color(0.15, 0.3, 0.25)][i % 4] as Color
		draw_colored_polygon(DecorArt.ellipse_pts(p, s, s * 0.55), Color(col, 0.75))
	# Central medallion
	var mc := _rug_pt(0.5, 0.5)
	var sc := 1.0 + (mc.y - L.FLOOR_Y) / 300.0
	var med := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		var rr := (110.0 if i % 2 == 0 else 80.0) * sc
		med.append(mc + Vector2(cos(a) * rr * 1.6, sin(a) * rr * 0.42))
	draw_colored_polygon(med, navy)
	var med2 := PackedVector2Array()
	for p in med:
		med2.append(mc + (p - mc) * 0.7)
	draw_colored_polygon(med2, gold.darkened(0.15))
	var med3 := PackedVector2Array()
	for p in med:
		med3.append(mc + (p - mc) * 0.45)
	draw_colored_polygon(med3, crimson)
	draw_colored_polygon(DecorArt.ellipse_pts(mc, 26 * sc, 9 * sc), ivory)
	# Corner spandrels
	for uv in [[0.09, 0.145], [0.91, 0.145], [0.09, 0.855], [0.91, 0.855]]:
		var p := _rug_pt(uv[0], uv[1])
		var du := 0.12 if uv[0] < 0.5 else -0.12
		var dv := 0.18 if uv[1] < 0.5 else -0.18
		draw_colored_polygon(PackedVector2Array([p, _rug_pt(uv[0] + du, uv[1]), _rug_pt(uv[0], uv[1] + dv)]), navy.lightened(0.05))
	# Fringe on the front edge
	for i in 80:
		var u := float(i) / 79.0
		var p := _rug_pt(u, 1.0)
		draw_line(p, p + Vector2(0, 14), Color(0.88, 0.82, 0.68, 0.85), 1.5)
	# Pile sheen: lighter toward the fire on the left
	draw_colored_polygon(PackedVector2Array([_rug_pt(0, 0), _rug_pt(0.45, 0), _rug_pt(0.3, 1), _rug_pt(0, 1)]), Color(1, 0.6, 0.3, 0.05))
