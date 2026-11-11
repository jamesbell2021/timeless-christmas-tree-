class_name Snowfall
extends Node2D
## Lightweight snowfall confined to a rectangle (a window, or the whole
## screen in the story scenes). Flakes drift on a sine sway; nearer flakes
## are larger and faster for a little parallax.

@export var area := Rect2(0, 0, 1920, 1080)
@export var count := 90
@export var wind := 12.0
@export var tint := Color(0.95, 0.97, 1.0, 0.9)
@export var size_scale := 1.0

var _flakes: Array = []
var _t := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(area.position.x * 13.0 + area.size.y)
	for i in count:
		var depth := rng.randf()
		_flakes.append({
			"p": Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y)),
			"depth": depth,
			"phase": rng.randf() * TAU,
			"speed": lerpf(18.0, 60.0, depth),
			"r": lerpf(1.0, 3.2, depth) * size_scale,
		})


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	for f in _flakes:
		var p: Vector2 = f["p"]
		p.y += f["speed"] * delta
		p.x += (wind * (0.4 + f["depth"]) + sin(_t * 0.9 + f["phase"]) * 14.0) * delta
		if p.y > area.end.y:
			p.y = area.position.y - 4.0
			p.x = randf_range(area.position.x, area.end.x)
		if p.x > area.end.x:
			p.x = area.position.x
		elif p.x < area.position.x:
			p.x = area.end.x
		f["p"] = p
	queue_redraw()


func _draw() -> void:
	for f in _flakes:
		var c := tint
		c.a *= lerpf(0.45, 1.0, f["depth"])
		draw_circle(f["p"], f["r"], c)
