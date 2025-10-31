extends Node

signal coins_changed(amount)
signal score_changed(score)
signal wave_changed(wave)

# Данные кораблей
var ships_data = {
	0: {
		"name": "Phoenix",
		"speed": 150,
		"max_shield": 10,
		"cooldown": 0.25,
		"bullet_color": Color(0, 1, 1),
		"cost": 0,
		"unlocked": true
	},
	1: {
		"name": "Raptor",
		"speed": 180,
		"max_shield": 8,
		"cooldown": 0.2,
		"bullet_color": Color(1, 0, 0),
		"cost": 500,
		"unlocked": false
	},
	2: {
		"name": "Viper",
		"speed": 140,
		"max_shield": 12,
		"cooldown": 0.3,
		"bullet_color": Color(0, 1, 0),
		"cost": 1000,
		"unlocked": false
	},
	3: {
		"name": "Falcon",
		"speed": 200,
		"max_shield": 7,
		"cooldown": 0.15,
		"bullet_color": Color(1, 1, 0),
		"cost": 2000,
		"unlocked": false
	},
	4: {
		"name": "Dragon",
		"speed": 160,
		"max_shield": 15,
		"cooldown": 0.25,
		"bullet_color": Color(1, 0, 1),
		"cost": 5000,
		"unlocked": false
	}
}

# Данные врагов
var enemy_types = {
	"basic": {
		"health": 1,
		"speed": 75,
		"score": 5,
		"shoot_interval": [4, 20]
	},
	"fast": {
		"health": 1,
		"speed": 120,
		"score": 10,
		"shoot_interval": [3, 15]
	},
	"tank": {
		"health": 3,
		"speed": 50,
		"score": 15,
		"shoot_interval": [5, 25]
	},
	"shooter": {
		"health": 2,
		"speed": 80,
		"score": 12,
		"shoot_interval": [2, 10]
	}
}

# Данные боссов
var boss_types = {
	0: {
		"name": "Guardian",
		"health": 50,
		"speed": 30,
		"score": 100,
		"pattern": "basic",
		"animation": "boss1"
	},
	1: {
		"name": "Destroyer", 
		"health": 80,
		"speed": 40,
		"score": 200,
		"pattern": "spread",
		"animation": "boss2"
	},
	2: {
		"name": "Overlord",
		"health": 120,
		"speed": 35,
		"score": 300,
		"pattern": "circle",
		"animation": "boss3"
	}
}

# Данные павер-апов
var powerup_types = {
	"health": {
		"color": Color(0, 1, 0),
		"effect": "heal",
		"value": 3
	},
	"shield": {
		"color": Color(0, 0.5, 1),
		"effect": "shield",
		"value": 5
	},
	"rapid_fire": {
		"color": Color(1, 1, 0),
		"effect": "rapid_fire",
		"duration": 5.0
	},
	"double_shot": {
		"color": Color(1, 0, 1),
		"effect": "double_shot",
		"duration": 8.0
	},
	"coin": {
		"color": Color(1, 0.84, 0),
		"effect": "coin",
		"value": 10
	}
}

# Игровые переменные
var current_score = 0
var current_wave = 0
var total_coins = 0
var selected_ship = 0
var high_score = 0

# Настройки игры
var difficulty_multiplier = 1.0

func _ready():
	load_game_data()

func get_ship_data(ship_id: int) -> Dictionary:
	return ships_data.get(ship_id, ships_data[0])

func is_ship_unlocked(ship_id: int) -> bool:
	return ships_data[ship_id].unlocked

func unlock_ship(ship_id: int) -> bool:
	if ships_data[ship_id].unlocked:
		return false
	
	var cost = ships_data[ship_id].cost
	if total_coins >= cost:
		total_coins -= cost
		ships_data[ship_id].unlocked = true
		coins_changed.emit(total_coins)
		save_game_data()
		AudioManager.play_sfx("purchase")
		return true
	return false

func select_ship(ship_id: int):
	if is_ship_unlocked(ship_id):
		selected_ship = ship_id
		save_game_data()
		AudioManager.play_sfx("ship_select")

func add_score(points: int):
	current_score += points
	score_changed.emit(current_score)
	
	if current_score > high_score:
		high_score = current_score
		save_game_data()

func add_coins(amount: int):
	total_coins += amount
	coins_changed.emit(total_coins)
	save_game_data()

func start_new_game():
	current_score = 0
	current_wave = 0
	difficulty_multiplier = 1.0
	score_changed.emit(current_score)
	wave_changed.emit(current_wave)

func next_wave():
	current_wave += 1
	difficulty_multiplier = 1.0 + (current_wave * 0.05)  # Уменьшил прирост сложности
	wave_changed.emit(current_wave)
	print("Wave: ", current_wave, " Difficulty: ", difficulty_multiplier)

func is_boss_wave() -> bool:
	return current_wave > 0 and current_wave % 10 == 0

func get_boss_for_wave() -> Dictionary:
	var boss_index = min(int(current_wave / 10.0) - 1, boss_types.size() - 1)
	return boss_types[boss_index]

func get_enemy_count_for_wave() -> int:
	return min(27, 9 + (current_wave * 2))

func save_game_data():
	var save_data = {
		"ships": ships_data,
		"selected_ship": selected_ship,
		"total_coins": total_coins,
		"high_score": high_score
	}
	
	var file = FileAccess.open("user://save_game.dat", FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

func load_game_data():
	if not FileAccess.file_exists("user://save_game.dat"):
		return
	
	var file = FileAccess.open("user://save_game.dat", FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()
		
		if save_data.has("ships"):
			ships_data = save_data.ships
		if save_data.has("selected_ship"):
			selected_ship = save_data.selected_ship
		if save_data.has("total_coins"):
			total_coins = save_data.total_coins
		if save_data.has("high_score"):
			high_score = save_data.high_score
		
		coins_changed.emit(total_coins)

func reset_progress():
	for ship_id in ships_data:
		if ship_id == 0:
			ships_data[ship_id].unlocked = true
		else:
			ships_data[ship_id].unlocked = false
	
	selected_ship = 0
	total_coins = 0
	high_score = 0
	save_game_data()
	coins_changed.emit(total_coins)
