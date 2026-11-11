class_name WinterClearing
extends Node2D
## The snowy clearing at dusk on Christmas Eve, 1901 — shared by Chapter III
## (the family arrives) and Chapter IV (they choose the tree). Builds the sky,
## hills, snow, the candidate firs and our tree, and exposes their positions.

const OUR_TREE := Vector2(1330, 880)
const SMALL_TREE := Vector2(560, 860)
const CROOKED_TREE := Vector2(900, 850)

var our_tree: TreeArt
var tree_glow: LightGlow
var snow: Snowfall


func _ready() -> void:
	add_child(Painter.new(_paint_backdrop))
	# Background firs
	for spec in [[150.0, 360.0, 200.0, 31], [1760.0, 840.0, 400.0, 32], [1620.0, 820.0, 300.0, 33], [300.0, 830.0, 330.0, 34]]:
		var t := TreeArt.new()
		t.position = Vector2(spec[0], spec[1])
		t.height = spec[2]
		t.width = spec[2] * 0.55
		t.seed_value = spec[3]
		t.palette = "dusk"
		t.snow = 0.8
		t.detail = 0.6
		t.modulate = Color(0.75, 0.8, 0.95)
		add_child(t)
	# The candidates
	var small := TreeArt.new()
	small.position = SMALL_TREE
	small.height = 190.0
	small.width = 120.0
	small.seed_value = 41
	small.palette = "dusk"
	small.snow = 0.9
	small.detail = 0.8
	add_child(small)
	var crooked := TreeArt.new()
	crooked.position = CROOKED_TREE
	crooked.height = 420.0
	crooked.width = 210.0
	crooked.seed_value = 42
	crooked.palette = "dusk"
	crooked.snow = 0.9
	crooked.detail = 0.8
	crooked.rotation = 0.16
	add_child(crooked)
	our_tree = TreeArt.new()
	our_tree.position = OUR_TREE
	our_tree.height = 560.0
	our_tree.width = 330.0
	our_tree.seed_value = 13
	our_tree.palette = "dusk"
	our_tree.snow = 0.85
	add_child(our_tree)
	tree_glow = LightGlow.new(Color(1.0, 0.75, 0.45), 0.0, 330.0, 0.2)
	tree_glow.position = OUR_TREE + Vector2(0, -260)
	add_child(tree_glow)
	add_child(Painter.new(_paint_foreground))
	snow = Snowfall.new()
	snow.count = 120
	snow.wind = 18.0
	add_child(snow)


func _paint_backdrop(ci: CanvasItem) -> void:
	# Blue hour: deep blue overhead, a rose and apricot glow on the horizon
	StoryScene.paint_sky(ci, Color(0.1, 0.13, 0.3), Color(0.38, 0.38, 0.58), Color(0.95, 0.72, 0.62), 700)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8
	for k in 70:
		var p := Vector2(rng.randf_range(0, 1920), rng.randf_range(0, 320))
		ci.draw_circle(p, rng.randf_range(0.8, 2.0), Color(1, 1, 0.95, rng.randf_range(0.3, 0.9)))
	# A thin new moon
	var m := Vector2(1560, 140)
	ci.draw_circle(m, 22, Color(1, 0.97, 0.85))
	ci.draw_circle(m + Vector2(8, -4), 20, Color(0.14, 0.17, 0.35))
	ci.draw_texture_rect(Tex.glow(), Rect2(m - Vector2(80, 80), Vector2(160, 160)), false, Color(1, 0.95, 0.8, 0.2))
	StoryScene.paint_hills(ci, 610, 80, Color(0.62, 0.6, 0.75), 0.7, 1.4)
	StoryScene.paint_hills(ci, 690, 45, Color(0.78, 0.78, 0.9), 2.2, 2.3)
	StoryScene.paint_fir_silhouettes(ci, 760, 110, 240, Color(0.2, 0.24, 0.36), Color(0.88, 0.9, 1.0, 0.85), 15, 64)
	# The family's sleigh waiting at the edge of the wood
	var sl := Vector2(150, 800)
	ci.draw_colored_polygon(PackedVector2Array([sl, sl + Vector2(110, 0), sl + Vector2(124, -38), sl + Vector2(10, -38)]), Color(0.42, 0.08, 0.1))
	ci.draw_line(sl + Vector2(-10, 10), sl + Vector2(140, 10), Color(0.75, 0.6, 0.3), 3.0)
	ci.draw_arc(sl + Vector2(140, 0), 10, -PI * 0.5, PI * 0.5, 8, Color(0.75, 0.6, 0.3), 3.0)
	ci.draw_colored_polygon(DecorArt.ellipse_pts(sl + Vector2(-40, -30), 34, 16), Color(0.3, 0.22, 0.18))
	ci.draw_line(sl + Vector2(-60, -24), sl + Vector2(-70, 10), Color(0.3, 0.22, 0.18), 5.0)
	ci.draw_line(sl + Vector2(-20, -24), sl + Vector2(-16, 10), Color(0.3, 0.22, 0.18), 5.0)
	ci.draw_line(sl + Vector2(-66, -38), sl + Vector2(-86, -66), Color(0.3, 0.22, 0.18), 9.0)
	ci.draw_circle(sl + Vector2(-90, -70), 9, Color(0.3, 0.22, 0.18))
	ci.draw_texture_rect(Tex.glow(), Rect2(sl + Vector2(90, -70), Vector2(50, 50)), false, Color(1, 0.7, 0.35, 0.6))
	# Snowfield of the clearing
	var g := PackedVector2Array([Vector2(0, 1080)])
	for i in 25:
		var x := i * 80.0
		g.append(Vector2(x, 800 + sin(x * 0.004 + 1.0) * 18))
	g.append(Vector2(1920, 1080))
	ci.draw_colored_polygon(g, Color(0.82, 0.85, 0.95))
	UIKit.vgrad(ci, Rect2(0, 820, 1920, 260), Color(0.9, 0.92, 1.0, 0.0), Color(0.62, 0.66, 0.82))
	# Warm horizon glow reflected on the snow
	UIKit.vgrad(ci, Rect2(0, 800, 1920, 70), Color(1.0, 0.8, 0.7, 0.25), Color(1.0, 0.8, 0.7, 0.0))


func _paint_foreground(ci: CanvasItem) -> void:
	# Drifts with blue shadows along the front
	for k in 6:
		var c := Vector2(k * 380.0 - 60, 1060 + (k % 2) * 20)
		ci.draw_colored_polygon(DecorArt.ellipse_pts(c, 260, 60), Color(0.93, 0.95, 1.0))
		ci.draw_colored_polygon(DecorArt.ellipse_pts(c + Vector2(30, 24), 230, 34), Color(0.7, 0.74, 0.9, 0.6))
	# Footprints wandering in from the left
	for k in 22:
		var x := -20.0 + k * 34.0
		var y := 905.0 + sin(k * 0.6) * 8.0 + (k % 2) * 10.0
		ci.draw_colored_polygon(DecorArt.ellipse_pts(Vector2(x, y), 7, 3), Color(0.6, 0.64, 0.8, 0.6))
