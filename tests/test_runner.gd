extends Node
## Automated tests. Run headless:
##   godot --headless --path . res://tests/test_runner.tscn
## Exits with the number of failures (0 = all passed).

const KNOWN_DRAW := ["candle", "bauble", "teardrop", "icicle", "bird", "pinecone", "grapes", "dresden_star", "cornucopia",
	"scrap_angel", "fan", "candy_cane", "gingerbread", "apple", "walnut", "pomander", "sugar_mouse", "angel", "star",
	"spire", "rosette", "mantel_garland", "stocking", "present", "present_tartan", "candlestick", "holly", "wreath",
	"mistletoe", "teddy", "rocking_horse", "soldier", "ark", "drum", "cards", "tinsel", "popcorn", "cranberry", "beads",
	"paper_chain", "electric"]

var _pass := 0
var _fail := 0


func check(cond: bool, what: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		print("  FAIL: ", what)


func _ready() -> void:
	print("== A Timeless Christmas Tree: tests ==")
	_test_catalogue()
	await _test_placement()
	await _test_decor_manager()
	_test_game_state()
	_test_carols()
	_test_synth()
	await _test_flow()
	print("== %d passed, %d failed ==" % [_pass, _fail])
	get_tree().quit(_fail)


func _test_catalogue() -> void:
	print("catalogue")
	var ids := Catalogue.all_ids()
	check(ids.size() >= 45, "at least 45 decorations (%d)" % ids.size())
	var tabs := []
	for t in Catalogue.TABS:
		tabs.append(t["id"])
	for id in ids:
		var d := Catalogue.get_item(id)
		for k in ["id", "name", "tab", "kind", "draw", "color", "rect", "sound", "desc"]:
			check(d.has(k), "%s has %s" % [id, k])
		check(d["tab"] in tabs, "%s tab valid" % id)
		check(d["draw"] in KNOWN_DRAW, "%s draw style known" % id)
		if d["kind"] == "room":
			check(d.has("zone"), "%s has a zone" % id)
		check((d["rect"] as Rect2).size.x > 0.0, "%s rect has size" % id)
	for t in tabs:
		check(Catalogue.items_in_tab(t).size() > 0, "tab %s not empty" % t)


func _make_tree() -> TreeArt:
	var tree := TreeArt.new()
	tree.height = RoomLayout.TREE_HEIGHT
	tree.width = RoomLayout.TREE_WIDTH
	tree.position = RoomLayout.TREE_BASE
	add_child(tree)
	return tree


func _test_placement() -> void:
	print("placement")
	var tree := _make_tree()
	await get_tree().process_frame
	var mid := tree.position + Vector2(0, -300)
	var r := Placement.resolve(Catalogue.get_item("bauble_red"), mid, tree, [], false, false)
	check(r["ok"] and r["layer"] == "ornament", "bauble hangs in the middle of the tree")
	r = Placement.resolve(Catalogue.get_item("bauble_red"), Vector2(200, 300), tree, [], false, false)
	check(not r["ok"], "bauble refused on the wall")
	var apex := tree.position + tree.apex
	r = Placement.resolve(Catalogue.get_item("topper_star"), apex + Vector2(40, 60), tree, [], false, false)
	check(r["ok"] and r["snap"] and (r["pos"] as Vector2).distance_to(apex) < 20.0, "topper snaps to the apex")
	r = Placement.resolve(Catalogue.get_item("topper_star"), apex + Vector2(0, 400), tree, [], true, false)
	check(not r["ok"], "topper refused far from the apex")
	r = Placement.resolve(Catalogue.get_item("topper_angel"), apex, tree, [], true, false)
	check(r["ok"] and r["replace"], "second topper replaces the first")
	r = Placement.resolve(Catalogue.get_item("stocking_red"), RoomLayout.STOCKING_HOOKS[1] + Vector2(10, 30), tree, [], false, false)
	check(r["ok"] and r["hook"] == 1, "stocking snaps to the nearest hook")
	r = Placement.resolve(Catalogue.get_item("stocking_red"), RoomLayout.STOCKING_HOOKS[1], tree, [0, 1, 2, 3], false, false)
	check(not r["ok"], "no free hooks, stocking refused")
	r = Placement.resolve(Catalogue.get_item("present_red"), Vector2(500, 880), tree, [], false, false)
	check(r["ok"] and r["layer"] == "floor", "present on the floor")
	r = Placement.resolve(Catalogue.get_item("present_red"), Vector2(1600, 800), tree, [], false, false)
	check(not r["ok"], "present refused under the armchair")
	r = Placement.resolve(Catalogue.get_item("candlestick"), Vector2(200, 380), tree, [], false, false)
	check(r["ok"] and is_equal_approx((r["pos"] as Vector2).y, RoomLayout.MANTEL_Y), "candlestick snaps to the mantel")
	r = Placement.resolve(Catalogue.get_item("candlestick"), Vector2(RoomLayout.CLOCK_X, 400), tree, [], false, false)
	check(not r["ok"], "candlestick keeps clear of the clock")
	r = Placement.resolve(Catalogue.get_item("wreath"), mid, tree, [], false, false)
	check(not r["ok"], "wreath refused on the tree")
	r = Placement.resolve(Catalogue.get_item("mantel_garland"), Vector2(340, 430), tree, [], false, true)
	check(not r["ok"], "only one mantel garland")
	var ends := Placement.garland_ends(mid, tree)
	check((ends[0] as Vector2).x < tree.position.x and (ends[1] as Vector2).x > tree.position.x, "garland spans the tree")
	var e := Placement.clamp_garland_end(Vector2(-500, 2000), tree)
	check(tree.contains_local(e - tree.position + Vector2(0, -2), -10.0) or e.y <= tree.position.y, "garland end clamped onto tree")
	tree.queue_free()


func _test_decor_manager() -> void:
	print("decor manager")
	var tree := _make_tree()
	var dm := DecorManager.new()
	add_child(dm)
	dm.setup(tree)
	await get_tree().process_frame
	var items := [
		{"id": "bauble_gold", "x": 960.0, "y": 600.0, "seed": 4},
		{"id": "tinsel_gold", "x": 820.0, "y": 420.0, "x2": 1080.0, "y2": 450.0, "seed": 5},
		{"id": "stocking_red", "x": 150.0, "y": 448.0, "hook": 0, "seed": 6},
		{"id": "present_red", "x": 840.0, "y": 905.0, "seed": 7},
		{"id": "no_such_thing", "x": 1.0, "y": 1.0},
	]
	dm.load_items(items)
	var s := dm.serialize()
	check(s.size() == 4, "unknown ids are skipped on load")
	check(s[0]["id"] == "bauble_gold" and is_equal_approx(float(s[0]["x"]), 960.0), "round trip keeps position")
	check(s[1].has("x2"), "garland keeps both ends")
	dm.push_undo()
	dm.load_items([])
	check(dm.count() == 0, "cleared")
	dm.undo()
	check(dm.count() == 4, "undo restores the tree")
	dm.set_candles_lit(true, false)
	dm.load_items([{"id": "candle_white", "x": 960.0, "y": 600.0}])
	await get_tree().process_frame
	check(dm.light_count() == 1, "candle counted as a light")
	dm.queue_free()
	tree.queue_free()


func _test_game_state() -> void:
	print("game state")
	var keep := GameState.arrangements.duplicate(true)
	var keep_i := GameState.current_arrangement
	GameState.switch_arrangement(2)
	GameState.set_current_items([{"id": "apple", "x": 1.0, "y": 2.0}])
	check(not GameState.is_arrangement_empty(2), "items stored in arrangement")
	GameState.copy_arrangement(2, 5)
	check((GameState.arrangements[5]["items"] as Array).size() == 1, "arrangement copied")
	GameState.clear_arrangement(5)
	check(GameState.is_arrangement_empty(5), "arrangement cleared")
	GameState.save_game()
	GameState.arrangements[2]["items"] = []
	GameState.load_game()
	check((GameState.arrangements[2]["items"] as Array).size() == 1, "save/load round trip")
	GameState.arrangements = keep
	GameState.current_arrangement = keep_i
	GameState.save_game()


func _test_carols() -> void:
	print("carols")
	check(Carols.note_to_midi("C4") == 60, "C4 = 60")
	check(Carols.note_to_midi("F#4") == 66, "F#4 = 66")
	check(Carols.note_to_midi("Bb3") == 58, "Bb3 = 58")
	var minor: Array = Carols.chord_tones("Em")
	check(minor[0] == 4 and (minor[1] as Array)[1] == 3, "Em is minor on E")
	for song in Carols.SONGS:
		check(Carols.bar_lengths_ok(song), "%s: every bar adds up" % song["title"])
		var bars := Carols.parse_melody(song["melody"])
		var chords := (song["chords"] as String).split("|")
		check(bars.size() == chords.size(), "%s: one chord entry per bar (%d vs %d)" % [song["title"], bars.size(), chords.size()])
		var ev := Carols.arrange(song, 0)
		check(ev.size() > 20, "%s arranged" % song["title"])


func _test_synth() -> void:
	print("synth")
	var sfx := Synth.make_sfx()
	for k in ["click", "glass", "paper", "soft", "wood", "tinsel", "match", "chime", "sleigh", "page", "shutter"]:
		check(sfx.has(k), "sfx %s exists" % k)
	var job := Synth.StringJob.new(60, 0.5, "piano")
	var guard := 0
	while not job.step(4000) and guard < 100:
		guard += 1
	check(job.result != null and job.result.data.size() > 1000, "string job renders a note")
	check(absf(job.true_freq - 261.6) < 6.0, "string job roughly in tune (%f)" % job.true_freq)


func _test_flow() -> void:
	print("flow")
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(2.5).timeout
	check(main.current is TitleScreen, "starts on the title")
	(main.current as TitleScreen).begin_story.emit()
	for stage in 4:
		await get_tree().create_timer(2.6).timeout
		check(main.current is StoryScene and (main.current as StoryScene).stage == stage, "story chapter %d" % stage)
		if main.current is StoryScene:
			(main.current as StoryScene)._finish()
	await get_tree().create_timer(2.6).timeout
	check(main.current is Parlour, "story ends in the parlour")
	var p := main.current as Parlour
	if p:
		p.decor.begin_new_drag("bauble_red")
		check(p.decor.is_dragging(), "dragging from the trunk")
		await get_tree().create_timer(0.3).timeout
		check(not p.decor.is_dragging(), "drag ends when the button is up")
		p.set_lamps(false)
		p.set_candles(true)
		check(not p.lamps_on and p.candles_lit, "lighting toggles")
		await p.switch_arrangement(1)
		check(GameState.current_arrangement == 1, "switched arrangement")
		await p.switch_arrangement(0)
		p.ui.set_trunk_open(true)
		await get_tree().create_timer(0.5).timeout
		check(p.ui.trunk_rect().size.x > 0.0, "trunk opens")
		p.request_story(1)
		await get_tree().create_timer(3.0).timeout
		check(main.current is StoryScene, "timeline replays a chapter")
		(main.current as StoryScene)._finish()
		await get_tree().create_timer(2.6).timeout
		check(main.current is Parlour, "single chapter returns to the parlour")
	main.queue_free()
