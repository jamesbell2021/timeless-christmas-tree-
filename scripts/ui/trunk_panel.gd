class_name TrunkPanel
extends Control
## The vintage trunk: a drawer of period decorations sorted into six
## velvet-lined trays. Pressing a slot starts a drag in the DecorManager.

signal drag_started(id: String)
signal closed

const W := 356.0
const SLOT := 98.0

var open := false
var _tab := "lights"
var _tabs: Dictionary = {}
var _grid: GridContainer
var _scroll: ScrollContainer
var _title := ""


func _ready() -> void:
	size = Vector2(W, 812)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Tabs
	var tx := 22.0
	for t in Catalogue.TABS:
		var b := OrnateButton.new("", "tab", t["icon"])
		b.toggle_mode = true
		b.position = Vector2(tx, 104)
		b.size = Vector2(50, 50)
		b.custom_minimum_size = Vector2(50, 50)
		b.tooltip_text = t["title"]
		b.pressed.connect(_select_tab.bind(t["id"]))
		add_child(b)
		_tabs[t["id"]] = b
		tx += 52.0
	# Close button
	var close := OrnateButton.new("", "round", "close")
	close.custom_minimum_size = Vector2(44, 44)
	close.size = Vector2(44, 44)
	close.position = Vector2(W - 58, 18)
	close.tooltip_text = "Close the trunk"
	close.pressed.connect(func() -> void: closed.emit())
	add_child(close)
	# Slots
	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(22, 204)
	_scroll.size = Vector2(W - 44, 548)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	_scroll.add_child(_grid)
	_select_tab("lights")


func _select_tab(id: String) -> void:
	_tab = id
	for k in _tabs.keys():
		(_tabs[k] as OrnateButton).button_pressed = (k == id)
	for c in _grid.get_children():
		c.queue_free()
	for d in Catalogue.items_in_tab(id):
		var s := ItemSlot.new(d)
		s.custom_minimum_size = Vector2(SLOT, SLOT)
		s.pressed_item.connect(func(item_id: String) -> void: drag_started.emit(item_id))
		_grid.add_child(s)
	for t in Catalogue.TABS:
		if t["id"] == id:
			_title = t["title"]
	_scroll.scroll_vertical = 0
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	UIKit.wood_panel(self, r, "velvet")
	# Trunk lid: a domed strip with brass corners and a hasp
	var lid := Rect2(10, 10, W - 20, 84)
	UIKit.vgrad(self, lid, Color(0.36, 0.2, 0.1), Color(0.16, 0.08, 0.04))
	draw_texture_rect(Tex.wood(), lid, true, Color(1, 1, 1, 0.4))
	for x in [lid.position.x + 16.0, lid.end.x - 104.0]:
		draw_rect(Rect2(x, lid.position.y, 18, lid.size.y), Color(0.12, 0.07, 0.04))
		for k in 3:
			draw_circle(Vector2(x + 9, lid.position.y + 16 + k * 26), 2.5, UIKit.GOLD)
	var hx := lid.position.x + 148
	draw_rect(Rect2(hx - 16, lid.end.y - 22, 32, 20), UIKit.GOLD_DARK)
	draw_rect(Rect2(hx - 12, lid.end.y - 18, 24, 12), UIKit.GOLD)
	draw_circle(Vector2(hx, lid.end.y - 12), 3, UIKit.WOOD_DARK)
	UIKit.gilt_text(self, UIKit.font("title"), Vector2(lid.position.x + 148, lid.position.y + 34), "The Trunk", 38)
	# Tray title
	UIKit.text_centered(self, UIKit.font("title_italic"), Vector2(W * 0.5, 176), _title, 25, UIKit.GOLD_LIGHT)
	UIKit.divider(self, Vector2(W * 0.5, 194), 120)
	# Footer instructions
	var fy := size.y - 46
	UIKit.text_centered(self, UIKit.font("body_italic"), Vector2(W * 0.5, fy), "Drag onto the tree or into the room", 18, Color(UIKit.TEXT_LIGHT, 0.8))
	UIKit.text_centered(self, UIKit.font("body_italic"), Vector2(W * 0.5, fy + 22), "Right-click, or drag back here, to put away", 15, Color(UIKit.TEXT_LIGHT, 0.6))
