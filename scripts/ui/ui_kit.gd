class_name UIKit
extends RefCounted
## UIKit — the period look shared by every interface element: fonts, palette,
## carved-wood panels, gold filigree and the generated Theme for stock
## Controls (sliders, check boxes, tooltips).
##
## Rule from the brief: the UI must never "break character" — no flat modern
## icons, no system fonts. Everything here is drawn as wood, paper and gilt.

const GOLD := Color(0.86, 0.69, 0.34)
const GOLD_LIGHT := Color(1.0, 0.9, 0.62)
const GOLD_DARK := Color(0.42, 0.29, 0.1)
const WOOD_DARK := Color(0.13, 0.07, 0.04)
const WOOD := Color(0.27, 0.14, 0.07)
const WOOD_LIGHT := Color(0.42, 0.23, 0.11)
const PAPER := Color(0.94, 0.88, 0.75)
const PAPER_DARK := Color(0.8, 0.71, 0.55)
const INK := Color(0.2, 0.11, 0.07)
const BURGUNDY := Color(0.42, 0.07, 0.09)
const VELVET_GREEN := Color(0.08, 0.2, 0.12)
const TEXT_LIGHT := Color(0.96, 0.9, 0.76)

static var _fonts: Dictionary = {}
static var _theme: Theme


static func font(kind: String = "body") -> Font:
	## kinds: "title" (IM Fell English), "title_italic", "caps" (IM Fell SC),
	## "body" (EB Garamond), "body_italic", "body_bold".
	if _fonts.is_empty():
		_fonts["title"] = _load_font("res://assets/fonts/IMFellEnglish-Regular.woff2")
		_fonts["title_italic"] = _load_font("res://assets/fonts/IMFellEnglish-Italic.woff2")
		_fonts["caps"] = _load_font("res://assets/fonts/IMFellEnglishSC-Regular.woff2")
		_fonts["body"] = _load_font("res://assets/fonts/EBGaramond-Regular.woff2")
		_fonts["body_italic"] = _load_font("res://assets/fonts/EBGaramond-Italic.woff2")
		_fonts["body_bold"] = _load_font("res://assets/fonts/EBGaramond-SemiBold.woff2")
	return _fonts.get(kind, _fonts["body"])


static func _load_font(path: String) -> Font:
	var f: Font = load(path)
	if f == null:
		return ThemeDB.fallback_font
	return f


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = font("body")
	t.default_font_size = 24

	t.set_color("font_color", "Label", TEXT_LIGHT)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.6))
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 2)

	# Tooltips on aged paper
	var tip := StyleBoxFlat.new()
	tip.bg_color = PAPER
	tip.border_color = GOLD_DARK
	tip.set_border_width_all(2)
	tip.set_corner_radius_all(3)
	tip.set_content_margin_all(10)
	tip.shadow_color = Color(0, 0, 0, 0.4)
	tip.shadow_size = 6
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", INK)
	t.set_font("font", "TooltipLabel", font("body_italic"))
	t.set_font_size("font_size", "TooltipLabel", 22)

	# Sliders: a brass rail with a gilt knob
	var rail := StyleBoxFlat.new()
	rail.bg_color = Color(0.08, 0.04, 0.02)
	rail.border_color = GOLD_DARK
	rail.set_border_width_all(1)
	rail.set_corner_radius_all(4)
	rail.content_margin_top = 5
	rail.content_margin_bottom = 5
	var fill := rail.duplicate() as StyleBoxFlat
	fill.bg_color = GOLD.darkened(0.25)
	t.set_stylebox("slider", "HSlider", rail)
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	var knob := _knob_texture(false)
	t.set_icon("grabber", "HSlider", knob)
	t.set_icon("grabber_highlight", "HSlider", _knob_texture(true))

	# Line edit on paper
	var le := StyleBoxFlat.new()
	le.bg_color = PAPER
	le.border_color = GOLD_DARK
	le.set_border_width_all(2)
	le.set_corner_radius_all(2)
	le.set_content_margin_all(8)
	t.set_stylebox("normal", "LineEdit", le)
	var lef := le.duplicate() as StyleBoxFlat
	lef.border_color = GOLD
	t.set_stylebox("focus", "LineEdit", lef)
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_placeholder_color", "LineEdit", Color(INK, 0.45))
	t.set_color("caret_color", "LineEdit", INK)
	t.set_font("font", "LineEdit", font("body_italic"))
	t.set_font_size("font_size", "LineEdit", 26)

	# Scroll bars: thin gilt rods
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.25)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	var grab := StyleBoxFlat.new()
	grab.bg_color = GOLD.darkened(0.3)
	grab.set_corner_radius_all(4)
	t.set_stylebox("scroll", "VScrollBar", sb)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)

	var empty := StyleBoxEmpty.new()
	t.set_stylebox("panel", "PanelContainer", empty)
	t.set_stylebox("panel", "ScrollContainer", empty)
	_theme = t
	return t


static func _knob_texture(hot: bool) -> Texture2D:
	var s := 28
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var d := Vector2(x - s * 0.5 + 0.5, y - s * 0.5 + 0.5).length() / (s * 0.5)
			if d > 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var shade := 1.0 - clampf((x + y) / float(s * 2), 0.0, 1.0) * 0.6
			var c := GOLD.lerp(GOLD_LIGHT, shade * (0.8 if hot else 0.5))
			if d > 0.82:
				c = GOLD_DARK
			img.set_pixel(x, y, Color(c, clampf((1.0 - d) * 12.0, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


# ------------------------------------------------------------ drawing helpers

static func vgrad(ci: CanvasItem, r: Rect2, top: Color, bottom: Color) -> void:
	ci.draw_polygon(
		PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))


static func hgrad(ci: CanvasItem, r: Rect2, left: Color, right: Color) -> void:
	ci.draw_polygon(
		PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([left, right, right, left]))


static func wood_panel(ci: CanvasItem, r: Rect2, inner: String = "velvet", glow: float = 0.0) -> void:
	## A carved dark-wood frame with a gilt bead and filigree corners.
	## inner: "velvet" (burgundy), "green" (bottle-green velvet), "paper", "dark".
	# Drop shadow
	ci.draw_rect(Rect2(r.position + Vector2(4, 6), r.size), Color(0, 0, 0, 0.35))
	# Outer moulding: bevel gradient
	vgrad(ci, r, WOOD_LIGHT, WOOD_DARK)
	var wood_tex := Tex.wood()
	ci.draw_texture_rect(wood_tex, r, true, Color(1, 1, 1, 0.55))
	ci.draw_rect(r, Color(0, 0, 0, 0.6), false, 2.0)
	ci.draw_line(r.position + Vector2(2, 2), Vector2(r.end.x - 2, r.position.y + 2), Color(1, 0.8, 0.55, 0.18), 2.0)
	var m := 10.0
	var ir := r.grow(-m)
	# Gilt bead
	ci.draw_rect(ir.grow(3), GOLD_DARK, false, 3.0)
	ci.draw_rect(ir.grow(1.5), GOLD.lerp(GOLD_LIGHT, glow), false, 1.5)
	# Inner field
	match inner:
		"velvet":
			vgrad(ci, ir, BURGUNDY.lightened(0.05), BURGUNDY.darkened(0.45))
		"green":
			vgrad(ci, ir, VELVET_GREEN.lightened(0.08), VELVET_GREEN.darkened(0.5))
		"paper":
			ci.draw_texture_rect(Tex.paper(), ir, true)
			ci.draw_rect(ir, Color(0.5, 0.3, 0.1, 0.12), false, 6.0)
		_:
			vgrad(ci, ir, Color(0.1, 0.06, 0.04), Color(0.05, 0.03, 0.02))
	ci.draw_rect(ir, Color(0, 0, 0, 0.45), false, 2.0)
	# Filigree corners
	var fs := minf(26.0, minf(r.size.x, r.size.y) * 0.22)
	filigree_corner(ci, ir.position + Vector2(4, 4), 1, 1, fs)
	filigree_corner(ci, Vector2(ir.end.x - 4, ir.position.y + 4), -1, 1, fs)
	filigree_corner(ci, Vector2(ir.position.x + 4, ir.end.y - 4), 1, -1, fs)
	filigree_corner(ci, ir.end - Vector2(4, 4), -1, -1, fs)


static func paper_panel(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(5, 8), r.size), Color(0, 0, 0, 0.4))
	ci.draw_texture_rect(Tex.paper(), r, true)
	# Darkened, foxed edges
	for i in 6:
		ci.draw_rect(r.grow(-i * 2.0), Color(0.45, 0.28, 0.1, 0.05), false, 2.0)
	ci.draw_rect(r.grow(-12), GOLD_DARK, false, 1.5)
	ci.draw_rect(r.grow(-16), Color(GOLD_DARK, 0.6), false, 1.0)
	var fs := 24.0
	filigree_corner(ci, r.position + Vector2(18, 18), 1, 1, fs, GOLD_DARK)
	filigree_corner(ci, Vector2(r.end.x - 18, r.position.y + 18), -1, 1, fs, GOLD_DARK)
	filigree_corner(ci, Vector2(r.position.x + 18, r.end.y - 18), 1, -1, fs, GOLD_DARK)
	filigree_corner(ci, r.end - Vector2(18, 18), -1, -1, fs, GOLD_DARK)


static func filigree_corner(ci: CanvasItem, p: Vector2, sx: float, sy: float, s: float, col: Color = GOLD) -> void:
	## A small C-scroll flourish growing from a corner into the panel.
	var c := col
	var w := maxf(1.2, s * 0.07)
	# Two arms along the edges
	ci.draw_line(p, p + Vector2(s * sx, 0), c, w, true)
	ci.draw_line(p, p + Vector2(0, s * sy), c, w, true)
	# Scroll curls at each arm end
	_curl(ci, p + Vector2(s * sx, 0), s * 0.22, sx, sy, c, w, 0)
	_curl(ci, p + Vector2(0, s * sy), s * 0.22, sx, sy, c, w, 1)
	# Inner leaf / diamond
	var q := p + Vector2(s * 0.32 * sx, s * 0.32 * sy)
	var d := s * 0.13
	ci.draw_colored_polygon(PackedVector2Array([
		q + Vector2(0, -d), q + Vector2(d, 0), q + Vector2(0, d), q + Vector2(-d, 0)]), c)
	ci.draw_circle(p + Vector2(s * 0.12 * sx, s * 0.12 * sy), w * 1.1, c)


static func _curl(ci: CanvasItem, p: Vector2, r: float, sx: float, sy: float, c: Color, w: float, axis: int) -> void:
	var pts := PackedVector2Array()
	var n := 14
	for i in n + 1:
		var t := float(i) / n
		var ang := t * TAU * 0.85
		var rr := r * (1.0 - t * 0.6)
		var off: Vector2
		if axis == 0:
			off = Vector2(sin(ang) * rr * sx, (1.0 - cos(ang)) * rr * sy)
		else:
			off = Vector2((1.0 - cos(ang)) * rr * sx, sin(ang) * rr * sy)
		pts.append(p + off)
	ci.draw_polyline(pts, c, w, true)


static func text_centered(ci: CanvasItem, f: Font, center: Vector2, text: String, size: int, col: Color, shadow: bool = true) -> void:
	var sz := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var base := Vector2(center.x - sz.x * 0.5, center.y + (f.get_ascent(size) - f.get_descent(size)) * 0.5)
	if shadow:
		ci.draw_string(f, base + Vector2(1, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.55))
	ci.draw_string(f, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


static func gilt_text(ci: CanvasItem, f: Font, center: Vector2, text: String, size: int) -> void:
	## Embossed gold lettering: dark outline, gold face, a hint of highlight.
	var sz := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var base := Vector2(center.x - sz.x * 0.5, center.y + (f.get_ascent(size) - f.get_descent(size)) * 0.5)
	ci.draw_string_outline(f, base + Vector2(0, 3), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, maxi(2, size / 12), Color(0, 0, 0, 0.6))
	ci.draw_string_outline(f, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, maxi(2, size / 16), GOLD_DARK.darkened(0.4))
	ci.draw_string(f, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, GOLD)
	ci.draw_string(f, base + Vector2(0, -1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(GOLD_LIGHT, 0.45))


static func divider(ci: CanvasItem, center: Vector2, half_width: float, col: Color = GOLD) -> void:
	## A typographic rule with a central lozenge, like a printer's ornament.
	ci.draw_line(center + Vector2(-half_width, 0), center + Vector2(-10, 0), col, 1.5, true)
	ci.draw_line(center + Vector2(10, 0), center + Vector2(half_width, 0), col, 1.5, true)
	var d := 6.0
	ci.draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -d), center + Vector2(d, 0), center + Vector2(0, d), center + Vector2(-d, 0)]), col)
	ci.draw_circle(center + Vector2(-half_width, 0), 2.5, col)
	ci.draw_circle(center + Vector2(half_width, 0), 2.5, col)
