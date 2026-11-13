extends Node
## GameState — the single source of truth for everything that persists:
## settings, story progress and the player's saved tree "arrangements".
##
## Design note: there is deliberately no score, timer or currency anywhere in
## this file. The only state worth keeping is what the player has made.

signal settings_changed
signal arrangement_changed(index: int)

const SAVE_PATH := "user://chronicle.json"
const SAVE_VERSION := 1
const ARRANGEMENT_COUNT := 6
const ROMAN := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]

## Narrative stages shown on the timeline (index 4 = the decorating sandbox).
const STAGES := [
	{"id": "seedling", "title": "Tiny Seedling", "chapter": "Chapter I: The Tiny Seedling"},
	{"id": "forest", "title": "Growing in Forest", "chapter": "Chapter II: Growing in the Forest"},
	{"id": "arrival", "title": "The Family Arrival", "chapter": "Chapter III: The Family Arrival"},
	{"id": "choosing", "title": "Choosing the Tree", "chapter": "Chapter IV: Choosing the Tree"},
	{"id": "decorating", "title": "Decorating the Home", "chapter": "Chapter V: The Decorated Home"},
]

var settings := {
	"music_volume": 0.65,
	"ambience_volume": 0.6,
	"sfx_volume": 0.8,
	"painterly": 2,        # 0 = off, 1 = light (grade only), 2 = full oil-paint filter
	"snow": true,
	"twinkle": true,
	"idle_fireside": true,
	"cat_mischief": true,  # Marmalade bats at the low ornaments now and then
	"trunk_x": -1.0,       # where the player left the trunk (-1 = docked right)
	"trunk_y": 124.0,
	"fullscreen": false,
}

## Highest stage the player has reached (0..4). Stages <= this are replayable.
var stage_reached := -1
var story_complete := false
var current_arrangement := 0
var arrangements: Array = []

var _save_queued := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_reset_arrangements()
	load_game()
	# Touch-first devices get the lighter filter by default (first run only).
	if not FileAccess.file_exists(SAVE_PATH) and _is_touch_device():
		settings["painterly"] = 1


func _is_touch_device() -> bool:
	return OS.has_feature("web_android") or OS.has_feature("web_ios") \
		or OS.has_feature("android") or OS.has_feature("ios")


func _reset_arrangements() -> void:
	arrangements.clear()
	for i in ARRANGEMENT_COUNT:
		arrangements.append(_blank_arrangement(i))


func _blank_arrangement(i: int) -> Dictionary:
	return {
		"name": "Arrangement %s" % ROMAN[i],
		"items": [],
		"lamps_on": true,
		"candles_lit": false,
		"updated": 0,
	}


# ---------------------------------------------------------------- arrangements

func current() -> Dictionary:
	return arrangements[current_arrangement]


func set_current_items(items: Array) -> void:
	var a: Dictionary = arrangements[current_arrangement]
	a["items"] = items.duplicate(true)
	a["updated"] = int(Time.get_unix_time_from_system())
	queue_save()


func set_lighting(lamps_on: bool, candles_lit: bool) -> void:
	var a: Dictionary = arrangements[current_arrangement]
	a["lamps_on"] = lamps_on
	a["candles_lit"] = candles_lit
	queue_save()


func switch_arrangement(index: int) -> void:
	current_arrangement = clampi(index, 0, ARRANGEMENT_COUNT - 1)
	queue_save()
	arrangement_changed.emit(current_arrangement)


func copy_arrangement(from_index: int, to_index: int) -> void:
	var src: Dictionary = arrangements[from_index]
	var dst: Dictionary = arrangements[to_index]
	dst["items"] = (src["items"] as Array).duplicate(true)
	dst["lamps_on"] = src["lamps_on"]
	dst["candles_lit"] = src["candles_lit"]
	dst["updated"] = int(Time.get_unix_time_from_system())
	queue_save()


func clear_arrangement(index: int) -> void:
	arrangements[index] = _blank_arrangement(index)
	queue_save()


func is_arrangement_empty(index: int) -> bool:
	return (arrangements[index]["items"] as Array).is_empty()


func thumb_path(index: int) -> String:
	return "user://album_%d.png" % index


# ------------------------------------------------------------------- progress

func reach_stage(stage: int) -> void:
	if stage > stage_reached:
		stage_reached = stage
		if stage >= 4:
			story_complete = true
		queue_save()


func has_save() -> bool:
	return story_complete or stage_reached >= 4


# ------------------------------------------------------------------- settings

func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	if key == "fullscreen":
		apply_fullscreen()
	settings_changed.emit()
	queue_save()


func apply_fullscreen() -> void:
	var want: bool = settings["fullscreen"]
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if want else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


# ------------------------------------------------------------------ save/load

## Saves are coalesced to once per frame — dragging many ornaments shouldn't
## hammer IndexedDB on the web build.
func queue_save() -> void:
	if _save_queued:
		return
	_save_queued = true
	_flush_save.call_deferred()


func _flush_save() -> void:
	_save_queued = false
	save_game()


func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"settings": settings,
		"stage_reached": stage_reached,
		"story_complete": story_complete,
		"current_arrangement": current_arrangement,
		"arrangements": arrangements,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Could not write save: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save file unreadable — starting fresh.")
		return
	var data: Dictionary = parsed
	var s: Dictionary = data.get("settings", {})
	for k in s.keys():
		if settings.has(k):
			settings[k] = s[k]
	settings["painterly"] = int(settings["painterly"])
	stage_reached = int(data.get("stage_reached", -1))
	story_complete = bool(data.get("story_complete", false))
	current_arrangement = clampi(int(data.get("current_arrangement", 0)), 0, ARRANGEMENT_COUNT - 1)
	var arr: Array = data.get("arrangements", [])
	for i in mini(arr.size(), ARRANGEMENT_COUNT):
		if typeof(arr[i]) == TYPE_DICTIONARY:
			var a: Dictionary = _blank_arrangement(i)
			for k in (arr[i] as Dictionary).keys():
				a[k] = arr[i][k]
			arrangements[i] = a


func reset_everything() -> void:
	_reset_arrangements()
	stage_reached = -1
	story_complete = false
	current_arrangement = 0
	for i in ARRANGEMENT_COUNT:
		if FileAccess.file_exists(thumb_path(i)):
			DirAccess.remove_absolute(thumb_path(i))
	save_game()
	arrangement_changed.emit(current_arrangement)
