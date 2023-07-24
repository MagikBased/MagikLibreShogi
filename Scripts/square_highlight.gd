extends Sprite2D

var parentNode = get_parent()
var currentPosition: Vector2
var isDropping: bool = false

func _ready():
	set_process_input(true)
	add_to_group("highlights")

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and get_rect().has_point(to_local(event.position)):
		if get_parent().has_method("move_piece"):
			get_parent().move_piece(currentPosition.x,currentPosition.y)
		if get_parent().has_method("drop_piece"):
			get_parent().drop_piece(currentPosition.x,currentPosition.y)

