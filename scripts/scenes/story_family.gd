class_name StoryFamily
extends StoryScene
## Shared base for Chapters III and IV: the winter clearing plus the family,
## each member following a simple timeline of (time, x) keyframes. Walking,
## facing and foot-bob are derived from movement, so choreography is just data.

var clearing: WinterClearing
var family: Dictionary = {}       # role -> Figure
var tracks: Dictionary = {}       # role -> [[t, x], ...]
var ground_y: Dictionary = {"father": 918.0, "mother": 900.0, "girl": 934.0, "boy": 944.0, "dog": 958.0}


func build_world() -> void:
	clearing = WinterClearing.new()
	add_child(clearing)
	for role in ["mother", "father", "boy", "girl", "dog"]:
		var f := Figure.new()
		f.role = role
		f.height_scale = 1.25
		f.position = Vector2(-300, ground_y[role])
		add_child(f)
		family[role] = f


func _x_at(role: String, time: float) -> float:
	var tr: Array = tracks.get(role, [])
	if tr.is_empty():
		return family[role].position.x
	if time <= float(tr[0][0]):
		return float(tr[0][1])
	for i in tr.size() - 1:
		var a: Array = tr[i]
		var b: Array = tr[i + 1]
		if time <= float(b[0]):
			var u := (time - float(a[0])) / maxf(0.001, float(b[0]) - float(a[0]))
			return lerpf(float(a[1]), float(b[1]), smoothstep(0.0, 1.0, u))
	return float(tr[tr.size() - 1][1])


func move_family(time: float, delta: float) -> void:
	for role in family.keys():
		var f: Figure = family[role]
		var nx := _x_at(role, time)
		var dx := nx - f.position.x
		f.walking = absf(dx) > 12.0 * delta
		if absf(dx) > 0.2:
			f.facing = signf(dx)
		f.position.x = nx
