extends Node
## AudioDirector — buses, synthesised instruments, the carol sequencer,
## ambience beds and sound effects. Everything is generated in code (Synth)
## so the game ships with no audio files.
##
## Instruments and ambience render progressively (a few thousand samples
## each frame); music starts as soon as the piano and harp are "tuned".

const MUSIC_BUS := "Music"
const AMB_BUS := "Ambience"
const SFX_BUS := "SFX"
const PIANO_NOTES := [36, 40, 44, 48, 52, 55, 58, 61, 64, 67, 70, 73, 76, 79, 82, 86, 90]
const HARP_NOTES := [43, 47, 51, 55, 58, 61, 64, 67, 70, 73, 76, 79, 83, 87, 91]
const VOICES := 28
const RENDER_BUDGET := 9000

var _sfx: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_next := 0
var _inst: Dictionary = {"piano": {}, "harp": {}}   # inst -> {midi: [stream, true_freq]}
var _voices: Array[AudioStreamPlayer] = []
var _voice_next := 0
var _jobs: Array = []                 # [job, callback]
var _fire: AudioStreamPlayer
var _wind: AudioStreamPlayer
var _amb_streams: Dictionary = {}
var _amb_kind := ""
var _bird_timer := 0.0

# Sequencer state
var _music_kind := ""
var _playlist: Array = []
var _song_i := 0
var _events: Array = []
var _event_i := 0
var _beat := 0.0
var _tempo := 80.0
var _gap := 0.0
var _variation := 0
var _ready_for_music := false
var _fade := 1.0
## When true, scene changes don't restart the music (used by the trailer).
var music_locked := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_make_buses()
	_sfx = Synth.make_sfx()
	for i in 12:
		_sfx_players.append(_player(SFX_BUS))
	for i in VOICES:
		_voices.append(_player(MUSIC_BUS))
	_fire = _player(AMB_BUS)
	_wind = _player(AMB_BUS)
	_queue_instrument_jobs()
	_jobs.append([Synth.FireJob.new(6.0), _store_amb.bind("fire")])
	_jobs.append([Synth.WindJob.new(9.0), _store_amb.bind("wind")])
	GameState.settings_changed.connect(_apply_volumes)
	_apply_volumes()


func _make_buses() -> void:
	## The buses (and their reverbs) live in default_bus_layout.tres. That file
	## matters for the browser build: the web audio graph is built from the bus
	## layout at startup, so a bus only added here in code would be silent there.
	## This just fills in anything missing.
	for n in [MUSIC_BUS, AMB_BUS, SFX_BUS]:
		if AudioServer.get_bus_index(n) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, n)
			AudioServer.set_bus_send(idx, "Master")


func _player(bus: String) -> AudioStreamPlayer:
	## Every sound in the game is synthesised at runtime. In the browser, Godot's
	## default "sample" playback is silent for streams made at runtime, so web
	## builds use "stream" playback, where the engine mixes the sound itself.
	var p := AudioStreamPlayer.new()
	p.bus = bus
	if OS.has_feature("web"):
		p.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(p)
	return p


func _apply_volumes() -> void:
	_set_bus(MUSIC_BUS, float(GameState.settings["music_volume"]) * 0.8)
	_set_bus(AMB_BUS, float(GameState.settings["ambience_volume"]) * 0.7)
	_set_bus(SFX_BUS, float(GameState.settings["sfx_volume"]))


func _set_bus(n: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(n)
	AudioServer.set_bus_mute(idx, linear <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))


func _queue_instrument_jobs() -> void:
	# Middle notes first so the melody is ready soonest.
	var order := PIANO_NOTES.duplicate()
	order.sort_custom(func(a: int, b: int) -> bool: return absi(a - 64) < absi(b - 64))
	for m in order:
		var secs := clampf(3.4 - (m - 36) * 0.035, 1.3, 3.4)
		var job := Synth.StringJob.new(m, secs, "piano")
		_jobs.append([job, _store_note.bind("piano", job)])
	for m in HARP_NOTES:
		var secs := clampf(2.6 - (m - 43) * 0.03, 1.1, 2.6)
		var job := Synth.StringJob.new(m, secs, "harp")
		_jobs.append([job, _store_note.bind("harp", job)])


func _store_amb(w: AudioStreamWAV, key: String) -> void:
	_amb_streams[key] = w
	_refresh_ambience()


func _store_note(w: AudioStreamWAV, inst: String, job: Synth.StringJob) -> void:
	(_inst[inst] as Dictionary)[job.midi] = [w, job.true_freq]
	if (_inst["piano"] as Dictionary).size() == PIANO_NOTES.size() and (_inst["harp"] as Dictionary).size() == HARP_NOTES.size():
		_ready_for_music = true


func is_ready() -> bool:
	return _ready_for_music


func finish_jobs() -> void:
	## Renders every pending instrument note and ambience loop right now.
	while not _jobs.is_empty():
		var job: Synth.SynthJob = _jobs[0][0]
		while not job.step(200000):
			pass
		var cb: Callable = _jobs[0][1]
		_jobs.pop_front()
		cb.call(job.result)


func start_music_now(kind: String) -> void:
	play_music_for(kind)
	_gap = 0.0


# ====================================================================== SFX

func sfx(sound: String, pitch: float = 1.0, vol_db: float = 0.0) -> void:
	var key := sound
	if sound == "glass" and randf() < 0.5:
		key = "glass2"
	if sound == "chirp":
		key = "chirp%d" % (randi() % 3)
	if not _sfx.has(key):
		return
	var p := _sfx_players[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx_players.size()
	p.stream = _sfx[key]
	p.pitch_scale = pitch * randf_range(0.97, 1.03)
	p.volume_db = vol_db
	p.play()


# ================================================================ ambience

func set_scene_ambience(kind: String) -> void:
	## kind: "parlour" (fire + soft wind), "spring", "summer", "winter", "title", "none"
	_amb_kind = kind
	_refresh_ambience()


func _refresh_ambience() -> void:
	var want_fire := _amb_kind == "parlour"
	var wind_db := -60.0
	match _amb_kind:
		"parlour": wind_db = -20.0
		"winter", "title": wind_db = -8.0
		"autumn": wind_db = -12.0
		"spring", "summer": wind_db = -26.0
	_set_loop(_fire, "fire", want_fire, -4.0)
	_set_loop(_wind, "wind", wind_db > -59.0, wind_db)


func _set_loop(p: AudioStreamPlayer, key: String, on: bool, db: float) -> void:
	if not _amb_streams.has(key):
		return
	if on:
		if p.stream != _amb_streams[key]:
			p.stream = _amb_streams[key]
		if not p.playing:
			p.volume_db = -40.0
			p.play()
		create_tween().tween_property(p, "volume_db", db, 1.5)
	elif p.playing:
		var tw := create_tween()
		tw.tween_property(p, "volume_db", -50.0, 1.2)
		tw.tween_callback(p.stop)


# =================================================================== music

func play_music_for(kind: String) -> void:
	if kind == _music_kind or music_locked:
		return
	_music_kind = kind
	var order: Array
	match kind:
		"title":
			order = [0, 1, 4, 2, 3]
		"story":
			order = [1, 3, 0]
		"parlour":
			order = [0, 2, 1, 4, 3]
		_:
			order = []
	_playlist = order
	_song_i = 0
	_variation = 0
	_events.clear()
	_gap = 0.8


func stop_music() -> void:
	_music_kind = ""
	_playlist = []
	_events.clear()


func _start_song() -> void:
	var song: Dictionary = Carols.SONGS[_playlist[_song_i % _playlist.size()]]
	_tempo = float(song["tempo"])
	if _music_kind == "story":
		_variation = 1
	_events = Carols.arrange(song, _variation)
	_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["t"] < b["t"])
	_event_i = 0
	_beat = -0.5


func _process(delta: float) -> void:
	# Progressive rendering of instruments and ambience
	var budget := RENDER_BUDGET
	while budget > 0 and not _jobs.is_empty():
		var job: Synth.SynthJob = _jobs[0][0]
		if job.step(budget):
			var cb: Callable = _jobs[0][1]
			_jobs.pop_front()
			cb.call(job.result)
		budget -= RENDER_BUDGET / 2
	# Spring birdsong
	if _amb_kind == "spring" or _amb_kind == "summer":
		_bird_timer -= delta
		if _bird_timer <= 0.0:
			_bird_timer = randf_range(1.5, 4.5)
			sfx("chirp", randf_range(0.9, 1.15), -12.0)
	_sequence(delta)


func _sequence(delta: float) -> void:
	if not _ready_for_music or _playlist.is_empty():
		return
	if _events.is_empty():
		_gap -= delta
		if _gap <= 0.0:
			_start_song()
		return
	_beat += delta * _tempo / 60.0
	while _event_i < _events.size() and float(_events[_event_i]["t"]) <= _beat:
		_play_note(_events[_event_i])
		_event_i += 1
	if _event_i >= _events.size():
		var last: Dictionary = _events[_events.size() - 1]
		if _beat > float(last["t"]) + float(last["dur"]) + 1.0:
			_events.clear()
			_gap = 3.5
			# Play each carol twice (the second time lighter), then move on.
			if _variation == 0 and _music_kind != "story":
				_variation = 1
			else:
				_variation = 0
				_song_i += 1


func _play_note(e: Dictionary) -> void:
	var inst: String = e["inst"]
	var bank: Dictionary = _inst.get(inst, {})
	if bank.is_empty():
		return
	var midi: int = e["midi"]
	# Nearest rendered sample, then resample to pitch.
	var best := -1
	var best_d := 999
	for k in bank.keys():
		var dd := absi(int(k) - midi)
		if dd < best_d:
			best_d = dd
			best = int(k)
	var entry: Array = bank[best]
	var target := 440.0 * pow(2.0, (midi - 69) / 12.0)
	var v := _voices[_voice_next]
	_voice_next = (_voice_next + 1) % _voices.size()
	v.stream = entry[0]
	v.pitch_scale = target / float(entry[1])
	var vel: float = float(e["vel"]) * randf_range(0.9, 1.05)
	v.volume_db = linear_to_db(maxf(vel, 0.01)) - 4.0
	v.play()
