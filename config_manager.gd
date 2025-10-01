extends Node

# Параметры игрока
var player_speed: float = 200.0  # Базовая скорость движения игрока в пикселях в секунду
var player_jump_velocity: float = -400.0  # Начальная скорость прыжка (отрицательная = вверх)

# Параметры врагов
var enemy_speed: float = 50.0  # Скорость движения врагов в пикселях в секунду

# Параметры игры
var max_coins: int = 5  # Максимальное количество монеток для завершения уровня
var enemy_chance: float = 0.3  # Вероятность появления врага на платформе (0.0 - 1.0)

# Путь к файлу конфигурации
const CONFIG_PATH: String = "res://config.cfg"

func _ready() -> void:
	# Загрузка конфигурации при инициализации менеджера
	load_config()

func load_config() -> void:
	# Создаем экземпляр ConfigFile для работы с конфигурационными файлами
	var config = ConfigFile.new()
	
	# Пытаемся загрузить конфигурационный файл
	var error = config.load(CONFIG_PATH)
	
	# Проверяем успешность загрузки файла
	if error == OK:
		# Успешно загрузили файл - читаем значения из соответствующих секций
		
		# Загружаем параметры игрока из секции "player"
		player_speed = config.get_value("player", "speed", player_speed)
		player_jump_velocity = config.get_value("player", "jump_velocity", player_jump_velocity)
		
		# Загружаем параметры врагов из секции "enemy"
		enemy_speed = config.get_value("enemy", "speed", enemy_speed)
		
		# Загружаем общие параметры игры из секции "game"
		enemy_chance = config.get_value("game", "enemy_chance", enemy_chance)
		max_coins = config.get_value("game", "max_coins", max_coins)
		
		# Выводим информацию о загруженной конфигурации (для отладки)
		print("=== Конфигурация загружена успешно ===")
		print("Скорость игрока: ", player_speed)
		print("Прыжок игрока: ", player_jump_velocity)
		print("Скорость врага: ", enemy_speed)
		print("Макс. монет: ", max_coins)  # Исправлено: было enemy_chance
		print("Вероятность появ. врага: ", enemy_chance)  # Исправлено: было max_coins
		print("=====================================")
	else:
		# Файл конфигурации не найден или поврежден - используем значения по умолчанию
		print("Конфигурационный файл не найден, используются значения по умолчанию")
