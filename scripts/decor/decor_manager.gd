class_name DecorManager
extends Node2D
## DecorManager — owns every placed decoration and all the hands-on
## interaction: dragging from the trunk, moving and removing ornaments,
## re-draping garlands, brushing through the boughs, undo and save data.
##
## Input model: a press on the trunk starts a drag via begin_new_drag();
## presses in the room arrive through _unhandled_input. While dragging we
## *poll* the pointer each frame, because the press may have begun on a UI
## Control that keeps receiving the motion events. Polling works the same
## for mouse and touch.

signal hint_changed(text: String, valid: bool)
signal hover_changed(text: String)
signal items_changed
signal drag_state_changed(dragging: bool)

const MAX_ITEMS := 400
const UNDO_DEPTH := 60

var tree: TreeArt
var trunk_rect_provider: Callable = func() -> Rect2: return Rect2()
var candles_lit := false
var enabled := true

var layer_room: Node2D
var layer_floor: Node2D
var layer_garland: Node2D
var layer_ornament: Node2D
var layer_topper: Node2D
var layer_drag: Node2D

var _items: Array[Node2D] = []
var _undo: Array = []

var _drag_node: Node2D = null
var _drag_def: Dictionary = {}
var _drag_from_trunk := false
var _drag_origin: Dictionary = {}
var _drag_offset := Vector2.ZERO
var _drag_garland: Garland = null
var _drag_garland_end := -1
var _last_res: Dictionary = {}
var _hover: Node2D = null
var _last_mouse := Vector2.ZERO
var _brush_cooldown := 0.0


func setup(p_tree: TreeArt) -> void:
	tree = p_tree
	layer_room = _make_layer("RoomDecor", 6)
	layer_floor = _make_layer("FloorDecor", 0)
	layer_floor.y_sort_enabled = true
	layer_garland = _make_layer("Garlands", 12)
	layer_ornament = _make_layer("Ornaments", 13)
	layer_topper = _make_layer("Topper", 14)
	layer_drag = _make_layer("Dragging", 70)


func _make_layer(n: String, z: int) -> Node2D:
	var l := Node2D.new()
	l.name = n
	l.z_index = z
	add_child(l)
	return l


# ============================================================ public API

func is_dragging() -> bool:
	return _drag_node != null or _drag_garland != null


func begin_new_drag(id: String) -> void:
	if not enabled or is_dragging():
		return
	var d := Catalogue.get_item(id)
	if d.is_empty():
		return
	if _items.size() >= MAX_ITEMS:
		hint_changed.emit("The tree can hold no more!", false)
		return
	_drag_def = d
	_drag_from_trunk = true
	_drag_origin = {}
	var ghost := Decoration.new().setup(d, {"id": id})
	ghost.position = get_global_mouse_position()
	layer_drag.add_child(ghost)
	_drag_node = ghost
	_drag_offset = Vector2.ZERO
	ghost.scale = Vector2.ONE * 1.1
	AudioDirector.sfx("pickup")
	drag_state_changed.emit(true)


func serialize() -> Array:
	var out: Array = []
	for n in _items:
		out.append((n.get("data") as Dictionary).duplicate())
	return out


func load_items(arr: Array) -> void:
	for n in _items:
		n.queue_free()
	_items.clear()
	_hover = null
	for e in arr:
		if typeof(e) != TYPE_DICTIONARY:
			continue
		var d := Catalogue.get_item(str(e.get("id", "")))
		if d.is_empty():
			continue
		var data: Dictionary = (e as Dictionary).duplicate()
		for k in ["x", "y", "x2", "y2"]:
			if data.has(k):
				data[k] = float(data[k])
		if data.has("hook"):
			data["hook"] = int(data["hook"])
		_spawn(d, data)


func clear_all() -> void:
	if _items.is_empty():
		return
	push_undo()
	load_items([])
	items_changed.emit()
	AudioDirector.sfx("remove")


func push_undo() -> void:
	_undo.append(serialize())
	if _undo.size() > UNDO_DEPTH:
		_undo.pop_front()


func can_undo() -> bool:
	return not _undo.is_empty()


func undo() -> void:
	if _undo.is_empty() or is_dragging():
		return
	load_items(_undo.pop_back())
	items_changed.emit()
	AudioDirector.sfx("undo")


func reset_undo() -> void:
	_undo.clear()


func set_candles_lit(on: bool, animate: bool = true) -> void:
	candles_lit = on
	var lights: Array = []
	for n in _items:
		if n is Decoration and (n as Decoration).def.get("light", false):
			lights.append(n)
		elif n is Garland and (n as Garland).def.get("light", false):
			lights.append(n)
	if not animate or not on:
		for n in lights:
			n.call("set_lit", on)
		if not on and not lights.is_empty() and animate:
			AudioDirector.sfx("snuff")
		return
	# Light them one by one from the top of the tree down — a little ceremony.
	lights.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.global_position.y < b.global_position.y)
	var i := 0
	for n in lights:
		var node: Node2D = n
		get_tree().create_timer(0.08 * i).timeout.connect(func() -> void:
			if is_instance_valid(node) and candles_lit:
				node.call("set_lit", true)
				AudioDirector.sfx("match", randf_range(0.9, 1.15), -6.0)
		)
		i += 1


func count() -> int:
	return _items.size()


func light_count() -> int:
	var c := 0
	for n in _items:
		if n.get("def") and (n.get("def") as Dictionary).get("light", false):
			c += 1
	return c


# ============================================================ spawning

func _spawn(d: Dictionary, data: Dictionary) -> Node2D:
	var node: Node2D
	if d.get("kind", "") == "garland":
		var g := Garland.new().setup(d, data)
		g.lit = candles_lit
		layer_garland.add_child(g)
		node = g
	else:
		var dec := Decoration.new().setup(d, data)
		dec.position = Vector2(data["x"], data["y"])
		dec.lit = candles_lit
		match d.get("kind", ""):
			"topper":
				layer_topper.add_child(dec)
			"hang", "clip":
				layer_ornament.add_child(dec)
			_:
				if d.get("zone", "") == "floor":
					dec.z_index = 9 if Placement.is_behind_tree(dec.position, tree) else 20
					layer_floor.add_child(dec)
				else:
					layer_room.add_child(dec)
		node = dec
	_items.append(node)
	return node


func _has_topper() -> bool:
	for n in _items:
		if n is Decoration and (n as Decoration).def.get("kind", "") == "topper":
			return true
	return false


func _topper_node() -> Decoration:
	for n in _items:
		if n is Decoration and (n as Decoration).def.get("kind", "") == "topper":
			return n
	return null


func _has_mantel() -> bool:
	for n in _items:
		if n is Decoration and (n as Decoration).def.get("zone", "") == "mantel_garland":
			return true
	return false


func _used_hooks() -> Array:
	var out: Array = []
	for n in _items:
		if n is Decoration and (n as Decoration).data.has("hook"):
			out.append(int((n as Decoration).data["hook"]))
	return out


# ============================================================ input

func _unhandled_input(event: InputEvent) -> void:
	if not enabled or is_dragging():
		return
	if event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		var p := get_global_mouse_position()
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if _try_begin_garland_end(p) or _try_pick(p):
				get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			var hit := _pick(p)
			if hit:
				push_undo()
				_remove(hit, true)
				items_changed.emit()
				get_viewport().set_input_as_handled()


func _try_begin_garland_end(p: Vector2) -> bool:
	for i in range(_items.size() - 1, -1, -1):
		var n := _items[i]
		if n is Garland:
			var e := (n as Garland).hit_end(p)
			if e >= 0:
				push_undo()
				_drag_garland = n
				_drag_garland_end = e
				_drag_garland.show_handles = true
				AudioDirector.sfx("pickup", 1.2, -4.0)
				drag_state_changed.emit(true)
				return true
	return false


func _try_pick(p: Vector2) -> bool:
	var hit := _pick(p)
	if hit == null:
		return false
	push_undo()
	_drag_origin = (hit.get("data") as Dictionary).duplicate()
	_drag_def = hit.get("def")
	_drag_from_trunk = false
	_items.erase(hit)
	if _hover == hit:
		_hover = null
	var ghost := Decoration.new().setup(_drag_def, {"id": _drag_def["id"], "seed": _drag_origin.get("seed", 0)})
	if hit is Garland:
		ghost.position = p
		_drag_offset = Vector2.ZERO
	else:
		ghost.position = hit.position
		_drag_offset = hit.position - p
	hit.queue_free()
	layer_drag.add_child(ghost)
	ghost.scale = Vector2.ONE * 1.1
	_drag_node = ghost
	AudioDirector.sfx("pickup")
	drag_state_changed.emit(true)
	return true


func _pick(p: Vector2) -> Node2D:
	## Topmost decoration under the pointer, in draw order.
	var order: Array = [layer_topper, layer_ornament, layer_garland, layer_floor, layer_room]
	# Floor items in front of the tree are drawn above it, so test those first.
	var front: Array[Node2D] = []
	var behind: Array[Node2D] = []
	for n in _items:
		if n.get_parent() == layer_floor:
			if n.z_index >= 20:
				front.append(n)
			else:
				behind.append(n)
	front.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.position.y > b.position.y)
	for n in front:
		if n.call("hit_test", p):
			return n
	for layer in order:
		if layer == layer_floor:
			continue
		var kids: Array = (layer as Node2D).get_children()
		for i in range(kids.size() - 1, -1, -1):
			var n: Node = kids[i]
			if n in _items and n.call("hit_test", p):
				return n as Node2D
	behind.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.position.y > b.position.y)
	for n in behind:
		if n.call("hit_test", p):
			return n
	return null


func _remove(n: Node2D, with_fx: bool) -> void:
	_items.erase(n)
	if _hover == n:
		_hover = null
		hover_changed.emit("")
	if with_fx:
		_puff(n.global_position, Color(0.9, 0.85, 0.7))
		AudioDirector.sfx("remove")
	n.queue_free()


# ============================================================ per frame

func _process(delta: float) -> void:
	var mouse := get_global_mouse_position()
	var vel := (mouse - _last_mouse) / maxf(delta, 0.001)
	_last_mouse = mouse
	_brush_cooldown = maxf(0.0, _brush_cooldown - delta)

	if _drag_garland:
		_update_garland_drag(mouse)
		return
	if _drag_node:
		_update_drag(mouse, delta)
		return
	if not enabled:
		return
	_update_hover(mouse)
	_brush(mouse, vel)


func _update_drag(mouse: Vector2, delta: float) -> void:
	var target := mouse + _drag_offset
	var res := Placement.resolve(_drag_def, target, tree, _used_hooks(), _has_topper(), _has_mantel())
	_last_res = res
	var over_trunk := _over_trunk(mouse)
	var goal: Vector2 = res["pos"] if (res["ok"] and res["snap"] and not over_trunk) else target
	_drag_node.position = _drag_node.position.lerp(goal, 1.0 - exp(-delta * 28.0))
	var ok: bool = res["ok"] and not over_trunk
	_drag_node.modulate = Color(1, 1, 1, 0.95) if ok else Color(1, 0.75, 0.7, 0.72)
	if over_trunk:
		hint_changed.emit("Put it back in the trunk" if not _drag_from_trunk else "", true)
	elif ok:
		var h := Catalogue.zone_hint(_drag_def)
		if res.get("replace", false):
			h = "Swap the topper"
		hint_changed.emit(h, true)
	else:
		hint_changed.emit(Catalogue.zone_hint(_drag_def), false)
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_finish_drag(mouse)


func _over_trunk(mouse: Vector2) -> bool:
	var r: Rect2 = trunk_rect_provider.call()
	return (r.size.x > 0.0 and r.has_point(mouse)) or mouse.y > RoomLayout.UI_BAR_TOP + 10.0


func _finish_drag(mouse: Vector2) -> void:
	var target := mouse + _drag_offset
	var res := Placement.resolve(_drag_def, target, tree, _used_hooks(), _has_topper(), _has_mantel())
	var over_trunk := _over_trunk(mouse)
	var ghost := _drag_node
	_drag_node = null
	if over_trunk:
		if not _drag_from_trunk:
			AudioDirector.sfx("remove")
			items_changed.emit()
		else:
			AudioDirector.sfx("putback")
		_fade_out(ghost)
	elif res["ok"]:
		if _drag_from_trunk:
			push_undo()
		var data := {"id": _drag_def["id"]}
		if _drag_origin.has("seed"):
			data["seed"] = _drag_origin["seed"]
		var pos: Vector2 = res["pos"]
		if res.has("hook"):
			data["hook"] = res["hook"]
		if res.get("replace", false):
			var old := _topper_node()
			if old:
				_remove(old, true)
		if _drag_def.get("kind", "") == "garland":
			var ends: Array
			if not _drag_from_trunk and _drag_origin.has("x2"):
				# Keep the drape's shape; move it by how far it was carried.
				var a0 := Vector2(_drag_origin["x"], _drag_origin["y"])
				var b0 := Vector2(_drag_origin["x2"], _drag_origin["y2"])
				var mid0 := (a0 + b0) * 0.5
				var delta := target - mid0
				ends = [Placement.clamp_garland_end(a0 + delta, tree), Placement.clamp_garland_end(b0 + delta, tree)]
			else:
				ends = Placement.garland_ends(pos, tree)
			data["x"] = ends[0].x
			data["y"] = ends[0].y
			data["x2"] = ends[1].x
			data["y2"] = ends[1].y
		else:
			data["x"] = pos.x
			data["y"] = pos.y
		var node := _spawn(_drag_def, data)
		_celebrate(node, pos)
		ghost.queue_free()
		items_changed.emit()
	else:
		if _drag_from_trunk:
			AudioDirector.sfx("putback")
			_fade_out(ghost)
		else:
			# Not a valid spot: it slips back to where it was.
			_undo.pop_back()
			var node := _spawn(_drag_def, _drag_origin)
			node.scale = Vector2.ONE * 1.1
			create_tween().tween_property(node, "scale", Vector2.ONE, 0.2)
			AudioDirector.sfx("putback")
			ghost.queue_free()
	hint_changed.emit("", true)
	drag_state_changed.emit(false)


func _update_garland_drag(mouse: Vector2) -> void:
	var g := _drag_garland
	var p := Placement.clamp_garland_end(mouse, tree)
	if _drag_garland_end == 0:
		g.set_ends(p, g.end_b())
	else:
		g.set_ends(g.end_a(), p)
	hint_changed.emit("Drape the garland", true)
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		g.show_handles = false
		_drag_garland = null
		_drag_garland_end = -1
		AudioDirector.sfx(str(g.def.get("sound", "tinsel")), 1.0, -4.0)
		hint_changed.emit("", true)
		items_changed.emit()
		drag_state_changed.emit(false)


func _update_hover(mouse: Vector2) -> void:
	var hit := _pick(mouse)
	if hit == null:
		# Show garland handles when the pointer is near either end.
		for n in _items:
			if n is Garland and (n as Garland).hit_end(mouse) >= 0:
				hit = n
				break
	if hit != _hover:
		if _hover and is_instance_valid(_hover):
			_hover.set("hovered", false)
			if _hover is Garland:
				(_hover as Garland).show_handles = false
		_hover = hit
		if _hover:
			_hover.set("hovered", true)
			if _hover is Garland:
				(_hover as Garland).show_handles = true
			hover_changed.emit(str((_hover.get("def") as Dictionary).get("name", "")))
		else:
			hover_changed.emit("")


func _brush(mouse: Vector2, vel: Vector2) -> void:
	## Sweeping the pointer through the branches sets ornaments swaying.
	if vel.length() < 350.0 or _brush_cooldown > 0.0:
		return
	if not tree.contains_local(mouse - tree.position, -20.0):
		return
	var any := false
	for n in _items:
		var d := n.global_position.distance_to(mouse)
		if d < 80.0:
			var fall := 1.0 - d / 80.0
			n.call("impulse", clampf(vel.x * 0.0011, -1.6, 1.6) * fall)
			any = true
	if any:
		_brush_cooldown = 0.12
		AudioDirector.sfx("rustle", randf_range(0.9, 1.1), -10.0)


# ============================================================ juice

func _celebrate(node: Node2D, pos: Vector2) -> void:
	AudioDirector.sfx(str(_drag_def.get("sound", "soft")), randf_range(0.92, 1.1))
	# Pop into place
	node.scale = Vector2.ONE * 1.25
	var tw := create_tween()
	tw.tween_property(node, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Swing in, and jostle the neighbours
	node.call("impulse", randf_range(0.8, 1.3) * (1.0 if randf() < 0.5 else -1.0))
	for n in _items:
		if n != node and n.global_position.distance_to(pos) < 90.0:
			n.call("impulse", randf_range(-0.5, 0.5))
	_sparkle(pos)
	if node is Decoration and (node as Decoration).def.get("light", false) and candles_lit:
		(node as Decoration).set_lit(true)
		AudioDirector.sfx("match", 1.0, -4.0)


func _sparkle(pos: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.position = pos + Vector2(0, 10)
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = 14
	p.lifetime = 0.7
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2(0, 60)
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 110.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	var g := Gradient.new()
	g.set_color(0, Color(1, 0.92, 0.6, 1))
	g.set_color(1, Color(1, 0.7, 0.3, 0))
	p.color_ramp = g
	p.material = Tex.add_material()
	p.z_index = 66
	p.z_as_relative = false
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


func _puff(pos: Vector2, col: Color) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 10
	p.lifetime = 0.5
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 70.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	var g := Gradient.new()
	g.set_color(0, Color(col, 0.6))
	g.set_color(1, Color(col, 0.0))
	p.color_ramp = g
	p.z_index = 66
	p.z_as_relative = false
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)


func _fade_out(n: Node2D) -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(n, "modulate:a", 0.0, 0.25)
	tw.tween_property(n, "scale", Vector2.ONE * 0.4, 0.25)
	tw.chain().tween_callback(n.queue_free)
