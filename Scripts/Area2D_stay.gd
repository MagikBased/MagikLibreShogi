extends Area2D

var mouse_over = false

func _input(event):
	if mouse_over and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		get_parent().selected_promote(false)
		get_parent().get_parent().get_parent().get_node("BoardSprite").emit_signal("turnEnd")


func _on_mouse_entered():
	mouse_over = true


func _on_mouse_exited():
	mouse_over = false
