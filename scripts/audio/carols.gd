class_name Carols
extends RefCounted
## Carols — public-domain Christmas tunes as compact note data, plus the
## arranger that turns a melody and chord chart into a gentle accompaniment.
##
## Melody tokens are NOTE:BEATS (quarter note = 1 beat); "|" separates bars.
## Chords are one per bar, or two per bar separated by a comma (half each).

const SONGS := [
	{
		"title": "O Tannenbaum", "beats": 3, "tempo": 76, "pickup": 1.0, "style": "waltz",
		"melody": "C4:1 | F4:0.75 F4:0.25 F4:1.5 G4:0.5 | A4:0.75 A4:0.25 A4:1.5 A4:0.5 | G4:0.5 A4:0.5 Bb4:1 E4:1 | G4:1 F4:1 C5:1 | C5:0.75 A4:0.25 D5:1.5 C5:0.5 | C5:0.75 Bb4:0.25 Bb4:1.5 Bb4:0.5 | Bb4:0.75 G4:0.25 C5:1.5 Bb4:0.5 | Bb4:1 A4:1 C4:1 | F4:0.75 F4:0.25 F4:1.5 G4:0.5 | A4:0.75 A4:0.25 A4:1.5 A4:0.5 | G4:0.5 A4:0.5 Bb4:1 E4:1 | G4:1 F4:2",
		"chords": "C7 | F | F | C7 | C7,F | F | C7 | C7 | F | F | F | C7 | C7,F",
	},
	{
		"title": "Silent Night", "beats": 3, "tempo": 72, "pickup": 0.0, "style": "arpeggio",
		"melody": "G4:0.75 A4:0.25 G4:0.5 E4:1.5 | G4:0.75 A4:0.25 G4:0.5 E4:1.5 | D5:1 D5:0.5 B4:1.5 | C5:1 C5:0.5 G4:1.5 | A4:1 A4:0.5 C5:0.75 B4:0.25 A4:0.5 | G4:0.75 A4:0.25 G4:0.5 E4:1.5 | A4:1 A4:0.5 C5:0.75 B4:0.25 A4:0.5 | G4:0.75 A4:0.25 G4:0.5 E4:1.5 | D5:1 D5:0.5 F5:0.75 D5:0.25 B4:0.5 | C5:1.5 E5:1.5 | C5:0.75 G4:0.25 E4:0.5 G4:0.75 F4:0.25 D4:0.5 | C4:3",
		"chords": "C | C | G7 | C | F | C | F | C | G7 | C | C,G7 | C",
	},
	{
		"title": "Good King Wenceslas", "beats": 4, "tempo": 84, "pickup": 0.0, "style": "march",
		"melody": "G4:1 G4:1 G4:1 A4:1 | G4:1 G4:1 D4:2 | E4:1 D4:1 E4:1 F#4:1 | G4:2 G4:2 | G4:1 G4:1 G4:1 A4:1 | G4:1 G4:1 D4:2 | E4:1 D4:1 E4:1 F#4:1 | G4:2 G4:2 | D5:1 C5:1 B4:1 A4:1 | B4:1 A4:1 G4:2 | E4:1 D4:1 E4:1 F#4:1 | G4:2 G4:2 | D4:1 D4:1 E4:1 F#4:1 | G4:1 G4:1 A4:2 | D5:1 C5:1 B4:1 A4:1 | G4:2 C5:2 | G4:4",
		"chords": "G | G,D | C,D | G | G | G,D | C,D | G | G,D7 | G | C,D | G | G,D | G,D | G,D7 | Em,C | G",
	},
	{
		"title": "Deck the Hall", "beats": 4, "tempo": 88, "pickup": 0.0, "style": "arpeggio",
		"melody": "G4:1.5 F4:0.5 E4:1 D4:1 | C4:1 D4:1 E4:1 C4:1 | D4:0.5 E4:0.5 F4:0.5 D4:0.5 E4:1.5 D4:0.5 | C4:1 B3:1 C4:2 | G4:1.5 F4:0.5 E4:1 D4:1 | C4:1 D4:1 E4:1 C4:1 | D4:0.5 E4:0.5 F4:0.5 D4:0.5 E4:1.5 D4:0.5 | C4:1 B3:1 C4:2 | D4:1.5 E4:0.5 F4:1 D4:1 | E4:1.5 F4:0.5 G4:1 D4:1 | E4:0.5 F#4:0.5 G4:1 A4:0.5 B4:0.5 C5:1 | B4:1 A4:1 G4:2 | G4:1.5 F4:0.5 E4:1 D4:1 | C4:1 D4:1 E4:1 C4:1 | A4:0.5 A4:0.5 A4:0.5 A4:0.5 G4:1.5 F4:0.5 | E4:1 D4:1 C4:2",
		"chords": "C | C | G7,C | G7,C | C | C | G7,C | G7,C | G7 | C,G | Em,Am | D7,G | C | C | F,C | G7,C",
	},
	{
		"title": "We Wish You a Merry Christmas", "beats": 3, "tempo": 92, "pickup": 1.0, "style": "waltz",
		"melody": "D4:1 | G4:1 G4:0.5 A4:0.5 G4:0.5 F#4:0.5 | E4:1 E4:1 E4:1 | A4:1 A4:0.5 B4:0.5 A4:0.5 G4:0.5 | F#4:1 D4:1 D4:1 | B4:1 B4:0.5 C5:0.5 B4:0.5 A4:0.5 | G4:1 E4:1 D4:0.5 D4:0.5 | E4:1 A4:1 F#4:1 | G4:2 D4:1 | G4:1 G4:1 G4:1 | F#4:2 F#4:1 | G4:1 F#4:1 E4:1 | D4:2 A4:1 | B4:1 A4:1 G4:1 | D5:1 D4:1 D4:0.5 D4:0.5 | E4:1 A4:1 F#4:1 | G4:3",
		"chords": "D | G | C | A7 | D | Em | C | Am,D7 | G | G | D | Em | D | G | D | Am,D7 | G",
	},
]

const NOTE_INDEX := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


static func note_to_midi(n: String) -> int:
	## "F#4" -> 66, "Bb3" -> 58
	var letter := n.substr(0, 1)
	var rest := n.substr(1)
	var acc := 0
	if rest.begins_with("#"):
		acc = 1
		rest = rest.substr(1)
	elif rest.begins_with("b"):
		acc = -1
		rest = rest.substr(1)
	var octave := int(rest)
	return 12 * (octave + 1) + int(NOTE_INDEX.get(letter, 0)) + acc


static func chord_tones(chord_name: String) -> Array:
	## Returns semitone offsets of the chord root (pitch class) and its tones.
	var root_name := chord_name.substr(0, 1)
	var rest := chord_name.substr(1)
	var root := int(NOTE_INDEX.get(root_name, 0))
	if rest.begins_with("#"):
		root += 1
		rest = rest.substr(1)
	elif rest.begins_with("b"):
		root -= 1
		rest = rest.substr(1)
	var tones := [0, 4, 7]
	if rest.begins_with("m") and not rest.begins_with("maj"):
		tones = [0, 3, 7]
	if rest.ends_with("7"):
		tones.append(10)
	return [posmod(root, 12), tones]


static func parse_melody(text: String) -> Array:
	## -> Array of bars; each bar is an Array of [midi, beats] (midi -1 = rest)
	var bars: Array = []
	for bar_txt in text.split("|"):
		var bar: Array = []
		for tok in bar_txt.strip_edges().split(" ", false):
			var parts := tok.split(":")
			var midi := -1 if parts[0] == "R" else note_to_midi(parts[0])
			bar.append([midi, float(parts[1])])
		bars.append(bar)
	return bars


static func bar_lengths_ok(song: Dictionary) -> bool:
	## Every full bar must add up to the time signature (used by the tests).
	var bars := parse_melody(song["melody"])
	var beats := float(song["beats"])
	for i in bars.size():
		var total := 0.0
		for n in bars[i]:
			total += float(n[1])
		var expect := beats
		if i == 0 and float(song.get("pickup", 0.0)) > 0.0:
			expect = float(song["pickup"])
		if i == bars.size() - 1:
			if total > beats + 0.001:
				return false
			continue
		if absf(total - expect) > 0.001:
			return false
	return true


static func arrange(song: Dictionary, variation: int) -> Array:
	## Builds a list of note events: {t (beats), midi, dur, vel, inst, part}.
	## variation 0: melody in the middle register; 1: melody an octave up,
	## a lighter accompaniment — so a repeat never sounds like a loop.
	var events: Array = []
	var bars := parse_melody(song["melody"])
	var chords: PackedStringArray = (song["chords"] as String).split("|")
	var beats := float(song["beats"])
	var pickup := float(song.get("pickup", 0.0))
	var lead := "piano" if variation == 0 else "harp"
	var oct := 0 if variation == 0 else 12
	var t := 0.0
	for bi in bars.size():
		var bar_start := t
		var bar_len := beats
		if bi == 0 and pickup > 0.0:
			bar_len = pickup
		# Melody
		var mt := bar_start
		for n in bars[bi]:
			var midi: int = n[0]
			var d: float = n[1]
			if midi >= 0:
				events.append({"t": mt, "midi": midi + oct, "dur": d, "vel": 0.62, "inst": lead, "part": "melody"})
			mt += d
		# Accompaniment from the chord chart
		if bi < chords.size():
			var parts := chords[bi].strip_edges().split(",")
			var seg := bar_len / parts.size()
			for pi in parts.size():
				var ct := chord_tones(parts[pi].strip_edges())
				var root: int = ct[0]
				var tones: Array = ct[1]
				var s0 := bar_start + pi * seg
				_accompany(events, song["style"], root, tones, s0, seg, beats, variation)
		t = bar_start + bar_len
	# Final chord rings out
	return events


static func _accompany(events: Array, style: String, root: int, tones: Array, start: float, length: float, beats: float, variation: int) -> void:
	var bass := 36 + root
	if bass > 45:
		bass -= 12
	var mid := 52 + root
	if mid > 59:
		mid -= 12
	var inst := "piano" if variation == 0 else "harp"
	var soft := 0.3 if variation == 0 else 0.26
	match style:
		"waltz":
			events.append({"t": start, "midi": bass, "dur": length, "vel": 0.4, "inst": "piano", "part": "bass"})
			var k := 1.0
			while k < length - 0.01:
				for tn in tones.slice(1, 3):
					events.append({"t": start + k, "midi": mid + int(tn), "dur": 0.9, "vel": soft, "inst": inst, "part": "chord"})
				k += 1.0
		"march":
			events.append({"t": start, "midi": bass, "dur": length, "vel": 0.42, "inst": "piano", "part": "bass"})
			var k2 := 1.0
			while k2 < length - 0.01:
				var tn2: int = tones[1 + int(k2) % 2] if tones.size() > 2 else tones[0]
				events.append({"t": start + k2, "midi": mid + tn2, "dur": 0.9, "vel": soft, "inst": inst, "part": "chord"})
				k2 += 1.0
		_:
			# Rolling arpeggio in eighth notes, harp-like
			var pattern := [0, 7, 12, 16, 12, 7, 0, 7]
			var step := 0.5
			var k3 := 0.0
			var idx := 0
			events.append({"t": start, "midi": bass, "dur": length, "vel": 0.38, "inst": "piano", "part": "bass"})
			while k3 < length - 0.01:
				var off: int = pattern[idx % pattern.size()]
				# Map the pattern's major-chord offsets onto this chord's real tones
				var tone_map := {0: 0, 7: 7, 12: 12, 16: 12 + int(tones[1])}
				var semis: int = tone_map.get(off, off)
				if idx > 0:
					events.append({"t": start + k3, "midi": bass + 12 + semis, "dur": 0.8, "vel": soft * 0.9, "inst": "harp", "part": "arp"})
				k3 += step
				idx += 1
