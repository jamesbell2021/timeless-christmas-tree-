class_name TimelineBar
extends Control
## The visual progress timeline from the brief: five gilt roundels for the
## five stages of the tree's life. Reached stages can be revisited; the
## current stage glows. Emits stage_selected(index).

signal stage_selected(index: int)

const ICONS := ["seedling", "sapling", "family", "lantern", "tree_decorated"]

var current := 4
var _hover := -1
var _pulse := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_exited.connect(func() -> void:
		_hover = -1
		tooltip_text = ""
		queue_redraw()
	)


func _centers() -> Array:
	var out: Array = []
	var n := ICONS.size()
	var margin := 82.0
	for i in n:
		out.append(Vector2(margin + i * (size.x - margin * 2.0) / (n - 1), 50))
	return out


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := _index_at(event.position)
		if h != _hover:
			_hover = h
			if h >= 0:
				var reached := h <= GameState.stage_reached
				var title: String = GameState.STAGES[h]["title"]
				if h == current:
					tooltip_text = "%s (you are here)" % title
				elif reached:
					tooltip_text = "Revisit: %s" % title
				else:
					tooltip_text = "%s (not yet reached)" % title
				if reached and h != current:
					AudioDirector.sfx("hover", 1.0 + h * 0.06, -14.0)
			else:
				tooltip_text = ""
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var i := _index_at(event.position)
		if i >= 0 and i <= GameState.stage_reached and i != current:
			AudioDirector.sfx("chime")
			stage_selected.emit(i)
			accept_event()


func _index_at(p: Vector2) -> int:
	var cs := _centers()
	for i in cs.size():
		if p.distance_to(cs[i]) < 34.0:
			return i
	return -1


func _draw() -> void:
	var cs := _centers()
	var f := UIKit.font("caps")
	# Connecting rail
	for i in cs.size() - 1:
		var a: Vector2 = cs[i]
		var b: Vector2 = cs[i + 1]
		var reached := i + 1 <= GameState.stage_reached
		draw_line(a + Vector2(32, 0), b - Vector2(32, 0), UIKit.GOLD_DARK, 4.0)
		draw_line(a + Vector2(32, 0), b - Vector2(32, 0), UIKit.GOLD if reached else Color(UIKit.GOLD, 0.25), 1.5)
		var mid := (a + b) * 0.5
		draw_colored_polygon(PackedVector2Array([mid + Vector2(0, -4), mid + Vector2(5, 0), mid + Vector2(0, 4), mid + Vector2(-5, 0)]), UIKit.GOLD if reached else UIKit.GOLD_DARK)
	for i in cs.size():
		var c: Vector2 = cs[i]
		var reached := i <= GameState.stage_reached
		var is_cur := i == current
		var hot := i == _hover and reached
		var r := 30.0
		if is_cur:
			var glow := 0.5 + 0.5 * sin(_pulse * 2.5)
			draw_texture_rect(Tex.glow(), Rect2(c - Vector2(56, 56), Vector2(112, 112)), false, Color(1.0, 0.8, 0.4, 0.35 + glow * 0.25))
		draw_circle(c + Vector2(2, 3), r + 3, Color(0, 0, 0, 0.45))
		draw_circle(c, r + 3, UIKit.GOLD_DARK)
		var face := UIKit.VELVET_GREEN.lightened(0.15) if reached else Color(0.1, 0.08, 0.06)
		if is_cur:
			face = UIKit.BURGUNDY.lightened(0.1)
		draw_circle(c, r, face)
		draw_arc(c, r, 0, TAU, 40, UIKit.GOLD_LIGHT if (is_cur or hot) else UIKit.GOLD, 2.5, true)
		draw_arc(c, r - 5, 0, TAU, 40, Color(UIKit.GOLD, 0.35), 1.0, true)
		var icol := UIKit.GOLD_LIGHT if (is_cur or hot) else (UIKit.GOLD if reached else Color(UIKit.GOLD, 0.3))
		UIIcons.draw(self, ICONS[i], Rect2(c - Vector2(19, 19), Vector2(38, 38)), icol)
		var label: String = GameState.STAGES[i]["title"]
		var lc := UIKit.GOLD_LIGHT if is_cur else (UIKit.TEXT_LIGHT if reached else Color(UIKit.TEXT_LIGHT, 0.35))
		UIKit.text_centered(self, f, c + Vector2(0, 50), label, 18, lc)
