extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var ships_button = $VBoxContainer/ShipsButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var high_score_label = $HighScoreLabel
@onready var coins_label = $CoinsLabel
@onready var title_label = $TitleLabel


func _ready():
	# Запускаем музыку меню
	AudioManager.play_music("menu")
	
	# Обновляем UI
	update_ui()
	
	# Подключаем сигналы
	GameManager.coins_changed.connect(_on_coins_changed)
	
	# Анимация заголовка
	animate_title()
	
	# Анимация кнопок
	animate_buttons()
	
	# Скрываем кнопку выхода на веб-платформах
	if OS.has_feature("web"):
		quit_button.hide()

func update_ui():
	high_score_label.text = "HIGH SCORE: %d" % GameManager.high_score
	coins_label.text = "COINS: %d" % GameManager.total_coins

func animate_title():
	var tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tween.tween_property(title_label, "position:y", title_label.position.y - 5, 1.5)
	tween.tween_property(title_label, "position:y", title_label.position.y + 5, 1.5)

func animate_buttons():
	var delay = 0.0
	for button in $VBoxContainer.get_children():
		if button is Button:
			button.modulate.a = 0
			var tween = create_tween()
			tween.tween_property(button, "modulate:a", 1.0, 0.3).set_delay(delay)
			delay += 0.1

func _on_start_button_pressed():
	AudioManager.play_sfx("button_click")
	transition_to_scene("res://scenes/game.tscn")

func _on_ships_button_pressed():
	AudioManager.play_sfx("button_click")
	transition_to_scene("res://scenes/ship_selection.tscn")

func _on_settings_button_pressed():
	AudioManager.play_sfx("button_click")
	# TODO: Открыть меню настроек
	pass

func _on_quit_button_pressed():
	AudioManager.play_sfx("button_click")
	get_tree().quit()

func _on_coins_changed(amount):
	coins_label.text = "COINS: %d" % amount

func transition_to_scene(scene_path: String):
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	get_tree().change_scene_to_file(scene_path)
