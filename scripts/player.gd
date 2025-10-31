extends Area2D

signal shield_changed(max_value, value)
signal died

@export var bullet_scene : PackedScene

var speed = 150
var cooldown = 0.25
var max_shield = 10
var bullet_color = Color.CYAN

var shield = max_shield:
	set = set_shield
	
var can_shoot = true
var powerups = {}

@onready var screensize = get_viewport().get_visible_rect().size
@onready var gun_cooldown = $GunCooldown
@onready var ship_sprite = $Ship
@onready var boosters = $Ship/Boosters

func _ready():
	# Загружаем данные выбранного корабля
	load_ship_data()
	start()

func load_ship_data():
	var ship_data = GameManager.get_ship_data(GameManager.selected_ship)
	speed = ship_data.speed
	max_shield = ship_data.max_shield
	cooldown = ship_data.cooldown
	bullet_color = ship_data.bullet_color
	gun_cooldown.wait_time = cooldown

func start():
	show()
	position = Vector2(screensize.x / 2, screensize.y - 64)
	shield = max_shield
	powerups.clear()
	
func _process(delta):
	# Обработка powerup таймеров
	process_powerups(delta)
	
	# Движение
	var input = Input.get_vector("left", "right", "up", "down")
	
	# Анимация корабля
	if input.x > 0:
		ship_sprite.frame = 2
		boosters.animation = "right"
	elif input.x < 0:
		ship_sprite.frame = 0
		boosters.animation = "left"
	else:
		ship_sprite.frame = 1
		boosters.animation = "forward"
	
	position += input * speed * delta
	position = position.clamp(Vector2(8, 8), screensize - Vector2(8, 8))

	# Стрельба
	if Input.is_action_pressed("shoot"):
		shoot()

func shoot():
	if not can_shoot:
		return
	
	can_shoot = false
	
	# Учитываем powerup rapid_fire
	var actual_cooldown = cooldown
	if powerups.has("rapid_fire"):
		actual_cooldown *= 0.5
	
	gun_cooldown.wait_time = actual_cooldown
	gun_cooldown.start()
	
	# Double shot powerup
	if powerups.has("double_shot"):
		shoot_bullet(Vector2(-4, -8))
		shoot_bullet(Vector2(4, -8))
	else:
		shoot_bullet(Vector2(0, -8))
	
	AudioManager.play_sfx("shoot", randf_range(0.9, 1.1))
	
	# Анимация отдачи
	var tween = create_tween().set_parallel(false)
	tween.tween_property(ship_sprite, "position:y", 1, 0.1)
	tween.tween_property(ship_sprite, "position:y", 0, 0.05)

func shoot_bullet(offset: Vector2):
	if not bullet_scene:
		push_error("Bullet scene not assigned!")
		return
	
	var b = bullet_scene.instantiate()
	get_tree().root.add_child(b)
	b.start(position + offset)
	if b.has_method("set_color"):
		b.set_color(bullet_color)

func set_shield(value):
	shield = min(max_shield, value)
	shield_changed.emit(max_shield, shield)
	if shield <= 0:
		die()

func die():
	hide()
	died.emit()
	AudioManager.play_sfx("game_over")

func apply_powerup(type: String, data: Dictionary):
	match type:
		"heal":
			shield = min(shield + data.value, max_shield)
			shield_changed.emit(max_shield, shield)
		"shield":
			max_shield += data.value
			shield += data.value
			shield_changed.emit(max_shield, shield)
		"rapid_fire":
			powerups["rapid_fire"] = data.duration
		"double_shot":
			powerups["double_shot"] = data.duration
		"coin":
			GameManager.add_coins(data.value)
	
	AudioManager.play_sfx("powerup")

func process_powerups(delta):
	var expired = []
	for powerup_name in powerups:
		powerups[powerup_name] -= delta
		if powerups[powerup_name] <= 0:
			expired.append(powerup_name)
	
	for powerup_name in expired:
		powerups.erase(powerup_name)

func _on_gun_cooldown_timeout():
	can_shoot = true

func _on_area_entered(area):
	if area.is_in_group("enemies"):
		area.explode()
		shield -= max_shield / 2.0
		AudioManager.play_sfx("hit")
	elif area.is_in_group("powerups"):
		area.collect(self)
