extends CharacterBody2D

# Скорость движения врага
var speed: float
# Направление движения врага (1 - вправо, -1 - влево)
var direction: int = 1

# Сигнал поражения игрока
signal gameover

# Ссылка на компонент анимированного спрайта врага
@onready var enemy_animation: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Инициализация скорости из глобальной конфигурации
	speed = get_node("/root/ConfigManager").enemy_speed
	# Запускаем стандартную анимацию врага
	enemy_animation.play("default")

func _physics_process(delta: float) -> void:
	# Применяем гравитацию, когда враг не на земле
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Устанавливаем горизонтальную скорость в соответствии с направлением
	velocity.x = speed * direction
	
	# Проверяем столкновения с помощью raycast'ов для смены направления
	handle_raycast_collisions()
	# Перемещаем врага и обрабатываем физику
	move_and_slide()
	# Проверяем столкновения с игроком после движения
	check_player_collision()

func handle_raycast_collisions() -> void:
	# Меняем направление на правое при столкновении слева или отсутствии пола слева
	if $left.is_colliding() or not $left_floor.is_colliding():
		direction = 1
		enemy_animation.flip_h = false
	# Меняем направление на левое при столкновении справа или отсутствии пола справа
	elif $right.is_colliding() or not $right_floor.is_colliding():
		direction = -1
		enemy_animation.flip_h = true

func check_player_collision() -> void:
	# Проверяем все столкновения, произошедшие после move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Если столкнулись с игроком (по имени или группе)
		if collider and (collider.name == "player" or collider.is_in_group("player")):
			# Отправляем сигнал поражения и выводим сообщение
			gameover.emit()
			print("Враг коснулся игрока!")
			# Прерываем цикл после первого обнаруженного столкновения с игроком
			break
