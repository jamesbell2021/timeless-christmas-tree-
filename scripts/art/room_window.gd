class_name RoomWindow
extends Node2D
## A sash window onto a snowy winter night, with velvet drapes and a fringed
## pelmet. Built from three layers: the view, the falling snow, the joinery.

@export var rect := RoomLayout.WINDOW
@export var pelmet := RoomLayout.PELMET
@export var view_seed := 3
@export var upper_cols := 3
@export var lower_cols := 2

var snow: Snowfall


func _ready() -> void:
	add_child(Painter.new(_paint_view))
	snow = Snowfall.new()
	snow.area = rect
	snow.count = int(rect.size.x * rect.size.y / 2600.0)
	add_child(snow)
	add_child(Painter.new(_paint_glass_and_frame))
	add_child(Painter.new(_paint_drapes))


func _paint_view(ci: CanvasItem) -> void:
	var r := rect
	# Night sky: deep blue above, a pale snow-light glow at the horizon
	UIKit.vgrad(ci, Rect2(r.position, Vector2(r.size.x, r.size.y * 0.62)), Color(0.04, 0.06, 0.16), Color(0.2, 0.25, 0.4))
	UIKit.vgrad(ci, Rect2(r.position + Vector2(0, r.size.y * 0.62), Vector2(r.size.x, r.size.y * 0.38)), Color(0.32, 0.38, 0.52), Color(0.55, 0.6, 0.72))
	# Moon glow behind the snow clouds
	var moon := r.position + Vector2(r.size.x * 0.72, r.size.y * 0.16)
	ci.draw_texture_rect(Tex.glow(), Rect2(moon - Vector2(110, 110), Vector2(220, 220)), false, Color(0.7, 0.78, 1.0, 0.35))
	ci.draw_circle(moon, 13, Color(0.92, 0.94, 1.0, 0.85))
	var rng := RandomNumberGenerator.new()
	rng.seed = view_seed
	# Distant hills
	var hy := r.position.y + r.size.y * 0.6
	var hills := PackedVector2Array([Vector2(r.position.x, r.end.y)])
	for i in 13:
		var t := float(i) / 12.0
		hills.append(Vector2(r.position.x + t * r.size.x, hy - sin(t * 3.0 + view_seed) * 26.0 - 12.0))
	hills.append(r.end)
	ci.draw_colored_polygon(hills, Color(0.48, 0.54, 0.68))
	# A village church across the fields, its windows lit for evensong
	var ch := Vector2(r.position.x + r.size.x * 0.32, hy - 6)
	ci.draw_rect(Rect2(ch + Vector2(-26, -26), Vector2(52, 26)), Color(0.14, 0.15, 0.24))
	ci.draw_colored_polygon(PackedVector2Array([ch + Vector2(-30, -26), ch + Vector2(30, -26), ch + Vector2(0, -44)]), Color(0.85, 0.88, 0.95))
	ci.draw_rect(Rect2(ch + Vector2(18, -58), Vector2(12, 58)), Color(0.12, 0.13, 0.22))
	ci.draw_colored_polygon(PackedVector2Array([ch + Vector2(16, -58), ch + Vector2(32, -58), ch + Vector2(24, -86)]), Color(0.12, 0.13, 0.22))
	for wx in [-16.0, -4.0, 8.0]:
		ci.draw_rect(Rect2(ch + Vector2(wx, -20), Vector2(5, 9)), Color(1.0, 0.75, 0.35))
		ci.draw_texture_rect(Tex.glow(), Rect2(ch + Vector2(wx - 10, -26), Vector2(26, 22)), false, Color(1, 0.6, 0.25, 0.4))
	# Snowy fir silhouettes in two depths
	for layer in 2:
		var base_y := r.end.y - (r.size.y * 0.22 if layer == 0 else r.size.y * 0.08)
		var col := Color(0.15, 0.2, 0.3) if layer == 0 else Color(0.07, 0.11, 0.16)
		var x := r.position.x - 10.0 + rng.randf_range(0, 30)
		while x < r.end.x + 20:
			var h := rng.randf_range(50, 120) * (1.6 if layer == 1 else 1.0)
			var w := h * 0.42
			for tier in 4:
				var ty := base_y - h + tier * h * 0.22
				var tw := w * (0.35 + tier * 0.22)
				ci.draw_colored_polygon(PackedVector2Array([Vector2(x, ty), Vector2(x + tw * 0.5, ty + h * 0.32), Vector2(x - tw * 0.5, ty + h * 0.32)]), col)
				ci.draw_line(Vector2(x - tw * 0.48, ty + h * 0.31), Vector2(x + tw * 0.15, ty + h * 0.22), Color(0.85, 0.9, 1.0, 0.75), 2.0)
			x += rng.randf_range(34, 80) * (1.4 if layer == 1 else 1.0)
	# Snow-covered ground in front
	var g := PackedVector2Array([Vector2(r.position.x, r.end.y)])
	for i in 9:
		var t := float(i) / 8.0
		g.append(Vector2(r.position.x + t * r.size.x, r.end.y - r.size.y * 0.06 - sin(t * 5.0 + view_seed) * 8.0))
	g.append(r.end)
	ci.draw_colored_polygon(g, Color(0.78, 0.83, 0.94))


func _paint_glass_and_frame(ci: CanvasItem) -> void:
	var r := rect
	var bar := 7.0
	var wood := Color(0.16, 0.08, 0.04)
	var meet_y := r.position.y + r.size.y * 0.5
	# Pane frost and reflections
	var panes: Array = []
	for row in 2:
		for col in upper_cols:
			panes.append(Rect2(r.position.x + col * r.size.x / upper_cols, r.position.y + row * (meet_y - r.position.y) / 2.0, r.size.x / upper_cols, (meet_y - r.position.y) / 2.0))
	for row in 2:
		for col in lower_cols:
			panes.append(Rect2(r.position.x + col * r.size.x / lower_cols, meet_y + row * (r.end.y - meet_y) / 2.0, r.size.x / lower_cols, (r.end.y - meet_y) / 2.0))
	for p in panes:
		var pr: Rect2 = p
		# Frost creeping in from the lower corners
		ci.draw_texture_rect(Tex.glow(), Rect2(pr.position + Vector2(-pr.size.x * 0.35, pr.size.y * 0.55), pr.size * Vector2(0.7, 0.9)), false, Color(0.9, 0.95, 1.0, 0.28))
		ci.draw_texture_rect(Tex.glow(), Rect2(pr.end - pr.size * Vector2(0.35, 0.45), pr.size * Vector2(0.7, 0.9)), false, Color(0.9, 0.95, 1.0, 0.22))
		# Faint warm reflection of the room
		ci.draw_colored_polygon(PackedVector2Array([
			pr.position + Vector2(pr.size.x * 0.15, 0), pr.position + Vector2(pr.size.x * 0.3, 0),
			pr.position + Vector2(pr.size.x * 0.12, pr.size.y), pr.position + Vector2(0, pr.size.y)]),
			Color(1, 0.85, 0.6, 0.05))
	# Glazing bars
	for col in range(1, upper_cols):
		var x := r.position.x + col * r.size.x / upper_cols
		ci.draw_rect(Rect2(x - bar * 0.5, r.position.y, bar, meet_y - r.position.y), wood)
	ci.draw_rect(Rect2(r.position.x, r.position.y + (meet_y - r.position.y) * 0.5 - bar * 0.5, r.size.x, bar), wood)
	for col in range(1, lower_cols):
		var x := r.position.x + col * r.size.x / lower_cols
		ci.draw_rect(Rect2(x - bar * 0.5, meet_y, bar, r.end.y - meet_y), wood)
	ci.draw_rect(Rect2(r.position.x, meet_y + (r.end.y - meet_y) * 0.5 - bar * 0.5, r.size.x, bar), wood)
	# Meeting rail
	UIKit.vgrad(ci, Rect2(r.position.x, meet_y - 8, r.size.x, 16), Color(0.3, 0.16, 0.08), Color(0.1, 0.05, 0.02))
	ci.draw_circle(Vector2(r.get_center().x, meet_y - 9), 4, UIKit.GOLD)
	# Sash frame and architrave
	ci.draw_rect(r, wood, false, 12.0)
	var arch := r.grow(22)
	ci.draw_rect(arch, Color(0.2, 0.1, 0.05), false, 22.0)
	ci.draw_rect(arch.grow(11), Color(0, 0, 0, 0.5), false, 2.0)
	ci.draw_line(arch.position + Vector2(-11, -11), Vector2(arch.end.x + 11, arch.position.y - 11), Color(1, 0.8, 0.5, 0.18), 2.0)
	# Deep sill
	var sill := Rect2(arch.position.x - 18, r.end.y + 8, arch.size.x + 36, 20)
	UIKit.vgrad(ci, sill, Color(0.35, 0.19, 0.09), Color(0.12, 0.06, 0.03))
	ci.draw_line(sill.position, Vector2(sill.end.x, sill.position.y), Color(1, 0.8, 0.5, 0.3), 2.0)
	UIKit.vgrad(ci, Rect2(sill.position.x, sill.end.y, sill.size.x, 18), Color(0, 0, 0, 0.5), Color(0, 0, 0, 0))


func _paint_drapes(ci: CanvasItem) -> void:
	var r := rect
	var top := pelmet.position.y + 20.0
	var floor_y := RoomLayout.FLOOR_Y + 6.0
	var drape_w := pelmet.size.x * 0.24
	var tie_y := r.position.y + r.size.y * 0.56
	_drape(ci, pelmet.position.x + 6.0, drape_w, top, floor_y, tie_y, 1.0)
	_drape(ci, pelmet.end.x - 6.0, drape_w, top, floor_y, tie_y, -1.0)
	_pelmet(ci, pelmet)


func _drape(ci: CanvasItem, wall_x: float, w: float, top: float, bottom: float, tie_y: float, dir: float) -> void:
	## A heavy velvet curtain hanging from wall_x, drawn back toward the wall
	## (dir = +1 for the left drape, -1 for the right) and tied at tie_y.
	var folds := 7
	var base := Color(0.07, 0.2, 0.12)
	var x_at := func(level: int, f: float) -> float:
		# level 0 = top, 1 = tie-back, 2 = floor
		var width_factor := [1.0, 0.48, 0.85][level] as float
		return wall_x + dir * f * w * width_factor
	var ys := [top, tie_y, bottom]
	for f in folds:
		var f0 := float(f) / folds
		var f1 := float(f + 1) / folds
		for level in 2:
			var y0: float = ys[level]
			var y1: float = ys[level + 1]
			var quad := PackedVector2Array([
				Vector2(x_at.call(level, f0), y0), Vector2(x_at.call(level, f1), y0),
				Vector2(x_at.call(level + 1, f1), y1), Vector2(x_at.call(level + 1, f0), y1)])
			var lit := base.lightened(0.18 + 0.06 * sin(f * 1.7))
			var dark := base.darkened(0.55)
			var cols := PackedColorArray([dark, lit, lit, dark]) if dir > 0 else PackedColorArray([lit, dark, dark, lit])
			ci.draw_polygon(quad, cols)
	# Gilt tie-back cord with a tassel
	var tx: float = x_at.call(1, 1.0)
	var tie_a := Vector2(wall_x, tie_y)
	var tie_b := Vector2(tx, tie_y)
	ci.draw_line(tie_a + Vector2(0, -4), tie_b + Vector2(dir * 6.0, 0), UIKit.GOLD.darkened(0.15), 6.0, true)
	ci.draw_line(tie_a + Vector2(0, -5), tie_b + Vector2(dir * 6.0, -1), UIKit.GOLD_LIGHT, 1.5, true)
	var tassel := tie_b + Vector2(dir * 4.0, 8)
	ci.draw_circle(tassel, 6, UIKit.GOLD)
	for i in 7:
		ci.draw_line(tassel + Vector2(-5 + i * 1.6, 4), tassel + Vector2(-6 + i * 2.0, 30), UIKit.GOLD.darkened(0.1 + 0.05 * (i % 2)), 1.5)
	# Floor puddle of fabric
	ci.draw_colored_polygon(DecorArt.ellipse_pts(Vector2(wall_x + dir * w * 0.42, bottom - 2), w * 0.5, 9), base.darkened(0.35))


func _pelmet(ci: CanvasItem, p: Rect2) -> void:
	var burg := Color(0.38, 0.06, 0.08)
	UIKit.vgrad(ci, Rect2(p.position, Vector2(p.size.x, p.size.y * 0.6)), burg.lightened(0.1), burg.darkened(0.3))
	# Scalloped lower edge
	var n := 7
	var sw := p.size.x / n
	for i in n:
		var c := Vector2(p.position.x + (i + 0.5) * sw, p.position.y + p.size.y * 0.6)
		var pts := PackedVector2Array([c + Vector2(-sw * 0.5, 0)])
		for k in 9:
			var a := PI * k / 8.0
			pts.append(c + Vector2(-cos(a) * sw * 0.5, sin(a) * p.size.y * 0.4))
		pts.append(c + Vector2(sw * 0.5, 0))
		ci.draw_colored_polygon(pts, burg.darkened(0.15))
		# Fringe
		for k in 12:
			var a := PI * (k + 0.5) / 12.0
			var q := c + Vector2(-cos(a) * sw * 0.48, sin(a) * p.size.y * 0.38)
			ci.draw_line(q, q + Vector2(0, 12), UIKit.GOLD.darkened(0.15 * (k % 2)), 1.6)
	# Braid along the top and a gilt pole-end at each side
	ci.draw_rect(Rect2(p.position.x, p.position.y + 10, p.size.x, 5), UIKit.GOLD.darkened(0.2))
	ci.draw_line(Vector2(p.position.x, p.position.y + 11), Vector2(p.end.x, p.position.y + 11), UIKit.GOLD_LIGHT, 1.0)
	ci.draw_rect(Rect2(p.position.x - 14, p.position.y - 4, p.size.x + 28, 10), Color(0.25, 0.13, 0.06))
	for x in [p.position.x - 16, p.end.x + 16]:
		DecorArt.sphere(ci, Vector2(x, p.position.y + 1), 9, UIKit.GOLD, 0.7)
