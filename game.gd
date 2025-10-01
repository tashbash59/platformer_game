extends Node2D

# Константы уровня
const WIDTH: int = 30  # Ширина уровня в тайлах
const HEIGHT: int = 30  # Высота уровня в тайлах

# Ссылка на тайловую карту блоков
@onready var block_tile: TileMapLayer = $block_tile

# Генератор шума для процедурной генерации платформ
var noise: FastNoiseLite = FastNoiseLite.new()

# Префабы объектов
var coin_scene: PackedScene = preload("res://coin.tscn")  # Сцена монетки
var enemy_scene: PackedScene = preload("res://enemy.tscn")  # Сцена врага

# Переменные игрового состояния
var coin_count: int = 0  # Количество созданных монеток
var coin_collected: int = 0  # Количество собранных монеток
var MAX_COINS: int = 5  # Максимальное количество монеток для сбора

# Массив для хранения позиций всех платформ
var platform_positions: Array[Vector2i] = []

# Seed для генерации уровня (используется в системе сохранения)
var noise_seed: int = 0

func _ready() -> void:
	# Инициализация игры: загрузка сохранения или генерация нового уровня
	if SaveSystem.save_exists():
		SaveSystem.load_game()
	else:
		generate_new_game()

func generate_new_game() -> void:
	# Настройка параметров новой игры
	MAX_COINS = get_node("/root/ConfigManager").max_coins
	coin_collected = 0
	coin_count = 0
	noise_seed = randi()  # Генерируем новый seed для процедурной генерации
	$CanvasLayer/Label.text = "Монетки " + str(coin_collected) + "/" + str(MAX_COINS)
	generate_uniform_platformer()

func generate_uniform_platformer() -> void:
	# Очистка предыдущего уровня
	block_tile.clear()
	platform_positions.clear()
	
	# Создание основного пола внизу уровня
	for x in range(WIDTH):
		block_tile.set_cell(Vector2i(x, 19), 0, Vector2i(0, 0))
	
	# Настройка генератора шума Перлина
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = noise_seed  # Используем сохраненный seed для воспроизводимости
	noise.frequency = 1.5  # Частота шума определяет вариативность платформ
	
	# Разделение уровня на вертикальные зоны для равномерного распределения платформ
	var zones: int = 7  # Количество вертикальных зон
	var zone_height: float = HEIGHT / zones  # Высота одной зоны
	
	# Генерация платформ по всей ширине уровня
	for x in range(0, WIDTH, 1):
		# Определяем зону на основе значения шума (нормализуем от -1..1 к 0..zones-1)
		var zone: int = int((noise.get_noise_2d(x * 3.0, 0) + 1) * zones / 2)
		
		# Вычисляем диапазон высот для выбранной зоны
		var min_height: int = (2 + zone * zone_height) - 5
		var max_height: int = min_height + zone_height - 1
		var platform_height: int = randi() % int(max_height - min_height) + min_height
		
		# Создаем платформу, если она помещается в пределах уровня
		if x + 2 < WIDTH and platform_height < HEIGHT - 2:
			create_platform(x, platform_height, 5)

	# Распределяем монетки по созданным платформам
	distribute_coins_uniformly()

func create_platform(start_x: int, y: int, length: int) -> void:
	# Проверяем, что платформа не выходит за границы уровня
	if start_x + length > WIDTH:
		return
		
	# Проверяем свободное пространство вокруг платформы
	var can_place: bool = true
	for i in range(-1, length + 1):
		for j in range(-2, 3):  # Проверяем область 3x(длина+2) вокруг платформы
			var check_x: int = start_x + i
			var check_y: int = y + j
			
			# Проверяем, что координаты в пределах уровня и ячейка свободна
			if check_x >= 0 and check_x < WIDTH and check_y >= 0 and check_y < HEIGHT:
				if block_tile.get_cell_source_id(Vector2i(check_x, check_y)) != -1:
					can_place = false
					break
		if not can_place:
			break
	
	# Создаем платформу, если место свободно
	if can_place:
		for i in range(length):
			var x: int = start_x + i
			block_tile.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
			
			# Сохраняем позицию блока для последующего размещения монеток
			platform_positions.append(Vector2i(x, y))
		
		# С шансом 30% создаем врага на платформе
		if randf() < 0.3:  
			spawn_enemy_on_platform(start_x, y, length)

func spawn_enemy_on_platform(platform_x: int, platform_y: int, platform_length: int) -> void:
	# Выбираем случайную позицию на платформе (исключая края)
	var enemy_x: int = platform_x + randi() % (platform_length - 2) + 1
	
	# Вычисляем мировые координаты для врага (центр тайла)
	var enemy_position: Vector2 = Vector2(enemy_x * 16 + 8, platform_y * 16 - 8)
	
	# Создаем экземпляр врага и добавляем на сцену
	var enemy_instance: Node2D = enemy_scene.instantiate()
	enemy_instance.position = enemy_position
	add_child(enemy_instance)
	
	# Подключаем сигнал поражения от врага
	enemy_instance.gameover.connect(_on_player_gameover)
	
	print("Враг размещен на платформе: ", Vector2i(enemy_x, platform_y))

func distribute_coins_uniformly() -> void:
	# Проверяем, что есть платформы для размещения монеток
	if platform_positions.size() == 0:
		return
	
	# Вычисляем шаг для равномерного распределения монеток по всем платформам
	var step: int = max(1, platform_positions.size() / MAX_COINS)
	
	# Размещаем монетки на выбранных платформах
	for i in range(0, min(MAX_COINS, platform_positions.size())):
		var index: int = i * step
		if index < platform_positions.size():
			var block_pos: Vector2i = platform_positions[index]
			spawn_coin_above_block(block_pos.x, block_pos.y)

func spawn_coin_above_block(block_x: int, block_y: int) -> void:
	# Увеличиваем счетчик созданных монеток
	coin_count += 1
	
	# Вычисляем мировые координаты для монетки (над блоком)
	var coin_position: Vector2 = Vector2(block_x * 16 + 8, block_y * 16 - 8)
	
	# Создаем экземпляр монетки и добавляем на сцену
	var coin_instance: Node2D = coin_scene.instantiate()
	coin_instance.position = coin_position
	add_child(coin_instance)
	
	# Подключаем сигнал сбора монетки
	coin_instance.collected.connect(_on_coin_collected)
	
	print("Монетка размещена над блоком: ", Vector2i(block_x, block_y))

func _on_coin_collected() -> void:
	# Обработка сбора монетки игроком
	coin_collected += 1
	$CanvasLayer/Label.text = "Монетки" + str(coin_collected) +"/" + str(MAX_COINS)
	
	# Проверяем условие победы (собраны все монетки)
	if coin_collected == MAX_COINS:
		get_tree().paused = true
		$CanvasLayer.process_mode = Node.PROCESS_MODE_ALWAYS
		hide_or_open_menu(true, true)  # Показываем экран победы

func hide_or_open_menu(win_or_lose: bool, open_or_hide: bool) -> void:
	# Управление видимостью элементов интерфейса окончания игры
	if win_or_lose:
		$CanvasLayer/win.visible = open_or_hide  # Показать/скрыть экран победы
	else:
		$CanvasLayer/lose.visible = open_or_hide  # Показать/скрыть экран поражения
	$CanvasLayer/restart.visible = open_or_hide  # Кнопка рестарта
	$CanvasLayer/exit.visible = open_or_hide  # Кнопка выхода

func _on_restart_pressed() -> void:
	# Обработка нажатия кнопки рестарта
	get_tree().paused = false
	
	# Удаляем сохранение при рестарте
	if SaveSystem.save_exists():
		SaveSystem.delete_save()
	
	# Полная перезагрузка текущей сцены
	get_tree().reload_current_scene()

func _on_exit_pressed() -> void:
	# Обработка нажатия кнопки выхода
	get_tree().quit()

func _on_player_gameover() -> void:
	# Обработка поражения игрока (сигнал от игрока или врага)
	get_tree().paused = true
	$CanvasLayer.process_mode = Node.PROCESS_MODE_ALWAYS
	hide_or_open_menu(false, true)  # Показываем экран поражения

func get_game_state() -> Dictionary:
	# Возвращает текущее состояние игры для сохранения
	return {
		"coins_collected": coin_collected,
		"max_coins": MAX_COINS,
		"coin_count": coin_count,
		"noise_seed": noise_seed
	}

func set_game_state(state: Dictionary) -> void:
	# Восстанавливает состояние игры из сохранения
	coin_collected = state.get("coins_collected", 0)
	MAX_COINS = state.get("max_coins", 5)
	coin_count = state.get("coin_count", 0)
	noise_seed = state.get("noise_seed", randi())
	
	# Обновляем интерфейс
	$CanvasLayer/Label.text = "Монетки " + str(coin_collected) + "/" + str(MAX_COINS)
