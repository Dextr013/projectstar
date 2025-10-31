extends Area2D

signal died(score)
signal health_changed(max_health, current_health)

var bullet_scene = preload("res://scenes/enemy_bullet.tscn")
var max_health = 50
var health = max_health
var speed = 30
var boss_type = 0
var pattern = "basic"
var move_direction = 1
var shoot_phase = 0

@onready var screensize = get_viewport().get_visible_rect().size
@onready var animated_sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var shoot_timer = $ShootTimer
@onready var pattern_timer = $PatternTimer

# SpriteFrames ресурс с анимациями боссов
var boss_frames = preload("res://boss.tres")

func _ready():
	add_to_group("boss")
	AudioManager.play_music("boss")

func start(wave: int):
	var boss_data = GameManager.get_boss_for_wave()
	boss_type = min(int(wave / 10.0) - 1, 2)
	max_health = boss_data.health * GameManager.difficulty_multiplier
	health = max_health
	speed = boss_data.speed
	pattern = boss_data.pattern
	
	# Устанавливаем SpriteFrames и анимацию
	animated_sprite.sprite_frames = boss_frames
	
	# Выбираем анимацию в зависимости от типа босса
	match boss_type:
		0:
			animated_sprite.play("boss1")
			animated_sprite.scale = Vector2(2, 2)
		1:
			animated_sprite.play("boss2")
			animated_sprite.scale = Vector2(2.2, 2.2)
		2:
			animated_sprite.play("boss3")
			animated_sprite.scale = Vector2(2.5, 2.5)
	
	# Появление босса
	position = Vector2(screensize.x / 2, -100)
	var tween = create_tween().set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "position:y", 80, 2.0)
	
	# Эффект появления
	animated_sprite.modulate.a = 0
	tween.parallel().tween_property(animated_sprite, "modulate:a", 1.0, 1.5)
	
	await tween.finished
	
	shoot_timer.start()
	pattern_timer.start()
	
	health_changed.emit(max_health, health)

func _process(delta):
	# Движение из стороны в сторону
	position.x += speed * move_direction * delta
	
	if position.x <= 50:
		move_direction = 1
	elif position.x >= screensize.x - 50:
		move_direction = -1

func hit(damage: int):
	health -= damage
	health_changed.emit(max_health, health)
	
	# Эффект попадания
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(2, 2, 2), 0.05)
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1), 0.05)
	
	if health <= 0:
		explode()

func explode():
	shoot_timer.stop()
	pattern_timer.stop()
	
	# Проигрываем анимацию смерти если есть
	if animated_sprite.sprite_frames.has_animation("explode"):
		animated_sprite.play("explode")
		await animated_sprite.animation_finished
	else:
		# Стандартная анимация взрыва
		animation_player.play("explode")
		await animation_player.animation_finished
	
	set_deferred("monitorable", false)
	
	var boss_data = GameManager.get_boss_for_wave()
	died.emit(boss_data.score)
	
	# Дропаем много powerups
	spawn_powerups(5)
	
	AudioManager.play_sfx("explosion")
	AudioManager.play_music("game", 1.0)
	
	# Эффект исчезновения
	var fade_tween = create_tween()
	fade_tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.5)
	await fade_tween.finished
	
	queue_free()

func spawn_powerups(count: int):
	call_deferred("_deferred_spawn_powerups", count)

func _deferred_spawn_powerups(count: int):
	var powerup_scene: PackedScene
	
	if ResourceLoader.exists("res://powerup.tscn"):
		powerup_scene = load("res://powerup.tscn")
	elif ResourceLoader.exists("res://scenes/powerup.tscn"):
		powerup_scene = load("res://scenes/powerup.tscn")
	else:
		return
	
	for i in count:
		var powerup = powerup_scene.instantiate()
		get_tree().root.add_child(powerup)
		powerup.position = position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		
		# Для босса - более редкие и ценные powerups
		var rare_types = ["shield", "rapid_fire", "double_shot"]
		powerup.set_type(rare_types[randi() % rare_types.size()])

func _on_shoot_timer_timeout():
	match pattern:
		"basic":
			shoot_basic()
		"spread":
			shoot_spread()
		"circle":
			shoot_circle()
	
	shoot_timer.wait_time = randf_range(1.5, 3.0)

func _on_pattern_timer_timeout():
	shoot_phase = (shoot_phase + 1) % 3
	pattern_timer.wait_time = randf_range(3, 6)

func shoot_basic():
	# Стреляет 3 пулями вниз
	for i in range(3):
		var b = bullet_scene.instantiate()
		get_tree().root.add_child(b)
		b.start(position + Vector2((i - 1) * 20, 10))
		AudioManager.play_sfx("enemy_shoot", 0.8)

func shoot_spread():
	# Стреляет веером
	var angles = [-30, -15, 0, 15, 30]
	for angle in angles:
		var b = bullet_scene.instantiate()
		get_tree().root.add_child(b)
		b.start(position + Vector2(0, 10))
		b.rotation_degrees = angle
	AudioManager.play_sfx("enemy_shoot", 0.9)

func shoot_circle():
	# Стреляет по кругу
	var bullet_count = 8
	for i in range(bullet_count):
		var angle = (TAU / bullet_count) * i
		var b = bullet_scene.instantiate()
		get_tree().root.add_child(b)
		b.start(position)
		b.rotation = angle
		if b.has_method("set_direction"):
			var direction = Vector2(cos(angle), sin(angle))
			b.set_direction(direction)
	AudioManager.play_sfx("enemy_shoot", 1.0)

# Вспомогательная функция для проверки анимаций
func get_animation_list() -> Array:
	var animations = []
	if animated_sprite.sprite_frames:
		for i in range(animated_sprite.sprite_frames.get_animation_count()):
			animations.append(animated_sprite.sprite_frames.get_animation_name(i))
	return animations
