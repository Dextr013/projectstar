extends Area2D

signal died(score)

var start_pos = Vector2.ZERO
var speed = 0
var bullet_scene = preload("res://scenes/enemy_bullet.tscn")
var _powerup_scene: PackedScene
var anchor
var follow_anchor = false
var enemy_type = "basic"
var health = 1

@onready var screensize = get_viewport().get_visible_rect().size
@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var move_timer = $MoveTimer
@onready var shoot_timer = $ShootTimer

func _ready():
	add_to_group("enemies")
	
	# Подключаем сигналы таймеров
	if not move_timer.timeout.is_connected(_on_move_timer_timeout):
		move_timer.timeout.connect(_on_move_timer_timeout)
	if not shoot_timer.timeout.is_connected(_on_shoot_timer_timeout):
		shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	
	# Пытаемся загрузить powerup сцену
	if ResourceLoader.exists("res://powerup.tscn"):
		_powerup_scene = load("res://powerup.tscn")
	elif ResourceLoader.exists("res://scenes/powerup.tscn"):
		_powerup_scene = load("res://scenes/powerup.tscn")

func start(pos, type = "basic"):
	enemy_type = type
	setup_enemy_type()
	
	follow_anchor = false
	speed = 0
	position = Vector2(pos.x, -pos.y)
	start_pos = pos
	
	await get_tree().create_timer(randf_range(0.25, 0.55)).timeout
	var tw = create_tween().set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "position:y", start_pos.y, 1.4)
	await tw.finished
	
	follow_anchor = true
	
	var enemy_data = GameManager.enemy_types[enemy_type]
	move_timer.wait_time = randf_range(5, 20)
	move_timer.start()
	shoot_timer.wait_time = randf_range(enemy_data.shoot_interval[0], enemy_data.shoot_interval[1])
	shoot_timer.start()

func setup_enemy_type():
	var enemy_data = GameManager.enemy_types.get(enemy_type, GameManager.enemy_types["basic"])
	health = enemy_data.health
	
	# Визуальная дифференциация типов
	match enemy_type:
		"fast":
			sprite.modulate = Color(1, 0.5, 0.5)  # Красноватый
		"tank":
			sprite.modulate = Color(0.5, 0.5, 1)  # Синеватый
			sprite.scale = Vector2(1.2, 1.2)
		"shooter":
			sprite.modulate = Color(1, 1, 0.5)  # Желтоватый

func _process(delta):
	if follow_anchor and anchor:
		position = start_pos + anchor.position
	position.y += speed * delta
	
	if position.y > screensize.y + 32:
		start(start_pos, enemy_type)

func hit(damage: int):
	health -= damage
	
	# Эффект попадания
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:v", 2.0, 0.1)
	tween.tween_property(sprite, "modulate:v", 1.0, 0.1)
	
	if health <= 0:
		explode()

func explode():
	speed = 0
	animation_player.play("explode")
	set_deferred("monitorable", false)
	
	var enemy_data = GameManager.enemy_types[enemy_type]
	died.emit(enemy_data.score)
	
	AudioManager.play_sfx("explosion", randf_range(0.8, 1.2))
	
	# Шанс выпадения powerup
	if randf() < 0.15:  # 15% шанс
		spawn_powerup()
	
	await animation_player.animation_finished
	queue_free()

func spawn_powerup():
	# Используем call_deferred для безопасного спавна
	call_deferred("_deferred_spawn_powerup")

func _deferred_spawn_powerup():
	if not _powerup_scene:
		return
		
	var powerup = _powerup_scene.instantiate()
	get_tree().root.add_child(powerup)
	powerup.position = position
	
	# Случайный тип powerup
	var types = ["health", "shield", "rapid_fire", "double_shot", "coin"]
	var weights = [30, 20, 15, 15, 20]  # Веса вероятности
	
	var total_weight = 0
	for w in weights:
		total_weight += w
	
	var random_value = randf() * total_weight
	var cumulative = 0
	
	for i in range(types.size()):
		cumulative += weights[i]
		if random_value <= cumulative:
			powerup.set_type(types[i])
			break

func _on_move_timer_timeout():
	var enemy_data = GameManager.enemy_types[enemy_type]
	speed = randf_range(enemy_data.speed * 0.75, enemy_data.speed * 1.25)
	follow_anchor = false

func _on_shoot_timer_timeout():
	if position.y > 0 and position.y < screensize.y:
		shoot()
	
	var enemy_data = GameManager.enemy_types[enemy_type]
	shoot_timer.wait_time = randf_range(enemy_data.shoot_interval[0], enemy_data.shoot_interval[1])
	shoot_timer.start()

func shoot():
	var b = bullet_scene.instantiate()
	get_tree().root.add_child(b)
	b.start(position)
	
	# Shooter тип стреляет несколькими пулями
	if enemy_type == "shooter":
		await get_tree().create_timer(0.1).timeout
		var b2 = bullet_scene.instantiate()
		get_tree().root.add_child(b2)
		b2.start(position + Vector2(-5, 0))
		
		var b3 = bullet_scene.instantiate()
		get_tree().root.add_child(b3)
		b3.start(position + Vector2(5, 0))
	
	AudioManager.play_sfx("enemy_shoot", randf_range(0.9, 1.1))
