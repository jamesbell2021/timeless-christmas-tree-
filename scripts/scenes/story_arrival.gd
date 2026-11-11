class_name StoryArrival
extends StoryFamily
## Chapter III — The Family Arrival. Christmas Eve, 1901: sleigh bells in the
## dusk, and a family walks into the snowy clearing with a lantern.


func _init() -> void:
	stage = 2
	duration = 21.0
	ambience = "winter"
	lines = [
		"Christmas Eve, 1901.",
		"Footsteps in the snow, and laughter on the cold air.",
		"A family had come to the wood to find their tree.",
	]
	tracks = {
		"father": [[1.0, -220.0], [13.0, 560.0]],
		"mother": [[1.4, -320.0], [13.5, 450.0]],
		"girl": [[1.0, -140.0], [12.5, 650.0]],
		"boy": [[0.6, -420.0], [13.8, 360.0]],
		"dog": [[0.4, -80.0], [5.0, 520.0], [7.5, 300.0], [11.0, 800.0], [13.0, 700.0]],
	}


func build_world() -> void:
	super.build_world()
	get_tree().create_timer(0.6).timeout.connect(func() -> void: AudioDirector.sfx("sleigh", 1.0, -6.0))


func update(time: float, delta: float) -> void:
	move_family(time, delta)
	var dad: Figure = family["father"]
	var girl: Figure = family["girl"]
	var boy: Figure = family["boy"]
	if time > 14.0:
		girl.pose = "point"
		girl.facing = 1.0
	if time > 15.0:
		dad.pose = "raise"
		dad.facing = 1.0
	if time > 15.5:
		boy.pose = "point"
		boy.facing = 1.0
	(family["mother"] as Figure).facing = 1.0 if time > 13.5 else (family["mother"] as Figure).facing
