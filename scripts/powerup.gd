extends Area2D

@export var speed = 50
@export var powerup_type = "health"

@onready var animated_sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer

# SpriteFrames ресурс с анимациями powerups
var powerup_frames = preload("res://powerup.tres")

func _ready():
	add_to_group("powerups")
	setup_powerup()

func setup_powerup():
	var _data = GameManager.powerup_types.get(powerup_type, GameManager.powerup_types["health"])  # Префикс _ для неиспользуемой переменной
	
	# Устанавливаем SpriteFrames и проигрываем анимацию
	animated_sprite.sprite_frames = powerup_frames
	
	# Выбираем анимацию в зависимости от типа powerup
	match powerup_type:
		"health":
			animated_sprite.play("health")
		"shield":
			animated_sprite.play("shield")
		"rapid_fire":
			animated_sprite.play("rapid_fire")
		"double_shot":
			animated_sprite.play("double_shot")
		"coin":
			animated_sprite.play("coin")
		_:
			animated_sprite.play("health")  # Анимация по умолчанию
	
	# Дополнительная анимация движения
	var tween = create_tween().set_loops().set_parallel(true)
	tween.tween_property(self, "position:y", position.y + 5, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_property(self, "position:y", position.y - 5, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _process(delta):
	position.y += speed * delta
	
	# Удаляем если вышел за экран
	if position.y > get_viewport_rect().size.y + 32:
		queue_free()

func collect(player):
	var data = GameManager.powerup_types[powerup_type]
	player.apply_powerup(data.effect, data)
	
	# Эффект сбора с анимацией
	AudioManager.play_sfx("powerup")
	
	var tween = create_tween()
	tween.tween_property(animated_sprite, "scale", Vector2(1.5, 1.5), 0.2)
	tween.parallel().tween_property(animated_sprite, "modulate:a", 0, 0.2)
	await tween.finished
	
	queue_free()

func set_type(type: String):
	powerup_type = type
	if is_inside_tree():
		setup_powerup()
