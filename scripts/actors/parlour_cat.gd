class_name ParlourCat
extends Node2D
## Marmalade, the parlour cat — a ginger tabby who sleeps by the fire.
##
## Petting: press on her and stroke (or just tap). Each stroke makes her purr
## louder, but also winds her up a little. Patience comes back on its own, so
## gentle petting with pauses is fine; keep going without a break and she
## warns you (sits up, ears flat, tail lashing, anger mark), then hisses and
## storms off for a while.
##
## Mischief: every minute or two, if there are ornaments on the low boughs,
## she wakes, pads over, crouches with a wiggle (tap her now to shoo her
## away) and swipes. Ornaments swing, and sometimes one comes off and rolls
## onto the floor until the player hangs it back up (Undo works too).
##
## Behaviour is a small state machine; every pose is drawn in code from a
## handful of parameters (crouch, rear, arch, ears, gait) blended each frame.

enum S { SLEEP, SIT, ROUSE, WALK, STALK, POUNCE, GLOAT, SHOOED, HISS, FLEE, AWAY }

const NAME := "Marmalade"
const HOME := Vector2(400, 874)          # her feet, curled on the hearth rug
const WALK_SPEED := 125.0
const RUN_SPEED := 600.0
const REACH_TOP := 500.0                 # the highest bough she can reach
const STAND_Y := 914.0                   # where she stands to swipe

# Petting balance (tuned so steady stroking makes her flee in ~4 s, while one
# stroke a second can carry on for ~20 s; patience recovers by itself)
const STROKE_DIST := 90.0                # pointer travel that counts as a stroke
const STROKE_GAP := 0.35                 # minimum seconds between strokes
const STROKE_ANNOY := 0.14
const ANNOY_DECAY := 0.09                # per second
const WARN_AT := 0.55
const FLEE_AT := 1.0

const FIRST_MISCHIEF := Vector2(45.0, 80.0)
const MISCHIEF_EVERY := Vector2(70.0, 140.0)
const AWAY_TIME := Vector2(30.0, 50.0)

const GINGER := Color(0.72, 0.4, 0.16)
const LIGHT := Color(0.86, 0.6, 0.32)
const DARK := Color(0.42, 0.2, 0.07)
const OUTLINE := Color(0.22, 0.1, 0.04, 0.8)
const CREAM := Color(0.95, 0.9, 0.82)

var parlour: Parlour
var state := S.SLEEP
var facing := -1.0                       # -1 looks left (towards the fire)
var annoy := 0.0
var content := 0.0                       # 0..1, drives the purr

var _t := 0.0
var _st := 0.0                           # seconds in the current state
var _gait := 0.0
var _speed := 0.0
var _walk_to := Vector2.ZERO
var _then := S.SLEEP                     # what to do on arrival
var _target: Decoration = null
var _swipes := 0
var _hit_done := false
var _jump_from := Vector2.ZERO
var _jump_top := 0.0
var _mischief := 0.0
var _away := 0.0
var _petting := false
var _stroke_acc := 0.0
var _last_stroke := -10.0
var _press_strokes := 0
var _last_mouse := Vector2.ZERO
var _hover_text := ""
var _fx: Array = []                      # [kind, pos, vel, life, max_life]
var _zzz := 1.5
var _squash := 0.0
var _purr: AudioStreamPlayer
var _rng := RandomNumberGenerator.new()

# Blended pose parameters
var _crouch := 0.0
var _rear := 0.0
var _arch := 0.0
var _ears := 0.0                         # 0 up, 1 flat back
var _paw := Vector2.ZERO                 # swipe target, local space


func _init(p_parlour: Parlour) -> void:
	parlour = p_parlour


func _ready() -> void:
	_rng.randomize()
	position = HOME
	z_index = 21
	_mischief = _rng.randf_range(FIRST_MISCHIEF.x, FIRST_MISCHIEF.y)
	_purr = AudioStreamPlayer.new()
	_purr.bus = "SFX"
	if OS.has_feature("web"):
		_purr.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	_purr.stream = AudioDirector.sfx_stream("purr")
	add_child(_purr)


# ================================================================ public

func hit_test(p: Vector2) -> bool:
	if state == S.AWAY or state == S.FLEE or not visible:
		return false
	var l := to_local(p)
	l.x *= facing
	match _mode():
		"curl":
			return Rect2(-82, -62, 160, 70).has_point(Vector2(-l.x, l.y))
		"sit":
			return Rect2(-54, -124, 104, 128).has_point(l)
	return Rect2(-78, -118, 156, 122).has_point(l)


func stroke() -> void:
	## One stroke of the hand.
	if state in [S.SLEEP, S.SIT, S.GLOAT]:
		_last_stroke = _t
		_press_strokes += 1
		annoy += STROKE_ANNOY
		if annoy >= FLEE_AT:
			_enter_state(S.HISS)
			return
		if annoy >= WARN_AT:
			content = minf(content, 0.25)
			_fx_add("anger", _head_pos())
			AudioDirector.sfx("mrrp", 0.62, -2.0)
			if state != S.SIT:
				_enter_state(S.SIT)
		else:
			content = minf(1.0, content + 0.35)
			_fx_add("heart", _head_pos())
			_squash = 0.6
	elif state in [S.ROUSE, S.WALK, S.STALK] and _target != null:
		_shoo()


func start_mischief() -> bool:
	## Wake up and go after an ornament. Returns false if there's nothing in reach.
	var targets := parlour.decor.cat_targets(REACH_TOP)
	if targets.is_empty():
		return false
	targets.sort_custom(func(a: Decoration, b: Decoration) -> bool: return a.position.y > b.position.y)
	_target = targets[_rng.randi() % mini(4, targets.size())]
	_swipes = 0
	_enter_state(S.ROUSE)
	return true


func is_home() -> bool:
	return position.distance_to(HOME) < 4.0


# ============================================================ behaviour

func _enter_state(s: S) -> void:
	state = s
	_st = 0.0
	_hit_done = false
	match s:
		S.SLEEP:
			facing = -1.0
			_squash = 0.5
		S.SIT, S.ROUSE, S.GLOAT, S.SHOOED:
			_squash = 0.5
			if s == S.ROUSE:
				AudioDirector.sfx("mrrp", 1.05, -6.0)
			elif s == S.SHOOED:
				AudioDirector.sfx("mrrp", 1.25, -2.0)
		S.STALK:
			pass
		S.POUNCE:
			_jump_from = position
			AudioDirector.sfx("swipe", _rng.randf_range(0.9, 1.1))
		S.HISS:
			content = 0.0
			AudioDirector.sfx("hiss")
			_fx_add("anger", _head_pos())
			_fx_add("anger", _head_pos() + Vector2(14, -10))
		S.FLEE:
			_target = null
			_walk_to = Vector2(-170, position.y)
			facing = -1.0
			parlour.ui.toast("%s has stormed off in a huff. Give her a minute." % NAME)
		S.AWAY:
			visible = false
			_away = _rng.randf_range(AWAY_TIME.x, AWAY_TIME.y)


func _walk(to: Vector2, then: S) -> void:
	_walk_to = to
	_then = then
	facing = 1.0 if to.x >= position.x else -1.0
	_enter_state(S.WALK)


func _go_home() -> void:
	_target = null
	if is_home():
		_enter_state(S.SLEEP)
	else:
		_walk(HOME, S.SLEEP)


func _shoo() -> void:
	_target = null
	annoy = minf(annoy + 0.1, WARN_AT - 0.05)
	_fx_add("anger", _head_pos())
	_enter_state(S.SHOOED)


func _can_mischief() -> bool:
	return bool(GameState.settings.get("cat_mischief", true)) and parlour.decor.enabled \
			and not parlour.fireside and not parlour.ui.has_modal() and not parlour.decor.is_dragging() \
			and not _petting and annoy < 0.3


func _target_ok() -> bool:
	return _target != null and parlour.decor.is_placed(_target) and not _target.data.get("fallen", false)


func _stand_point() -> Vector2:
	var side := 1.0 if _target.position.x >= position.x else -1.0
	return Vector2(_target.position.x - side * 58.0, STAND_Y)


func _process(delta: float) -> void:
	if parlour.ui == null:
		return
	delta = minf(delta, 0.1)
	_t += delta
	_st += delta
	annoy = maxf(0.0, annoy - ANNOY_DECAY * delta * (0.5 if _petting else 1.0))
	content = move_toward(content, 0.0, delta * 0.22)
	_squash = move_toward(_squash, 0.0, delta * 3.0)
	if not GameState.settings.get("cat_mischief", true) and _target != null and state in [S.ROUSE, S.WALK, S.STALK]:
		_go_home()
	_input_update()
	_behave(delta)
	_pose_update(delta)
	_fx_update(delta)
	_purr_update()
	_hover_update()
	queue_redraw()


func _behave(delta: float) -> void:
	match state:
		S.SLEEP:
			_zzz -= delta
			if _zzz <= 0.0 and not _petting and content < 0.05:
				_zzz = 2.6
				_fx_add("z", _head_pos() + Vector2(-6, -8))
			if _can_mischief():
				_mischief -= delta
				if _mischief <= 0.0:
					_mischief = _rng.randf_range(MISCHIEF_EVERY.x, MISCHIEF_EVERY.y)
					start_mischief()
		S.SIT:
			if is_home() and annoy < 0.25 and _st > 2.5 and not _petting:
				_enter_state(S.SLEEP)
			elif not is_home() and _st > 1.8 and annoy < WARN_AT:
				_go_home()
		S.ROUSE:
			if not _target_ok():
				_go_home()
			elif _st > 1.2:
				_walk(_stand_point(), S.STALK)
		S.WALK:
			_speed = WALK_SPEED
			if _then == S.STALK and not _target_ok():
				_go_home()
				return
			var d := _walk_to - position
			if d.length() <= WALK_SPEED * delta:
				position = _walk_to
				_arrive()
			else:
				position += d.normalized() * WALK_SPEED * delta
				_gait += delta * 9.0
		S.STALK:
			if not _target_ok():
				_enter_state(S.GLOAT)
			else:
				facing = 1.0 if _target.position.x >= position.x else -1.0
				if _st > (1.4 if _swipes == 0 else 0.6):
					_enter_state(S.POUNCE)
		S.POUNCE:
			var u := clampf(_st / 0.6, 0.0, 1.0)
			var lift := 0.0
			if _target_ok():
				# Feet rise until her paw (about 110 px above them) reaches the ornament.
				lift = clampf(_jump_from.y - (_target.position.y + 105.0), 0.0, 260.0)
			position = _jump_from - Vector2(0, sin(u * PI) * lift)
			if u >= 0.5 and not _hit_done:
				_hit_done = true
				if _target_ok():
					var knock := _rng.randf() < (0.55 if _swipes == 0 else 0.75)
					var item_name := str(_target.def.get("name", "ornament"))
					parlour.decor.cat_swat(_target, facing, knock)
					if knock:
						parlour.ui.toast("%s knocked the %s off the tree!" % [NAME, item_name.to_lower()])
						_target = null
				_swipes += 1
			if u >= 1.0:
				position = _jump_from
				if _target_ok() and _swipes < 2:
					_enter_state(S.STALK)
				else:
					_enter_state(S.GLOAT)
		S.GLOAT:
			if _st > 2.0 and annoy < WARN_AT:
				_go_home()
			elif annoy >= WARN_AT:
				_enter_state(S.SIT)
		S.SHOOED:
			if _st > 0.9:
				_go_home()
		S.HISS:
			if _st > 0.75:
				_enter_state(S.FLEE)
		S.FLEE:
			position.x -= RUN_SPEED * delta
			_gait += delta * 22.0
			if position.x <= _walk_to.x:
				_enter_state(S.AWAY)
		S.AWAY:
			_away -= delta
			annoy = 0.0
			if _away <= 0.0:
				visible = true
				position = Vector2(-120, HOME.y)
				parlour.ui.toast("%s has wandered back to the fire." % NAME)
				_walk(HOME, S.SLEEP)


func _arrive() -> void:
	match _then:
		S.STALK:
			if _target_ok():
				facing = 1.0 if _target.position.x >= position.x else -1.0
				_enter_state(S.STALK)
			else:
				_go_home()
		_:
			_enter_state(S.SLEEP)


# ================================================================ input

func _interactive() -> bool:
	return parlour.decor.enabled and not parlour.decor.is_dragging() and not parlour.fireside \
			and not parlour.ui.has_modal()


func _unhandled_input(event: InputEvent) -> void:
	if parlour.ui == null or not _interactive():
		return
	if event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var p := get_global_mouse_position()
		if hit_test(p):
			_petting = true
			_press_strokes = 0
			_stroke_acc = 0.0
			_last_mouse = p
			get_viewport().set_input_as_handled()


func _input_update() -> void:
	if not _petting:
		return
	var m := get_global_mouse_position()
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_petting = false
		if _press_strokes == 0:
			stroke()      # a tap is a single pat
		return
	if hit_test(m):
		_stroke_acc += m.distance_to(_last_mouse)
		if _stroke_acc >= STROKE_DIST and _t - _last_stroke >= STROKE_GAP:
			_stroke_acc = 0.0
			stroke()
	_last_mouse = m


func _hover_update() -> void:
	var text := ""
	if _interactive() and hit_test(get_global_mouse_position()):
		match state:
			S.ROUSE, S.WALK, S.STALK:
				text = ("Shoo! (tap %s)" % NAME) if _target else ""
			S.HISS, S.FLEE:
				text = ""
			_:
				text = ("%s has had quite enough..." % NAME) if annoy >= WARN_AT else ("Stroke %s" % NAME)
	if text == _hover_text:
		return
	_hover_text = text
	# Don't wipe the name of a decoration the pointer has just moved onto.
	if text != "" or not parlour.decor.has_hover():
		parlour.ui.show_hover(text)


func _purr_update() -> void:
	if _purr.stream == null:
		return
	if content > 0.03:
		_purr.volume_db = linear_to_db(content * 0.8)
		if not _purr.playing:
			_purr.play()
	elif _purr.playing:
		_purr.stop()


# ================================================================ poses

func _mode() -> String:
	match state:
		S.SLEEP:
			return "curl"
		S.SIT, S.ROUSE, S.GLOAT, S.SHOOED:
			return "sit"
	return "stand"


func _pose_update(delta: float) -> void:
	var crouch := 0.0
	var rear := 0.0
	var arch := 0.0
	var ears := 0.0
	match state:
		S.STALK:
			crouch = 1.0
		S.POUNCE:
			rear = sin(clampf(_st / 0.6, 0.0, 1.0) * PI)
		S.HISS:
			arch = 1.0
			ears = 1.0
		S.FLEE:
			crouch = 0.35
			ears = 1.0
		S.SHOOED:
			ears = 1.0
	if annoy >= WARN_AT:
		ears = 1.0
	var k := 1.0 - exp(-delta * 12.0)
	_crouch = lerpf(_crouch, crouch, k)
	_rear = lerpf(_rear, rear, minf(k * 1.6, 1.0))
	_arch = lerpf(_arch, arch, k)
	_ears = lerpf(_ears, ears, k)
	if _target_ok():
		_paw = (to_local(_target.global_position) * Vector2(facing, 1.0))
	else:
		_paw = Vector2(70, -110)


func _head_pos() -> Vector2:
	## Roughly where her head is, in room coordinates (for hearts and z's).
	match _mode():
		"curl":
			return position + Vector2(-50, -40)
		"sit":
			return position + Vector2(14.0 * facing, -112)
	return position + Vector2(58.0 * facing, -88)


# ================================================================ drawing

func _draw() -> void:
	if state == S.AWAY:
		return
	var sq := Vector2(1.0 + _squash * 0.08, 1.0 - _squash * 0.08)
	match _mode():
		"curl":
			draw_set_transform(Vector2.ZERO, 0.0, sq)
			_draw_curl()
		"sit":
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0) * sq)
			_draw_sit()
		_:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
			_draw_stand()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_fx()


func _poly_outline(pts: PackedVector2Array, w: float = 2.0, col: Color = OUTLINE) -> void:
	var o := pts.duplicate()
	o.append(o[0])
	draw_polyline(o, col, w, true)


func _draw_curl() -> void:
	## Curled up asleep, head on her paws, facing the fire. She breathes, her
	## tail tip twitches in her dreams, and she shivers gently when purring.
	var purr := sin(_t * 60.0) * 0.7 * content
	var c := Vector2(purr, -24)
	var breathe := 1.0 + sin(_t * 1.6) * 0.035
	draw_colored_polygon(DecorArt.ellipse_pts(c + Vector2(0, 24), 70, 10), Color(0, 0, 0, 0.4))
	var body := DecorArt.ellipse_pts(c, 50, 24 * breathe, 28)
	var haunch := DecorArt.ellipse_pts(c + Vector2(24, -6 * breathe), 30, 26 * breathe, 24)
	draw_colored_polygon(haunch, GINGER.darkened(0.05))
	draw_colored_polygon(body, GINGER)
	_poly_outline(haunch)
	for k in 7:
		var x := c.x - 26 + k * 10.0
		draw_arc(Vector2(x, c.y + 14), 26, PI * 1.32, PI * 1.62, 6, DARK, 3.0, true)
	draw_colored_polygon(DecorArt.ellipse_pts(c + Vector2(-6, 12), 34, 9), LIGHT)
	var twitch := maxf(0.0, sin(_t * 0.7)) * sin(_t * 9.0) * 0.3 + content * sin(_t * 2.0) * 0.25
	var tail := PackedVector2Array()
	for i in 16:
		var t := float(i) / 15.0
		var a := -PI * 0.05 + t * PI * 0.92 + twitch * t * t
		tail.append(c + Vector2(10, 0) + Vector2(cos(a) * 62, sin(a) * 22 + 2))
	draw_polyline(tail, OUTLINE, 13.0, true)
	draw_polyline(tail, GINGER.darkened(0.08), 10.0, true)
	for i in range(2, 15, 3):
		draw_circle(tail[i], 4.0, DARK)
	draw_circle(tail[tail.size() - 1], 5.5, LIGHT)
	# Head resting on the front paws; an ear flicks when she's stroked
	var h := c + Vector2(-50, 6)
	var flick := _squash * 0.25
	draw_colored_polygon(DecorArt.ellipse_pts(h + Vector2(2, 16), 16, 6), CREAM)
	draw_colored_polygon(PackedVector2Array([h + Vector2(-15, -6), h + Vector2(-13, -30).rotated(-flick), h + Vector2(-1, -14)]), GINGER.darkened(0.12))
	draw_colored_polygon(PackedVector2Array([h + Vector2(1, -15), h + Vector2(12, -31), h + Vector2(16, -8)]), GINGER.darkened(0.12))
	draw_colored_polygon(PackedVector2Array([h + Vector2(-12, -9), h + Vector2(-11, -24), h + Vector2(-4, -14)]), Color(0.85, 0.55, 0.5))
	var head := DecorArt.ellipse_pts(h, 20, 17, 24)
	draw_colored_polygon(head, GINGER)
	_poly_outline(head)
	draw_arc(h + Vector2(0, -6), 9, PI * 1.25, PI * 1.75, 6, DARK, 2.5, true)
	draw_colored_polygon(DecorArt.ellipse_pts(h + Vector2(-4, 7), 9, 6), LIGHT)
	# Closed eyes; contented "smiling" ones while purring
	var lid := Color(0.15, 0.07, 0.03)
	if content > 0.1:
		draw_arc(h + Vector2(-9, 2), 4.5, PI + 0.3, TAU - 0.3, 6, lid, 1.8, true)
		draw_arc(h + Vector2(5, 2), 4.5, PI + 0.3, TAU - 0.3, 6, lid, 1.8, true)
	else:
		draw_arc(h + Vector2(-9, 0), 4.5, 0.25, PI - 0.25, 6, lid, 1.8, true)
		draw_arc(h + Vector2(5, 0), 4.5, 0.25, PI - 0.25, 6, lid, 1.8, true)
	draw_colored_polygon(PackedVector2Array([h + Vector2(-6, 6), h + Vector2(-2, 6), h + Vector2(-4, 9)]), Color(0.8, 0.45, 0.45))
	for k in 3:
		draw_line(h + Vector2(-12, 8 + k * 2.5), h + Vector2(-26, 6 + k * 4.0), Color(1, 1, 1, 0.45), 1.0, true)


func _draw_sit() -> void:
	## Sitting up, facing +x (the transform flips her). Tail wraps her paws,
	## or lashes behind her when she's cross.
	var cross := annoy >= WARN_AT or state == S.SHOOED
	var bob := sin(_t * 1.4) * 1.2
	draw_colored_polygon(DecorArt.ellipse_pts(Vector2(-4, 2), 54, 9), Color(0, 0, 0, 0.4))
	if cross:
		_draw_tail(Vector2(-38, -22), "lash")
	var haunch := DecorArt.ellipse_pts(Vector2(-14, -30), 34, 30, 26)
	draw_colored_polygon(haunch, GINGER.darkened(0.06))
	_poly_outline(haunch)
	for k in 4:
		draw_arc(Vector2(-14, -30), 18.0 + k * 5.0, PI * 1.05, PI * 1.45, 6, Color(DARK, 0.85), 2.5, true)
	_leg([Vector2(18, -44), Vector2(22, -20), Vector2(22, -2)], GINGER.darkened(0.25), 10.0)
	var chest := DecorArt.ellipse_pts(Vector2(6, -58 + bob * 0.5), 21, 34, 24)
	draw_colored_polygon(chest, GINGER)
	_poly_outline(chest)
	draw_colored_polygon(DecorArt.ellipse_pts(Vector2(16, -56 + bob * 0.5), 10, 24), CREAM)
	_leg([Vector2(8, -44), Vector2(10, -20), Vector2(10, -2)], GINGER, 11.0)
	if not cross:
		var twitch := maxf(0.0, sin(_t * 0.9)) * sin(_t * 8.0) * 0.12
		var tail := PackedVector2Array()
		for i in 15:
			var t := float(i) / 14.0
			var a := PI - t * (PI - 0.25) + twitch * t * t
			tail.append(Vector2(-6, -6) + Vector2(cos(a) * 42, sin(a) * 9))
		draw_polyline(tail, OUTLINE, 12.0, true)
		draw_polyline(tail, GINGER.darkened(0.08), 9.0, true)
		for i in range(2, 14, 3):
			draw_circle(tail[i], 3.5, DARK)
		draw_circle(tail[tail.size() - 1], 5.0, LIGHT)
	var look := 0.0
	if state == S.ROUSE and _target_ok():
		look = -0.25        # eyeing up the tree
	_draw_head(Vector2(14, -98 + bob), look, "wide" if state == S.ROUSE else ("narrow" if cross else "open"))


func _draw_stand() -> void:
	## Standing, walking, stalking, rearing to swipe, hissing or running.
	var stretch := 10.0 if state == S.FLEE else 0.0
	var hip := Vector2(-30 - stretch, -50 + _crouch * 20.0 - _arch * 10.0)
	var sh := Vector2(32 + stretch, -54 + _crouch * 22.0 - _arch * 8.0)
	if _rear > 0.01:
		sh = hip + (sh - hip).rotated(-_rear * 0.95)
	var axis := sh - hip
	var ang := axis.angle()
	var mid := (hip + sh) * 0.5
	var up := axis.normalized().rotated(-PI * 0.5)
	var moving := state == S.WALK or state == S.FLEE
	var stride := (18.0 if state == S.FLEE else 12.0) if moving else 0.0
	var wiggle := sin(_t * 18.0) * 3.0 if state == S.STALK and _st > 0.5 else 0.0
	draw_colored_polygon(DecorArt.ellipse_pts(Vector2(0, 2), 64, 9), Color(0, 0, 0, 0.4 * (1.0 - _rear * 0.5)))
	# Tail
	var tail_mode := "up"
	match state:
		S.STALK, S.POUNCE:
			tail_mode = "low"
		S.HISS:
			tail_mode = "puff"
		S.FLEE:
			tail_mode = "flat"
	_draw_tail(hip + Vector2(-18, -6 + wiggle * 0.5).rotated(_rear * -0.3), tail_mode)
	# Far legs (in shadow)
	var shade := GINGER.darkened(0.3)
	_leg(_hind(hip + Vector2(6, 0), PI, stride, wiggle), shade, 9.0)
	_leg(_front(sh + Vector2(-6, 2), 0.0, stride, true), shade, 9.0)
	# Body
	if _arch > 0.05:
		draw_colored_polygon(DecorArt.ellipse_pts(mid + up * (12.0 * _arch), 34, 20 * _arch + 4, 20, ang), GINGER.darkened(0.04))
	var body := DecorArt.ellipse_pts(mid + Vector2(wiggle * 0.3, 0), axis.length() * 0.5 + 16.0, 22.0 + _arch * 4.0, 28, ang)
	draw_colored_polygon(body, GINGER)
	draw_colored_polygon(DecorArt.ellipse_pts(hip + Vector2(wiggle, 0), 26, 24, 22), GINGER.darkened(0.05))
	draw_colored_polygon(DecorArt.ellipse_pts(sh, 22, 22, 22), GINGER)
	_poly_outline(body)
	draw_colored_polygon(DecorArt.ellipse_pts(mid - up * 11.0, axis.length() * 0.38, 9, 18, ang), LIGHT)
	for k in 5:
		var p := hip.lerp(sh, 0.15 + k * 0.17) + up * 8.0
		draw_arc(p, 16, ang - PI * 0.5 - 0.5, ang - PI * 0.5 + 0.5, 6, DARK, 3.0, true)
	if _arch > 0.4:
		# Hackles up
		for k in 9:
			var p := hip.lerp(sh, 0.1 + k * 0.1) + up * (20.0 + 12.0 * _arch)
			draw_line(p, p + up * 6.0 + Vector2(-2, 0), GINGER.darkened(0.1), 3.0, true)
	# Near legs
	_leg(_hind(hip + Vector2(-2, 0), 0.0, stride, wiggle), GINGER, 10.0)
	_leg(_front(sh + Vector2(4, 2), PI, stride, false), GINGER, 10.0)
	# Head
	var hp := sh + Vector2(22, -24).rotated(-_rear * 0.55) + Vector2(0, _crouch * 8.0)
	var eyes := "open"
	if state in [S.STALK, S.POUNCE]:
		eyes = "wide"
	elif state == S.HISS:
		eyes = "hiss"
	elif state == S.FLEE:
		eyes = "narrow"
	_draw_head(hp, -_rear * 0.5, eyes)


func _hind(hip: Vector2, phase: float, stride: float, wiggle: float) -> PackedVector2Array:
	var a := _gait + phase
	var foot := Vector2(hip.x + 4.0 + sin(a) * stride + wiggle * 0.5, -maxf(0.0, -cos(a)) * stride * 0.45)
	var knee := (hip + foot) * 0.5 + Vector2(-10.0 - _crouch * 8.0, 4.0)
	return PackedVector2Array([hip, knee, foot])


func _front(sh: Vector2, phase: float, stride: float, far: bool) -> PackedVector2Array:
	if _rear > 0.25:
		# Up on the hind legs: the near paw reaches for the ornament.
		var reach := sh + (_paw - sh).limit_length(70.0) if not far else sh + Vector2(14, 20).rotated(-_rear * 0.8)
		return PackedVector2Array([sh, (sh + reach) * 0.5 + Vector2(4, 4), reach])
	var a := _gait + phase
	var foot := Vector2(sh.x + 2.0 + sin(a) * stride, -maxf(0.0, -cos(a)) * stride * 0.45)
	var elbow := (sh + foot) * 0.5 + Vector2(3.0 + _crouch * 10.0, 0)
	return PackedVector2Array([sh, elbow, foot])


func _leg(pts: PackedVector2Array, col: Color, w: float) -> void:
	draw_polyline(pts, OUTLINE, w + 3.0, true)
	draw_polyline(pts, col, w, true)
	var foot := pts[pts.size() - 1]
	draw_colored_polygon(DecorArt.ellipse_pts(foot + Vector2(3, -2), 8, 5), col.lightened(0.08))


func _draw_tail(base: Vector2, mode: String) -> void:
	## A tail drawn like a turtle path: a start angle and a steady curl.
	var a0 := -PI * 0.6
	var curl := 1.3
	var length := 80.0
	var width := 10.0
	var wob := sin(_t * 2.2) * 0.15
	match mode:
		"low":
			a0 = PI - 0.2
			curl = -0.9
			wob = sin(_t * 14.0) * 0.2
		"lash":
			a0 = -PI * 0.72 + sin(_t * 7.0) * 0.55
			curl = 0.4
			wob = 0.0
		"puff":
			a0 = -PI * 0.55
			curl = 0.3
			width = 19.0
			wob = sin(_t * 30.0) * 0.04
		"flat":
			a0 = PI - 0.06
			curl = 0.1
			length = 88.0
			wob = sin(_t * 20.0) * 0.06
	var pts := PackedVector2Array([base])
	var p := base
	for i in 15:
		var t := float(i) / 14.0
		p += Vector2.from_angle(a0 + curl * t + wob * t * 2.0) * (length / 15.0)
		pts.append(p)
	draw_polyline(pts, OUTLINE, width + 3.0, true)
	draw_polyline(pts, GINGER.darkened(0.08), width, true)
	if mode == "puff":
		for i in range(1, pts.size(), 2):
			var n := (pts[mini(i + 1, pts.size() - 1)] - pts[i - 1]).normalized().rotated(PI * 0.5)
			draw_line(pts[i] + n * width * 0.5, pts[i] + n * (width * 0.5 + 5.0), GINGER.darkened(0.08), 3.0, true)
			draw_line(pts[i] - n * width * 0.5, pts[i] - n * (width * 0.5 + 5.0), GINGER.darkened(0.08), 3.0, true)
	for i in range(3, pts.size() - 1, 3):
		draw_circle(pts[i], width * 0.38, DARK)
	draw_circle(pts[pts.size() - 1], width * 0.52, LIGHT)


func _draw_head(h: Vector2, tilt: float, eyes: String) -> void:
	## A three-quarter head facing +x. eyes: open, wide, narrow, hiss.
	var tr := Transform2D(tilt, h)
	var P := func(v: Vector2) -> Vector2: return tr * v
	var ear_col := GINGER.darkened(0.12)
	var flat := _ears
	for side in [-1.0, 1.0]:
		var root := Vector2(-4.0 + side * 9.0, -13.0)
		var tip := root + Vector2(side * 4.0, -17.0).rotated(-side * flat * 1.1 - flat * 0.5) * (1.0 - flat * 0.35)
		var e1: Vector2 = P.call(root + Vector2(-7, 2))
		var e2: Vector2 = P.call(tip)
		var e3: Vector2 = P.call(root + Vector2(7, 2))
		draw_colored_polygon(PackedVector2Array([e1, e2, e3]), ear_col)
		draw_colored_polygon(PackedVector2Array([P.call(root + Vector2(-4, 1)), e2.lerp(P.call(root), 0.25), P.call(root + Vector2(4, 1))]), Color(0.85, 0.55, 0.5))
	var head := PackedVector2Array()
	for v in DecorArt.ellipse_pts(Vector2.ZERO, 21, 18, 24):
		head.append(P.call(v))
	draw_colored_polygon(head, GINGER)
	_poly_outline(head)
	# Forehead stripes
	for k in 3:
		draw_line(P.call(Vector2(-6 + k * 5, -16)), P.call(Vector2(-5 + k * 4, -9)), DARK, 2.2, true)
	var muzzle := PackedVector2Array()
	for v in DecorArt.ellipse_pts(Vector2(11, 7), 11, 7):
		muzzle.append(P.call(v))
	draw_colored_polygon(muzzle, CREAM)
	draw_colored_polygon(PackedVector2Array([P.call(Vector2(17, 1)), P.call(Vector2(22, 1)), P.call(Vector2(19.5, 4.5))]), Color(0.8, 0.45, 0.45))
	if eyes == "hiss":
		draw_colored_polygon(PackedVector2Array([P.call(Vector2(8, 9)), P.call(Vector2(20, 8)), P.call(Vector2(15, 16))]), Color(0.3, 0.05, 0.05))
		draw_line(P.call(Vector2(11, 9)), P.call(Vector2(11.5, 12)), Color.WHITE, 1.5)
		draw_line(P.call(Vector2(18, 8.5)), P.call(Vector2(18, 11.5)), Color.WHITE, 1.5)
	for k in 3:
		draw_line(P.call(Vector2(16, 8 + k * 2.5)), P.call(Vector2(34, 5 + k * 4.0)), Color(1, 1, 1, 0.5), 1.0, true)
	var lid := Color(0.15, 0.07, 0.03)
	for e in [[Vector2(-2, -3), 4.6], [Vector2(11, -3), 3.8]]:
		var c: Vector2 = P.call(e[0])
		var r: float = e[1]
		match eyes:
			"wide":
				draw_circle(c, r + 1.0, Color(0.78, 0.72, 0.2))
				draw_circle(c + Vector2(0.5, 0), r * 0.75, Color(0.05, 0.03, 0.02))
				draw_circle(c + Vector2(-1, -1.5), 1.2, Color(1, 1, 1, 0.9))
			"narrow", "hiss":
				draw_colored_polygon(DecorArt.ellipse_pts(c, r + 0.5, 1.8, 12, tilt + 0.25), Color(0.78, 0.72, 0.2))
				draw_line(c + Vector2(-r - 1, -2).rotated(tilt), c + Vector2(r + 1, 0.5).rotated(tilt), lid, 2.0, true)
			_:
				draw_colored_polygon(DecorArt.ellipse_pts(c, r, r * 0.7, 14, tilt), Color(0.78, 0.72, 0.2))
				draw_line(c + Vector2(0, -r * 0.6).rotated(tilt), c + Vector2(0, r * 0.6).rotated(tilt), Color(0.05, 0.03, 0.02), 1.6)
				draw_circle(c + Vector2(-1, -1), 0.9, Color(1, 1, 1, 0.8))


# ========================================================= little effects

func _fx_add(kind: String, at: Vector2) -> void:
	var life := 1.6 if kind == "z" else 1.1
	_fx.append([kind, at + Vector2(_rng.randf_range(-6, 6), 0), Vector2(_rng.randf_range(-12, 12), -42), life, life])


func _fx_update(delta: float) -> void:
	for i in range(_fx.size() - 1, -1, -1):
		var f: Array = _fx[i]
		f[3] -= delta
		if f[3] <= 0.0:
			_fx.remove_at(i)
			continue
		f[1] += f[2] * delta
		if f[0] == "z":
			f[1] = f[1] + Vector2(sin(_t * 3.0 + i) * 0.4, 0.0)


func _draw_fx() -> void:
	for f in _fx:
		var kind: String = f[0]
		var p: Vector2 = f[1] - position
		var a: float = clampf(f[3] / f[4] * 1.6, 0.0, 1.0)
		var grow: float = 1.0 + (1.0 - f[3] / f[4]) * 0.4
		match kind:
			"heart":
				_heart(p, 7.0 * grow, Color(0.86, 0.18, 0.24, a))
			"anger":
				var col := Color(0.85, 0.12, 0.08, a)
				for k in 4:
					var dir := Vector2.from_angle(PI * 0.25 + k * PI * 0.5)
					draw_line(p + dir * 3.0 * grow, p + dir * 9.0 * grow, col, 3.0, true)
			"z":
				var font := UIKit.font("title_italic")
				draw_string_outline(font, p, "z", HORIZONTAL_ALIGNMENT_LEFT, -1, int(16 * grow), 4, Color(0.1, 0.05, 0.02, a * 0.6))
				draw_string(font, p, "z", HORIZONTAL_ALIGNMENT_LEFT, -1, int(16 * grow), Color(1, 0.95, 0.85, a * 0.85))


func _heart(c: Vector2, s: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var t := TAU * i / 24.0
		pts.append(c + Vector2(16.0 * pow(sin(t), 3.0), -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))) * (s / 16.0))
	draw_colored_polygon(pts, col)
	_poly_outline(pts, 1.5, Color(0.35, 0.04, 0.06, col.a))
