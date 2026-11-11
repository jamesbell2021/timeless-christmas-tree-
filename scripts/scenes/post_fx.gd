class_name PostFX
extends ColorRect
## Full-screen post-process layer. Sits above the world (high z_index) and
## below the UI CanvasLayer, so menus stay crisp while the scene is painted.

var mode := "oil"   # "oil" (parlour) or "watercolour" (story)


func _init(p_mode: String = "oil") -> void:
	mode = p_mode


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(1920, 1080)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	z_as_relative = false
	var mat := ShaderMaterial.new()
	if mode == "watercolour":
		mat.shader = load("res://shaders/watercolour.gdshader")
		mat.set_shader_parameter("noise_tex", Tex.noise_tile(31, 0.012, 512))
		mat.set_shader_parameter("paper_tex", Tex.paper())
	else:
		mat.shader = load("res://shaders/painterly.gdshader")
		mat.set_shader_parameter("weave_tex", Tex.canvas_weave())
	material = mat
	GameState.settings_changed.connect(_apply)
	_apply()


func _apply() -> void:
	var q: int = int(GameState.settings["painterly"])
	var mat := material as ShaderMaterial
	if mode == "watercolour":
		visible = q > 0
		mat.set_shader_parameter("wobble", 2.2 if q >= 2 else 1.2)
	else:
		mat.set_shader_parameter("quality", q)
		visible = true
		mat.set_shader_parameter("grain", 0.035 if q > 0 else 0.0)
		mat.set_shader_parameter("vignette", 0.55 if q > 0 else 0.4)
