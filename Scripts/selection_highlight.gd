extends Node2D

@onready var selection_color = get_parent().selectionColor
@export var moved_indicator_highlight: bool
var rect_size = Vector2(100,100)
var piece_moved: bool = false
var moved_from: Vector2

func _ready():
	call_deferred("set_rect_size")
	if moved_indicator_highlight:
		selection_color.a = 0.3

func set_rect_size():
	rect_size = get_parent().rectSize

func _draw():
	draw_rect(Rect2(Vector2(0,0) - rect_size/2,rect_size),selection_color,true)
