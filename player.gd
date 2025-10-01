extends CharacterBody2D

# Переменные движения игрока
var speed: float
var jump: float

# Сигнал поражения игрока
signal gameover

# Ссылка на компонент анимированного спрайта
@onready var player_animation: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Инициализация параметров игрока из глобальной конфигурации
	speed = get_node("/root/ConfigManager").player_speed
	jump = get_node("/root/ConfigManager").player_jump_velocity

func _physics_process(delta: float) -> void:
	# Применяем гравитацию, когда игрок не на земле
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Обрабатываем прыжок при нажатии кнопки и нахождении на земле
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump

	# Получаем направление ввода по горизонтали (-1 влево, 1 вправо, 0 отсутствие)
	var direction := Input.get_axis("left", "right")
	
	# Применяем движение или замедление в зависимости от ввода
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	# Обновляем анимации игрока в зависимости от текущего состояния
	handle_animations()
	
	# Проверяем, не упал ли игрок с уровня
	check_fall_death()
	
	# Перемещаем персонажа и обрабатываем столкновения
	move_and_slide()

func check_fall_death() -> void:
	# Перезапускаем уровень, если игрок упал ниже определенной позиции по Y
	if global_position.y > 350:
		gameover.emit()

func handle_animations() -> void:
	# Обрабатываем отражение спрайта в зависимости от направления движения
	if velocity.x < 0:
		player_animation.flip_h = true
	elif velocity.x > 0:
		player_animation.flip_h = false
	
	# Воспроизводим соответствующую анимацию в зависимости от состояния игрока
	if not is_on_floor():
		player_animation.play("jump")
	elif velocity.x != 0:
		player_animation.play("run")
	else:
		player_animation.play("idle")
