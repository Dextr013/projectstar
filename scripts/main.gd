extends Node2D

var enemy_scene = preload("res://enemy.tscn")
var boss_scene: PackedScene

var playing = false
var current_boss = null
var spawning_wave = false

@onready var player = $Player
@onready var ui = $CanvasLayer/UI
@onready var camera = $Camera2D
@onready var enemy_anchor = $EnemyAnchor
@onready var pause_menu = $CanvasLayer/PauseMenu if has_node("CanvasLayer/PauseMenu") else null
@onready var game_over_screen = $CanvasLayer/GameOverScreen if has_node("CanvasLayer/GameOverScreen") else null
@onready var start_button = $CanvasLayer/CenterContainer/Start if has_node("CanvasLayer/CenterContainer/Start") else null
@onready var game_over_label = $CanvasLayer/CenterContainer/GameOver if has_node("CanvasLayer/CenterContainer/GameOver") else null

func _ready():
	# Пытаемся загрузить boss сцену
	if ResourceLoader.exists("res://scenes/boss.tscn"):
		boss_scene = load("res://scenes/boss.tscn")
	
	# Скрываем UI элементы
	if pause_menu:
		pause_menu.hide()
	if game_over_screen:
		game_over_screen.hide()
	if game_over_label:
		game_over_label.hide()
	if start_button:
		start_button.show()
		if not start_button.pressed.is_connected(_on_start_pressed):
			start_button.pressed.connect(_on_start_pressed)
	
	# Запускаем игровую музыку
	AudioManager.play_music("game")
	
	# Настраиваем анимацию anchor
	setup_anchor_animation()
	
	# Подключаем сигналы
	if not player.died.is_connected(_on_player_died):
		player.died.connect(_on_player_died)
	if not player.shield_changed.is_connected(ui.update_shield):
		player.shield_changed.connect(ui.update_shield)
	if not GameManager.score_changed.is_connected(ui.update_score):
		GameManager.score_changed.connect(ui.update_score)
	if not GameManager.wave_changed.is_connected(ui.update_wave):
		GameManager.wave_changed.connect(ui.update_wave)
	
	if not start_button:
		new_game()

func setup_anchor_animation():
	var tween = create_tween().set_loops().set_parallel(false).set_trans(Tween.TRANS_SINE)
	tween.tween_property(enemy_anchor, "position:x", enemy_anchor.position.x + 3, 1.0)
	tween.tween_property(enemy_anchor, "position:x", enemy_anchor.position.x - 3, 1.0)
	
	var tween2 = create_tween().set_loops().set_parallel(false).set_trans(Tween.TRANS_BACK)
	tween2.tween_property(enemy_anchor, "position:y", enemy_anchor.position.y + 3, 1.5).set_ease(Tween.EASE_IN_OUT)
	tween2.tween_property(enemy_anchor, "position:y", enemy_anchor.position.y - 3, 1.5).set_ease(Tween.EASE_IN_OUT)

func new_game():
	print("=== НОВАЯ ИГРА ===")
	GameManager.start_new_game()
	player.start()
	playing = true
	spawning_wave = false
	spawn_wave()

func spawn_wave():
	if spawning_wave:
		print("Уже спавним волну, пропускаем")
		return
	
	print("Начинаем спавн волны ", GameManager.current_wave)
	spawning_wave = true
	
	# Сначала увеличиваем волну
	GameManager.next_wave()
	print("Волна увеличена до: ", GameManager.current_wave)
	
	# Затем спавним врагов или босса
	if GameManager.is_boss_wave() and boss_scene:
		print("Спавним босса для волны ", GameManager.current_wave)
		spawn_boss()
	else:
		print("Спавним обычных врагов для волны ", GameManager.current_wave)
		spawn_enemies()
	
	# ВАЖНОЕ ИСПРАВЛЕНИЕ: Сбрасываем флаг после завершения спавна
	spawning_wave = false
	print("Спавн волны завершен, spawning_wave = ", spawning_wave)

func spawn_enemies():
	var enemy_count = GameManager.get_enemy_count_for_wave()
	var rows = min(3, int(enemy_count / 9.0) + 1)
	var cols = min(9, enemy_count)
	
	print("Спавн врагов: count=", enemy_count, " rows=", rows, " cols=", cols)
	
	if not enemy_scene:
		push_error("Enemy scene not loaded!")
		return
	
	var enemy_types = ["basic", "fast", "tank", "shooter"]
	var type_weights = [50, 25, 15, 10]
	
	var spawned_count = 0
	for x in range(cols):
		for y in range(rows):
			if spawned_count >= enemy_count:
				break
				
			var e = enemy_scene.instantiate()
			var pos = Vector2(x * (16 + 8) + 24, 16 * 4 + y * 16)
			add_child(e)
			
			# Выбираем случайный тип врага
			var enemy_type = get_weighted_random(enemy_types, type_weights)
			e.start(pos, enemy_type)
			e.anchor = enemy_anchor
			e.died.connect(_on_enemy_died)
			spawned_count += 1
	
	print("Создано врагов: ", spawned_count)

func spawn_boss():
	if not boss_scene:
		push_warning("Boss scene not found, skipping boss wave")
		spawning_wave = false
		return
	
	var boss = boss_scene.instantiate()
	add_child(boss)
	boss.start(GameManager.current_wave)
	boss.died.connect(_on_boss_died)
	boss.health_changed.connect(ui.update_boss_health)
	current_boss = boss
	
	ui.show_boss_health_bar()
	AudioManager.play_sfx("boss_appear")
	print("Босс создан")

func get_weighted_random(items: Array, weights: Array):
	var total = 0
	for w in weights:
		total += w
	
	var random_value = randf() * total
	var cumulative = 0
	
	for i in range(items.size()):
		cumulative += weights[i]
		if random_value <= cumulative:
			return items[i]
	
	return items[0]

func _process(_delta):
	if not playing:
		return
	
	# Проверяем завершение волны
	var enemies = get_tree().get_nodes_in_group("enemies")
	var bosses = get_tree().get_nodes_in_group("boss")
	
	# Отладочная информация
	if Engine.get_frames_drawn() % 60 == 0: # Каждую секунду
		print("Отладка: enemies=", enemies.size(), " bosses=", bosses.size(), " spawning_wave=", spawning_wave, " playing=", playing)
	
	# Спавним новую волну только если нет врагов И не спавним уже
	if enemies.size() == 0 and bosses.size() == 0 and not spawning_wave and playing:
		print("Условия для новой волны выполнены! Запускаем спавн через 2 секунды")
		spawning_wave = true
		await get_tree().create_timer(2.0).timeout
		if playing:  # Проверяем еще раз после задержки
			print("Таймер завершен, запускаем spawn_wave()")
			spawn_wave()
		else:
			print("Игра остановлена, пропускаем спавн")
			spawning_wave = false

func toggle_pause():
	get_tree().paused = not get_tree().paused
	if get_tree().paused:
		if pause_menu:
			pause_menu.show()
	else:
		if pause_menu:
			pause_menu.hide()

func _on_enemy_died(score):
	print("Враг убит, очки: ", score)
	GameManager.add_score(score)
	camera.add_trauma(0.3)
	
	# Шанс выпадения монет
	if randf() < 0.1:
		GameManager.add_coins(1)

func _on_boss_died(score):
	print("Босс убит, очки: ", score)
	GameManager.add_score(score)
	GameManager.add_coins(50)
	camera.add_trauma(1.0)
	if ui:
		ui.hide_boss_health_bar()
	current_boss = null

func _on_player_died():
	print("Игрок умер, игра окончена")
	playing = false
	spawning_wave = false
	get_tree().call_group("enemies", "queue_free")
	get_tree().call_group("boss", "queue_free")
	
	if game_over_screen:
		var coins_earned = int(GameManager.current_score / 10.0)
		GameManager.add_coins(coins_earned)
		game_over_screen.show_game_over(GameManager.current_score, coins_earned)
	elif game_over_label:
		game_over_label.show()
		await get_tree().create_timer(2).timeout
		game_over_label.hide()
		if start_button:
			start_button.show()

func _on_start_pressed():
	if start_button:
		start_button.hide()
	if game_over_label:
		game_over_label.hide()
	new_game()

func return_to_menu():
	AudioManager.stop_music()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
