extends Node2D

@onready var selection_color = get_parent().selectionColor
var rect_size = Vector2(100,100)

func _ready():
	call_deferred("set_rect_size")

func set_rect_size():
	rect_size = get_parent().rectSize

func _draw():
	draw_rect(Rect2(Vector2(0,0) - rect_size/2,rect_size),selection_color,true)
