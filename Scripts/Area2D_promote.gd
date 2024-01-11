extends Area2D

var mouse_over = false
#@onready var boardSprite = get_parent().get_parent().get_parent()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and mouse_over:
		get_parent().selected_promote(true)
		get_parent().get_parent().get_parent().get_node("BoardSprite").emit_signal("turnEnd")
		#queue_free()


func _on_mouse_entered():
	mouse_over = true

func _on_mouse_exited():
	mouse_over = false
