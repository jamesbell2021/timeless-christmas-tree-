class_name OrnateButton
extends BaseButton
## A fully hand-drawn button so nothing looks like a stock widget.
## Styles:
##   "plaque" — carved wood with gilt lettering (main actions)
##   "round"  — a brass roundel carrying an engraved icon (tools)
##   "tab"    — a small velvet tab with an icon (trunk categories)
##   "paper"  — ink on card, for use inside paper panels

@export var text := ""
@export var icon_kind := ""
@export var style := "plaque"
@export var font_size := 26
@export var subtext := ""

var _hover := 0.0
var _press := 0.0


func _init(p_text: String = "", p_style: String = "plaque", p_icon: String = "") -> void:
	text = p_text
	style = p_style
	icon_kind = p_icon
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _ready() -> void:
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	toggled.connect(func(_on: bool) -> void: queue_redraw())
	pressed.connect(_on_pressed)
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = _natural_size()


func _natural_size() -> Vector2:
	match style:
		"round":
			return Vector2(64, 64)
		"tab":
			return Vector2(52, 52)
		_:
			var f := UIKit.font("caps")
			var sz := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			var extra := 44.0 if icon_kind != "" else 0.0
			return Vector2(sz.x + 56 + extra, font_size * 2.1 + (font_size * 0.8 if subtext != "" else 0.0))


func _on_pressed() -> void:
	AudioDirector.sfx("click")


func _process(delta: float) -> void:
	var target_h := 1.0 if is_hovered() and not disabled else 0.0
	var target_p := 1.0 if (button_pressed or get_draw_mode() == DRAW_PRESSED) else 0.0
	var nh := move_toward(_hover, target_h, delta * 6.0)
	var np := move_toward(_press, target_p, delta * 10.0)
	if not is_equal_approx(nh, _hover) or not is_equal_approx(np, _press):
		_hover = nh
		_press = np
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var dim := 0.45 if disabled else 1.0
	match style:
		"round":
			_draw_round(r, dim)
		"tab":
			_draw_tab(r, dim)
		"paper":
			_draw_paper(r, dim)
		_:
			_draw_plaque(r, dim)


func _draw_plaque(r: Rect2, dim: float) -> void:
	var off := Vector2(0, 2.0 * _press)
	var rr := Rect2(r.position + off, r.size)
	draw_rect(Rect2(r.position + Vector2(3, 5), r.size), Color(0, 0, 0, 0.4))
	UIKit.vgrad(self, rr, UIKit.WOOD_LIGHT.lerp(UIKit.WOOD, 0.3), UIKit.WOOD_DARK)
	draw_texture_rect(Tex.wood(), rr, true, Color(1, 1, 1, 0.45))
	if toggle_mode and button_pressed:
		UIKit.vgrad(self, rr.grow(-6), UIKit.BURGUNDY.lightened(0.1), UIKit.BURGUNDY.darkened(0.4))
	draw_rect(rr, Color(0, 0, 0, 0.7), false, 2.0)
	var gold := UIKit.GOLD.lerp(UIKit.GOLD_LIGHT, _hover * 0.8)
	draw_rect(rr.grow(-5), Color(UIKit.GOLD_DARK, dim), false, 2.0)
	draw_rect(rr.grow(-7), Color(gold, 0.85 * dim), false, 1.0)
	if _hover > 0.0:
		draw_rect(rr.grow(-8), Color(1.0, 0.8, 0.45, 0.07 * _hover))
	UIKit.filigree_corner(self, rr.position + Vector2(9, 9), 1, 1, 10, Color(gold, dim))
	UIKit.filigree_corner(self, Vector2(rr.end.x - 9, rr.position.y + 9), -1, 1, 10, Color(gold, dim))
	UIKit.filigree_corner(self, Vector2(rr.position.x + 9, rr.end.y - 9), 1, -1, 10, Color(gold, dim))
	UIKit.filigree_corner(self, rr.end - Vector2(9, 9), -1, -1, 10, Color(gold, dim))
	var f := UIKit.font("caps")
	var cx := rr.get_center().x
	if icon_kind != "":
		var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var ix := cx - (tw + 44) * 0.5
		UIIcons.draw(self, icon_kind, Rect2(Vector2(ix, rr.get_center().y - 18), Vector2(36, 36)), Color(gold, dim))
		cx += 22
	var cy := rr.get_center().y - (font_size * 0.38 if subtext != "" else 0.0)
	UIKit.text_centered(self, f, Vector2(cx, cy), text, font_size, Color(gold, dim))
	if subtext != "":
		UIKit.text_centered(self, UIKit.font("body_italic"), Vector2(rr.get_center().x, cy + font_size * 0.95), subtext, int(font_size * 0.62), Color(UIKit.TEXT_LIGHT, 0.75 * dim))


func _draw_round(r: Rect2, dim: float) -> void:
	var c := r.get_center() + Vector2(0, 2.0 * _press)
	var rad := minf(r.size.x, r.size.y) * 0.5 - 3.0
	draw_circle(c + Vector2(2, 4), rad, Color(0, 0, 0, 0.4))
	draw_circle(c, rad, UIKit.GOLD_DARK)
	draw_circle(c, rad - 3, UIKit.WOOD_DARK.lerp(UIKit.WOOD, 0.4))
	var on := toggle_mode and button_pressed
	if on:
		draw_circle(c, rad - 5, UIKit.BURGUNDY.darkened(0.1))
	# Brass ring with a highlight arc
	var gold := UIKit.GOLD.lerp(UIKit.GOLD_LIGHT, _hover * 0.8)
	draw_arc(c, rad - 2, 0, TAU, 40, Color(gold, dim), 3.0, true)
	draw_arc(c, rad - 2, PI * 1.05, PI * 1.6, 12, Color(1, 0.95, 0.75, 0.6 * dim), 2.0, true)
	if _hover > 0.0:
		draw_circle(c, rad - 5, Color(1.0, 0.85, 0.5, 0.08 * _hover))
	var ir := rad * 0.62
	UIIcons.draw(self, icon_kind, Rect2(c - Vector2(ir, ir), Vector2(ir * 2, ir * 2)), Color(gold, dim))


func _draw_tab(r: Rect2, dim: float) -> void:
	var on := button_pressed
	var rr := r.grow(-2)
	UIKit.vgrad(self, rr, (UIKit.BURGUNDY.lightened(0.12) if on else UIKit.WOOD), (UIKit.BURGUNDY.darkened(0.3) if on else UIKit.WOOD_DARK))
	var gold := UIKit.GOLD.lerp(UIKit.GOLD_LIGHT, maxf(_hover, 1.0 if on else 0.0) * 0.7)
	draw_rect(rr, Color(gold, (0.9 if on else 0.5) * dim), false, 1.5)
	UIIcons.draw(self, icon_kind, rr.grow(-9), Color(gold, dim))


func _draw_paper(r: Rect2, dim: float) -> void:
	var off := Vector2(0, 1.5 * _press)
	var rr := Rect2(r.position + off, r.size)
	draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.25))
	draw_texture_rect(Tex.paper(), rr, true, Color(1, 1, 1, 1))
	if toggle_mode and button_pressed:
		draw_rect(rr, Color(UIKit.BURGUNDY, 0.25))
	draw_rect(rr, UIKit.GOLD_DARK.lerp(UIKit.BURGUNDY, _hover), false, 2.0)
	draw_rect(rr.grow(-4), Color(UIKit.GOLD_DARK, 0.5), false, 1.0)
	var f := UIKit.font("caps")
	UIKit.text_centered(self, f, rr.get_center(), text, font_size, Color(UIKit.INK.lerp(UIKit.BURGUNDY, _hover * 0.8), dim), false)
