extends Node


# Настройки сохранения
var auto_save_enabled: bool = true
var save_file_path: String = "user://game_save.cfg"

func _ready() -> void:
	# Автоматическое сохранение при закрытии игры
	get_tree().root.close_requested.connect(_on_close_requested)

func _on_close_requested() -> void:
	# Сохраняем игру перед выходом
	save_game()
	get_tree().quit()

# Основная функция сохранения игры
func save_game() -> void:
	if not auto_save_enabled:
		return
	
	print("=== СОХРАНЕНИЕ ИГРЫ ===")
	
	# Собираем все данные игры в одну структуру
	var save_data: Dictionary = collect_game_data()
	
	# Сохраняем в конфигурационный файл
	var config_file: ConfigFile = ConfigFile.new()
	config_file.set_value("game", "save_data", save_data)
	
	var error: int = config_file.save(save_file_path)
	if error == OK:
		print("Успешно сохранено: ", save_file_path)
	else:
		print("Ошибка сохранения: ", error)

# Сбор всех данных игры в один словарь
func collect_game_data() -> Dictionary:
	var current_scene: Node = get_tree().current_scene
	if not current_scene:
		return {}
	
	return {
		"timestamp": Time.get_unix_time_from_system(),
		"scene_name": current_scene.scene_file_path,
		"player_data": get_player_data(current_scene),
		"enemies_data": get_enemies_data(current_scene),
		"coins_data": get_coins_data(current_scene),
		"platforms_data": get_platforms_data(current_scene),
		"game_state": get_game_state_data(current_scene)
	}

# Получение данных игрока
func get_player_data(scene: Node) -> Dictionary:
	var player: Node2D = scene.find_child("player", true, false)
	if not player:
		return {}
	
	return {
		"position": {
			"x": player.global_position.x,
			"y": player.global_position.y
		}
	}

# Получение данных всех врагов
func get_enemies_data(scene: Node) -> Array:
	var enemies_data: Array = []
	var enemies: Array = scene.get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if enemy and enemy.is_inside_tree():
			enemies_data.append({
				"position": {
					"x": enemy.global_position.x,
					"y": enemy.global_position.y
				},
				"direction": enemy.direction
			})
	
	print("Сохранено врагов: ", enemies_data.size())
	return enemies_data

# Получение данных всех монеток
func get_coins_data(scene: Node) -> Array:
	var coins_data: Array = []
	var coins: Array = scene.get_tree().get_nodes_in_group("coin")
	
	for coin in coins:
		if coin and coin.is_inside_tree():
			coins_data.append({
				"position": {
					"x": coin.global_position.x,
					"y": coin.global_position.y
				}
			})
	
	print("Сохранено монеток: ", coins_data.size())
	return coins_data

# Получение данных платформ из TileMapLayer
func get_platforms_data(scene: Node) -> Array:
	var platforms_data: Array = []
	# Ищем TileMapLayer вместо TileMap
	var tilemap_layer: TileMapLayer = scene.find_child("block_tile", true, false)
	
	if not tilemap_layer:
		print("TileMapLayer 'block_tile' не найден")
		return platforms_data
	
	# Для TileMapLayer получаем все использованные ячейки
	var used_cells: Array = tilemap_layer.get_used_cells()
	
	for cell in used_cells:
		# Для TileMapLayer используем упрощенное сохранение
		platforms_data.append({
			"cell": {"x": cell.x, "y": cell.y},
			"source_id": 0,  # Базовая текстура
			"atlas_coords": {"x": 0, "y": 0},  # Координаты в атласе
			"layer": 0  # Слой по умолчанию
		})
	
	print("Сохранено платформ: ", platforms_data.size())
	return platforms_data

# Получение состояния игры из основного скрипта
func get_game_state_data(scene: Node) -> Dictionary:
	if scene and scene.has_method("get_game_state"):
		var game_state: Dictionary = scene.get_game_state()
		print("Состояние игры сохранено")
		return game_state
	return {}

# Основная функция загрузки игры
func load_game() -> bool:
	print("=== ЗАГРУЗКА ИГРЫ ===")
	
	var config_file: ConfigFile = ConfigFile.new()
	var error: int = config_file.load(save_file_path)
	
	if error != OK:
		print("Файл сохранения не найден")
		return false
	
	var save_data: Dictionary = config_file.get_value("game", "save_data", {})
	if save_data.is_empty():
		print("Нет данных для загрузки")
		return false
	
	# Ждем готовности сцены и восстанавливаем данные
	await get_tree().process_frame
	restore_game_data(save_data)
	
	print("Игра загружена успешно")
	return true

# Восстановление всех данных игры
func restore_game_data(save_data: Dictionary) -> void:
	var current_scene: Node = get_tree().current_scene
	if not current_scene:
		return
	
	# Очищаем текущую сцену перед восстановлением
	clear_scene_objects(current_scene)
	
	# Восстанавливаем данные в правильном порядке
	restore_platforms(current_scene, save_data.get("platforms_data", []))
	restore_coins(current_scene, save_data.get("coins_data", []))
	restore_enemies(current_scene, save_data.get("enemies_data", []))
	restore_player(current_scene, save_data.get("player_data", {}))
	restore_game_state(current_scene, save_data.get("game_state", {}))
	
	print("Все данные восстановлены")

# Очистка динамических объектов сцены
func clear_scene_objects(scene: Node) -> void:
	# Удаляем врагов
	var enemies: Array = scene.get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		enemy.queue_free()
	
	# Удаляем монетки
	var coins: Array = scene.get_tree().get_nodes_in_group("coin")
	for coin in coins:
		coin.queue_free()
	
	# Очищаем TileMapLayer
	var tilemap_layer: TileMapLayer = scene.find_child("block_tile", true, false)
	if tilemap_layer:
		tilemap_layer.clear()
	
	print("Сцена очищена")

# Восстановление платформ в TileMapLayer
func restore_platforms(scene: Node, platforms_data: Array) -> void:
	await get_tree().process_frame
	
	var tilemap_layer: TileMapLayer = scene.find_child("block_tile", true, false)
	if not tilemap_layer:
		print("Ошибка: TileMapLayer 'block_tile' не найден для восстановления")
		return
	
	for platform in platforms_data:
		var cell: Vector2i = Vector2i(platform["cell"]["x"], platform["cell"]["y"])
		var source_id: int = platform.get("source_id", 0)
		var atlas_coords: Vector2i = Vector2i(platform["atlas_coords"]["x"], platform["atlas_coords"]["y"])
		
		# Для TileMapLayer используем set_cell с координатами и источником
		tilemap_layer.set_cell(cell, source_id, atlas_coords)
	
	print("Восстановлено платформ: ", platforms_data.size())

# Восстановление монеток
func restore_coins(scene: Node, coins_data: Array) -> void:
	var coin_scene: PackedScene = preload("res://coin.tscn")
	
	for coin_data in coins_data:
		var coin: Node2D = coin_scene.instantiate()
		coin.global_position = Vector2(coin_data["position"]["x"], coin_data["position"]["y"])
		scene.add_child(coin)
		
		if coin.has_signal("collected"):
			coin.collected.connect(scene._on_coin_collected)
	
	print("Восстановлено монеток: ", coins_data.size())

# Восстановление врагов
func restore_enemies(scene: Node, enemies_data: Array) -> void:
	var enemy_scene: PackedScene = preload("res://enemy.tscn")
	
	for enemy_data in enemies_data:
		var enemy: Node2D = enemy_scene.instantiate()
		enemy.global_position = Vector2(enemy_data["position"]["x"], enemy_data["position"]["y"])
		enemy.direction = enemy_data.get("direction", 1)
		scene.add_child(enemy)
		
		if enemy.has_signal("gameover"):
			enemy.gameover.connect(scene._on_player_gameover)
	
	print("Восстановлено врагов: ", enemies_data.size())

# Восстановление игрока
func restore_player(scene: Node, player_data: Dictionary) -> void:
	var player: Node2D = scene.find_child("player", true, false)
	if player and not player_data.is_empty():
		var position: Vector2 = Vector2(player_data["position"]["x"], player_data["position"]["y"])
		player.global_position = position
		player.velocity = Vector2.ZERO
		print("Игрок восстановлен")

# Восстановление состояния игры
func restore_game_state(scene: Node, game_state: Dictionary) -> void:
	if scene and scene.has_method("set_game_state"):
		scene.set_game_state(game_state)
		print("Состояние игры восстановлено")

# Проверка существования файла сохранения
func save_exists() -> bool:
	return FileAccess.file_exists(save_file_path)

# Удаление сохранения
func delete_save() -> void:
	if save_exists():
		var dir: DirAccess = DirAccess.open("user://")
		if dir:
			dir.remove(save_file_path.get_file())
			print("Сохранение удалено")
	else:
		print("Сохранение не существует")
