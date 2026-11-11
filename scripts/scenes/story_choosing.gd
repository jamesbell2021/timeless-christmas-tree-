class_name StoryChoosing
extends StoryFamily
## Chapter IV — Choosing the Tree. Too small; rather crooked; and then the
## lantern is lifted, warm light falls on our tree, and the robin settles on
## its very top.

var _robin: Robin
var _lit := false


func _init() -> void:
	stage = 3
	duration = 24.0
	ambience = "winter"
	caption_hold = 3.2
	lines = [
		"They looked at a great many trees.",
		"One was rather too small. One was a little crooked.",
		"And then they saw ours.",
		"And so, with soft smiles, they chose our tree.",
	]
	tracks = {
		"father": [[0.0, 560.0], [3.0, 470.0], [6.5, 470.0], [9.0, 780.0], [12.0, 780.0], [15.5, 1130.0]],
		"mother": [[0.0, 450.0], [3.2, 420.0], [6.8, 420.0], [9.5, 760.0], [12.4, 760.0], [16.0, 1060.0]],
		"girl": [[0.0, 650.0], [3.0, 640.0], [6.5, 640.0], [9.2, 990.0], [12.2, 990.0], [15.0, 1200.0]],
		"boy": [[0.0, 360.0], [2.8, 630.0], [6.2, 680.0], [9.0, 1010.0], [12.0, 1020.0], [15.2, 1240.0]],
		"dog": [[0.0, 700.0], [3.0, 600.0], [7.0, 820.0], [10.0, 1100.0], [13.0, 1000.0], [16.0, 1180.0]],
	}


func build_world() -> void:
	super.build_world()
	for role in family.keys():
		(family[role] as Figure).position.x = _x_at(role, 0.0)
	_robin = Robin.new()
	_robin.size = 1.6
	_robin.facing = -1.0
	_robin.visible = false
	add_child(_robin)


func update(time: float, delta: float) -> void:
	move_family(time, delta)
	var dad: Figure = family["father"]
	var mum: Figure = family["mother"]
	var girl: Figure = family["girl"]
	var boy: Figure = family["boy"]
	boy.pose = "shake" if time > 3.4 and time < 6.0 else ("point" if time > 16.5 else "stand")
	mum.pose = "shake" if time > 9.8 and time < 12.0 else ("clasp" if time > 17.0 else "stand")
	girl.pose = "clasp" if time > 15.5 else ("point" if time > 12.4 and time < 14.0 else "stand")
	dad.pose = "raise" if time > 16.6 else "stand"
	if time > 15.6:
		for f in [dad, mum, girl, boy]:
			(f as Figure).facing = 1.0
	if time > 16.8 and not _lit:
		_lit = true
		var tw := create_tween()
		tw.tween_property(clearing.tree_glow, "energy", 0.55, 2.0)
		tw.parallel().tween_property(clearing.our_tree, "modulate", Color(1.15, 1.08, 0.95), 2.0)
		AudioDirector.sfx("chime", 0.9, -4.0)
	# The robin flutters down to the tip of the tree
	if time > 18.5:
		_robin.visible = true
		var apex := clearing.our_tree.position + clearing.our_tree.apex + Vector2(0, 6)
		var u := smooth(18.5, 20.5, time)
		_robin.position = Vector2(1900, 200).lerp(apex, u) + Vector2(0, -sin(u * PI) * 60)
