class_name RoomFireplace
extends Node2D
## The hearth: a mahogany surround with Art Nouveau tile slips, a cast-iron
## insert, a living fire, the mantel clock, wall sconces and the overmantel
## painting. The fire and candle flames are separate animated children.

const L = preload("res://scripts/art/room_layout.gd")

var sconce_flames: Array[Flame] = []
var fire_rect: ColorRect
var fire_glows: Array[LightGlow] = []
var _pendulum: Painter
var _t := 0.0


func _ready() -> void:
	add_child(Painter.new(_paint_static))
	# The fire itself (additive shader quad)
	fire_rect = ColorRect.new()
	fire_rect.position = Vector2(L.FIREBOX.position.x + 18, L.FIREBOX.position.y + 30)
	fire_rect.size = Vector2(L.FIREBOX.size.x - 36, L.FIREBOX.size.y - 66)
	fire_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/fire.gdshader")
	mat.set_shader_parameter("noise_tex", Tex.noise_tile(17, 0.025, 256, 2))
	fire_rect.material = mat
	fire_rect.z_index = 62
	fire_rect.z_as_relative = false
	add_child(fire_rect)
	# Rising embers
	var embers := CPUParticles2D.new()
	embers.position = Vector2(L.FIREBOX.get_center().x, L.FIREBOX.end.y - 50)
	embers.amount = 18
	embers.lifetime = 2.2
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(80, 6)
	embers.direction = Vector2(0, -1)
	embers.spread = 18.0
	embers.gravity = Vector2(0, -30)
	embers.initial_velocity_min = 30.0
	embers.initial_velocity_max = 70.0
	embers.scale_amount_min = 1.5
	embers.scale_amount_max = 3.0
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.75, 0.3, 1.0))
	grad.set_color(1, Color(1.0, 0.3, 0.05, 0.0))
	embers.color_ramp = grad
	embers.material = Tex.add_material()
	embers.z_index = 63
	embers.z_as_relative = false
	add_child(embers)
	# Firelight: a strong glow at the grate and a broad warm wash
	var fb := L.FIREBOX
	var g1 := LightGlow.new(Color(1.0, 0.5, 0.18), 0.85, 210.0, 1.0)
	g1.position = Vector2(fb.get_center().x, fb.end.y - 40)
	add_child(g1)
	var g2 := LightGlow.new(Color(1.0, 0.45, 0.15), 0.32, 620.0, 0.6)
	g2.position = Vector2(fb.get_center().x + 40, fb.end.y - 20)
	add_child(g2)
	var g3 := LightGlow.new(Color(1.0, 0.5, 0.2), 0.35, 300.0, 0.7)
	g3.position = Vector2(fb.get_center().x, L.FLOOR_Y + 70)
	g3.squash = 0.35
	add_child(g3)
	fire_glows = [g1, g2, g3]
	# Wall sconces: two candles each
	for s in L.SCONCES:
		for dx in [-30.0, 30.0]:
			var f := Flame.new()
			f.height = 12.0
			f.halo = 60.0
			f.position = s + Vector2(dx, -34)
			add_child(f)
			sconce_flames.append(f)
		var wash := LightGlow.new(Color(1.0, 0.72, 0.4), 0.3, 170.0, 0.3)
		wash.position = s + Vector2(0, -20)
		add_child(wash)
		fire_glows.append(wash)
	# Clock pendulum (animated)
	_pendulum = Painter.new(_paint_pendulum)
	add_child(_pendulum)


func set_sconces_lit(on: bool) -> void:
	for f in sconce_flames:
		f.lit = on
	for i in range(3, fire_glows.size()):
		fire_glows[i].dim = 1.0 if on else 0.0


func _process(delta: float) -> void:
	_t += delta
	_pendulum.queue_redraw()


func _paint_pendulum(ci: CanvasItem) -> void:
	var pivot := Vector2(L.CLOCK_X, 386)
	var a := sin(_t * PI) * 0.22
	var bob := pivot + Vector2(0, 22).rotated(a)
	ci.draw_line(pivot, bob, UIKit.GOLD.darkened(0.2), 1.5)
	ci.draw_circle(bob, 4.5, UIKit.GOLD)
	ci.draw_circle(bob + Vector2(-1.5, -1.5), 1.5, UIKit.GOLD_LIGHT)


func _paint_static(ci: CanvasItem) -> void:
	_overmantel(ci)
	_sconces(ci)
	_surround(ci)
	_insert(ci)
	_hearth(ci)
	_clock(ci)


func _overmantel(ci: CanvasItem) -> void:
	var r := L.OVERMANTEL
	# Gilt frame
	ci.draw_rect(Rect2(r.position + Vector2(6, 8), r.size), Color(0, 0, 0, 0.45))
	UIKit.vgrad(ci, r, UIKit.GOLD.lightened(0.1), UIKit.GOLD_DARK)
	var inner := r.grow(-20)
	ci.draw_rect(r.grow(-6), UIKit.GOLD_DARK.darkened(0.3), false, 2.0)
	ci.draw_rect(r.grow(-14), UIKit.GOLD_LIGHT, false, 2.0)
	for i in 16:
		var t := float(i) / 16.0
		ci.draw_circle(Vector2(r.position.x + 10 + t * (r.size.x - 20), r.position.y + 10), 2.0, UIKit.GOLD_LIGHT)
	# The painting: dusk over the Mourne Mountains and a still lough
	UIKit.vgrad(ci, Rect2(inner.position, Vector2(inner.size.x, inner.size.y * 0.55)), Color(0.32, 0.36, 0.5), Color(0.86, 0.6, 0.42))
	var hy := inner.position.y + inner.size.y * 0.55
	var mtn := PackedVector2Array([Vector2(inner.position.x, hy)])
	var peaks := [0.0, 0.2, 0.35, 0.45, 0.62, 0.74, 0.9, 1.0]
	var hs := [10.0, 52.0, 30.0, 70.0, 38.0, 58.0, 22.0, 12.0]
	for i in peaks.size():
		mtn.append(Vector2(inner.position.x + peaks[i] * inner.size.x, hy - hs[i]))
	mtn.append(Vector2(inner.end.x, hy))
	ci.draw_colored_polygon(mtn, Color(0.25, 0.24, 0.35))
	UIKit.vgrad(ci, Rect2(inner.position.x, hy, inner.size.x, inner.size.y * 0.2), Color(0.7, 0.55, 0.45), Color(0.3, 0.32, 0.42))
	UIKit.vgrad(ci, Rect2(inner.position.x, hy + inner.size.y * 0.2, inner.size.x, inner.size.y * 0.25), Color(0.18, 0.2, 0.14), Color(0.1, 0.1, 0.07))
	ci.draw_line(Vector2(inner.position.x + 20, hy + 8), Vector2(inner.end.x - 50, hy + 12), Color(1, 0.85, 0.6, 0.35), 2.0)
	# A stag on the near bank
	var sg := Vector2(inner.position.x + inner.size.x * 0.7, inner.end.y - 26)
	ci.draw_colored_polygon(DecorArt.ellipse_pts(sg, 13, 6), Color(0.14, 0.09, 0.06))
	for lx in [-9.0, -5.0, 6.0, 10.0]:
		ci.draw_line(sg + Vector2(lx, 3), sg + Vector2(lx, 15), Color(0.14, 0.09, 0.06), 2.0)
	ci.draw_line(sg + Vector2(10, -3), sg + Vector2(15, -13), Color(0.14, 0.09, 0.06), 4.0)
	ci.draw_circle(sg + Vector2(17, -14), 3.5, Color(0.14, 0.09, 0.06))
	ci.draw_line(sg + Vector2(16, -17), sg + Vector2(12, -28), Color(0.14, 0.09, 0.06), 1.2)
	ci.draw_line(sg + Vector2(18, -17), sg + Vector2(23, -28), Color(0.14, 0.09, 0.06), 1.2)
	ci.draw_rect(inner, Color(0, 0, 0, 0.5), false, 2.0)
	# Varnish sheen
	ci.draw_colored_polygon(PackedVector2Array([inner.position, inner.position + Vector2(inner.size.x * 0.35, 0), inner.position + Vector2(0, inner.size.y * 0.5)]), Color(1, 0.95, 0.8, 0.06))
	# Brass picture-rail chains
	ci.draw_line(Vector2(r.position.x + 30, L.PICTURE_RAIL_Y), Vector2(r.get_center().x, r.position.y - 2), Color(0.7, 0.6, 0.35, 0.8), 1.5)
	ci.draw_line(Vector2(r.end.x - 30, L.PICTURE_RAIL_Y), Vector2(r.get_center().x, r.position.y - 2), Color(0.7, 0.6, 0.35, 0.8), 1.5)


func _sconces(ci: CanvasItem) -> void:
	for s in L.SCONCES:
		var c: Vector2 = s
		ci.draw_colored_polygon(DecorArt.ellipse_pts(c + Vector2(3, 4), 15, 30), Color(0, 0, 0, 0.35))
		ci.draw_colored_polygon(DecorArt.ellipse_pts(c, 14, 28), UIKit.GOLD_DARK)
		ci.draw_colored_polygon(DecorArt.ellipse_pts(c + Vector2(-2, -3), 10, 22), UIKit.GOLD)
		ci.draw_circle(c + Vector2(-4, -10), 3, UIKit.GOLD_LIGHT)
		for dx in [-30.0, 30.0]:
			var arm := PackedVector2Array()
			for i in 9:
				var t := float(i) / 8.0
				arm.append(c + Vector2(dx * t, 10 - sin(t * PI) * 10 + t * 2))
			ci.draw_polyline(arm, UIKit.GOLD.darkened(0.1), 4.0, true)
			var cup := c + Vector2(dx, 12)
			ci.draw_colored_polygon(DecorArt.ellipse_pts(cup, 10, 4), UIKit.GOLD)
			UIKit.hgrad(ci, Rect2(cup + Vector2(-4.5, -34), Vector2(9, 32)), Color(0.99, 0.96, 0.88), Color(0.78, 0.72, 0.6))
			ci.draw_line(cup + Vector2(0, -34), cup + Vector2(0, -37), Color(0.1, 0.06, 0.04), 1.4)


func _surround(ci: CanvasItem) -> void:
	var mah := Color(0.24, 0.1, 0.05)
	var mah_dk := Color(0.1, 0.04, 0.02)
	var x0 := L.MANTEL_X0
	var x1 := L.MANTEL_X1
	var top := L.MANTEL_Y
	# Pillars
	for px in [104.0, 506.0]:
		var pr := Rect2(px, top + 70, 70, L.FLOOR_Y - top - 70)
		UIKit.hgrad(ci, pr, mah.lightened(0.12), mah_dk)
		ci.draw_texture_rect(Tex.wood(), pr, true, Color(1, 1, 1, 0.25))
		for k in 4:
			var fx: float = px + 14 + k * 14.0
			ci.draw_line(Vector2(fx, pr.position.y + 26), Vector2(fx, pr.end.y - 46), Color(0, 0, 0, 0.45), 3.0)
			ci.draw_line(Vector2(fx + 3, pr.position.y + 26), Vector2(fx + 3, pr.end.y - 46), Color(1, 0.75, 0.5, 0.1), 1.5)
		# Plinth and capital
		UIKit.vgrad(ci, Rect2(px - 6, L.FLOOR_Y - 40, 82, 40), mah.lightened(0.1), mah_dk)
		UIKit.vgrad(ci, Rect2(px - 6, pr.position.y, 82, 18), mah.lightened(0.2), mah_dk)
	# Frieze beneath the shelf with a carved swag
	var fr := Rect2(x0 + 16, top + 22, x1 - x0 - 32, 52)
	UIKit.vgrad(ci, fr, mah.lightened(0.08), mah_dk)
	ci.draw_texture_rect(Tex.wood(), fr, true, Color(1, 1, 1, 0.25))
	for sw in 3:
		var a := Vector2(fr.position.x + 120 + sw * 92.0, fr.position.y + 14)
		var b := a + Vector2(92, 0)
		var pts := PackedVector2Array()
		for i in 13:
			var t := float(i) / 12.0
			pts.append(a.lerp(b, t) + Vector2(0, sin(t * PI) * 18))
		ci.draw_polyline(pts, Color(0, 0, 0, 0.5), 5.0, true)
		ci.draw_polyline(pts, Color(1, 0.7, 0.45, 0.14), 2.0, true)
	# Corbels
	for cx in [104.0, 506.0]:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(cx - 4, top + 22), Vector2(cx + 74, top + 22), Vector2(cx + 60, top + 74), Vector2(cx + 10, top + 74)]), mah.lightened(0.05))
		ci.draw_circle(Vector2(cx + 35, top + 46), 9, mah_dk)
		ci.draw_arc(Vector2(cx + 35, top + 46), 9, PI, TAU, 10, Color(1, 0.7, 0.45, 0.2), 2.0)
	# Shelf: layered mouldings with a polished edge
	ci.draw_rect(Rect2(x0 + 4, top + 26, x1 - x0 - 8, 8), Color(0, 0, 0, 0.5))
	UIKit.vgrad(ci, Rect2(x0, top, x1 - x0, 24), mah.lightened(0.3), mah_dk)
	ci.draw_texture_rect(Tex.wood(), Rect2(x0, top, x1 - x0, 24), true, Color(1, 1, 1, 0.3))
	ci.draw_line(Vector2(x0, top), Vector2(x1, top), Color(1, 0.85, 0.6, 0.45), 2.0)
	UIKit.vgrad(ci, Rect2(x0 + 8, top + 24, x1 - x0 - 16, 8), mah.lightened(0.15), mah_dk)


func _insert(ci: CanvasItem) -> void:
	var top := L.MANTEL_Y + 74
	var inner := Rect2(174, top, 332, L.FLOOR_Y - top)
	ci.draw_rect(inner, Color(0.06, 0.05, 0.05))
	# Art Nouveau tile slips: tulips on green
	for side in 2:
		var x := 174.0 if side == 0 else 466.0
		var n := 6
		var th := (L.FLOOR_Y - top - 8) / n
		for k in n:
			var tr := Rect2(x + 2, top + 4 + k * th, 36, th - 2)
			UIKit.vgrad(ci, tr, Color(0.2, 0.36, 0.3), Color(0.1, 0.22, 0.18))
			var c := tr.get_center()
			ci.draw_line(c + Vector2(0, 12), c + Vector2(0, -4), Color(0.35, 0.55, 0.35), 2.0)
			ci.draw_colored_polygon(DecorArt.ellipse_pts(c + Vector2(0, -8), 6, 8), Color(0.62, 0.15, 0.18))
			ci.draw_colored_polygon(DecorArt.ellipse_pts(c + Vector2(-6, 8), 3, 7, 12, 0.6), Color(0.3, 0.5, 0.3))
			ci.draw_colored_polygon(DecorArt.ellipse_pts(c + Vector2(6, 8), 3, 7, 12, -0.6), Color(0.3, 0.5, 0.3))
			ci.draw_rect(tr, Color(1, 1, 1, 0.08), false, 1.0)
			ci.draw_line(tr.position + Vector2(3, 3), tr.position + Vector2(12, 3), Color(1, 1, 1, 0.25), 1.5)
	# Cast-iron arch around the firebox
	var fb := L.FIREBOX
	var arch_top := fb.position.y - 30
	var outer := PackedVector2Array()
	outer.append(Vector2(fb.position.x - 8, L.FLOOR_Y))
	for i in 17:
		var a := PI + PI * i / 16.0
		outer.append(Vector2(fb.get_center().x + cos(a) * (fb.size.x * 0.5 + 8), fb.position.y + 20 + sin(a) * 42))
	outer.append(Vector2(fb.end.x + 8, L.FLOOR_Y))
	ci.draw_colored_polygon(outer, Color(0.12, 0.11, 0.11))
	var hole := PackedVector2Array()
	hole.append(Vector2(fb.position.x + 8, L.FLOOR_Y))
	for i in 17:
		var a := PI + PI * i / 16.0
		hole.append(Vector2(fb.get_center().x + cos(a) * (fb.size.x * 0.5 - 8), fb.position.y + 24 + sin(a) * 32))
	hole.append(Vector2(fb.end.x - 8, L.FLOOR_Y))
	ci.draw_colored_polygon(hole, Color(0.03, 0.02, 0.02))
	ci.draw_polyline(outer, Color(0.4, 0.38, 0.36, 0.45), 2.0, true)
	ci.draw_circle(Vector2(fb.get_center().x, arch_top + 10), 8, Color(0.2, 0.19, 0.18))
	# Fireback glow and grate basket
	ci.draw_texture_rect(Tex.glow(), Rect2(fb.position + Vector2(10, 40), fb.size - Vector2(20, 40)), false, Color(0.7, 0.25, 0.05, 0.6))
	var gy := fb.end.y - 48
	for k in 5:
		ci.draw_line(Vector2(fb.position.x + 28, gy + k * 8), Vector2(fb.end.x - 28, gy + k * 8), Color(0.1, 0.09, 0.09), 4.0)
	for k in 9:
		var x := fb.position.x + 30 + k * (fb.size.x - 60) / 8.0
		ci.draw_line(Vector2(x, gy - 4), Vector2(x, gy + 36), Color(0.12, 0.1, 0.1), 3.0)
	# Glowing coals
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for i in 26:
		var p := Vector2(rng.randf_range(fb.position.x + 34, fb.end.x - 34), gy - rng.randf_range(-2, 18))
		var r := rng.randf_range(6, 12)
		var pts := DecorArt.ellipse_pts(p, r, r * 0.7, 7, rng.randf() * TAU)
		ci.draw_colored_polygon(pts, Color(0.09, 0.05, 0.04))
		ci.draw_colored_polygon(DecorArt.ellipse_pts(p + Vector2(0, 2), r * 0.6, r * 0.3, 7), Color(1.0, 0.35 + rng.randf() * 0.25, 0.05, 0.85))
	# Ash pan front
	UIKit.vgrad(ci, Rect2(fb.position.x + 20, fb.end.y - 14, fb.size.x - 40, 14), Color(0.18, 0.17, 0.16), Color(0.05, 0.05, 0.05))


func _hearth(ci: CanvasItem) -> void:
	var y0 := L.FLOOR_Y
	var slab := PackedVector2Array([Vector2(70, y0), Vector2(610, y0), Vector2(636, y0 + 38), Vector2(44, y0 + 38)])
	ci.draw_colored_polygon(slab, Color(0.1, 0.16, 0.13))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 14:
		var a := Vector2(rng.randf_range(70, 600), y0 + rng.randf_range(4, 34))
		ci.draw_line(a, a + Vector2(rng.randf_range(20, 60), rng.randf_range(-4, 4)), Color(0.6, 0.7, 0.62, 0.2), 1.2, true)
	ci.draw_line(Vector2(44, y0 + 38), Vector2(636, y0 + 38), Color(0, 0, 0, 0.6), 3.0)
	# Brass fender
	var fender := PackedVector2Array([Vector2(86, y0 + 4), Vector2(86, y0 + 26), Vector2(594, y0 + 26), Vector2(594, y0 + 4)])
	ci.draw_polyline(fender, UIKit.GOLD.darkened(0.2), 6.0, true)
	ci.draw_polyline(fender, UIKit.GOLD_LIGHT, 1.5, true)
	for x in [86.0, 594.0]:
		DecorArt.sphere(ci, Vector2(x, y0 + 2), 6, UIKit.GOLD, 0.8)
	# Fire irons on a stand
	var st := Vector2(624, y0 + 30)
	ci.draw_line(st, st + Vector2(0, -150), Color(0.25, 0.2, 0.15), 4.0)
	for k in 3:
		var tip := st + Vector2(-10 + k * 10, -130)
		ci.draw_line(tip, tip + Vector2((k - 1) * 4.0, 110), Color(0.3, 0.27, 0.24), 3.0)
		DecorArt.sphere(ci, tip + Vector2(0, -6), 5, UIKit.GOLD, 0.6)
	ci.draw_colored_polygon(DecorArt.ellipse_pts(st, 22, 6), Color(0.2, 0.17, 0.14))
	# Coal scuttle
	var cs := Vector2(48, y0 + 6)
	ci.draw_colored_polygon(PackedVector2Array([cs + Vector2(-26, 0), cs + Vector2(26, 0), cs + Vector2(32, -46), cs + Vector2(-18, -60)]), Color(0.2, 0.12, 0.08))
	ci.draw_line(cs + Vector2(-18, -60), cs + Vector2(32, -46), UIKit.GOLD.darkened(0.2), 4.0)
	ci.draw_arc(cs + Vector2(6, -60), 18, PI * 1.1, PI * 1.9, 10, UIKit.GOLD.darkened(0.1), 3.0, true)


func _clock(ci: CanvasItem) -> void:
	var cx := L.CLOCK_X
	var base := L.MANTEL_Y
	var body := Rect2(cx - 38, base - 92, 76, 92)
	ci.draw_rect(Rect2(body.position + Vector2(5, 4), body.size), Color(0, 0, 0, 0.4))
	UIKit.hgrad(ci, body, Color(0.32, 0.14, 0.07), Color(0.12, 0.05, 0.02))
	ci.draw_texture_rect(Tex.wood(), body, true, Color(1, 1, 1, 0.3))
	var dome := PackedVector2Array([Vector2(cx - 38, base - 92)])
	for i in 13:
		var a := PI + PI * i / 12.0
		dome.append(Vector2(cx + cos(a) * 38, base - 92 + sin(a) * 26))
	ci.draw_colored_polygon(dome, Color(0.26, 0.11, 0.05))
	DecorArt.sphere(ci, Vector2(cx, base - 122), 6, UIKit.GOLD, 0.8)
	UIKit.vgrad(ci, Rect2(cx - 44, base - 10, 88, 10), Color(0.3, 0.14, 0.07), Color(0.1, 0.04, 0.02))
	# Dial
	var dc := Vector2(cx, base - 62)
	ci.draw_circle(dc, 26, UIKit.GOLD_DARK)
	ci.draw_circle(dc, 23, UIKit.GOLD)
	ci.draw_circle(dc, 19, Color(0.95, 0.92, 0.82))
	for i in 12:
		var a := TAU * i / 12.0
		ci.draw_line(dc + Vector2(cos(a), sin(a)) * 15, dc + Vector2(cos(a), sin(a)) * 18, Color(0.15, 0.1, 0.08), 1.5)
	# Ten to midnight on Christmas Eve
	ci.draw_line(dc, dc + Vector2(0, -12), Color(0.1, 0.06, 0.04), 2.0)
	ci.draw_line(dc, dc + Vector2(-14, -8), Color(0.1, 0.06, 0.04), 1.5)
	ci.draw_circle(dc, 2, UIKit.GOLD_DARK)
	# Pendulum window
	ci.draw_rect(Rect2(cx - 14, base - 34, 28, 22), Color(0.05, 0.03, 0.02))
	ci.draw_rect(Rect2(cx - 14, base - 34, 28, 22), UIKit.GOLD_DARK, false, 1.5)
