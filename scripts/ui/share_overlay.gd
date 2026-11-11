class_name ShareOverlay
extends ModalPanel
## "Share Your Design": frames a snapshot of the parlour as a vintage
## Christmas card (gilt border, holly, greeting, signature) and saves it as a
## PNG — a download in the browser, or into Pictures on desktop.

const CARD_SIZE := Vector2i(1800, 1300)
const GREETINGS := ["A Merry Christmas", "Season's Greetings", "A Joyous Yuletide", "Christmas Greetings", "Peace on Earth"]
const SUBTITLES := ["& a Happy New Year", "from our parlour to yours", "& every Good Wish for the New Year", "& a Bright New Year", "& Goodwill to All"]

var scene_tex: Texture2D
var greeting := 0
var signer := ""

var _vp: SubViewport
var _painter: Painter
var _preview: TextureRect
var _greet_label: Label
var _status: Label


func _init(p_scene: Image) -> void:
	super("Share Your Design", Vector2(1320, 960))
	scene_tex = ImageTexture.create_from_image(p_scene)


func _build() -> void:
	_vp = SubViewport.new()
	_vp.size = CARD_SIZE
	_vp.transparent_bg = false
	_vp.disable_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	_painter = Painter.new(_paint_card)
	_vp.add_child(_painter)

	_preview = TextureRect.new()
	_preview.texture = _vp.get_texture()
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview.position = Vector2(150, 108)
	_preview.size = Vector2(1020, 640)
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_preview)

	var y := 770.0
	var left := OrnateButton.new("", "round", "left")
	left.custom_minimum_size = Vector2(52, 52)
	left.size = Vector2(52, 52)
	left.position = Vector2(150, y)
	left.pressed.connect(_change_greeting.bind(-1))
	content.add_child(left)
	_greet_label = add_label(GREETINGS[greeting], Vector2(210, y + 6), "title", 32, UIKit.INK, 360)
	_greet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var right := OrnateButton.new("", "round", "right")
	right.custom_minimum_size = Vector2(52, 52)
	right.size = Vector2(52, 52)
	right.position = Vector2(578, y)
	right.pressed.connect(_change_greeting.bind(1))
	content.add_child(right)

	var name_edit := LineEdit.new()
	name_edit.placeholder_text = "Signed with love from... (optional)"
	name_edit.position = Vector2(660, y)
	name_edit.size = Vector2(510, 52)
	name_edit.max_length = 40
	name_edit.text_changed.connect(func(t: String) -> void:
		signer = t.strip_edges()
		_painter.queue_redraw()
	)
	content.add_child(name_edit)

	var save := OrnateButton.new("Save Card", "plaque", "camera")
	save.font_size = 28
	save.position = Vector2(panel_size.x * 0.5 - 150, y + 76)
	save.custom_minimum_size = Vector2(300, 64)
	save.size = Vector2(300, 64)
	save.pressed.connect(_save)
	content.add_child(save)
	_status = add_label("", Vector2(0, y + 146), "body_italic", 22, Color(UIKit.INK, 0.75), panel_size.x)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _change_greeting(d: int) -> void:
	greeting = (greeting + d + GREETINGS.size()) % GREETINGS.size()
	_greet_label.text = GREETINGS[greeting]
	_painter.queue_redraw()


func _save() -> void:
	AudioDirector.sfx("shutter")
	await RenderingServer.frame_post_draw
	var img := _vp.get_texture().get_image()
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", " ")
	var file_name := "A Timeless Christmas Tree %s.png" % stamp
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(img.save_png_to_buffer(), file_name, "image/png")
		_status.text = "Your card is downloading, ready to share."
		return
	var dir := OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	if dir == "" or not DirAccess.dir_exists_absolute(dir):
		dir = OS.get_user_data_dir()
	var path := dir.path_join(file_name)
	var err := img.save_png(path)
	if err == OK:
		_status.text = "Saved to %s" % path
		OS.shell_show_in_file_manager(path)
	else:
		_status.text = "Sorry, the card could not be saved (error %d)." % err


# ------------------------------------------------------------ the card

func _paint_card(ci: CanvasItem) -> void:
	var W := float(CARD_SIZE.x)
	var H := float(CARD_SIZE.y)
	var r := Rect2(0, 0, W, H)
	ci.draw_texture_rect(Tex.paper(), r, true)
	for i in 14:
		ci.draw_rect(r.grow(-i * 4.0), Color(0.45, 0.28, 0.1, 0.035), false, 4.0)
	# Gilt double border with corner flourishes
	var b1 := r.grow(-40)
	var b2 := r.grow(-56)
	ci.draw_rect(b1, UIKit.GOLD_DARK, false, 6.0)
	ci.draw_rect(b1, UIKit.GOLD, false, 3.0)
	ci.draw_rect(b2, UIKit.GOLD_DARK, false, 2.0)
	for c in [[b2.position, 1, 1], [Vector2(b2.end.x, b2.position.y), -1, 1], [Vector2(b2.position.x, b2.end.y), 1, -1], [b2.end, -1, -1]]:
		UIKit.filigree_corner(ci, c[0] + Vector2(c[1] * 10, c[2] * 10), c[1], c[2], 70.0, UIKit.GOLD_DARK)
	# The scene, mounted with a bevelled gilt slip
	var inset := Rect2(130, 120, 1540, 866)
	ci.draw_rect(inset.grow(26), Color(0, 0, 0, 0.25))
	UIKit.vgrad(ci, inset.grow(20), UIKit.GOLD_LIGHT, UIKit.GOLD_DARK)
	ci.draw_rect(inset.grow(8), Color(0.2, 0.12, 0.06))
	if scene_tex:
		ci.draw_texture_rect_region(scene_tex, inset, Rect2(0, 0, 1920, 1080))
	ci.draw_rect(inset, Color(0, 0, 0, 0.5), false, 3.0)
	# Holly sprigs on the inset corners
	var holly := Catalogue.get_item("holly")
	for p in [inset.position + Vector2(10, 4), Vector2(inset.end.x - 10, inset.position.y + 4), Vector2(inset.position.x + 10, inset.end.y - 4), inset.end - Vector2(10, 4)]:
		ci.draw_set_transform(p, 0.0, Vector2(1.6, 1.6))
		DecorArt.draw_item(ci, holly, 3)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Greeting, in gilt
	UIKit.gilt_text(ci, UIKit.font("title"), Vector2(W * 0.5, 1076), GREETINGS[greeting], 104)
	UIKit.text_centered(ci, UIKit.font("title_italic"), Vector2(W * 0.5, 1150), SUBTITLES[greeting], 46, UIKit.INK.lerp(UIKit.BURGUNDY, 0.4), false)
	if signer != "":
		UIKit.text_centered(ci, UIKit.font("body_italic"), Vector2(W * 0.5, 1206), "with love from %s" % signer, 38, UIKit.INK, false)
	else:
		UIKit.divider(ci, Vector2(W * 0.5, 1204), 220, UIKit.GOLD_DARK)
