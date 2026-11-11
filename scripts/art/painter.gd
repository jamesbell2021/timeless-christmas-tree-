class_name Painter
extends Node2D
## A tiny helper node: draws by calling a Callable with itself as the canvas.
## Lets one script compose several draw layers (e.g. view, snow, frame)
## without writing a class per layer.

var paint: Callable


func _init(p: Callable = Callable()) -> void:
	paint = p


func _draw() -> void:
	if paint.is_valid():
		paint.call(self)
