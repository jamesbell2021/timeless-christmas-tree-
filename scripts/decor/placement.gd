class_name Placement
extends RefCounted
## Placement — the rules for where each kind of decoration may go.
## Pure functions: given an item, a pointer position and the scene state, say
## whether a drop is valid, where it snaps and which layer it belongs to.
##
## Keeping this logic free of nodes makes it trivially unit-testable
## (see tests/test_runner.gd).

const L = preload("res://scripts/art/room_layout.gd")


static func resolve(d: Dictionary, p: Vector2, tree: TreeArt, used_hooks: Array, has_topper: bool, has_mantel: bool) -> Dictionary:
	var res := {"ok": false, "pos": p, "layer": "", "snap": false, "replace": false}
	var tree_local := p - tree.position
	match d.get("kind", ""):
		"hang", "clip":
			if tree.contains_local(tree_local, 8.0) and tree_local.y > tree.apex.y + 34.0:
				res["ok"] = true
				res["layer"] = "ornament"
		"topper":
			var apex_w := tree.position + tree.apex
			if p.distance_to(apex_w) < 150.0:
				res["ok"] = true
				res["pos"] = apex_w + Vector2(0, 8)
				res["layer"] = "topper"
				res["snap"] = true
				res["replace"] = has_topper
		"garland":
			if tree.contains_local(tree_local, 0.0) and tree_local.y > tree.apex.y + 70.0:
				res["ok"] = true
				res["layer"] = "garland"
		"room":
			_resolve_room(d, p, tree, used_hooks, has_mantel, res)
	return res


static func _resolve_room(d: Dictionary, p: Vector2, tree: TreeArt, used_hooks: Array, has_mantel: bool, res: Dictionary) -> void:
	var tree_local := p - tree.position
	var on_tree := tree.contains_local(tree_local, -6.0)
	match d.get("zone", ""):
		"mantel_garland":
			var zone := Rect2(L.MANTEL_X0 - 40, L.MANTEL_Y - 90, L.MANTEL_X1 - L.MANTEL_X0 + 80, 210)
			if zone.has_point(p) and not has_mantel:
				res["ok"] = true
				res["pos"] = Vector2(L.CLOCK_X, L.MANTEL_Y + 22)
				res["layer"] = "room"
				res["snap"] = true
		"hooks":
			var best := -1
			var best_d := 170.0
			for i in L.STOCKING_HOOKS.size():
				if i in used_hooks:
					continue
				var dd: float = p.distance_to(L.STOCKING_HOOKS[i])
				if dd < best_d:
					best_d = dd
					best = i
			if best >= 0:
				res["ok"] = true
				res["pos"] = L.STOCKING_HOOKS[best]
				res["layer"] = "room"
				res["snap"] = true
				res["hook"] = best
		"floor":
			if L.FLOOR_ZONE.has_point(p) and not L.FLOOR_EXCLUDE.has_point(p):
				res["ok"] = true
				res["layer"] = "floor"
		"surface":
			for s in L.SURFACES:
				if p.x >= s[0] and p.x <= s[1] and absf(p.y - s[2]) < 90.0:
					var x := p.x
					# Keep clear of the mantel clock
					if s[2] == L.MANTEL_Y and absf(x - L.CLOCK_X) < 60.0:
						continue
					res["ok"] = true
					res["pos"] = Vector2(x, s[2])
					res["layer"] = "room"
					res["snap"] = true
					break
		"wall":
			if L.WALL_ZONE.has_point(p) and not on_tree and not L.FIREBOX.grow(20).has_point(p):
				res["ok"] = true
				res["layer"] = "room"
		"ceiling":
			if L.CEILING_ZONE.has_point(p) and not on_tree:
				res["ok"] = true
				res["layer"] = "room"


static func garland_ends(p: Vector2, tree: TreeArt) -> Array:
	## Default swag for a garland dropped at p: across the tree at that height,
	## the left end a little higher so it reads as a hand-hung drape.
	var local := p - tree.position
	var hw := tree.half_width_at(local.y) * 0.86
	hw = maxf(hw, 40.0)
	var a := Vector2(tree.position.x - hw, p.y - 16.0)
	var b := Vector2(tree.position.x + hw, p.y + 16.0)
	return [a, b]


static func clamp_garland_end(p: Vector2, tree: TreeArt) -> Vector2:
	## Keeps a dragged garland end on (or just at the edge of) the tree.
	var local := p - tree.position
	local.y = clampf(local.y, tree.apex.y + 40.0, -20.0)
	var hw := tree.half_width_at(local.y) + 6.0
	local.x = clampf(local.x, -hw, hw)
	return tree.position + local


static func is_behind_tree(p: Vector2, tree: TreeArt) -> bool:
	## Floor items set behind the trunk line are drawn under the lowest boughs.
	return p.y < tree.position.y - 4.0 and absf(p.x - tree.position.x) < tree.half_width_at(-30.0) + 20.0
