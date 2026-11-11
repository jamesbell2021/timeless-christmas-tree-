class_name LightGlow
extends Sprite2D
## An additive pool of light. Brightness is driven by a base energy, an
## optional flicker and the room's lighting state (lamps / candles).

@export var color := Color(1.0, 0.7, 0.35)
@export var energy := 0.6
@export var flicker := 0.0        # 0 = steady, 1 = lively
@export var radius := 120.0
@export var squash := 1.0          # vertical scale, for floor pools

var dim := 1.0                     # animated by the room (0 = off)
var _t := 0.0
var _noise := FastNoiseLite.new()


func _init(p_color: Color = Color(1, 0.7, 0.35), p_energy: float = 0.6, p_radius: float = 120.0, p_flicker: float = 0.0) -> void:
	color = p_color
	energy = p_energy
	radius = p_radius
	flicker = p_flicker


func _ready() -> void:
	texture = Tex.glow()
	material = Tex.add_material()
	z_index = 60
	z_as_relative = false
	_noise.seed = randi()
	_noise.frequency = 1.4
	_t = randf() * 100.0
	_update()


func _process(delta: float) -> void:
	_t += delta
	_update()


func _update() -> void:
	var f := 1.0
	if flicker > 0.0:
		f = 1.0 + _noise.get_noise_1d(_t * 6.0) * 0.35 * flicker + _noise.get_noise_1d(_t * 17.0) * 0.12 * flicker
	var s := radius / 128.0
	scale = Vector2(s, s * squash) * (1.0 + (f - 1.0) * 0.25)
	modulate = Color(color.r, color.g, color.b, clampf(energy * f * dim, 0.0, 1.0))
	visible = dim > 0.01
