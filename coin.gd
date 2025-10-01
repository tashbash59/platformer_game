extends Area2D

# Сигнал, который отправляется при сборе монетки игроком
signal collected

func _on_body_entered(body: Node2D) -> void:
	
	# Проверяем, что вошедший объект является игроком
	if body.is_in_group("player"):
		# Отправляем сигнал о том, что монетка собрана
		collected.emit()
		# Удаляем монетку со сцены после сбора
		queue_free()
