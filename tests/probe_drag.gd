extends Node
## Interaction probe: simulates real mouse input to drag decorations from
## the trunk onto the tree and into the room, then checks the results.

var p: Parlour
var fails := 0


func _ready() -> void:
	GameState.clear_arrangement(GameState.current_arrangement)
	p = Parlour.new(false)
	add_child(p)
	await _wait(1.0)
	p.ui.set_trunk_open(true)
	await _wait(0.6)
	# 1. A candle from the first tray onto the tree
	await _drag_slot(0, Vector2(980, 520))
	_expect(p.decor.count() == 1, "candle placed")
	# 2. Glass tray: a bauble
	p.ui.trunk._select_tab("glass")
	await _wait(0.2)
	await _drag_slot(0, Vector2(900, 640), true)
	_expect(p.decor.count() == 2, "bauble placed")
	# 3. Toppers tray: the star
	p.ui.trunk._select_tab("toppers")
	await _wait(0.2)
	await _drag_slot(1, Vector2(960, 230))
	_expect(p.decor.count() == 3, "topper placed")
	# 4. Garland
	p.ui.trunk._select_tab("garlands")
	await _wait(0.2)
	await _drag_slot(0, Vector2(960, 560))
	_expect(p.decor.count() == 4, "garland placed")
	# 5. Room: a present on the floor and a stocking on a hook
	p.ui.trunk._select_tab("room")
	await _wait(0.2)
	await _drag_slot(4, Vector2(820, 900))
	await _drag_slot(1, Vector2(250, 470))
	_expect(p.decor.count() == 6, "present and stocking placed")
	# 6. An invalid drop: bauble onto the wall disappears
	p.ui.trunk._select_tab("glass")
	await _wait(0.2)
	await _drag_slot(1, Vector2(1300, 300))
	_expect(p.decor.count() == 6, "invalid drop refused")
	# 7. Move the bauble by dragging it
	await _drag_world(Vector2(900, 650), Vector2(1040, 700))
	var moved := false
	for d in p.decor.serialize():
		if d["id"] == "bauble_red" and absf(float(d["x"]) - 1040.0) < 30.0:
			moved = true
	_expect(moved, "bauble moved")
	# 8. Right-click removes
	await _click(Vector2(820, 880), MOUSE_BUTTON_RIGHT)
	_expect(p.decor.count() == 5, "right-click removed present")
	# 9. Undo brings it back
	p.decor.undo()
	_expect(p.decor.count() == 6, "undo restores")
	p.set_candles(true)
	await _wait(1.0)
	await _shot("drag_result")
	print("drag probe: %d failures" % fails)
	get_tree().quit(fails)


func _expect(c: bool, what: String) -> void:
	print(("  ok   " if c else "  FAIL ") + what, "   [count=%d dragging=%s enabled=%s hovered=%s]" % [p.decor.count(), p.decor.is_dragging(), p.decor.enabled, get_viewport().gui_get_hovered_control()])
	if not c:
		fails += 1


func _slot_center(i: int) -> Vector2:
	var grid: GridContainer = p.ui.trunk._grid
	var slot := grid.get_child(i) as Control
	return slot.get_global_rect().get_center()


func _drag_slot(i: int, to: Vector2, shoot: bool = false) -> void:
	await _drag_world(_slot_center(i), to, shoot)


func _drag_world(from: Vector2, to: Vector2, shoot: bool = false) -> void:
	print("   drag from ", from, " to ", to, " hovered=", get_viewport().gui_get_hovered_control())
	_motion(from)
	await get_tree().process_frame
	_button(from, true, MOUSE_BUTTON_LEFT)
	await get_tree().process_frame
	for k in 20:
		var q := from.lerp(to, float(k + 1) / 20.0)
		_motion(q)
		await get_tree().process_frame
	await _wait(0.15)
	if shoot:
		await _shot("drag_mid")
	print("   before release dragging=", p.decor.is_dragging(), " def=", p.decor._drag_def.get("id", "-"), " mouse=", p.decor.get_global_mouse_position())
	_button(to, false, MOUSE_BUTTON_LEFT)
	await _wait(0.4)
	var ids := []
	for d in p.decor.serialize():
		ids.append(d["id"])
	print("   now: ", ids)


func _click(at: Vector2, button: int) -> void:
	_motion(at)
	await get_tree().process_frame
	_button(at, true, button)
	await get_tree().process_frame
	_button(at, false, button)
	await _wait(0.3)


func _motion(at: Vector2) -> void:
	Input.warp_mouse(at)
	var e := InputEventMouseMotion.new()
	e.position = at
	e.global_position = at
	Input.parse_input_event(e)


func _button(at: Vector2, pressed: bool, button: int) -> void:
	var e := InputEventMouseButton.new()
	e.position = at
	e.global_position = at
	e.button_index = button
	e.pressed = pressed
	e.button_mask = (MOUSE_BUTTON_MASK_LEFT if button == MOUSE_BUTTON_LEFT else MOUSE_BUTTON_MASK_RIGHT) if pressed else 0
	Input.parse_input_event(e)


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tests/out/%s.png" % n)
