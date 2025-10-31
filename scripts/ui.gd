extends MarginContainer

@onready var shield_bar = $HBoxContainer/ShieldBar if has_node("HBoxContainer/ShieldBar") else null
@onready var score_counter = $HBoxContainer/ScoreCounter if has_node("HBoxContainer/ScoreCounter") else null
@onready var wave_label = $HBoxContainer/WaveLabel if has_node("HBoxContainer/WaveLabel") else null
@onready var boss_health_container = $BossHealthContainer if has_node("BossHealthContainer") else null
@onready var boss_health_bar = $BossHealthContainer/BossHealthBar if boss_health_container and boss_health_container.has_node("BossHealthBar") else null
@onready var boss_name_label = $BossHealthContainer/BossNameLabel if boss_health_container and boss_health_container.has_node("BossNameLabel") else null

func _ready():
	if boss_health_container:
		boss_health_container.hide()

func update_score(value):
	if score_counter and score_counter.has_method("display_digits"):
		score_counter.display_digits(value)

func update_shield(max_value, value):
	if not shield_bar:
		return
		
	shield_bar.max_value = max_value
	shield_bar.value = value
	
	# Цветовая индикация здоровья - работает для TextureProgressBar
	var health_percent = float(value) / float(max_value)
	
	# Используем "in" для проверки наличия свойства
	if "tint_progress" in shield_bar:
		if health_percent > 0.6:
			shield_bar.tint_progress = Color(0, 1, 0)
		elif health_percent > 0.3:
			shield_bar.tint_progress = Color(1, 1, 0)
		else:
			shield_bar.tint_progress = Color(1, 0, 0)

func update_wave(wave):
	if wave_label:
		wave_label.text = "WAVE %d" % wave
	else:
		print("Wave: ", wave)

func show_boss_health_bar():
	if boss_health_container:
		boss_health_container.show()
		if boss_name_label:
			var boss_data = GameManager.get_boss_for_wave()
			boss_name_label.text = "%s - WAVE %d" % [boss_data.name, GameManager.current_wave]

func hide_boss_health_bar():
	if boss_health_container:
		boss_health_container.hide()

func update_boss_health(max_value, value):
	if boss_health_bar:
		boss_health_bar.max_value = max_value
		boss_health_bar.value = value
		
		# Цветовая индикация здоровья босса
		var health_percent = float(value) / float(max_value)
		if "tint_progress" in boss_health_bar:
			if health_percent > 0.6:
				boss_health_bar.tint_progress = Color(1, 0.2, 0.2)  # Красный
			elif health_percent > 0.3:
				boss_health_bar.tint_progress = Color(1, 0.5, 0.2)  # Оранжевый
			else:
				boss_health_bar.tint_progress = Color(1, 0.8, 0.2)  # Желтый
