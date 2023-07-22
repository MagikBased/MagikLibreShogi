extends Sprite2D

var parentNode = get_parent()
var currentPosition: Vector2

func _ready():
	set_process_input(true)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and get_rect().has_point(to_local(event.position)):
		get_parent().move_piece(currentPosition.x,currentPosition.y)


