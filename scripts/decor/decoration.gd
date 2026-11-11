class_name Decoration
extends Node2D
## One placed (or dragged) decoration. Holds its catalogue definition and its
## save data, paints itself through DecorArt and simulates a damped pendulum
## so hanging ornaments sway when brushed, placed or nudged.

const SWING_KINDS := ["hang"]
const SWING_ROOM := ["stocking", "mistletoe", "wreath"]

var def: Dictionary = {}
var data: Dictionary = {}
var flame: Flame
var hovered := false:
	set(v):
		if hovered != v:
			hovered = v
			modulate = Color(1.22, 1.15, 1.02) if v else Color.WHITE
var lit := false

var _swing := 0.0
var _swing_v := 0.0
var _stiffness := 26.0
var _damping := 1.6
var _can_swing := false


func setup(p_def: Dictionary, p_data: Dictionary) -> Decoration:
	def = p_def
	data = p_data
	if not data.has("seed"):
		data["seed"] = randi() % 100000
	_can_swing = def.get("kind", "") in SWING_KINDS or def.get("draw", "") in SWING_ROOM
	if def.get("draw", "") in SWING_ROOM:
		_stiffness = 40.0
		_damping = 2.6
	return self


func _ready() -> void:
	if def.get("light", false):
		flame = Flame.new()
		if def.get("draw", "") == "candlestick":
			flame.position = Vector2(0.5, -89)
			flame.height = 14.0
			flame.halo = 90.0
		else:
			flame.position = Vector2(0.5, -38)
			flame.height = 12.0
			flame.halo = 78.0
			flame.halo_energy = 0.62
		flame.lit = lit
		add_child(flame)


func set_lit(on: bool) -> void:
	lit = on
	if flame:
		flame.lit = on


func impulse(v: float) -> void:
	if _can_swing:
		_swing_v += v
		set_process(true)
	if flame:
		flame.nudge(v * 0.4)


func _process(delta: float) -> void:
	if not _can_swing:
		set_process(false)
		return
	# Damped spring pendulum (semi-implicit Euler).
	var acc := -_stiffness * _swing - _damping * _swing_v
	_swing_v += acc * delta
	_swing += _swing_v * delta
	_swing = clampf(_swing, -0.9, 0.9)
	rotation = _swing
	if absf(_swing) < 0.0005 and absf(_swing_v) < 0.002:
		_swing = 0.0
		_swing_v = 0.0
		rotation = 0.0
		set_process(false)


func _draw() -> void:
	var extra := {}
	if def.get("zone", "") == "ceiling":
		extra["ceiling_dy"] = global_position.y - RoomLayout.CORNICE_H
	DecorArt.draw_item(self, def, int(data.get("seed", 0)), extra)


func hit_test(global_p: Vector2) -> bool:
	var local := to_local(global_p)
	var r: Rect2 = def.get("rect", Rect2(-16, -16, 32, 32))
	if def.get("zone", "") == "mantel_garland":
		return r.has_point(local)
	return r.grow(4).has_point(local)
