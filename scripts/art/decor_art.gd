class_name DecorArt
extends RefCounted
## DecorArt — paints every decoration from primitives.
##
## Convention: each routine draws relative to the item's anchor at (0, 0):
##   hang   -> anchor is the hook; the ornament hangs below (+y)
##   clip   -> anchor is the clip; the item stands above (-y)
##   topper -> anchor is the apex of the tree; the topper rises above
##   room   -> anchor is the base/bottom-centre (floor, surface), hook (hooks),
##             nail (wall) or the ball centre (ceiling)
## `rng_seed` gives each placed instance small, stable variations.

const THREAD := Color(0.92, 0.86, 0.62, 0.85)


static func draw_item(ci: CanvasItem, d: Dictionary, rng_seed: int = 0, extra: Dictionary = {}) -> void:
	var col: Color = d.get("color", Color.WHITE)
	match d.get("draw", ""):
		"candle": _candle(ci, col, extra.get("preview", false))
		"bauble": _bauble(ci, col, rng_seed)
		"teardrop": _teardrop(ci, col)
		"icicle": _icicle(ci, col)
		"bird": _bird(ci, col, rng_seed)
		"pinecone": _pinecone(ci, col)
		"grapes": _grapes(ci, col)
		"dresden_star": _dresden_star(ci, col)
		"cornucopia": _cornucopia(ci, col)
		"scrap_angel": _scrap_angel(ci)
		"fan": _fan(ci, col)
		"candy_cane": _candy_cane(ci, col)
		"gingerbread": _gingerbread(ci, col)
		"apple": _apple(ci, col)
		"walnut": _walnut(ci, col)
		"pomander": _pomander(ci, col)
		"sugar_mouse": _sugar_mouse(ci, col)
		"angel": _angel_topper(ci)
		"star": _star_topper(ci, col)
		"spire": _spire_topper(ci, col)
		"rosette": _rosette_topper(ci, col)
		"mantel_garland": _mantel_garland(ci, rng_seed)
		"stocking": _stocking(ci, col, rng_seed)
		"present": _present(ci, d, rng_seed)
		"present_tartan": _present_tartan(ci, d)
		"candlestick": _candlestick(ci, col, extra.get("preview", false))
		"holly": _holly(ci, rng_seed)
		"wreath": _wreath(ci, rng_seed)
		"mistletoe": _mistletoe(ci, extra.get("ceiling_dy", 300.0), rng_seed)
		"teddy": _teddy(ci, col)
		"rocking_horse": _rocking_horse(ci)
		"soldier": _soldier(ci, col)
		"ark": _ark(ci, col)
		"drum": _drum(ci, col)
		"cards": _cards(ci, rng_seed)
		_:
			# Garlands are drawn by Garland; in previews show a short swag.
			if d.get("kind", "") == "garland":
				var pts := PackedVector2Array()
				for i in 25:
					var t := float(i) / 24.0
					pts.append(Vector2(-22 + t * 44, -8 + sin(t * PI) * 18))
				draw_garland(ci, d, pts, 0.0, rng_seed, true)
			else:
				ci.draw_circle(Vector2(0, 16), 14, col)


static func draw_preview(ci: CanvasItem, d: Dictionary, slot: Rect2) -> void:
	## Draws an item fitted into a trunk slot.
	var r: Rect2 = d.get("rect", Rect2(-20, -20, 40, 40))
	var fit := minf(slot.size.x / r.size.x, slot.size.y / r.size.y) * 0.8
	fit = minf(fit, 1.6)
	var center := slot.get_center() - (r.position + r.size * 0.5) * fit
	ci.draw_set_transform(center, 0.0, Vector2(fit, fit))
	draw_item(ci, d, 1, {"preview": true, "ceiling_dy": 40.0})
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# =============================================================== primitives

static func ellipse_pts(c: Vector2, rx: float, ry: float, n: int = 24, rot: float = 0.0) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		p.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return p


static func _ell(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, rot: float = 0.0) -> void:
	ci.draw_colored_polygon(ellipse_pts(c, rx, ry, 24, rot), col)


static func sphere(ci: CanvasItem, c: Vector2, r: float, col: Color, spec: float = 0.9) -> void:
	var rect := Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0)
	ci.draw_texture_rect(Tex.sphere_body(), rect, false, col.lightened(0.12))
	if spec > 0.0:
		ci.draw_texture_rect(Tex.sphere_spec(), rect, false, Color(1, 1, 1, spec))


static func _thread(ci: CanvasItem, to_y: float) -> void:
	ci.draw_line(Vector2.ZERO, Vector2(0, to_y), THREAD, 1.2, true)
	ci.draw_arc(Vector2(0, 2), 2.5, PI, TAU, 6, Color(0.75, 0.7, 0.5), 1.0, true)


static func _cap(ci: CanvasItem, top: Vector2, w: float) -> void:
	var r := Rect2(top + Vector2(-w * 0.5, 0), Vector2(w, w * 0.55))
	UIKit.hgrad(ci, r, Color(0.95, 0.82, 0.5), Color(0.45, 0.32, 0.12))
	ci.draw_line(r.position + Vector2(0, r.size.y), r.end, Color(0.3, 0.2, 0.08), 1.0)
	ci.draw_arc(top + Vector2(0, -1), w * 0.22, PI, TAU, 8, Color(0.85, 0.75, 0.45), 1.2, true)


static func _star_pts(c: Vector2, ro: float, ri: float, n: int, rot: float = -PI * 0.5) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n * 2:
		var a := rot + i * PI / n
		p.append(c + Vector2(cos(a), sin(a)) * (ro if i % 2 == 0 else ri))
	return p


static func _faceted_star(ci: CanvasItem, c: Vector2, ro: float, ri: float, n: int, col: Color, rot: float = -PI * 0.5) -> void:
	## Each point split into a lit and a shaded facet: reads as embossed metal.
	var pts := _star_pts(c, ro, ri, n, rot)
	for i in n:
		var tip := pts[i * 2]
		var left := pts[(i * 2 - 1 + n * 2) % (n * 2)]
		var right := pts[i * 2 + 1]
		var lit := col.lightened(0.35)
		var shade := col.darkened(0.35)
		ci.draw_colored_polygon(PackedVector2Array([c, left, tip]), lit if (i % 2 == 0) else col)
		ci.draw_colored_polygon(PackedVector2Array([c, tip, right]), shade if (i % 2 == 0) else col.darkened(0.15))
	var outline := pts.duplicate()
	outline.append(pts[0])
	ci.draw_polyline(outline, col.darkened(0.55), 1.0, true)


static func _leaf(ci: CanvasItem, base: Vector2, dir: float, length: float, width: float, col: Color, spiky: bool = false) -> void:
	var pts := PackedVector2Array()
	var n := 10
	for i in n + 1:
		var t := float(i) / n
		var wv := sin(t * PI) * width
		if spiky:
			wv *= 1.0 + 0.35 * (1.0 if i % 2 == 0 else -0.4)
		pts.append(base + Vector2(t * length, -wv).rotated(dir))
	for i in range(n - 1, 0, -1):
		var t := float(i) / n
		var wv := sin(t * PI) * width
		if spiky:
			wv *= 1.0 + 0.35 * (1.0 if i % 2 == 0 else -0.4)
		pts.append(base + Vector2(t * length, wv).rotated(dir))
	ci.draw_colored_polygon(pts, col)
	ci.draw_line(base, base + Vector2(length * 0.9, 0).rotated(dir), col.lightened(0.25), 1.0, true)


static func _berry(ci: CanvasItem, c: Vector2, r: float, col: Color = Color(0.75, 0.05, 0.08)) -> void:
	ci.draw_circle(c, r, col.darkened(0.3))
	ci.draw_circle(c + Vector2(-r * 0.15, -r * 0.15), r * 0.8, col)
	ci.draw_circle(c + Vector2(-r * 0.35, -r * 0.35), r * 0.28, Color(1, 0.9, 0.85, 0.85))


static func _bow(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	var dk := col.darkened(0.35)
	ci.draw_colored_polygon(PackedVector2Array([c, c + Vector2(-s, -s * 0.55), c + Vector2(-s * 1.05, s * 0.35)]), col)
	ci.draw_colored_polygon(PackedVector2Array([c, c + Vector2(s, -s * 0.55), c + Vector2(s * 1.05, s * 0.35)]), col.lightened(0.1))
	ci.draw_colored_polygon(PackedVector2Array([c, c + Vector2(-s * 0.3, s * 1.2), c + Vector2(-s * 0.65, s * 1.05)]), dk)
	ci.draw_colored_polygon(PackedVector2Array([c, c + Vector2(s * 0.35, s * 1.2), c + Vector2(s * 0.7, s * 1.0)]), dk)
	ci.draw_circle(c, s * 0.25, col.lightened(0.15))


# ================================================================ candles

static func _candle(ci: CanvasItem, col: Color, preview: bool) -> void:
	# Tin clip
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-8, 0), Vector2(8, 0), Vector2(6, 6), Vector2(-6, 6)]), Color(0.55, 0.55, 0.5))
	ci.draw_line(Vector2(-6, 6), Vector2(-9, 9), Color(0.4, 0.4, 0.38), 2.0)
	ci.draw_line(Vector2(6, 6), Vector2(9, 9), Color(0.4, 0.4, 0.38), 2.0)
	_ell(ci, Vector2(0, -1), 9, 3, Color(0.7, 0.68, 0.6))
	# Taper
	var body := Rect2(-4.5, -32, 9, 31)
	UIKit.hgrad(ci, body, col.lightened(0.25), col.darkened(0.3))
	_ell(ci, Vector2(0, -32), 4.5, 1.6, col.lightened(0.35))
	# A wax drip
	ci.draw_line(Vector2(3, -31), Vector2(3, -24), col.lightened(0.15), 2.0, true)
	ci.draw_line(Vector2(0, -33), Vector2(0.5, -37), Color(0.12, 0.08, 0.05), 1.4)
	if preview:
		_flame_shape(ci, Vector2(0.5, -38), 12.0)


static func _flame_shape(ci: CanvasItem, base: Vector2, h: float) -> void:
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		var y := -cos(a)
		var widen := 0.55 + 0.45 * (1.0 - (y * 0.5 + 0.5))
		outer.append(base + Vector2(sin(a) * h * 0.24 * widen, -h * 0.5 + y * h * 0.5))
		inner.append(base + Vector2(sin(a) * h * 0.12 * widen, -h * 0.35 + y * h * 0.3))
	ci.draw_colored_polygon(outer, Color(1.0, 0.62, 0.18, 0.95))
	ci.draw_colored_polygon(inner, Color(1.0, 0.95, 0.75))


# ============================================================ blown glass

static func _bauble(ci: CanvasItem, col: Color, s: int) -> void:
	_thread(ci, 7)
	_cap(ci, Vector2(0, 6), 9)
	var c := Vector2(0, 27)
	sphere(ci, c, 16, col)
	match s % 3:
		0:
			# A frosted mica band around the equator
			ci.draw_arc(c + Vector2(0, -26), 30, PI * 0.36, PI * 0.64, 16, Color(1, 0.95, 0.85, 0.55), 2.0, true)
			ci.draw_arc(c + Vector2(0, -22), 30, PI * 0.38, PI * 0.62, 16, Color(UIKit.GOLD_LIGHT, 0.45), 1.2, true)
		1:
			for i in 5:
				var a := -0.9 + i * 0.45
				ci.draw_circle(c + Vector2(sin(a) * 10.0, 3 + cos(a * 2.0) * 2.0), 1.3, Color(1, 1, 1, 0.65))
		_:
			pass


static func _teardrop(ci: CanvasItem, col: Color) -> void:
	_thread(ci, 7)
	_cap(ci, Vector2(0, 6), 8)
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in 24:
		var a := TAU * i / 24.0
		var y := -cos(a)  # -1 top .. 1 bottom
		var t := y * 0.5 + 0.5
		var wv := sin(t * PI) * (0.35 + 0.65 * t) * 11.5
		var p := Vector2(sin(a) * wv, 12 + t * 44)
		pts.append(p)
		cols.append(col.lightened(0.3) if p.x < -2 else col.darkened(0.3))
	ci.draw_polygon(pts, cols)
	sphere(ci, Vector2(0, 40), 10, col, 0.0)
	ci.draw_line(Vector2(-4, 18), Vector2(-6, 40), Color(1, 1, 1, 0.65), 2.0, true)
	ci.draw_circle(Vector2(-4, 36), 2.5, Color(1, 1, 1, 0.8))


static func _icicle(ci: CanvasItem, col: Color) -> void:
	_thread(ci, 5)
	var pts := PackedVector2Array([Vector2(-6, 5), Vector2(6, 5), Vector2(0.5, 70)])
	ci.draw_colored_polygon(pts, Color(col, 0.55))
	for i in 7:
		var y := 8 + i * 8.5
		var hw := 6.0 * (1.0 - (y - 5) / 65.0)
		ci.draw_line(Vector2(-hw, y), Vector2(hw, y + 5), Color(1, 1, 1, 0.55), 1.2, true)
	ci.draw_line(Vector2(-3, 7), Vector2(0, 60), Color(1, 1, 1, 0.9), 1.0, true)


static func _bird(ci: CanvasItem, col: Color, s: int) -> void:
	var fl := -1.0 if s % 2 == 0 else 1.0
	# Clip
	ci.draw_line(Vector2(-4, 6), Vector2(4, -4), Color(0.45, 0.45, 0.4), 2.0)
	ci.draw_line(Vector2(4, 6), Vector2(-4, -4), Color(0.45, 0.45, 0.4), 2.0)
	# Spun-glass tail: many fine filaments fanning back
	for i in 16:
		var a := deg_to_rad(-20 + i * 5.0)
		var tip := Vector2(-30 * fl, -14) + Vector2(cos(a) * -12 * fl, sin(a) * 16)
		ci.draw_line(Vector2(-8 * fl, -14), tip, Color(1, 1, 1, 0.55), 1.0, true)
	# Body
	var body := ellipse_pts(Vector2(0, -15), 13, 8, 24, 0.12 * fl)
	ci.draw_colored_polygon(body, col)
	sphere(ci, Vector2(1 * fl, -16), 8, col.lightened(0.1), 0.8)
	ci.draw_circle(Vector2(12 * fl, -21), 6, col.lightened(0.05))
	ci.draw_circle(Vector2(13 * fl, -23), 2.2, Color(1, 1, 1, 0.7))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(17 * fl, -22), Vector2(23 * fl, -20), Vector2(17 * fl, -19)]), Color(0.85, 0.6, 0.2))
	ci.draw_circle(Vector2(14 * fl, -22), 1.2, Color(0.1, 0.05, 0.03))
	# Wing
	_leaf(ci, Vector2(-2 * fl, -16), PI if fl > 0 else 0.0, 12, 4, col.darkened(0.2))


static func _pinecone(ci: CanvasItem, col: Color) -> void:
	_thread(ci, 7)
	_cap(ci, Vector2(0, 6), 8)
	_ell(ci, Vector2(0, 30), 11, 19, col.darkened(0.3))
	for row in 7:
		var y := 15 + row * 4.6
		var hw := sin((row + 0.5) / 7.0 * PI) * 10.0
		var n := 3 + (row % 2)
		for k in n:
			var x := -hw + (k + 0.5) * (hw * 2.0 / n)
			var c := col.lerp(UIKit.GOLD, 0.25 + 0.15 * (row % 2))
			ci.draw_arc(Vector2(x, y), 3.6, 0.1, PI - 0.1, 8, c.lightened(0.2), 2.2, true)
	ci.draw_circle(Vector2(-4, 22), 2.0, Color(1, 0.95, 0.8, 0.7))


static func _grapes(ci: CanvasItem, col: Color) -> void:
	_thread(ci, 6)
	_cap(ci, Vector2(0, 5), 7)
	_leaf(ci, Vector2(0, 11), -0.4, 16, 6, Color(0.25, 0.45, 0.2))
	var rows := [[-9, 0, 9], [-6, 6], [-9, 0, 9], [-5, 5], [0]]
	for ri in rows.size():
		for x in rows[ri]:
			sphere(ci, Vector2(x, 18 + ri * 8.5), 6.2, col, 0.8)


# ======================================================= paper, fruit, sweets

static func _dresden_star(ci: CanvasItem, col: Color) -> void:
	_thread(ci, 6)
	_faceted_star(ci, Vector2(0, 26), 21, 9, 8, col)
	_faceted_star(ci, Vector2(0, 26), 11, 5, 8, col.lightened(0.15), -PI * 0.5 + PI / 8.0)
	ci.draw_circle(Vector2(0, 26), 3.5, Color(0.75, 0.1, 0.12))
	ci.draw_circle(Vector2(-1, 25), 1.2, Color(1, 0.8, 0.8))


static func _cornucopia(ci: CanvasItem, col: Color) -> void:
	# Ribbon handle
	ci.draw_arc(Vector2(0, 14), 14, PI * 1.08, PI * 1.92, 12, Color(0.8, 0.15, 0.2), 2.0, true)
	var cone := PackedVector2Array([Vector2(-15, 14), Vector2(15, 14), Vector2(1, 58)])
	ci.draw_polygon(cone, PackedColorArray([col.lightened(0.25), col.darkened(0.25), col.darkened(0.4)]))
	for i in 4:
		var y := 22 + i * 8.0
		var hw := 15.0 * (1.0 - (y - 14) / 44.0)
		ci.draw_line(Vector2(-hw, y), Vector2(hw, y + 3), Color(UIKit.GOLD_LIGHT, 0.7), 1.2, true)
	# Lace edge and sweets
	for i in 9:
		ci.draw_circle(Vector2(-15 + i * 3.75, 14), 2.2, Color(0.98, 0.95, 0.85))
	var sweets := [Color(0.95, 0.9, 0.6), Color(0.6, 0.85, 0.6), Color(0.95, 0.6, 0.7), Color(0.98, 0.98, 0.95)]
	for i in 5:
		ci.draw_circle(Vector2(-9 + i * 4.5, 10 - (i % 2) * 2.5), 3.4, sweets[i % sweets.size()])


static func _scrap_angel(ci: CanvasItem) -> void:
	_thread(ci, 8)
	# Wings
	var wing := Color(0.97, 0.9, 0.92)
	_leaf(ci, Vector2(-2, 22), PI + 0.5, 20, 8, wing)
	_leaf(ci, Vector2(2, 22), -0.5, 20, 8, wing)
	ci.draw_arc(Vector2(-12, 16), 10, PI * 0.9, PI * 1.6, 8, Color(UIKit.GOLD, 0.8), 1.2, true)
	ci.draw_arc(Vector2(12, 16), 10, PI * 1.4, PI * 2.1, 8, Color(UIKit.GOLD, 0.8), 1.2, true)
	# Gown
	ci.draw_polygon(PackedVector2Array([Vector2(-5, 20), Vector2(5, 20), Vector2(11, 56), Vector2(-11, 56)]),
		PackedColorArray([Color(0.75, 0.82, 0.95), Color(0.6, 0.68, 0.88), Color(0.5, 0.55, 0.8), Color(0.82, 0.88, 1.0)]))
	for i in 3:
		ci.draw_line(Vector2(-4 + i * 4, 26), Vector2(-7 + i * 7, 55), Color(1, 1, 1, 0.35), 1.0, true)
	# Head, hair, halo
	ci.draw_arc(Vector2(0, 11), 8, 0, TAU, 20, Color(UIKit.GOLD_LIGHT, 0.9), 1.4, true)
	ci.draw_circle(Vector2(0, 14), 6.5, Color(0.92, 0.72, 0.35))
	ci.draw_circle(Vector2(0, 15), 5, Color(0.99, 0.86, 0.76))
	ci.draw_circle(Vector2(-2, 16.5), 1.2, Color(0.95, 0.55, 0.55, 0.6))
	ci.draw_circle(Vector2(2, 16.5), 1.2, Color(0.95, 0.55, 0.55, 0.6))
	ci.draw_circle(Vector2(-1.8, 14.5), 0.7, Color(0.2, 0.15, 0.3))
	ci.draw_circle(Vector2(1.8, 14.5), 0.7, Color(0.2, 0.15, 0.3))
	# Hands clasped
	ci.draw_circle(Vector2(0, 28), 2.5, Color(0.99, 0.86, 0.76))


static func _fan(ci: CanvasItem, col: Color) -> void:
	_thread(ci, 4)
	var c := Vector2(0, 34)
	var n := 10
	for i in n:
		var a0 := PI + PI * i / n
		var a1 := PI + PI * (i + 1) / n
		var tri := PackedVector2Array([c, c + Vector2(cos(a0), sin(a0)) * 24, c + Vector2(cos(a1), sin(a1)) * 24])
		ci.draw_colored_polygon(tri, col.lightened(0.25) if i % 2 == 0 else col.darkened(0.1))
	ci.draw_arc(c, 24, PI, TAU, 20, UIKit.GOLD, 1.5, true)
	ci.draw_arc(c, 15, PI * 1.15, PI * 1.85, 12, Color(1, 1, 1, 0.5), 1.0, true)
	for i in 4:
		var a := PI * 1.2 + i * PI * 0.2
		ci.draw_circle(c + Vector2(cos(a), sin(a)) * 19, 2.0, Color(0.95, 0.5, 0.6))
	ci.draw_rect(Rect2(-3, 31, 6, 8), Color(0.3, 0.18, 0.1))
	ci.draw_line(Vector2(0, 4), Vector2(0, 10), THREAD, 1.0)


static func _candy_cane(ci: CanvasItem, col: Color) -> void:
	var path := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		path.append(Vector2(0, 12) + Vector2(cos(a), sin(a)) * 8.0)
	for i in range(1, 12):
		path.append(Vector2(8, 12 + i * 4.0))
	ci.draw_polyline(path, Color(0.96, 0.95, 0.9), 7.0, true)
	for i in path.size() - 1:
		if i % 2 == 0:
			ci.draw_line(path[i], path[i + 1], col, 7.0, true)
	ci.draw_polyline(path, Color(1, 1, 1, 0.35), 2.0, true)


static func _gingerbread(ci: CanvasItem, col: Color) -> void:
	ci.draw_line(Vector2.ZERO, Vector2(0, 10), Color(0.8, 0.12, 0.15), 2.0)
	var heart := PackedVector2Array()
	for i in 32:
		var t := TAU * i / 32.0
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		heart.append(Vector2(x, y) * 1.15 + Vector2(0, 26))
	ci.draw_colored_polygon(heart, col)
	var icing := PackedVector2Array()
	for i in 33:
		var t := TAU * i / 32.0
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		var p := Vector2(x, y) * 0.92 + Vector2(0, 26)
		icing.append(p + Vector2(0, sin(i * 2.2) * 0.8))
	ci.draw_polyline(icing, Color(0.98, 0.96, 0.92), 1.6, true)
	for p in [Vector2(-6, 22), Vector2(6, 22), Vector2(0, 31)]:
		ci.draw_circle(p, 2.0, Color(0.85, 0.15, 0.2))
	ci.draw_circle(Vector2(-9, 18), 4, Color(1, 0.85, 0.6, 0.15))


static func _apple(ci: CanvasItem, col: Color) -> void:
	_thread(ci, 8)
	sphere(ci, Vector2(0, 24), 15, col, 0.7)
	for i in 4:
		ci.draw_line(Vector2(-8 + i * 5, 14), Vector2(-9 + i * 5.5, 34), Color(0.95, 0.75, 0.2, 0.18), 2.0, true)
	ci.draw_line(Vector2(0, 10), Vector2(2, 5), Color(0.3, 0.18, 0.08), 2.0)
	_leaf(ci, Vector2(1, 8), -0.5, 11, 4, Color(0.3, 0.5, 0.2))


static func _walnut(ci: CanvasItem, col: Color) -> void:
	_thread(ci, 6)
	_ell(ci, Vector2(0, 19), 11, 13, col.darkened(0.15))
	sphere(ci, Vector2(0, 19), 11, col, 0.5)
	ci.draw_line(Vector2(0, 6), Vector2(0, 32), col.darkened(0.5), 1.4, true)
	for i in 6:
		var y := 10 + i * 3.8
		ci.draw_arc(Vector2(-4, y), 3, 0.3, 2.6, 6, col.darkened(0.35), 1.0, true)
		ci.draw_arc(Vector2(4, y + 1.5), 3, 0.5, 2.8, 6, col.darkened(0.35), 1.0, true)


static func _pomander(ci: CanvasItem, col: Color) -> void:
	sphere(ci, Vector2(0, 26), 15, col, 0.55)
	for i in 5:
		for j in 5:
			var p := Vector2(-10 + i * 5, 16 + j * 5)
			if p.distance_to(Vector2(0, 26)) < 13.0 and (i + j) % 2 == 0:
				ci.draw_circle(p, 1.2, Color(0.25, 0.12, 0.05))
	var rib := Color(0.72, 0.08, 0.1)
	ci.draw_line(Vector2(0, 11), Vector2(0, 41), rib, 3.0)
	ci.draw_arc(Vector2(0, 26), 15, -0.25, 0.25, 4, rib, 3.0)
	ci.draw_arc(Vector2(0, 26), 15, PI - 0.25, PI + 0.25, 4, rib, 3.0)
	ci.draw_line(Vector2(-15, 26), Vector2(15, 26), rib, 3.0)
	_bow(ci, Vector2(0, 10), 6, rib)
	ci.draw_line(Vector2.ZERO, Vector2(0, 8), rib, 1.5)


static func _sugar_mouse(ci: CanvasItem, col: Color) -> void:
	_thread(ci, 10)
	var body := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		var r := 1.0 + 0.35 * cos(a)
		body.append(Vector2(cos(a) * 15 * r, sin(a) * 9) + Vector2(-2, 22))
	ci.draw_colored_polygon(body, col)
	ci.draw_colored_polygon(ellipse_pts(Vector2(-4, 19), 9, 4), col.lightened(0.25))
	ci.draw_circle(Vector2(-10, 15), 4, col.darkened(0.08))
	ci.draw_circle(Vector2(-10, 15), 2.2, Color(1, 0.6, 0.7))
	ci.draw_circle(Vector2(-15, 21), 1.3, Color(0.2, 0.05, 0.05))
	ci.draw_circle(Vector2(-21, 23), 1.2, Color(0.95, 0.4, 0.5))
	var tail := PackedVector2Array()
	for i in 10:
		var t := float(i) / 9.0
		tail.append(Vector2(15 + t * 9, 24 + sin(t * 5.0) * 4))
	ci.draw_polyline(tail, Color(0.85, 0.82, 0.75), 1.2, true)


# =============================================================== toppers

static func _angel_topper(ci: CanvasItem) -> void:
	# Sleeve over the leader
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-6, 4), Vector2(6, 4), Vector2(4, -14), Vector2(-4, -14)]), Color(0.7, 0.62, 0.45))
	# Wings — gilt-edged paper, feathered
	for side in [-1.0, 1.0]:
		for f in 5:
			var base := Vector2(4 * side, -62)
			var ang: float = (PI if side < 0 else 0.0) + side * (-0.9 + f * 0.32)
			_leaf(ci, base, ang, 34 - f * 3.0, 6.0, Color(0.98, 0.95, 0.9).darkened(f * 0.04))
		ci.draw_arc(Vector2(18 * side, -66), 18, (PI * 1.0 if side < 0 else PI * 1.55), (PI * 1.45 if side < 0 else PI * 2.0), 10, UIKit.GOLD, 1.6, true)
	# Gown with folds
	var gown := PackedVector2Array([Vector2(-7, -62), Vector2(7, -62), Vector2(22, -10), Vector2(0, -6), Vector2(-22, -10)])
	ci.draw_polygon(gown, PackedColorArray([Color(1, 0.98, 0.94), Color(0.92, 0.88, 0.82), Color(0.78, 0.74, 0.7), Color(0.88, 0.84, 0.8), Color(1, 0.98, 0.95)]))
	for i in 5:
		ci.draw_line(Vector2(-5 + i * 2.5, -56), Vector2(-17 + i * 8.5, -11), Color(0.7, 0.66, 0.6, 0.5), 1.0, true)
	ci.draw_line(Vector2(-21, -10), Vector2(21, -10), UIKit.GOLD, 2.0, true)
	ci.draw_line(Vector2(-7, -50), Vector2(7, -50), UIKit.GOLD, 1.5, true)
	# Arms holding a little star
	ci.draw_line(Vector2(-6, -56), Vector2(-2, -46), Color(0.95, 0.92, 0.86), 4.0, true)
	ci.draw_line(Vector2(6, -56), Vector2(2, -46), Color(0.95, 0.92, 0.86), 4.0, true)
	_faceted_star(ci, Vector2(0, -44), 5, 2.2, 5, UIKit.GOLD)
	# Wax face and golden hair
	ci.draw_circle(Vector2(0, -70), 9, Color(0.86, 0.66, 0.32))
	ci.draw_circle(Vector2(0, -68.5), 7, Color(1.0, 0.89, 0.8))
	for p in [Vector2(-8, -66), Vector2(8, -66), Vector2(-7, -61), Vector2(7, -61)]:
		ci.draw_circle(p, 3.0, Color(0.88, 0.68, 0.34))
	ci.draw_circle(Vector2(-2.5, -66), 1.6, Color(0.95, 0.6, 0.6, 0.55))
	ci.draw_circle(Vector2(2.5, -66), 1.6, Color(0.95, 0.6, 0.6, 0.55))
	ci.draw_line(Vector2(-3.5, -69.5), Vector2(-1.5, -69.5), Color(0.3, 0.2, 0.15), 1.0)
	ci.draw_line(Vector2(1.5, -69.5), Vector2(3.5, -69.5), Color(0.3, 0.2, 0.15), 1.0)
	ci.draw_arc(Vector2(0, -66), 2, 0.4, PI - 0.4, 6, Color(0.7, 0.3, 0.3), 1.0, true)
	# Halo
	ci.draw_arc(Vector2(0, -84), 10, 0, TAU, 24, UIKit.GOLD_LIGHT, 2.0, true)


static func _star_topper(ci: CanvasItem, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-6, 4), Vector2(6, 4), Vector2(3, -30), Vector2(-3, -30)]), col.darkened(0.3))
	# Rays behind the star
	for i in 16:
		var a := TAU * i / 16.0 + PI / 16.0
		var ray_len := 46.0 if i % 2 == 0 else 34.0
		ci.draw_line(Vector2(0, -52), Vector2(0, -52) + Vector2(cos(a), sin(a)) * ray_len, Color(UIKit.GOLD_LIGHT, 0.45), 1.5, true)
	_faceted_star(ci, Vector2(0, -52), 36, 14, 5, col)
	ci.draw_circle(Vector2(0, -52), 5, col.lightened(0.45))
	ci.draw_circle(Vector2(-10, -64), 3, Color(1, 1, 0.92, 0.8))


static func _spire_topper(ci: CanvasItem, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-8, 4), Vector2(8, 4), Vector2(5, -24), Vector2(-5, -24)]), col.darkened(0.25))
	ci.draw_line(Vector2(-7, -6), Vector2(7, -6), UIKit.GOLD, 2.0)
	sphere(ci, Vector2(0, -38), 16, col)
	ci.draw_arc(Vector2(0, -38), 16, 0.1, PI - 0.1, 16, Color(UIKit.GOLD_LIGHT, 0.6), 2.0, true)
	sphere(ci, Vector2(0, -62), 9, col.lightened(0.05))
	var spike := PackedVector2Array([Vector2(-5, -70), Vector2(5, -70), Vector2(0, -110)])
	ci.draw_polygon(spike, PackedColorArray([col.lightened(0.3), col.darkened(0.3), col]))
	ci.draw_line(Vector2(-1.5, -72), Vector2(-0.5, -102), Color(1, 1, 1, 0.7), 1.2, true)


static func _rosette_topper(ci: CanvasItem, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-6, 4), Vector2(6, 4), Vector2(3, -26), Vector2(-3, -26)]), col.darkened(0.3))
	var c := Vector2(0, -48)
	_faceted_star(ci, c, 36, 22, 12, col.darkened(0.08))
	_faceted_star(ci, c, 27, 15, 12, col.lightened(0.1), -PI * 0.5 + PI / 12.0)
	ci.draw_circle(c, 13, Color(0.7, 0.08, 0.12))
	ci.draw_arc(c, 13, 0, TAU, 24, UIKit.GOLD_LIGHT, 2.0, true)
	for i in 12:
		var a := TAU * i / 12.0
		ci.draw_circle(c + Vector2(cos(a), sin(a)) * 18.5, 1.4, Color(1, 0.95, 0.8))
	ci.draw_circle(c + Vector2(-4, -4), 3, Color(1, 0.85, 0.85, 0.75))


# ================================================================ garlands

static func draw_garland(ci: CanvasItem, d: Dictionary, pts: PackedVector2Array, time: float, s: int, lit: bool) -> void:
	var col: Color = d.get("color", Color.WHITE)
	match d.get("draw", ""):
		"tinsel":
			ci.draw_polyline(pts, col.darkened(0.35), 7.0, true)
			var n := pts.size()
			for i in n:
				var p := pts[i]
				for k in 3:
					var a := float(i * 3 + k) * 2.39996
					var l := 5.0 + fmod(a * 7.0, 4.0)
					var shimmer := 0.5 + 0.5 * sin(time * 3.0 + i * 0.7 + k * 2.0)
					ci.draw_line(p, p + Vector2(cos(a), sin(a)) * l, col.lerp(Color.WHITE, shimmer * 0.5), 1.5, true)
			for i in range(0, n, 3):
				var sh := 0.5 + 0.5 * sin(time * 4.0 + i * 1.3)
				if sh > 0.85:
					ci.draw_circle(pts[i], 2.2, Color(1, 1, 0.95, (sh - 0.85) * 6.0))
		"popcorn":
			ci.draw_polyline(pts, Color(0.9, 0.88, 0.8, 0.6), 1.0, true)
			for i in range(0, pts.size(), 1):
				var p := pts[i]
				var j := float(i) * 1.7
				ci.draw_circle(p + Vector2(sin(j) * 1.5, cos(j) * 1.5), 4.2, col.darkened(0.12))
				ci.draw_circle(p + Vector2(sin(j * 1.3) * 2.0 - 1.0, -1.5), 3.0, col)
		"cranberry":
			ci.draw_polyline(pts, Color(0.9, 0.88, 0.8, 0.5), 1.0, true)
			for i in pts.size():
				_berry(ci, pts[i], 3.6, col)
		"beads":
			ci.draw_polyline(pts, Color(0.5, 0.4, 0.2, 0.6), 1.0, true)
			var bead_cols := [UIKit.GOLD, Color(0.75, 0.1, 0.12), UIKit.GOLD, Color(0.2, 0.45, 0.75)]
			for i in pts.size():
				sphere(ci, pts[i], 4.0 if i % 2 == 0 else 3.0, bead_cols[i % 4], 0.8)
		"paper_chain":
			var link_cols := [Color(0.72, 0.07, 0.09), Color(0.1, 0.42, 0.22), Color(0.9, 0.68, 0.24), Color(0.92, 0.88, 0.8)]
			for i in range(0, pts.size() - 1):
				var a := pts[i]
				var b := pts[i + 1]
				var mid := (a + b) * 0.5
				var ang := (b - a).angle()
				var c: Color = link_cols[i % 4]
				if i % 2 == 0:
					ci.draw_colored_polygon(ellipse_pts(mid, 7, 4, 16, ang), c)
					ci.draw_colored_polygon(ellipse_pts(mid, 4.5, 1.8, 12, ang), c.darkened(0.45))
				else:
					ci.draw_line(mid - Vector2(0, 5).rotated(ang), mid + Vector2(0, 5).rotated(ang), c, 3.5, true)
		"electric":
			ci.draw_polyline(pts, Color(0.1, 0.16, 0.1), 2.0, true)
			var bulb_cols := [Color(1, 0.3, 0.25), Color(1, 0.8, 0.3), Color(0.4, 0.75, 1.0), Color(0.5, 1, 0.5)]
			for i in range(1, pts.size(), 3):
				var p := pts[i]
				var bc: Color = bulb_cols[(i / 3) % 4]
				ci.draw_rect(Rect2(p + Vector2(-2, -1), Vector2(4, 4)), Color(0.55, 0.5, 0.35))
				var glow_amt := 1.0 if lit else 0.35
				ci.draw_colored_polygon(ellipse_pts(p + Vector2(0, 7), 3.6, 5.5, 12), bc.lerp(Color.WHITE, 0.35 * glow_amt) if lit else bc.darkened(0.45))
				if lit:
					ci.draw_circle(p + Vector2(-1, 6), 1.4, Color(1, 1, 1, 0.9))
		_:
			ci.draw_polyline(pts, col, 3.0, true)


# ================================================================ the room

static func _needle_tuft(ci: CanvasItem, c: Vector2, r: float, base: Color, s: int) -> void:
	for k in 9:
		var a := float(k * 7 + s) * 2.39996
		var l := r * (0.6 + fmod(a * 3.1, 0.5))
		var col := base.lightened(0.05 * (k % 3)) if k % 2 == 0 else base.darkened(0.15)
		ci.draw_line(c, c + Vector2(cos(a), sin(a)) * l, col, 2.0, true)


static func _mantel_garland(ci: CanvasItem, s: int) -> void:
	# Three swags hanging between four bow points across 480 px.
	var xs := [-236.0, -80.0, 80.0, 236.0]
	var green := Color(0.13, 0.3, 0.16)
	for sw in 3:
		var a := Vector2(xs[sw], 0)
		var b := Vector2(xs[sw + 1], 0)
		for i in 22:
			var t := float(i) / 21.0
			var p := a.lerp(b, t) + Vector2(0, sin(t * PI) * 38.0)
			_needle_tuft(ci, p, 12.0, green.lightened(0.1 * sin(t * 9.0 + sw)), i + sw * 30 + s)
			_needle_tuft(ci, p + Vector2(0, 5), 9.0, green.darkened(0.2), i + 11)
		# Holly clusters on each swag
		var m := a.lerp(b, 0.5) + Vector2(0, 38)
		for k in 3:
			_leaf(ci, m + Vector2(-4 + k * 4, 0), -0.3 - k * 1.2, 15, 5, Color(0.1, 0.32, 0.14), true)
		for k in 3:
			_berry(ci, m + Vector2(-4 + k * 4, 2 + (k % 2) * 3), 3.2)
	# Trailing ivy at the two ends
	for side in [-1.0, 1.0]:
		var p := Vector2(xs[0 if side < 0 else 3], 0)
		for i in 6:
			var q := p + Vector2(side * sin(i * 0.9) * 6, 8 + i * 9)
			_leaf(ci, q, PI * 0.5 + side * 0.6, 9, 4, Color(0.18, 0.36, 0.18))
	for x in xs:
		_bow(ci, Vector2(x, -2), 10, Color(0.68, 0.06, 0.09))


static func _stocking(ci: CanvasItem, col: Color, s: int) -> void:
	ci.draw_arc(Vector2(0, 2), 4, PI, TAU, 8, Color(0.85, 0.8, 0.65), 1.5, true)
	var leg := PackedVector2Array([Vector2(-14, 18), Vector2(14, 18), Vector2(14, 56), Vector2(30, 64),
		Vector2(32, 78), Vector2(4, 80), Vector2(-14, 64)])
	ci.draw_colored_polygon(leg, col)
	# Knit texture
	for row in 8:
		var y := 22 + row * 7.0
		for k in 4:
			var x := -10 + k * 7.0
			if y > 60 and x < -10:
				continue
			ci.draw_line(Vector2(x, y), Vector2(x + 3, y + 3), col.lightened(0.18), 1.2, true)
			ci.draw_line(Vector2(x + 3, y + 3), Vector2(x + 6, y), col.lightened(0.18), 1.2, true)
	# Heel and toe in contrast
	var contrast := Color(0.92, 0.88, 0.78) if col.v < 0.7 else Color(0.62, 0.08, 0.1)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-14, 58), Vector2(-4, 66), Vector2(-6, 76), Vector2(-14, 64)]), contrast)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(24, 62), Vector2(30, 64), Vector2(32, 78), Vector2(22, 79)]), contrast)
	# Cuff
	UIKit.vgrad(ci, Rect2(-17, 4, 34, 15), contrast.lightened(0.1), contrast.darkened(0.15))
	for k in 6:
		ci.draw_line(Vector2(-14 + k * 6, 6), Vector2(-14 + k * 6, 17), contrast.darkened(0.2), 1.0)
	# A treat poking out of some stockings
	if s % 2 == 0:
		ci.draw_line(Vector2(-8, 6), Vector2(-10, -6), Color(0.96, 0.95, 0.9), 4.0, true)
		ci.draw_arc(Vector2(-6, -7), 4, PI, TAU, 6, Color(0.85, 0.1, 0.12), 4.0, true)
		sphere(ci, Vector2(7, 2), 6, Color(0.92, 0.5, 0.12), 0.5)


static func _present(ci: CanvasItem, d: Dictionary, s: int) -> void:
	var r: Rect2 = d["rect"]
	var col: Color = d["color"]
	var acc: Color = d.get("accent", UIKit.GOLD)
	var w := r.size.x
	var h := r.size.y - 12.0
	var depth := 10.0
	var front := Rect2(-w * 0.5, -h, w - depth, h)
	UIKit.vgrad(ci, front, col.lightened(0.08), col.darkened(0.25))
	# Side face
	ci.draw_colored_polygon(PackedVector2Array([Vector2(front.end.x, -h), Vector2(front.end.x + depth, -h - depth),
		Vector2(front.end.x + depth, -depth), Vector2(front.end.x, 0)]), col.darkened(0.4))
	# Top face
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-w * 0.5, -h), Vector2(front.end.x, -h),
		Vector2(front.end.x + depth, -h - depth), Vector2(-w * 0.5 + depth, -h - depth)]), col.lightened(0.18))
	# Ribbon
	var rx := front.position.x + front.size.x * 0.5
	ci.draw_rect(Rect2(rx - 4, -h, 8, h), acc.darkened(0.1))
	ci.draw_rect(Rect2(front.position.x, -h * 0.5 - 4, front.size.x, 8), acc.darkened(0.15))
	ci.draw_line(Vector2(rx + 4, -h - 1), Vector2(rx + 4 + depth, -h - depth - 1), acc, 6.0)
	if d["id"] == "present_brown":
		# String instead of ribbon, and a wax seal label
		ci.draw_rect(Rect2(front.position.x + 6, -h + 8, 22, 14), Color(0.95, 0.9, 0.78))
		ci.draw_circle(Vector2(front.position.x + 17, -h + 15), 3.5, Color(0.65, 0.08, 0.08))
	_bow(ci, Vector2(rx + depth * 0.5, -h - depth * 0.5), 11 + (s % 3), acc)
	ci.draw_rect(Rect2(front.position, front.size), Color(0, 0, 0, 0.25), false, 1.0)


static func _present_tartan(ci: CanvasItem, d: Dictionary) -> void:
	var r: Rect2 = d["rect"]
	var col: Color = d["color"]
	var acc: Color = d["accent"]
	var w := r.size.x
	var h := r.size.y - 10.0
	var front := Rect2(-w * 0.5, -h, w - 10, h)
	ci.draw_rect(front, col)
	for i in range(0, int(front.size.x), 12):
		ci.draw_rect(Rect2(front.position.x + i, -h, 4, h), Color(acc, 0.55))
		ci.draw_rect(Rect2(front.position.x + i + 7, -h, 1.5, h), Color(0.9, 0.85, 0.3, 0.5))
	for j in range(0, int(h), 12):
		ci.draw_rect(Rect2(front.position.x, -h + j, front.size.x, 4), Color(acc, 0.45))
		ci.draw_rect(Rect2(front.position.x, -h + j + 7, front.size.x, 1.5), Color(0.9, 0.85, 0.3, 0.4))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(front.end.x, -h), Vector2(front.end.x + 10, -h - 10), Vector2(front.end.x + 10, -10), Vector2(front.end.x, 0)]), col.darkened(0.45))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-w * 0.5, -h), Vector2(front.end.x, -h), Vector2(front.end.x + 10, -h - 10), Vector2(-w * 0.5 + 10, -h - 10)]), col.lightened(0.15))
	UIKit.vgrad(ci, front, Color(1, 1, 1, 0.08), Color(0, 0, 0, 0.25))
	_bow(ci, Vector2(front.get_center().x + 5, -h - 5), 12, Color(0.9, 0.85, 0.75))


static func _candlestick(ci: CanvasItem, col: Color, preview: bool) -> void:
	_ell(ci, Vector2(0, -3), 15, 5, col.darkened(0.35))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-15, -3), Vector2(15, -3), Vector2(8, -12), Vector2(-8, -12)]), col.darkened(0.1))
	var stem := Rect2(-3.5, -50, 7, 40)
	UIKit.hgrad(ci, stem, col.lightened(0.35), col.darkened(0.3))
	for y in [-14.0, -30.0, -48.0]:
		_ell(ci, Vector2(0, y), 6.5, 3, col.lightened(0.15))
	_ell(ci, Vector2(0, -52), 11, 3.5, col)
	var candle := Rect2(-4.5, -84, 9, 32)
	UIKit.hgrad(ci, candle, Color(0.99, 0.96, 0.88), Color(0.8, 0.74, 0.62))
	ci.draw_line(Vector2(0, -84), Vector2(0.5, -88), Color(0.12, 0.08, 0.05), 1.4)
	ci.draw_line(Vector2(-2, -12), Vector2(-2, -48), Color(1, 0.95, 0.8, 0.5), 1.2)
	if preview:
		_flame_shape(ci, Vector2(0.5, -89), 13.0)


static func _holly(ci: CanvasItem, s: int) -> void:
	var g := Color(0.1, 0.32, 0.15)
	_leaf(ci, Vector2(0, 0), PI + 0.35, 30, 9, g, true)
	_leaf(ci, Vector2(0, 0), -0.35, 30, 9, g.lightened(0.06), true)
	_leaf(ci, Vector2(0, 0), -PI * 0.5 + 0.25 * ((s % 3) - 1), 24, 8, g.darkened(0.1), true)
	for p in [Vector2(-4, 2), Vector2(4, 3), Vector2(0, 8)]:
		_berry(ci, p, 4.2)


static func _wreath(ci: CanvasItem, s: int) -> void:
	# Ribbon loop up to the nail
	ci.draw_line(Vector2(0, 0), Vector2(-6, 14), Color(0.65, 0.06, 0.09), 3.0, true)
	ci.draw_line(Vector2(0, 0), Vector2(6, 14), Color(0.65, 0.06, 0.09), 3.0, true)
	ci.draw_circle(Vector2(0, 0), 2.5, Color(0.6, 0.5, 0.3))
	var c := Vector2(0, 58)
	var ring_col := Color(0.08, 0.24, 0.12)
	ci.draw_arc(c, 38, 0, TAU, 40, ring_col.darkened(0.3), 20.0, true)
	for i in 36:
		var a := TAU * i / 36.0
		var p := c + Vector2(cos(a), sin(a)) * (38.0 + sin(i * 2.7) * 4.0)
		_leaf(ci, p, a + PI * 0.5 + 0.6, 17, 5.5, ring_col.lightened(0.04 * (i % 4)), true)
	for i in 9:
		var a := TAU * i / 9.0 + 0.3
		var p := c + Vector2(cos(a), sin(a)) * 40.0
		_berry(ci, p, 3.6)
		_berry(ci, p + Vector2(4, 3), 3.0)
	_bow(ci, c + Vector2(0, 40), 16, Color(0.7, 0.06, 0.09))


static func _mistletoe(ci: CanvasItem, ceiling_dy: float, s: int) -> void:
	# Ribbon up to the ceiling
	ci.draw_line(Vector2(0, -24), Vector2(0, -ceiling_dy), Color(0.7, 0.08, 0.1), 3.0)
	_bow(ci, Vector2(0, -24), 10, Color(0.72, 0.07, 0.1))
	var c := Vector2(0, 6)
	ci.draw_circle(c, 22, Color(0.25, 0.35, 0.18))
	for i in 22:
		var a := float(i) * 2.39996 + s
		var p := c + Vector2(cos(a), sin(a)) * (8.0 + fmod(a * 5.0, 14.0))
		_leaf(ci, p, a, 12, 3.6, Color(0.5, 0.62, 0.32).darkened(0.05 * (i % 3)))
	for i in 9:
		var a := float(i) * 1.9 + s
		var p := c + Vector2(cos(a), sin(a)) * (6.0 + fmod(a * 3.0, 14.0))
		ci.draw_circle(p, 2.8, Color(0.97, 0.96, 0.9))
		ci.draw_circle(p + Vector2(-0.8, -0.8), 1.0, Color(1, 1, 1))
	# Trailing ribbon tails
	ci.draw_line(c + Vector2(0, 20), c + Vector2(-6, 42), Color(0.7, 0.08, 0.1), 3.0, true)
	ci.draw_line(c + Vector2(0, 20), c + Vector2(7, 40), Color(0.6, 0.06, 0.08), 3.0, true)


static func _teddy(ci: CanvasItem, col: Color) -> void:
	var dk := col.darkened(0.3)
	var lt := col.lightened(0.18)
	# Legs (sitting, feet forward)
	_ell(ci, Vector2(-15, -10), 12, 9, col)
	_ell(ci, Vector2(15, -10), 12, 9, col)
	_ell(ci, Vector2(-18, -9), 6, 6, Color(0.85, 0.72, 0.5))
	_ell(ci, Vector2(18, -9), 6, 6, Color(0.85, 0.72, 0.5))
	# Body
	_ell(ci, Vector2(0, -30), 19, 22, col)
	_ell(ci, Vector2(-4, -34), 11, 14, lt)
	# Arms
	_ell(ci, Vector2(-20, -32), 7, 14, dk, 0.4)
	_ell(ci, Vector2(20, -32), 7, 14, dk, -0.4)
	# Head
	ci.draw_circle(Vector2(-12, -70), 7, col)
	ci.draw_circle(Vector2(12, -70), 7, col)
	ci.draw_circle(Vector2(-12, -70), 3.5, dk)
	ci.draw_circle(Vector2(12, -70), 3.5, dk)
	ci.draw_circle(Vector2(0, -58), 16, col)
	ci.draw_circle(Vector2(-4, -62), 8, Color(lt, 0.6))
	_ell(ci, Vector2(0, -53), 8, 6, Color(0.88, 0.75, 0.55))
	ci.draw_circle(Vector2(0, -55), 2.6, Color(0.15, 0.08, 0.05))
	ci.draw_circle(Vector2(-6, -62), 2.2, Color(0.08, 0.05, 0.03))
	ci.draw_circle(Vector2(6, -62), 2.2, Color(0.08, 0.05, 0.03))
	ci.draw_circle(Vector2(-6.6, -62.8), 0.7, Color(1, 1, 1, 0.8))
	ci.draw_arc(Vector2(0, -52), 3, 0.3, PI - 0.3, 6, Color(0.2, 0.1, 0.05), 1.2, true)
	# Ribbon bow
	_bow(ci, Vector2(0, -44), 8, Color(0.72, 0.07, 0.1))


static func _rocking_horse(ci: CanvasItem) -> void:
	var rocker := Color(0.6, 0.1, 0.1)
	var pts := PackedVector2Array()
	for i in 21:
		var t := float(i) / 20.0
		pts.append(Vector2(-60 + t * 120, -14 + sin(t * PI) * 10.0))
	ci.draw_polyline(pts, rocker, 8.0, true)
	ci.draw_polyline(pts, rocker.lightened(0.3), 2.0, true)
	var grey := Color(0.88, 0.87, 0.84)
	var dk := Color(0.55, 0.55, 0.55)
	# Legs splayed to the rocker
	for lx in [[-30.0, -40.0], [-18.0, -24.0], [18.0, 26.0], [30.0, 42.0]]:
		ci.draw_line(Vector2(lx[0], -50), Vector2(lx[1], -16), grey.darkened(0.12), 6.0, true)
	# Body
	_ell(ci, Vector2(0, -56), 38, 15, grey)
	for i in 10:
		ci.draw_circle(Vector2(-28 + i * 6.5, -58 + sin(i * 1.7) * 6), 3.0, Color(dk, 0.55))
	# Neck and head
	ci.draw_colored_polygon(PackedVector2Array([Vector2(24, -62), Vector2(36, -64), Vector2(46, -90), Vector2(34, -94)]), grey)
	_ell(ci, Vector2(46, -88), 14, 7, grey, 0.5)
	ci.draw_circle(Vector2(42, -92), 1.8, Color(0.1, 0.05, 0.03))
	ci.draw_line(Vector2(36, -96), Vector2(38, -102), grey, 3.0)
	# Mane and tail
	for i in 7:
		ci.draw_line(Vector2(30 + i * 1.8, -66 - i * 4.0), Vector2(24 + i * 1.8, -62 - i * 4.0), Color(0.3, 0.25, 0.2), 3.0, true)
	for i in 5:
		ci.draw_line(Vector2(-38, -60), Vector2(-50 - i * 2, -42 + i * 2), Color(0.32, 0.27, 0.22), 2.0, true)
	# Saddle and bridle
	_ell(ci, Vector2(-4, -68), 13, 5, Color(0.55, 0.08, 0.08))
	ci.draw_line(Vector2(-4, -64), Vector2(-4, -44), Color(0.4, 0.25, 0.1), 2.0)
	ci.draw_line(Vector2(40, -86), Vector2(28, -66), Color(0.55, 0.08, 0.08), 1.6, true)


static func _soldier(ci: CanvasItem, col: Color) -> void:
	ci.draw_rect(Rect2(-14, -6, 28, 6), Color(0.15, 0.3, 0.15))
	ci.draw_rect(Rect2(-9, -26, 7, 20), Color(0.08, 0.1, 0.25))
	ci.draw_rect(Rect2(2, -26, 7, 20), Color(0.08, 0.1, 0.25))
	ci.draw_rect(Rect2(-9, -10, 7, 4), Color(0.05, 0.05, 0.05))
	ci.draw_rect(Rect2(2, -10, 7, 4), Color(0.05, 0.05, 0.05))
	UIKit.hgrad(ci, Rect2(-11, -52, 22, 27), col.lightened(0.15), col.darkened(0.3))
	ci.draw_line(Vector2(-10, -50), Vector2(10, -28), Color(0.95, 0.95, 0.9), 3.0)
	ci.draw_line(Vector2(10, -50), Vector2(-10, -28), Color(0.95, 0.95, 0.9), 3.0)
	for y in [-46.0, -40.0, -34.0]:
		ci.draw_circle(Vector2(0, y), 1.3, UIKit.GOLD)
	ci.draw_rect(Rect2(-15, -50, 5, 22), col.darkened(0.15))
	ci.draw_rect(Rect2(10, -50, 5, 22), col.darkened(0.15))
	ci.draw_circle(Vector2(0, -58), 6.5, Color(0.97, 0.85, 0.72))
	ci.draw_circle(Vector2(-2.5, -59), 1.0, Color(0.1, 0.05, 0.03))
	ci.draw_circle(Vector2(2.5, -59), 1.0, Color(0.1, 0.05, 0.03))
	ci.draw_circle(Vector2(-3.5, -56), 1.4, Color(0.95, 0.4, 0.4, 0.7))
	ci.draw_circle(Vector2(3.5, -56), 1.4, Color(0.95, 0.4, 0.4, 0.7))
	# Bearskin
	_ell(ci, Vector2(0, -73), 9, 13, Color(0.06, 0.05, 0.05))
	ci.draw_circle(Vector2(-3, -78), 3, Color(0.2, 0.18, 0.18))
	ci.draw_line(Vector2(-6, -63), Vector2(6, -63), UIKit.GOLD, 1.5)


static func _ark(ci: CanvasItem, col: Color) -> void:
	var hull := PackedVector2Array([Vector2(-58, -26), Vector2(58, -26), Vector2(44, -2), Vector2(-44, -2)])
	ci.draw_polygon(hull, PackedColorArray([col.lightened(0.15), col, col.darkened(0.35), col.darkened(0.2)]))
	for i in 3:
		ci.draw_line(Vector2(-54 + i * 3, -20 + i * 6), Vector2(54 - i * 3, -20 + i * 6), col.darkened(0.4), 1.0)
	ci.draw_rect(Rect2(-28, -46, 50, 20), Color(0.85, 0.78, 0.6))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-34, -46), Vector2(28, -46), Vector2(16, -60), Vector2(-22, -60)]), Color(0.6, 0.1, 0.1))
	for x in [-20.0, -4.0, 12.0]:
		ci.draw_rect(Rect2(x, -42, 8, 9), Color(0.25, 0.15, 0.08))
	# Two giraffes peeking from the deck
	for gx in [34.0, 42.0]:
		ci.draw_line(Vector2(gx, -26), Vector2(gx + 2, -50), Color(0.85, 0.65, 0.3), 3.0)
		_ell(ci, Vector2(gx + 5, -51), 5, 2.5, Color(0.85, 0.65, 0.3))
	# Two elephants
	_ell(ci, Vector2(-44, -32), 8, 6, Color(0.55, 0.55, 0.58))
	_ell(ci, Vector2(-36, -31), 7, 5, Color(0.5, 0.5, 0.53))


static func _drum(ci: CanvasItem, col: Color) -> void:
	var body := Rect2(-26, -38, 52, 34)
	UIKit.hgrad(ci, body, col.lightened(0.2), col.darkened(0.35))
	for i in 6:
		var x0 := -26 + i * 10.4
		ci.draw_line(Vector2(x0, -36), Vector2(x0 + 5.2, -6), UIKit.GOLD, 1.5, true)
		ci.draw_line(Vector2(x0 + 5.2, -6), Vector2(x0 + 10.4, -36), UIKit.GOLD, 1.5, true)
	ci.draw_rect(Rect2(-27, -40, 54, 5), Color(0.7, 0.08, 0.1))
	ci.draw_rect(Rect2(-27, -6, 54, 5), Color(0.7, 0.08, 0.1))
	_ell(ci, Vector2(0, -40), 26, 6, Color(0.93, 0.88, 0.76))
	ci.draw_line(Vector2(-18, -50), Vector2(10, -38), Color(0.55, 0.35, 0.15), 3.0, true)
	ci.draw_line(Vector2(18, -50), Vector2(-8, -39), Color(0.55, 0.35, 0.15), 3.0, true)
	ci.draw_circle(Vector2(-18, -50), 3, Color(0.85, 0.75, 0.55))
	ci.draw_circle(Vector2(18, -50), 3, Color(0.85, 0.75, 0.55))


static func _cards(ci: CanvasItem, s: int) -> void:
	var pics := ["robin", "holly", "snow"]
	for i in 3:
		var x := -30 + i * 30.0
		var tilt := (-0.12 + i * 0.12) + 0.03 * ((s + i) % 3 - 1)
		var w := 26.0
		var h := 38.0
		var base := Vector2(x, 0)
		var corners := PackedVector2Array([Vector2(-w * 0.5, -h), Vector2(w * 0.5, -h), Vector2(w * 0.5, 0), Vector2(-w * 0.5, 0)])
		var poly := PackedVector2Array()
		for c in corners:
			poly.append(base + c.rotated(tilt))
		ci.draw_colored_polygon(PackedVector2Array([poly[0] + Vector2(3, 2), poly[1] + Vector2(3, 2), poly[2] + Vector2(3, 0), poly[3] + Vector2(3, 0)]), Color(0, 0, 0, 0.25))
		ci.draw_colored_polygon(poly, Color(0.95, 0.9, 0.78))
		var inner := PackedVector2Array()
		for c in corners:
			inner.append(base + (c * 0.72 + Vector2(0, -h * 0.12)).rotated(tilt))
		var pic: String = pics[(i + s) % 3]
		var bg := Color(0.75, 0.82, 0.9) if pic == "snow" else Color(0.85, 0.78, 0.62)
		ci.draw_colored_polygon(inner, bg)
		var cc := base + Vector2(0, -h * 0.55).rotated(tilt)
		match pic:
			"robin":
				ci.draw_circle(cc, 5, Color(0.45, 0.3, 0.18))
				ci.draw_circle(cc + Vector2(-1, 1.5), 3, Color(0.85, 0.3, 0.12))
				ci.draw_circle(cc + Vector2(3, -3), 2.5, Color(0.45, 0.3, 0.18))
			"holly":
				_leaf(ci, cc, PI + 0.4, 9, 3, Color(0.1, 0.35, 0.15), true)
				_leaf(ci, cc, -0.4, 9, 3, Color(0.1, 0.35, 0.15), true)
				ci.draw_circle(cc, 2.2, Color(0.8, 0.08, 0.1))
			_:
				ci.draw_colored_polygon(PackedVector2Array([cc + Vector2(-6, 6), cc + Vector2(0, -7), cc + Vector2(6, 6)]), Color(0.15, 0.3, 0.2))
				ci.draw_rect(Rect2(cc + Vector2(-8, 6), Vector2(16, 3)), Color(1, 1, 1))
		ci.draw_polyline(PackedVector2Array([poly[0], poly[1], poly[2], poly[3], poly[0]]), Color(UIKit.GOLD_DARK, 0.6), 1.0)
