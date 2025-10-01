extends Node2D

func win():
	$CanvasLayer/win.visible = true

func gameover():
	$CanvasLayer/lose.visible = true
	

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_exit_pressed() -> void:
	get_tree().quit()
