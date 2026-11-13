class_name RoomFurniture
extends Node2D
## The oxblood wingback and the lamp table. (Marmalade the cat is her own
## node now: see ParlourCat.)

const L = preload("res://scripts/art/room_layout.gd")

var lamp_glows: Array[LightGlow] = []


func _ready() -> void:
	add_child(Painter.new(_paint_static))
	var shade := LightGlow.new(Color(1.0, 0.72, 0.4), 0.7, 150.0, 0.05)
	shade.position = L.LAMP_GLOW
	add_child(shade)
	var pool := LightGlow.new(Color(1.0, 0.7, 0.4), 0.35, 420.0, 0.05)
	pool.position = L.LAMP_GLOW + Vector2(-60, 120)
	add_child(pool)
	lamp_glows = [shade, pool]


func set_lamp_lit(on: bool) -> void:
	for g in lamp_glows:
		g.dim = 1.0 if on else 0.0
	_lamp_on = on
	get_child(0).queue_redraw()


var _lamp_on := true


func _paint_static(ci: CanvasItem) -> void:
	_armchair(ci)
	_side_table(ci)


func _armchair(ci: CanvasItem) -> void:
	var leather := Color(0.36, 0.08, 0.06)
	var hi := leather.lightened(0.22)
	var dk := leather.darkened(0.55)
	var a := L.ARMCHAIR
	var ox := a.position.x
	var oy := a.position.y
	# Shadow on the floor
	ci.draw_colored_polygon(DecorArt.ellipse_pts(Vector2(ox + 170, oy + 352), 190, 22), Color(0, 0, 0, 0.45))
	# Back with a rounded crest
	var back := PackedVector2Array()
	back.append(Vector2(ox + 60, oy + 230))
	for i in 15:
		var t := float(i) / 14.0
		back.append(Vector2(ox + 60 + t * 220, oy + 30 - sin(t * PI) * 26))
	back.append(Vector2(ox + 280, oy + 230))
	ci.draw_polygon(back, _shade_cols(back.size(), hi, dk))
	# Deep-buttoned tufting
	for row in 4:
		for col in 5:
			var p := Vector2(ox + 88 + col * 40 + (20 if row % 2 == 1 else 0), oy + 60 + row * 38)
			if p.x > ox + 268:
				continue
			ci.draw_circle(p, 3.2, dk)
			ci.draw_line(p, p + Vector2(20, 19), Color(dk, 0.6), 1.5)
			ci.draw_line(p, p + Vector2(-20, 19), Color(dk, 0.6), 1.5)
			ci.draw_circle(p + Vector2(-1, -1), 1.2, Color(1, 0.8, 0.7, 0.3))
	# Wings
	for side in [-1.0, 1.0]:
		var wx := ox + (60.0 if side < 0 else 280.0)
		var wing := PackedVector2Array([Vector2(wx, oy + 40), Vector2(wx + side * 40, oy + 70), Vector2(wx + side * 46, oy + 200), Vector2(wx, oy + 230)])
		ci.draw_colored_polygon(wing, leather.darkened(0.15 if side < 0 else 0.35))
		ci.draw_line(Vector2(wx, oy + 40), Vector2(wx + side * 40, oy + 70), Color(hi, 0.6), 2.0)
	# Seat cushion
	var seat := Rect2(ox + 40, oy + 222, 260, 46)
	UIKit.vgrad(ci, seat, hi, leather.darkened(0.2))
	ci.draw_line(seat.position + Vector2(8, 6), Vector2(seat.end.x - 8, seat.position.y + 6), Color(1, 0.8, 0.7, 0.25), 2.0)
	# Rolled arms
	for side in [-1.0, 1.0]:
		var ax := ox + (14.0 if side < 0 else 286.0)
		var arm := Rect2(ax, oy + 190, 46, 120)
		UIKit.hgrad(ci, arm, hi if side < 0 else leather, dk)
		ci.draw_colored_polygon(DecorArt.ellipse_pts(Vector2(ax + 23, oy + 196), 30, 18), hi if side < 0 else leather.lightened(0.05))
		ci.draw_arc(Vector2(ax + 23, oy + 196), 14, 0, TAU, 18, Color(dk, 0.7), 2.0, true)
		for k in 8:
			ci.draw_circle(Vector2(ax + 4 + k * 5.5, oy + 214), 1.6, UIKit.GOLD.darkened(0.2))
	# Front apron and turned legs
	var apron := Rect2(ox + 40, oy + 268, 260, 56)
	UIKit.vgrad(ci, apron, leather, dk)
	for k in 30:
		ci.draw_circle(Vector2(apron.position.x + 4 + k * 8.6, apron.position.y + 6), 1.6, UIKit.GOLD.darkened(0.25))
	for lx in [ox + 30.0, ox + 300.0]:
		UIKit.hgrad(ci, Rect2(lx, oy + 310, 16, 40), Color(0.32, 0.15, 0.07), Color(0.1, 0.05, 0.02))
		DecorArt.sphere(ci, Vector2(lx + 8, oy + 350), 6, UIKit.GOLD_DARK, 0.4)
	# A tartan throw over the right arm and a velvet cushion
	var throw := PackedVector2Array([Vector2(ox + 262, oy + 176), Vector2(ox + 340, oy + 186), Vector2(ox + 334, oy + 330), Vector2(ox + 292, oy + 344), Vector2(ox + 270, oy + 300)])
	ci.draw_colored_polygon(throw, Color(0.12, 0.24, 0.17))
	for k in 6:
		ci.draw_line(Vector2(ox + 270 + k * 12, oy + 180), Vector2(ox + 274 + k * 11, oy + 336), Color(0.6, 0.1, 0.1, 0.55), 3.0)
		ci.draw_line(Vector2(ox + 266, oy + 200 + k * 24), Vector2(ox + 336, oy + 204 + k * 24), Color(0.85, 0.75, 0.3, 0.3), 1.5)
	for k in 7:
		ci.draw_line(Vector2(ox + 292 + k * 6, oy + 342 - k * 2), Vector2(ox + 292 + k * 6, oy + 356 - k * 2), Color(0.12, 0.24, 0.17), 2.0)
	var cush := DecorArt.ellipse_pts(Vector2(ox + 110, oy + 208), 52, 30, 24, -0.2)
	ci.draw_colored_polygon(cush, Color(0.62, 0.48, 0.18))
	ci.draw_colored_polygon(DecorArt.ellipse_pts(Vector2(ox + 104, oy + 202), 34, 18, 20, -0.2), Color(0.72, 0.58, 0.26))
	ci.draw_circle(Vector2(ox + 110, oy + 208), 4, Color(0.4, 0.28, 0.08))


func _shade_cols(n: int, a: Color, b: Color) -> PackedColorArray:
	var c := PackedColorArray()
	for i in n:
		c.append(a.lerp(b, float(i) / maxf(1.0, n - 1)))
	return c


func _side_table(ci: CanvasItem) -> void:
	var c := L.SIDE_TABLE
	var mah := Color(0.28, 0.12, 0.06)
	ci.draw_colored_polygon(DecorArt.ellipse_pts(Vector2(c.x, L.FLOOR_Y + 70), 60, 9), Color(0, 0, 0, 0.4))
	# Pedestal and tripod feet
	UIKit.hgrad(ci, Rect2(c.x - 9, c.y + 14, 18, 150), mah.lightened(0.15), mah.darkened(0.5))
	for k in 3:
		var dir := [-1.0, 0.0, 1.0][k] as float
		ci.draw_line(Vector2(c.x, c.y + 150), Vector2(c.x + dir * 46, c.y + 186 - absf(dir) * 4), mah.darkened(0.2), 7.0, true)
	# Top with a lace doily
	ci.draw_colored_polygon(DecorArt.ellipse_pts(c + Vector2(0, 8), 64, 15), mah.darkened(0.4))
	ci.draw_colored_polygon(DecorArt.ellipse_pts(c, 64, 15), mah.lightened(0.12))
	ci.draw_colored_polygon(DecorArt.ellipse_pts(c, 44, 10), Color(0.93, 0.9, 0.82))
	for i in 20:
		var a := TAU * i / 20.0
		ci.draw_circle(c + Vector2(cos(a) * 44, sin(a) * 10), 2.5, Color(0.93, 0.9, 0.82))
	# The lamp: brass column and a fringed silk shade
	var lamp_base := c + Vector2(4, -2)
	ci.draw_colored_polygon(DecorArt.ellipse_pts(lamp_base, 18, 5), UIKit.GOLD_DARK)
	UIKit.hgrad(ci, Rect2(lamp_base.x - 5, lamp_base.y - 88, 10, 86), UIKit.GOLD_LIGHT, UIKit.GOLD_DARK)
	DecorArt.sphere(ci, lamp_base + Vector2(0, -46), 11, UIKit.GOLD, 0.7)
	var sh_top := lamp_base.y - 140
	var shade := PackedVector2Array([Vector2(lamp_base.x - 34, sh_top), Vector2(lamp_base.x + 34, sh_top), Vector2(lamp_base.x + 62, sh_top + 54), Vector2(lamp_base.x - 62, sh_top + 54)])
	var lit := Color(1.0, 0.78, 0.48) if _lamp_on else Color(0.55, 0.3, 0.2)
	var edge := Color(0.85, 0.45, 0.25) if _lamp_on else Color(0.35, 0.15, 0.1)
	ci.draw_polygon(shade, PackedColorArray([edge, lit, lit, edge]))
	for k in 25:
		var x := lamp_base.x - 60 + k * 5.0
		ci.draw_line(Vector2(x, sh_top + 54), Vector2(x, sh_top + 68), Color(0.7, 0.3, 0.15), 1.5)
		ci.draw_circle(Vector2(x, sh_top + 69), 1.6, UIKit.GOLD)
	ci.draw_line(Vector2(lamp_base.x - 62, sh_top + 54), Vector2(lamp_base.x + 62, sh_top + 54), UIKit.GOLD, 2.0)
	# A book and a teacup
	ci.draw_rect(Rect2(c.x - 50, c.y - 10, 36, 9), Color(0.15, 0.22, 0.35))
	ci.draw_rect(Rect2(c.x - 50, c.y - 10, 36, 2), UIKit.GOLD)
	ci.draw_colored_polygon(DecorArt.ellipse_pts(c + Vector2(38, 2), 13, 4), Color(0.95, 0.94, 0.9))
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(30, -12), c + Vector2(46, -12), c + Vector2(43, -1), c + Vector2(33, -1)]), Color(0.96, 0.95, 0.92))
	ci.draw_arc(c + Vector2(48, -7), 4, -PI * 0.5, PI * 0.5, 8, Color(0.96, 0.95, 0.92), 2.0)
	ci.draw_line(c + Vector2(31, -10), c + Vector2(45, -10), Color(0.2, 0.4, 0.6), 1.5)


static func paint_tree_stand(ci: CanvasItem, base: Vector2) -> void:
	## A brass urn on a linen tree skirt. Drawn in front of the trunk.
	var skirt_c := base + Vector2(0, 40)
	ci.draw_colored_polygon(DecorArt.ellipse_pts(skirt_c + Vector2(6, 6), 250, 40, 40), Color(0, 0, 0, 0.35))
	var skirt := DecorArt.ellipse_pts(skirt_c, 240, 36, 40)
	ci.draw_colored_polygon(skirt, Color(0.88, 0.84, 0.74))
	var edge := PackedVector2Array()
	for p in skirt:
		edge.append(skirt_c + (p - skirt_c) * 0.93)
	edge.append(edge[0])
	ci.draw_polyline(edge, Color(0.6, 0.08, 0.1), 5.0, true)
	for i in 12:
		var a := TAU * i / 12.0 + 0.2
		ci.draw_line(skirt_c + Vector2(cos(a) * 70, sin(a) * 12), skirt_c + Vector2(cos(a) * 225, sin(a) * 33), Color(0.6, 0.55, 0.45, 0.35), 2.0)
	# Brass urn
	var top_y := base.y - 18
	var body := PackedVector2Array([Vector2(base.x - 74, top_y), Vector2(base.x + 74, top_y), Vector2(base.x + 56, base.y + 46), Vector2(base.x - 56, base.y + 46)])
	ci.draw_polygon(body, PackedColorArray([UIKit.GOLD_LIGHT, UIKit.GOLD_DARK.darkened(0.2), UIKit.GOLD_DARK.darkened(0.4), UIKit.GOLD]))
	for k in 3:
		var y := top_y + 14 + k * 20.0
		var hw := lerpf(74.0, 56.0, (y - top_y) / 64.0)
		ci.draw_line(Vector2(base.x - hw, y), Vector2(base.x + hw, y), Color(0.35, 0.22, 0.06, 0.8), 2.0)
	for k in 7:
		var x := base.x - 48 + k * 16.0
		ci.draw_arc(Vector2(x, top_y + 34), 6, 0, TAU, 10, Color(UIKit.GOLD_LIGHT, 0.5), 1.2, true)
	ci.draw_colored_polygon(DecorArt.ellipse_pts(Vector2(base.x, top_y), 76, 11), UIKit.GOLD)
	ci.draw_colored_polygon(DecorArt.ellipse_pts(Vector2(base.x, top_y), 66, 8), Color(0.12, 0.08, 0.05))
	# Earth and moss packed round the trunk, and the trunk going down into it
	# (the urn is drawn over the tree, so the trunk is repeated here).
	ci.draw_colored_polygon(DecorArt.ellipse_pts(Vector2(base.x, top_y + 1), 62, 6.5), Color(0.2, 0.13, 0.07))
	for k in 9:
		var mx := base.x - 50.0 + k * 12.5
		ci.draw_circle(Vector2(mx, top_y + 1.0 + sin(k * 1.7) * 2.0), 3.2, Color(0.22, 0.3, 0.12, 0.8))
	var tw := TreeArt.trunk_half_width(L.TREE_WIDTH)
	var trunk_col := Color(0.22, 0.12, 0.06)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(base.x - tw, top_y + 3), Vector2(base.x + tw, top_y + 3),
			Vector2(base.x + tw * 0.97, top_y - 10), Vector2(base.x - tw * 0.97, top_y - 10)]), trunk_col)
	ci.draw_colored_polygon(DecorArt.ellipse_pts(Vector2(base.x, top_y + 3), tw + 5, 3.5), Color(0.16, 0.1, 0.05))
	ci.draw_line(Vector2(base.x - tw * 0.4, top_y + 2), Vector2(base.x - tw * 0.38, top_y - 10), Color(1, 0.9, 0.7, 0.12), 2.0)
	# Lion-ring handles
	for side in [-1.0, 1.0]:
		ci.draw_arc(Vector2(base.x + side * 66, top_y + 26), 9, 0, TAU, 14, UIKit.GOLD_LIGHT, 2.5, true)
		ci.draw_circle(Vector2(base.x + side * 66, top_y + 16), 5, UIKit.GOLD_DARK)
	ci.draw_line(Vector2(base.x - 60, top_y + 4), Vector2(base.x - 40, base.y + 40), Color(1, 1, 0.9, 0.35), 3.0)
