extends Control

@onready var ship_container = $ShipContainer
@onready var ship_name_label = $InfoPanel/ShipName
@onready var stats_label = $InfoPanel/StatsLabel
@onready var select_button = $InfoPanel/SelectButton
@onready var unlock_button = $InfoPanel/UnlockButton
@onready var back_button = $BackButton
@onready var coins_label = $CoinsLabel
@onready var preview_sprite = $InfoPanel/PreviewSprite

var current_ship_index = 0
var ship_buttons = []

func _ready():
	AudioManager.play_music("menu")
	update_coins_label()
	GameManager.coins_changed.connect(_on_coins_changed)
	create_ship_buttons()
	show_ship_info(GameManager.selected_ship)

func create_ship_buttons():
	for i in range(5):
		var button = Button.new()
		button.custom_minimum_size = Vector2(48, 48)
		button.text = str(i + 1)
		button.pressed.connect(_on_ship_button_pressed.bind(i))
		ship_container.add_child(button)
		ship_buttons.append(button)
		
		# Визуальное отображение состояния
		update_ship_button(i)

func update_ship_button(ship_id: int):
	var button = ship_buttons[ship_id]
	var ship_data = GameManager.get_ship_data(ship_id)
	
	if ship_data.unlocked:
		button.disabled = false
		if ship_id == GameManager.selected_ship:
			button.modulate = Color(0, 1, 0)  # Зеленый - выбран
		else:
			button.modulate = Color(1, 1, 1)  # Белый - доступен
	else:
		button.disabled = false
		button.modulate = Color(0.5, 0.5, 0.5)  # Серый - заблокирован

func show_ship_info(ship_id: int):
	current_ship_index = ship_id
	var ship_data = GameManager.get_ship_data(ship_id)
	
	ship_name_label.text = ship_data.name
	
	# Статистика корабля
	var stats_text = ""
	stats_text += "Speed: %d\n" % ship_data.speed
	stats_text += "Shield: %d\n" % ship_data.max_shield
	stats_text += "Fire Rate: %.2f/s\n" % (1.0 / ship_data.cooldown)
	
	if not ship_data.unlocked:
		stats_text += "\nCost: %d coins" % ship_data.cost
	
	stats_label.text = stats_text
	
	# Управление кнопками
	if ship_data.unlocked:
		select_button.show()
		unlock_button.hide()
		select_button.disabled = (ship_id == GameManager.selected_ship)
		if ship_id == GameManager.selected_ship:
			select_button.text = "SELECTED"
		else:
			select_button.text = "SELECT"
	else:
		select_button.hide()
		unlock_button.show()
		unlock_button.disabled = (GameManager.total_coins < ship_data.cost)
		unlock_button.text = "UNLOCK (%d)" % ship_data.cost
	
	# Цвет превью (можно заменить на спрайт корабля)
	preview_sprite.modulate = ship_data.bullet_color

func _on_ship_button_pressed(ship_id: int):
	AudioManager.play_sfx("button_click")
	show_ship_info(ship_id)

func _on_select_button_pressed():
	GameManager.select_ship(current_ship_index)
	update_all_ship_buttons()
	show_ship_info(current_ship_index)

func _on_unlock_button_pressed():
	if GameManager.unlock_ship(current_ship_index):
		update_all_ship_buttons()
		show_ship_info(current_ship_index)
		
		# Анимация разблокировки
		var tween = create_tween()
		tween.tween_property(preview_sprite, "scale", Vector2(1.5, 1.5), 0.2)
		tween.tween_property(preview_sprite, "scale", Vector2(1, 1), 0.2)

func update_all_ship_buttons():
	for i in range(5):
		update_ship_button(i)

func _on_back_button_pressed():
	AudioManager.play_sfx("button_click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_coins_changed(_amount):
	update_coins_label()
	# Обновляем кнопку разблокировки
	show_ship_info(current_ship_index)

func update_coins_label():
	coins_label.text = "COINS: %d" % GameManager.total_coins
