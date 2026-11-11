class_name Synth
extends RefCounted
## Synth — every sound in the game is synthesised here at runtime.
##
## Short effects are rendered immediately. Instrument notes and ambience
## loops are rendered by resumable jobs (SynthJob) a few thousand samples per
## frame, so the web build never stalls while it "tunes the piano".

const MIX := 22050


# =================================================================== helpers

static func to_wav(data: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		bytes.encode_s16(i * 2, int(clampf(data[i], -1.0, 1.0) * 32760.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = MIX
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = data.size()
	return w


static func buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * MIX))
	return b


static func normalize(b: PackedFloat32Array, peak: float = 0.9) -> PackedFloat32Array:
	var m := 0.0001
	for v in b:
		m = maxf(m, absf(v))
	var k := peak / m
	for i in b.size():
		b[i] *= k
	return b


static func fade_edges(b: PackedFloat32Array, fade_in: float = 0.002, fade_out: float = 0.02) -> void:
	var fi := int(fade_in * MIX)
	var fo := int(fade_out * MIX)
	var n := b.size()
	for i in mini(fi, n):
		b[i] *= float(i) / fi
	for i in mini(fo, n):
		b[n - 1 - i] *= float(i) / fo


# ===================================================== one-shot effects

static func noise_burst(dur: float, attack: float, decay: float, lp: float, hp: float, seed_v: int = 1) -> PackedFloat32Array:
	## Filtered noise with an attack/decay envelope. lp/hp are one-pole
	## coefficients in 0..1 (higher = brighter for lp, more bass cut for hp).
	var b := buf(dur)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var y := 0.0
	var low := 0.0
	var n := b.size()
	var a_n := maxf(1.0, attack * MIX)
	for i in n:
		var x := rng.randf_range(-1.0, 1.0)
		y += lp * (x - y)
		low += hp * (y - low)
		var s := y - low
		var t := float(i) / MIX
		var env := minf(1.0, i / a_n) * exp(-t / maxf(0.001, decay))
		b[i] = s * env
	return b


static func bell(freq: float, dur: float, ratios: Array, amps: Array, decay: float) -> PackedFloat32Array:
	var b := buf(dur)
	var n := b.size()
	for p in ratios.size():
		var w := TAU * freq * float(ratios[p]) / MIX
		var c := 2.0 * cos(w)
		var y1 := sin(-w)
		var y2 := sin(-2.0 * w)
		var amp: float = amps[p]
		var dk := exp(-1.0 / (MIX * decay / (1.0 + p * 0.7)))
		for i in n:
			var y := c * y1 - y2
			y2 = y1
			y1 = y
			b[i] += y * amp
			amp *= dk
	fade_edges(b, 0.001, 0.02)
	return b


static func mix_into(dst: PackedFloat32Array, src: PackedFloat32Array, offset_s: float, gain: float = 1.0) -> void:
	var o := int(offset_s * MIX)
	for i in src.size():
		var j := o + i
		if j >= dst.size():
			break
		dst[j] += src[i] * gain


static func sweep(f0: float, f1: float, dur: float, vib: float = 0.0, harm: int = 1) -> PackedFloat32Array:
	var b := buf(dur)
	var n := b.size()
	var ph := 0.0
	for i in n:
		var t := float(i) / n
		var f := lerpf(f0, f1, t) * (1.0 + sin(t * 40.0) * vib)
		ph += TAU * f / MIX
		var s := 0.0
		for h in harm:
			s += sin(ph * (h + 1)) / (h + 1)
		b[i] = s * sin(t * PI)
	return b


static func make_sfx() -> Dictionary:
	## Builds the whole library of short sound effects.
	var d := {}
	# Wooden click (UI)
	var click := noise_burst(0.05, 0.0005, 0.008, 0.5, 0.15, 3)
	mix_into(click, bell(180.0, 0.05, [1.0], [0.5], 0.01), 0.0)
	d["click"] = to_wav(normalize(click, 0.6))
	d["hover"] = to_wav(normalize(noise_burst(0.03, 0.0005, 0.004, 0.7, 0.4, 4), 0.25))
	# Glass ting (two variants for variety)
	d["glass"] = to_wav(normalize(bell(2350.0, 0.7, [1.0, 2.76, 5.4, 8.93], [1.0, 0.45, 0.22, 0.1], 0.18), 0.55))
	d["glass2"] = to_wav(normalize(bell(1980.0, 0.7, [1.0, 2.71, 5.2, 8.7], [1.0, 0.5, 0.2, 0.1], 0.2), 0.5))
	# Paper crinkle
	var paper := buf(0.26)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for k in 9:
		mix_into(paper, noise_burst(0.03, 0.001, 0.008, 0.85, 0.35, k + 20), rng.randf_range(0.0, 0.2), rng.randf_range(0.4, 1.0))
	d["paper"] = to_wav(normalize(paper, 0.45))
	# Soft thud (presents, fruit)
	var soft := sweep(140.0, 70.0, 0.18)
	mix_into(soft, noise_burst(0.12, 0.002, 0.03, 0.15, 0.01, 6), 0.0, 0.5)
	d["soft"] = to_wav(normalize(soft, 0.6))
	# Wooden knock
	var wood := bell(420.0, 0.16, [1.0, 2.6, 4.1], [1.0, 0.5, 0.25], 0.03)
	mix_into(wood, noise_burst(0.02, 0.0005, 0.004, 0.6, 0.2, 7), 0.0, 0.6)
	d["wood"] = to_wav(normalize(wood, 0.55))
	# Tinsel shimmer
	var tinsel := buf(0.6)
	for k in 8:
		mix_into(tinsel, bell(rng.randf_range(3200.0, 6800.0), 0.25, [1.0, 2.4], [1.0, 0.3], 0.05), k * 0.05 + rng.randf_range(0.0, 0.03), rng.randf_range(0.3, 0.8))
	d["tinsel"] = to_wav(normalize(tinsel, 0.4))
	# Whooshes
	var whoosh := noise_burst(0.32, 0.08, 0.12, 0.3, 0.05, 8)
	d["remove"] = to_wav(normalize(whoosh, 0.4))
	var putback := noise_burst(0.22, 0.03, 0.06, 0.2, 0.02, 10)
	mix_into(putback, sweep(160.0, 90.0, 0.12), 0.08, 0.4)
	d["putback"] = to_wav(normalize(putback, 0.4))
	var undo := whoosh.duplicate()
	undo.reverse()
	d["undo"] = to_wav(normalize(undo, 0.35))
	# Pick up: a little rustle and tick
	var pickup := noise_burst(0.12, 0.02, 0.04, 0.45, 0.2, 11)
	mix_into(pickup, bell(2900.0, 0.2, [1.0, 2.7], [0.3, 0.1], 0.05), 0.0)
	d["pickup"] = to_wav(normalize(pickup, 0.35))
	# Match strike and flare
	var match := noise_burst(0.12, 0.005, 0.05, 0.8, 0.5, 12)
	mix_into(match, noise_burst(0.45, 0.06, 0.18, 0.08, 0.005, 13), 0.06, 1.4)
	d["match"] = to_wav(normalize(match, 0.4))
	d["snuff"] = to_wav(normalize(noise_burst(0.3, 0.01, 0.08, 0.12, 0.01, 14), 0.4))
	# Lamp switch
	var lamp := noise_burst(0.04, 0.0005, 0.006, 0.6, 0.3, 15)
	mix_into(lamp, bell(900.0, 0.08, [1.0, 2.3], [0.4, 0.2], 0.02), 0.0)
	d["lamp"] = to_wav(normalize(lamp, 0.45))
	# Page turn
	var page := buf(0.4)
	var y := 0.0
	var prng := RandomNumberGenerator.new()
	prng.seed = 16
	for i in page.size():
		var t := float(i) / page.size()
		var lp := lerpf(0.05, 0.55, t)
		y += lp * (prng.randf_range(-1, 1) - y)
		page[i] = y * sin(t * PI) * (0.7 + 0.3 * sin(t * 90.0))
	d["page"] = to_wav(normalize(page, 0.35))
	# Trunk creak and latch
	var creak := sweep(170.0, 240.0, 0.5, 0.03, 5)
	mix_into(creak, noise_burst(0.05, 0.0005, 0.01, 0.6, 0.2, 17), 0.44, 0.7)
	d["trunk_open"] = to_wav(normalize(creak, 0.4))
	var thump := sweep(120.0, 60.0, 0.2)
	mix_into(thump, noise_burst(0.05, 0.0005, 0.01, 0.6, 0.2, 18), 0.0, 0.6)
	d["trunk_close"] = to_wav(normalize(thump, 0.5))
	# Camera shutter and flash
	var shutter := noise_burst(0.03, 0.0005, 0.006, 0.7, 0.3, 19)
	mix_into(shutter, noise_burst(0.03, 0.0005, 0.006, 0.7, 0.3, 21), 0.09)
	mix_into(shutter, noise_burst(0.4, 0.02, 0.15, 0.9, 0.6, 22), 0.02, 0.25)
	d["shutter"] = to_wav(normalize(shutter, 0.5))
	# Chime: three little bells
	var chime := buf(1.2)
	for k in 3:
		mix_into(chime, bell([1318.5, 1568.0, 2093.0][k], 0.9, [1.0, 2.0, 3.0, 4.2], [1.0, 0.3, 0.15, 0.08], 0.35), k * 0.09)
	d["chime"] = to_wav(normalize(chime, 0.4))
	# Branch rustle
	var rustle := buf(0.35)
	var rr := RandomNumberGenerator.new()
	rr.seed = 23
	var ry := 0.0
	for i in rustle.size():
		var t := float(i) / rustle.size()
		ry += 0.35 * (rr.randf_range(-1, 1) - ry)
		rustle[i] = ry * sin(t * PI) * (0.6 + 0.4 * absf(sin(t * 35.0)))
	d["rustle"] = to_wav(normalize(rustle, 0.3))
	# Sleigh bells
	var sleigh := buf(1.8)
	var sr := RandomNumberGenerator.new()
	sr.seed = 24
	for k in 40:
		var t0 := float(k) / 40.0 * 1.5 + sr.randf_range(0.0, 0.03)
		var amp := 0.5 + 0.5 * absf(sin(t0 * 9.0))
		mix_into(sleigh, bell(sr.randf_range(2600.0, 4200.0), 0.3, [1.0, 2.3, 3.9], [1.0, 0.4, 0.2], 0.06), t0, amp * 0.6)
	d["sleigh"] = to_wav(normalize(sleigh, 0.35))
	# Birdsong: three chirps
	for k in 3:
		var bird := buf(0.6)
		var br := RandomNumberGenerator.new()
		br.seed = 30 + k
		var notes := 3 + k
		for j in notes:
			var f0 := br.randf_range(2600.0, 4200.0)
			var f1 := f0 * br.randf_range(0.7, 1.35)
			mix_into(bird, sweep(f0, f1, br.randf_range(0.05, 0.11), 0.02, 2), j * 0.11, br.randf_range(0.5, 1.0))
		d["chirp%d" % k] = to_wav(normalize(bird, 0.25))
	return d


# ========================================================= resumable jobs

class SynthJob extends RefCounted:
	## Base: call step(budget) each frame until it returns true, then read
	## `result` (an AudioStreamWAV).
	var result: AudioStreamWAV
	var out := PackedFloat32Array()
	var i := 0
	var _convert_i := 0
	var _bytes := PackedByteArray()
	var loop := false

	func _render(_budget: int) -> bool:
		return true

	func step(budget: int) -> bool:
		if i < out.size():
			_render(budget)
			return false
		if _bytes.is_empty():
			_finish()
			_bytes.resize(out.size() * 2)
		var end := mini(out.size(), _convert_i + budget * 2)
		while _convert_i < end:
			_bytes.encode_s16(_convert_i * 2, int(clampf(out[_convert_i], -1.0, 1.0) * 32760.0))
			_convert_i += 1
		if _convert_i < out.size():
			return false
		var w := AudioStreamWAV.new()
		w.format = AudioStreamWAV.FORMAT_16_BITS
		w.mix_rate = Synth.MIX
		w.data = _bytes
		if loop:
			w.loop_mode = AudioStreamWAV.LOOP_FORWARD
			w.loop_begin = 0
			w.loop_end = out.size()
		result = w
		return true

	func _finish() -> void:
		pass


class StringJob extends SynthJob:
	## Karplus-Strong plucked/struck string. Two slightly detuned strings give
	## the chorus of a piano unison; a soft, filtered excitation gives warmth.
	var midi := 60
	var true_freq := 261.6
	var _a := PackedFloat32Array()
	var _b := PackedFloat32Array()
	var _ia := 0
	var _ib := 0
	var _decay := 0.996
	var _gain := 0.5
	var _hammer := 0.0

	func _init(p_midi: int, seconds: float, kind: String) -> void:
		midi = p_midi
		var f := 440.0 * pow(2.0, (midi - 69) / 12.0)
		# Averaging each sample with the *next* one shortens the loop by half
		# a sample, so a buffer of N samples sounds at MIX / (N - 0.5).
		var na := maxi(4, int(round(Synth.MIX / f + 0.5)))
		var nb := maxi(4, int(round(Synth.MIX / (f * 1.0016) + 0.5)))
		true_freq = Synth.MIX / (float(na) - 0.5)
		out.resize(int(seconds * Synth.MIX))
		var rng := RandomNumberGenerator.new()
		rng.seed = midi * 7 + (1 if kind == "harp" else 2)
		var t60 := seconds * (0.7 if kind == "harp" else 0.85)
		_decay = pow(0.001, 1.0 / (t60 * true_freq)) if true_freq > 0.0 else 0.996
		_decay = minf(_decay, 0.99995)
		var bright := 0.92 if kind == "harp" else 0.42
		_a.resize(na)
		_b.resize(nb)
		var y := 0.0
		for k in na:
			y += bright * (rng.randf_range(-1.0, 1.0) - y)
			# Pluck position comb: mute the harmonics a pluck near the middle kills
			_a[k] = y + (sin(TAU * k / na) * (0.0 if kind == "harp" else 0.6))
		y = 0.0
		for k in nb:
			y += bright * (rng.randf_range(-1.0, 1.0) - y)
			_b[k] = y + (sin(TAU * k / nb) * (0.0 if kind == "harp" else 0.6))
		_gain = 0.5 if kind == "harp" else 0.42
		_hammer = 0.0 if kind == "harp" else 0.35

	func _render(budget: int) -> bool:
		var n := out.size()
		var na := _a.size()
		var nb := _b.size()
		var end := mini(n, i + budget)
		while i < end:
			var a0 := _a[_ia]
			var a1 := _a[(_ia + 1) % na]
			_a[_ia] = (a0 + a1) * 0.5 * _decay
			_ia = (_ia + 1) % na
			var b0 := _b[_ib]
			var b1 := _b[(_ib + 1) % nb]
			_b[_ib] = (b0 + b1) * 0.5 * _decay
			_ib = (_ib + 1) % nb
			var s := (a0 + b0) * _gain
			# A soft felt-hammer thump in the first few milliseconds
			if i < 400 and _hammer > 0.0:
				s += sin(float(i) * 0.05) * (1.0 - i / 400.0) * _hammer * 0.3
			out[i] = s
			i += 1
		return i >= n

	func _finish() -> void:
		Synth.fade_edges(out, 0.001, 0.08)


class FireJob extends SynthJob:
	## A crackling hearth: low rumble, breathy hiss and random sparky pops.
	var _rng := RandomNumberGenerator.new()
	var _brown := 0.0
	var _hiss := 0.0
	var _pop_env := 0.0
	var _pop_lp := 0.0

	func _init(seconds: float) -> void:
		out.resize(int(seconds * Synth.MIX))
		_rng.seed = 77
		loop = true

	func _render(budget: int) -> bool:
		var n := out.size()
		var end := mini(n, i + budget)
		while i < end:
			var w := _rng.randf_range(-1.0, 1.0)
			_brown = clampf(_brown * 0.995 + w * 0.04, -1.0, 1.0)
			_hiss += 0.6 * (w - _hiss)
			if _rng.randf() < 0.00045:
				_pop_env = _rng.randf_range(0.4, 1.0)
			_pop_env *= 0.993
			_pop_lp += 0.85 * (w - _pop_lp)
			var s := _brown * 0.9 + _hiss * 0.025 + _pop_lp * _pop_env * 0.7
			out[i] = s
			i += 1
		return i >= n

	func _finish() -> void:
		Synth.normalize(out, 0.5)
		_crossfade_loop()

	func _crossfade_loop() -> void:
		var x := int(0.25 * Synth.MIX)
		var n := out.size()
		for k in x:
			var t := float(k) / x
			out[k] = out[k] * t + out[n - x + k] * (1.0 - t)
		out.resize(n - x)


class WindJob extends SynthJob:
	## Winter wind round the house: resonant, slowly wandering band-passed noise.
	var _rng := RandomNumberGenerator.new()
	var _low := 0.0
	var _band := 0.0

	func _init(seconds: float) -> void:
		out.resize(int(seconds * Synth.MIX))
		_rng.seed = 91
		loop = true

	func _render(budget: int) -> bool:
		var n := out.size()
		var end := mini(n, i + budget)
		while i < end:
			var t := float(i) / n
			var fc := 260.0 + 180.0 * sin(t * TAU * 2.0) + 90.0 * sin(t * TAU * 5.0 + 1.0)
			var f := 2.0 * sin(PI * fc / Synth.MIX)
			var q := 0.12
			var x := _rng.randf_range(-1.0, 1.0)
			var high := x - _low - q * _band
			_band += f * high
			_low += f * _band
			var amp := 0.55 + 0.45 * sin(t * TAU * 3.0 + sin(t * TAU) * 2.0)
			out[i] = _band * amp
			i += 1
		return i >= n

	func _finish() -> void:
		Synth.normalize(out, 0.55)
		var x := int(0.4 * Synth.MIX)
		var n := out.size()
		for k in x:
			var t := float(k) / x
			out[k] = out[k] * t + out[n - x + k] * (1.0 - t)
		out.resize(n - x)
