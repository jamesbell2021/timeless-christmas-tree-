extends Node
## Tex — procedural texture factory. Every bitmap in the game is generated
## here at runtime and cached, so the project ships with no image assets.
##
## All textures are created lazily on first request; generation cost is a few
## milliseconds each, paid once.

var _cache: Dictionary = {}


func glow() -> Texture2D:
	## Soft radial light falloff, white -> transparent. Used additively for
	## candle halos, firelight and lamp glows.
	return _cached("glow", _make_glow)


func sphere_body() -> Texture2D:
	## Lambert-shaded sphere (light from upper left), greyscale so it can be
	## tinted with modulate. Edge darkening gives the "glass" rim.
	return _cached("sphere_body", _make_sphere_body)


func sphere_spec() -> Texture2D:
	## Window-shaped specular highlight that stays white over any tint.
	return _cached("sphere_spec", _make_sphere_spec)


func paper() -> Texture2D:
	## Aged card stock: warm cream with fibres and foxing spots.
	return _cached("paper", _make_paper)


func canvas_weave() -> Texture2D:
	## Tileable greyscale linen weave used by the oil-paint post filter.
	return _cached("weave", _make_canvas_weave)


func noise_tile(seed_value: int = 1, freq: float = 0.02, size: int = 256, octaves: int = 4) -> Texture2D:
	## Generic seamless value noise used by the watercolour filter and fire.
	var key := "noise_%d_%f_%d_%d" % [seed_value, freq, size, octaves]
	if not _cache.has(key):
		var t := NoiseTexture2D.new()
		var n := FastNoiseLite.new()
		n.seed = seed_value
		n.frequency = freq
		n.fractal_octaves = octaves
		t.noise = n
		t.seamless = true
		t.width = size
		t.height = size
		_cache[key] = t
	return _cache[key]


func wood() -> Texture2D:
	## Dark oak grain, horizontal. Tile it with texture_repeat.
	return _cached("wood", _make_wood)


func streak() -> Texture2D:
	## A thin vertical streak for rain particles.
	if not _cache.has("streak"):
		var img := Image.create(3, 28, false, Image.FORMAT_RGBA8)
		for y in 28:
			var a := sin(float(y) / 27.0 * PI)
			for x in 3:
				img.set_pixel(x, y, Color(1, 1, 1, a * (1.0 if x == 1 else 0.4)))
		_cache["streak"] = ImageTexture.create_from_image(img)
	return _cache["streak"]


func _cached(key: String, maker: Callable) -> Texture2D:
	if not _cache.has(key):
		_cache[key] = maker.call()
	return _cache[key]


func add_material() -> CanvasItemMaterial:
	## Shared additive blend material for light glows.
	if not _cache.has("add_mat"):
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_cache["add_mat"] = m
	return _cache["add_mat"]


func mul_material() -> CanvasItemMaterial:
	if not _cache.has("mul_mat"):
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
		_cache["mul_mat"] = m
	return _cache["mul_mat"]


# ------------------------------------------------------------- generators

func _make_glow() -> Texture2D:
	var g := Gradient.new()
	g.set_offset(0, 0.0)
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_offset(1, 1.0)
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.18, Color(1, 1, 1, 0.62))
	g.add_point(0.45, Color(1, 1, 1, 0.2))
	g.add_point(0.75, Color(1, 1, 1, 0.04))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 256
	t.height = 256
	return t


func _make_sphere_body() -> Texture2D:
	var n := 96
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var light := Vector3(-0.55, -0.6, 0.6).normalized()
	for y in n:
		for x in n:
			var px := (x + 0.5) / n * 2.0 - 1.0
			var py := (y + 0.5) / n * 2.0 - 1.0
			var d2 := px * px + py * py
			if d2 > 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var nz := sqrt(1.0 - d2)
			var nrm := Vector3(px, py, nz)
			var lam := clampf(nrm.dot(light), 0.0, 1.0)
			var rim := pow(1.0 - nz, 2.2)
			# Reflected warm room light along the lower right edge.
			var bounce := clampf(nrm.dot(Vector3(0.6, 0.7, 0.2).normalized()), 0.0, 1.0) * 0.25
			var v := 0.22 + lam * 0.85 + bounce - rim * 0.25
			var a := clampf((1.0 - d2) * 40.0, 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v, v, a))
	return ImageTexture.create_from_image(img)


func _make_sphere_spec() -> Texture2D:
	var n := 96
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var px := (x + 0.5) / n * 2.0 - 1.0
			var py := (y + 0.5) / n * 2.0 - 1.0
			# Main soft highlight
			var d := Vector2(px + 0.38, py + 0.42).length()
			var a := clampf(1.0 - d / 0.32, 0.0, 1.0)
			a = a * a
			# Small sharp window glint
			var w := clampf(1.0 - Vector2((px + 0.3) * 1.6, (py + 0.36) * 0.9).length() / 0.12, 0.0, 1.0)
			a = maxf(a * 0.75, w)
			# Secondary lower-right reflection
			var d2 := Vector2(px - 0.45, py - 0.5).length()
			a = maxf(a, clampf(1.0 - d2 / 0.2, 0.0, 1.0) * 0.25)
			if px * px + py * py > 0.98:
				a = 0.0
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func _make_paper() -> Texture2D:
	var w := 512
	var h := 512
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var n := FastNoiseLite.new()
	n.seed = 7
	n.frequency = 0.012
	n.fractal_octaves = 4
	var fib := FastNoiseLite.new()
	fib.seed = 11
	fib.frequency = 0.09
	var base := Color(0.93, 0.87, 0.74)
	for y in h:
		for x in w:
			var v := n.get_noise_2d(x, y) * 0.5 + 0.5
			var f := fib.get_noise_2d(x * 0.35, y * 2.2)
			var c := base.darkened(0.12 * v + 0.05 * absf(f))
			img.set_pixel(x, y, c)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 26:
		var cx := rng.randi_range(0, w - 1)
		var cy := rng.randi_range(0, h - 1)
		var r := rng.randf_range(2.0, 7.0)
		for yy in range(int(cy - r), int(cy + r) + 1):
			for xx in range(int(cx - r), int(cx + r) + 1):
				if xx < 0 or yy < 0 or xx >= w or yy >= h:
					continue
				var dd := Vector2(xx - cx, yy - cy).length() / r
				if dd < 1.0:
					var c0 := img.get_pixel(xx, yy)
					img.set_pixel(xx, yy, c0.lerp(Color(0.72, 0.55, 0.35), (1.0 - dd) * 0.22))
	return ImageTexture.create_from_image(img)


func _make_canvas_weave() -> Texture2D:
	var s := 128
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var n := FastNoiseLite.new()
	n.seed = 21
	n.frequency = 0.25
	for y in s:
		for x in s:
			var wx := sin(x * TAU / 4.0) * 0.5 + 0.5
			var wy := sin(y * TAU / 4.0) * 0.5 + 0.5
			var weave := (wx if (int(y / 4.0) % 2 == 0) else wy)
			var nn := n.get_noise_2d(x, y) * 0.5 + 0.5
			var v := 0.5 + (weave - 0.5) * 0.35 + (nn - 0.5) * 0.4
			img.set_pixel(x, y, Color(v, v, v, 1))
	return ImageTexture.create_from_image(img)


func _make_wood() -> Texture2D:
	var w := 512
	var h := 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var n := FastNoiseLite.new()
	n.seed = 5
	n.frequency = 0.01
	n.fractal_octaves = 3
	var dark := Color(0.16, 0.085, 0.045)
	var light := Color(0.33, 0.18, 0.09)
	for y in h:
		for x in w:
			var warp := n.get_noise_2d(x * 0.3, y * 2.0) * 9.0
			var ring := sin((y + warp) * 0.55) * 0.5 + 0.5
			var fine := n.get_noise_2d(x * 4.0, y * 6.0) * 0.5 + 0.5
			var v := clampf(ring * 0.65 + fine * 0.35, 0.0, 1.0)
			img.set_pixel(x, y, dark.lerp(light, v))
	return ImageTexture.create_from_image(img)
