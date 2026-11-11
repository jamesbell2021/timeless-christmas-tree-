extends Node
## Main — the scene director. Owns the single active scene (title, a story
## chapter or the parlour) and cross-fades between them.
##
## Flow:  Title -> I Seedling -> II Forest -> III Arrival -> IV Choosing -> Parlour
## From the parlour's timeline any reached chapter can be replayed; it then
## returns to the parlour.

var current: Node
var _fade: ColorRect
var _busy := false


func _ready() -> void:
	GameState.apply_fullscreen()
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0.03, 0.02, 0.015)
	_fade.size = Vector2(1920, 1080)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	show_title()


func _switch(node: Node) -> void:
	if _busy:
		node.queue_free()
		return
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, 0.7 if current else 0.01)
	await tw.finished
	if current:
		current.queue_free()
		await get_tree().process_frame
	current = node
	add_child(node)
	move_child(node, 0)
	# Give procedural art a frame to generate before revealing it.
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(_fade, "modulate:a", 0.0, 1.0)
	await tw2.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


func show_title() -> void:
	var t := TitleScreen.new()
	t.begin_story.connect(func() -> void: play_story(0, false))
	t.go_parlour.connect(func() -> void: show_parlour(false))
	_switch(t)


func play_story(stage: int, single: bool) -> void:
	var s: StoryScene
	match stage:
		0: s = StorySeedling.new()
		1: s = StoryYears.new()
		2: s = StoryArrival.new()
		_: s = StoryChoosing.new()
	s.single_chapter = single
	s.finished.connect(func() -> void:
		GameState.reach_stage(stage)
		if single:
			show_parlour(false)
		elif stage < 3:
			play_story(stage + 1, false)
		else:
			show_parlour(true)
	)
	s.skip_all.connect(func() -> void:
		GameState.reach_stage(3)
		show_parlour(not single and not GameState.story_complete)
	)
	_switch(s)


func show_parlour(first_visit: bool) -> void:
	var p := Parlour.new(first_visit)
	p.story_requested.connect(func(stage: int) -> void: play_story(stage, true))
	p.title_requested.connect(show_title)
	_switch(p)
