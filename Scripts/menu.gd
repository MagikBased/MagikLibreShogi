extends Control


func _on_play_game_pressed():
	get_tree().change_scene_to_file("res://Scenes/game_scene.tscn")


func _on_tsume_pressed():
	pass # Replace with function body.


func _on_quit_pressed():
	get_tree().quit()
