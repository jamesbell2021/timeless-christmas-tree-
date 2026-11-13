class_name TreeArt
extends Node2D
## TreeArt — a procedurally grown fir.
##
## The tree is built once from a seed into three batches of needle strokes
## (back / middle / front boughs) and drawn with draw_multiline_colors, which
## is one draw call per batch. Godot caches the canvas commands, so after
## generation the tree costs almost nothing per frame.
##
## Origin (0, 0) is the base of the trunk; the apex is at (0, -height).
## The same generator draws the seedling, the sapling and the parlour tree.

@export var height := 760.0
@export var width := 560.0
@export var seed_value := 1901
@export var palette := "parlour"   # parlour | spring | summer | autumn | winter | dusk
@export_range(0.0, 1.0) var snow := 0.0
@export_range(0.2, 1.5) var detail := 1.0
@export var show_trunk := true

var silhouette := PackedVector2Array()
var apex := Vector2.ZERO

var _batches: Array = []          # [{points, colors, width}]
var _shadow := PackedVector2Array()
var _snow_dots: Array = []        # [Vector2, radius]
var _pal: Dictionary = {}


const PALETTES := {
	"parlour": {"shadow": Color(0.02, 0.06, 0.035, 0.92), "dark": Color(0.04, 0.13, 0.07), "mid": Color(0.1, 0.27, 0.13),
		"light": Color(0.26, 0.44, 0.2), "warm": Color(0.55, 0.47, 0.2), "cool": Color(0.25, 0.4, 0.45), "trunk": Color(0.22, 0.12, 0.06)},
	"spring": {"shadow": Color(0.1, 0.22, 0.12, 0.7), "dark": Color(0.13, 0.3, 0.16), "mid": Color(0.25, 0.48, 0.24),
		"light": Color(0.55, 0.75, 0.38), "warm": Color(0.75, 0.8, 0.45), "cool": Color(0.3, 0.5, 0.45), "trunk": Color(0.35, 0.24, 0.15)},
	"summer": {"shadow": Color(0.08, 0.2, 0.1, 0.75), "dark": Color(0.1, 0.27, 0.13), "mid": Color(0.2, 0.42, 0.18),
		"light": Color(0.45, 0.62, 0.25), "warm": Color(0.78, 0.72, 0.35), "cool": Color(0.25, 0.42, 0.4), "trunk": Color(0.33, 0.22, 0.13)},
	"autumn": {"shadow": Color(0.08, 0.16, 0.08, 0.75), "dark": Color(0.1, 0.22, 0.11), "mid": Color(0.2, 0.36, 0.16),
		"light": Color(0.42, 0.52, 0.22), "warm": Color(0.75, 0.55, 0.25), "cool": Color(0.28, 0.38, 0.33), "trunk": Color(0.3, 0.2, 0.12)},
	"winter": {"shadow": Color(0.06, 0.14, 0.12, 0.8), "dark": Color(0.08, 0.2, 0.15), "mid": Color(0.15, 0.32, 0.24),
		"light": Color(0.32, 0.48, 0.4), "warm": Color(0.5, 0.55, 0.5), "cool": Color(0.4, 0.55, 0.62), "trunk": Color(0.26, 0.2, 0.16)},
	"dusk": {"shadow": Color(0.03, 0.07, 0.1, 0.85), "dark": Color(0.05, 0.12, 0.13), "mid": Color(0.1, 0.22, 0.2),
		"light": Color(0.22, 0.36, 0.34), "warm": Color(0.6, 0.48, 0.3), "cool": Color(0.32, 0.42, 0.55), "trunk": Color(0.16, 0.12, 0.12)},
}


func _ready() -> void:
	if _batches.is_empty():
		generate()


func generate() -> void:
	_pal = PALETTES.get(palette, PALETTES["parlour"])
	_batches.clear()
	_snow_dots.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var batch_back := {"points": PackedVector2Array(), "colors": PackedColorArray(), "width": 3.0}
	var batch_mid := {"points": PackedVector2Array(), "colors": PackedColorArray(), "width": 2.5}
	var batch_front := {"points": PackedVector2Array(), "colors": PackedColorArray(), "width": 2.0}
	var batch_snow := {"points": PackedVector2Array(), "colors": PackedColorArray(), "width": 2.5}

	var crown_top := -height
	var crown_len := height * 0.88
	var whorls := maxi(3, int(height / 34.0))
	var branches: Array = []
	var left_tips: Array = []
	var right_tips: Array = []

	for w in whorls:
		var t := (w + 0.6) / float(whorls)
		var y0 := crown_top + t * crown_len + rng.randf_range(-3.0, 3.0)
		var reach := width * 0.5 * pow(t, 0.85) * rng.randf_range(0.9, 1.05) + height * 0.02
		var per_side := 3 + int(t * 4.0 * detail)
		var lmost := Vector2(0, y0)
		var rmost := Vector2(0, y0)
		for side in [-1.0, 1.0]:
			for k in per_side:
				var depth := (k + rng.randf_range(0.0, 0.9)) / float(per_side)
				var length := reach * lerpf(0.55, 1.0, rng.randf()) * (0.75 + 0.25 * depth)
				var droop := 0.22 + t * 0.28 + rng.randf_range(-0.06, 0.08)
				var b := {"start": Vector2(side * rng.randf_range(0.0, 4.0), y0 + rng.randf_range(-6, 6)),
					"side": side, "len": length, "droop": droop, "depth": depth, "t": t,
					"seed": rng.randi()}
				branches.append(b)
				var tip := _branch_point(b, 1.0)
				if side < 0 and tip.x < lmost.x:
					lmost = tip
				if side > 0 and tip.x > rmost.x:
					rmost = tip
		left_tips.append(lmost)
		right_tips.append(rmost)

	# Back boughs first, front last.
	branches.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["depth"] < b["depth"])

	# Leader at the very top
	var leader := {"start": Vector2(0, crown_top + height * 0.12), "side": 0.0, "len": height * 0.12, "droop": -10.0,
		"depth": 0.8, "t": 0.0, "seed": 7, "leader": true}
	branches.append(leader)

	for b in branches:
		var batch: Dictionary = batch_back
		if b["depth"] > 0.66:
			batch = batch_front
		elif b["depth"] > 0.33:
			batch = batch_mid
		_grow_branch(b, batch, batch_snow, rng)

	_batches = [batch_back, batch_mid, batch_front]
	if snow > 0.0:
		_batches.append(batch_snow)

	# Silhouette (for decoration hit-testing) and the inner shadow mass.
	apex = Vector2(0, crown_top)
	silhouette = PackedVector2Array([apex])
	for p in right_tips:
		silhouette.append(p)
	for i in range(left_tips.size() - 1, -1, -1):
		silhouette.append(left_tips[i])
	_shadow = PackedVector2Array()
	for p in silhouette:
		_shadow.append(Vector2(p.x * 0.8, lerpf(p.y, -height * 0.5, 0.06)))
	queue_redraw()


static func trunk_half_width(tree_width: float) -> float:
	return maxf(4.0, tree_width * 0.035)


func _branch_point(b: Dictionary, s: float) -> Vector2:
	if b.get("leader", false):
		return b["start"] + Vector2(0, -b["len"] * s)
	var L: float = b["len"]
	var side: float = b["side"]
	var dir := Vector2(side, b["droop"]).normalized()
	# Fir boughs sag in the middle and lift a little at the tips.
	var p: Vector2 = b["start"] + dir * L * s
	p.y += sin(s * PI) * L * 0.06 - s * s * L * 0.08
	return p


func _grow_branch(b: Dictionary, batch: Dictionary, snow_batch: Dictionary, rng: RandomNumberGenerator) -> void:
	var L: float = b["len"]
	var depth: float = b["depth"]
	var side: float = b["side"]
	var step := 3.2 / detail
	var n := maxi(3, int(L / step))
	var dark: Color = _pal["dark"]
	var mid: Color = _pal["mid"]
	var light: Color = _pal["light"]
	var warm: Color = _pal["warm"]
	var cool: Color = _pal["cool"]
	# Take sole ownership of the packed arrays while appending (avoids
	# copy-on-write duplicating the whole batch on every append).
	var pts: PackedVector2Array = batch["points"]
	var cols: PackedColorArray = batch["colors"]
	batch["points"] = PackedVector2Array()
	batch["colors"] = PackedColorArray()
	var sp: PackedVector2Array = snow_batch["points"]
	var sc: PackedColorArray = snow_batch["colors"]
	snow_batch["points"] = PackedVector2Array()
	snow_batch["colors"] = PackedColorArray()
	# The branch stem itself
	var prev := _branch_point(b, 0.0)
	for i in range(1, n + 1):
		var s := float(i) / n
		var p := _branch_point(b, s)
		pts.append(prev)
		pts.append(p)
		var stem_col: Color = (_pal["trunk"] as Color).lerp(dark, 0.5)
		cols.append(stem_col)
		var tangent := (p - prev).normalized()
		prev = p
		# Needles: denser and longer mid-branch, fresh and pale at the tips
		var needle_len := lerpf(9.0, 6.0, s) * (0.8 + depth * 0.3) * clampf(height / 700.0, 0.35, 1.2) + 2.0
		var count := 3 if s < 0.9 else 2
		for k in count:
			var spread := rng.randf_range(0.45, 1.35) * (1.0 if k % 2 == 0 else -1.0)
			var ang := tangent.angle() + spread + 0.25 * side
			var q := p + Vector2(cos(ang), sin(ang)) * needle_len * rng.randf_range(0.75, 1.15)
			var base_col := dark.lerp(mid, depth).lerp(light, s * s * (0.4 + depth * 0.6))
			# Firelight from the left, cool window light from behind/right
			var lx := clampf(-q.x / (width * 0.5), -1.0, 1.0)
			if lx > 0.0:
				base_col = base_col.lerp(warm, lx * 0.22 * depth)
			else:
				base_col = base_col.lerp(cool, -lx * 0.12)
			# Needles pointing up catch more light
			if sin(ang) < -0.3:
				base_col = base_col.lightened(0.08)
			base_col = base_col.lightened(rng.randf_range(-0.06, 0.06))
			pts.append(p)
			pts.append(q)
			cols.append(base_col)
		# Side twigs
		if not b.get("leader", false) and i % int(maxf(2.0, 14.0 / step)) == 0 and s > 0.15 and s < 0.92:
			var tw_len := L * (1.0 - s) * rng.randf_range(0.18, 0.32)
			var tw_ang := tangent.angle() + rng.randf_range(0.5, 0.9) * (1.0 if rng.randf() < 0.5 else -1.0)
			var tn := maxi(2, int(tw_len / step))
			for j in range(1, tn + 1):
				var u := float(j) / tn
				var tp := p + Vector2(cos(tw_ang), sin(tw_ang)) * tw_len * u
				for k2 in 2:
					var a2 := tw_ang + (0.9 if k2 == 0 else -0.9) + rng.randf_range(-0.3, 0.3)
					var q2 := tp + Vector2(cos(a2), sin(a2)) * needle_len * 0.8
					var c2 := dark.lerp(mid, depth).lerp(light, u * 0.35 + s * 0.3).lightened(rng.randf_range(-0.05, 0.05))
					pts.append(tp)
					pts.append(q2)
					cols.append(c2)
		# Snow sits on the upper side of boughs
		if snow > 0.0 and depth > 0.25 and rng.randf() < snow * 0.55:
			var up := Vector2(0, -2.5)
			sp.append(p + up - tangent * 4.0)
			sp.append(p + up + tangent * 4.0)
			var scol := Color(0.93, 0.95, 1.0).lerp(Color(0.75, 0.82, 0.95), 1.0 - depth)
			sc.append(scol)
			if rng.randf() < 0.18:
				_snow_dots.append([p + Vector2(0, -3), rng.randf_range(2.0, 4.0) * clampf(height / 600.0, 0.4, 1.2), scol])
	batch["points"] = pts
	batch["colors"] = cols
	snow_batch["points"] = sp
	snow_batch["colors"] = sc


func _draw() -> void:
	var tw := trunk_half_width(width)
	var trunk_col: Color = _pal.get("trunk", Color(0.2, 0.1, 0.05))
	if show_trunk:
		var trunk := PackedVector2Array([Vector2(-tw, 0), Vector2(tw, 0), Vector2(tw * 0.5, -height * 0.6), Vector2(-tw * 0.5, -height * 0.6)])
		draw_colored_polygon(trunk, trunk_col)
		draw_line(Vector2(-tw * 0.4, 0), Vector2(-tw * 0.2, -height * 0.5), Color(1, 0.9, 0.7, 0.12), 2.0)
	if _shadow.size() >= 3:
		draw_colored_polygon(_shadow, _pal.get("shadow", Color(0, 0.05, 0.02, 0.9)))
	if show_trunk:
		# The foot of the trunk again, over the inner shadow, so it shows in
		# the gap under the lowest boughs (higher up the shadow keeps it hidden).
		var h := height * 0.13
		var k := 1.0 - 0.5 * (h / (height * 0.6))
		draw_colored_polygon(PackedVector2Array([Vector2(-tw, 0), Vector2(tw, 0), Vector2(tw * k, -h), Vector2(-tw * k, -h)]), trunk_col)
		draw_line(Vector2(-tw * 0.4, 0), Vector2(-tw * 0.37, -h), Color(1, 0.9, 0.7, 0.12), 2.0)
	for b in _batches:
		var p: PackedVector2Array = b["points"]
		if p.size() >= 2:
			draw_multiline_colors(p, b["colors"], b["width"])
	for d in _snow_dots:
		draw_circle(d[0], d[1], d[2])


# ------------------------------------------------------------- hit testing

func contains_local(p: Vector2, inset: float = 0.0) -> bool:
	if silhouette.size() < 3:
		return false
	if inset <= 0.0:
		return Geometry2D.is_point_in_polygon(p, silhouette)
	# Approximate inset by scaling the polygon towards the trunk axis.
	var shrunk := PackedVector2Array()
	for q in silhouette:
		var k := maxf(0.0, 1.0 - inset / maxf(1.0, absf(q.x) + inset))
		shrunk.append(Vector2(q.x * k, q.y + (inset * 0.6 if q == apex else 0.0)))
	return Geometry2D.is_point_in_polygon(p, shrunk)


func half_width_at(y_local: float) -> float:
	## Horizontal half-width of the silhouette at a given local y.
	var best := 0.0
	var n := silhouette.size()
	for i in n:
		var a := silhouette[i]
		var b := silhouette[(i + 1) % n]
		if (a.y - y_local) * (b.y - y_local) <= 0.0 and absf(b.y - a.y) > 0.001:
			var t := (y_local - a.y) / (b.y - a.y)
			best = maxf(best, absf(lerpf(a.x, b.x, t)))
	return best
