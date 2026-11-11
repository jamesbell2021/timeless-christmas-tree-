class_name UIIcons
extends RefCounted
## Engraved, line-drawn icons in the manner of a Victorian catalogue plate.
## Every icon is drawn from primitives inside the given rect, so they scale
## crisply and can be tinted (gold by default).


static func draw(ci: CanvasItem, kind: String, r: Rect2, col: Color = UIKit.GOLD) -> void:
	var c := r.get_center()
	var s := minf(r.size.x, r.size.y) * 0.5
	var w := maxf(1.5, s * 0.09)
	match kind:
		"trunk":
			var body := Rect2(c + Vector2(-s * 0.85, -s * 0.2), Vector2(s * 1.7, s * 0.95))
			ci.draw_rect(body, Color(col, 0.18))
			ci.draw_rect(body, col, false, w)
			var lid := PackedVector2Array()
			for i in 13:
				var t := float(i) / 12.0
				lid.append(c + Vector2(-s * 0.85 + t * s * 1.7, -s * 0.2 - sin(t * PI) * s * 0.45))
			ci.draw_polyline(lid, col, w, true)
			ci.draw_line(c + Vector2(-s * 0.45, -s * 0.6), c + Vector2(-s * 0.45, s * 0.75), col, w * 0.8)
			ci.draw_line(c + Vector2(s * 0.45, -s * 0.6), c + Vector2(s * 0.45, s * 0.75), col, w * 0.8)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.13, -s * 0.28), Vector2(s * 0.26, s * 0.3)), col)
		"candle":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.18, -s * 0.15), Vector2(s * 0.36, s * 0.95)), Color(col, 0.25))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.18, -s * 0.15), Vector2(s * 0.36, s * 0.95)), col, false, w)
			_flame(ci, c + Vector2(0, -s * 0.2), s * 0.55, col)
		"flame":
			_flame(ci, c + Vector2(0, s * 0.55), s * 1.25, col)
		"bauble":
			ci.draw_circle(c + Vector2(0, s * 0.18), s * 0.62, Color(col, 0.2))
			ci.draw_arc(c + Vector2(0, s * 0.18), s * 0.62, 0, TAU, 32, col, w, true)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.16, -s * 0.62), Vector2(s * 0.32, s * 0.2)), col)
			ci.draw_arc(c + Vector2(0, -s * 0.72), s * 0.13, PI, TAU, 10, col, w * 0.8, true)
			ci.draw_arc(c + Vector2(-s * 0.18, 0.0), s * 0.25, PI * 1.1, PI * 1.5, 8, col, w * 0.8, true)
		"paper":
			_star(ci, c, s * 0.85, s * 0.42, 8, col, w)
			ci.draw_circle(c, s * 0.16, col)
		"garland":
			var pts := PackedVector2Array()
			for i in 17:
				var t := float(i) / 16.0
				pts.append(c + Vector2(-s * 0.9 + t * s * 1.8, -s * 0.35 + sin(t * PI) * s * 0.75))
			ci.draw_polyline(pts, col, w, true)
			for i in range(1, 16, 3):
				ci.draw_circle(pts[i], s * 0.12, col)
		"topper":
			_star(ci, c + Vector2(0, -s * 0.1), s * 0.75, s * 0.32, 5, col, w)
			ci.draw_line(c + Vector2(0, s * 0.5), c + Vector2(0, s * 0.95), col, w * 1.3)
		"room":
			# A knitted stocking
			var st := PackedVector2Array([
				c + Vector2(-s * 0.3, -s * 0.85), c + Vector2(s * 0.25, -s * 0.85),
				c + Vector2(s * 0.25, s * 0.25), c + Vector2(s * 0.75, s * 0.45),
				c + Vector2(s * 0.7, s * 0.9), c + Vector2(-s * 0.05, s * 0.85),
				c + Vector2(-s * 0.3, s * 0.45)])
			ci.draw_colored_polygon(st, Color(col, 0.2))
			st.append(st[0])
			ci.draw_polyline(st, col, w, true)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.38, -s * 0.95), Vector2(s * 0.72, s * 0.3)), col)
		"undo":
			ci.draw_arc(c + Vector2(s * 0.1, s * 0.1), s * 0.6, PI * 1.05, PI * 2.3, 20, col, w * 1.2, true)
			var tip := c + Vector2(-s * 0.5, s * 0.05)
			ci.draw_colored_polygon(PackedVector2Array([tip + Vector2(-s * 0.3, -s * 0.05), tip + Vector2(s * 0.28, -s * 0.15), tip + Vector2(-s * 0.02, s * 0.38)]), col)
		"lamp":
			var shade := PackedVector2Array([c + Vector2(-s * 0.3, -s * 0.8), c + Vector2(s * 0.3, -s * 0.8), c + Vector2(s * 0.7, -s * 0.1), c + Vector2(-s * 0.7, -s * 0.1)])
			ci.draw_colored_polygon(shade, Color(col, 0.3))
			shade.append(shade[0])
			ci.draw_polyline(shade, col, w, true)
			for i in 7:
				var x := -s * 0.6 + i * s * 0.2
				ci.draw_line(c + Vector2(x, -s * 0.1), c + Vector2(x, s * 0.05), col, w * 0.6)
			ci.draw_line(c + Vector2(0, -s * 0.1), c + Vector2(0, s * 0.7), col, w)
			ci.draw_line(c + Vector2(-s * 0.4, s * 0.8), c + Vector2(s * 0.4, s * 0.8), col, w * 1.4)
		"album":
			var b := Rect2(c + Vector2(-s * 0.75, -s * 0.6), Vector2(s * 1.5, s * 1.2))
			ci.draw_rect(b, Color(col, 0.18))
			ci.draw_rect(b, col, false, w)
			ci.draw_line(c + Vector2(0, -s * 0.6), c + Vector2(0, s * 0.6), col, w)
			for i in 3:
				var y := -s * 0.3 + i * s * 0.25
				ci.draw_line(c + Vector2(-s * 0.55, y), c + Vector2(-s * 0.15, y), col, w * 0.6)
			ci.draw_rect(Rect2(c + Vector2(s * 0.15, -s * 0.4), Vector2(s * 0.42, s * 0.5)), col, false, w * 0.7)
		"camera":
			var bx := Rect2(c + Vector2(-s * 0.8, -s * 0.35), Vector2(s * 1.6, s * 0.95))
			ci.draw_rect(bx, Color(col, 0.18))
			ci.draw_rect(bx, col, false, w)
			ci.draw_arc(c + Vector2(0, s * 0.12), s * 0.36, 0, TAU, 24, col, w, true)
			ci.draw_circle(c + Vector2(0, s * 0.12), s * 0.14, col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.55, -s * 0.6), Vector2(s * 0.4, s * 0.25)), col)
		"eye":
			var e := PackedVector2Array()
			for i in 21:
				var t := float(i) / 20.0 * TAU
				e.append(c + Vector2(cos(t) * s * 0.85, sin(t) * s * 0.42))
			ci.draw_polyline(e, col, w, true)
			ci.draw_circle(c, s * 0.25, col)
		"music":
			ci.draw_circle(c + Vector2(-s * 0.35, s * 0.5), s * 0.22, col)
			ci.draw_circle(c + Vector2(s * 0.45, s * 0.35), s * 0.22, col)
			ci.draw_line(c + Vector2(-s * 0.15, s * 0.5), c + Vector2(-s * 0.15, -s * 0.7), col, w)
			ci.draw_line(c + Vector2(s * 0.65, s * 0.35), c + Vector2(s * 0.65, -s * 0.85), col, w)
			ci.draw_line(c + Vector2(-s * 0.15, -s * 0.7), c + Vector2(s * 0.65, -s * 0.85), col, w * 2.0)
		"close":
			ci.draw_line(c + Vector2(-s * 0.55, -s * 0.55), c + Vector2(s * 0.55, s * 0.55), col, w * 1.3, true)
			ci.draw_line(c + Vector2(s * 0.55, -s * 0.55), c + Vector2(-s * 0.55, s * 0.55), col, w * 1.3, true)
		"left", "right":
			var d := -1.0 if kind == "left" else 1.0
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(s * 0.5 * d, 0), c + Vector2(-s * 0.35 * d, -s * 0.6), c + Vector2(-s * 0.35 * d, s * 0.6)]), col)
		"seedling":
			ci.draw_line(c + Vector2(-s * 0.7, s * 0.55), c + Vector2(s * 0.7, s * 0.55), col, w)
			ci.draw_line(c + Vector2(0, s * 0.55), c + Vector2(0, -s * 0.1), col, w)
			for i in 5:
				var a := -PI * 0.5 + (i - 2) * 0.45
				ci.draw_line(c + Vector2(0, -s * 0.1), c + Vector2(0, -s * 0.1) + Vector2(cos(a), sin(a)) * s * 0.45, col, w * 0.8, true)
		"sapling":
			_fir(ci, c + Vector2(0, s * 0.6), s * 1.2, s * 0.9, 3, col, w)
			ci.draw_arc(c + Vector2(s * 0.62, -s * 0.6), s * 0.2, 0, TAU, 14, col, w * 0.7, true)
		"family":
			for i in 3:
				var x := (i - 1) * s * 0.55
				var hgt := s * (1.0 if i != 2 else 0.7)
				var base := c + Vector2(x, s * 0.75)
				ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-s * 0.2, 0), base + Vector2(s * 0.2, 0), base + Vector2(s * 0.1, -hgt * 0.95), base + Vector2(-s * 0.1, -hgt * 0.95)]), col)
				ci.draw_circle(base + Vector2(0, -hgt * 1.12), s * 0.14, col)
		"lantern":
			_fir(ci, c + Vector2(-s * 0.2, s * 0.75), s * 1.45, s * 1.0, 3, col, w)
			ci.draw_rect(Rect2(c + Vector2(s * 0.45, -s * 0.05), Vector2(s * 0.3, s * 0.4)), col, false, w * 0.8)
			ci.draw_circle(c + Vector2(s * 0.6, s * 0.15), s * 0.08, col)
		"tree_decorated":
			_fir(ci, c + Vector2(0, s * 0.75), s * 1.45, s * 1.15, 3, col, w)
			_star(ci, c + Vector2(0, -s * 0.78), s * 0.24, s * 0.1, 5, col, 1.0)
			ci.draw_circle(c + Vector2(-s * 0.2, 0), s * 0.08, col)
			ci.draw_circle(c + Vector2(s * 0.25, s * 0.3), s * 0.08, col)
		_:
			ci.draw_circle(c, s * 0.4, col)


static func _flame(ci: CanvasItem, base: Vector2, h: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 17:
		var t := float(i) / 16.0 * TAU
		var y := -h * 0.5 + cos(t) * h * 0.5
		var x := sin(t) * h * 0.22 * (0.4 + 0.6 * (1.0 - (cos(t) * 0.5 + 0.5)))
		pts.append(base + Vector2(x, y - h * 0.0))
	ci.draw_colored_polygon(pts, col)


static func _star(ci: CanvasItem, c: Vector2, ro: float, ri: float, points: int, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	for i in points * 2:
		var a := -PI * 0.5 + i * PI / points
		var rr := ro if i % 2 == 0 else ri
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	ci.draw_colored_polygon(pts, Color(col, 0.35))
	pts.append(pts[0])
	ci.draw_polyline(pts, col, w, true)


static func _fir(ci: CanvasItem, base: Vector2, h: float, wd: float, tiers: int, col: Color, w: float) -> void:
	for i in tiers:
		var t0 := float(i) / tiers
		var t1 := float(i + 1) / tiers
		var top := base + Vector2(0, -h + t0 * h * 0.75)
		var by := base.y - h + t1 * h * 0.92
		var hw := wd * 0.5 * (0.35 + 0.65 * t1)
		var tri := PackedVector2Array([top, Vector2(base.x + hw, by), Vector2(base.x - hw, by)])
		ci.draw_colored_polygon(tri, Color(col, 0.28))
		tri.append(tri[0])
		ci.draw_polyline(tri, col, w * 0.8, true)
	ci.draw_line(base, base + Vector2(0, -h * 0.08), col, w * 1.4)
