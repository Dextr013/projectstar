extends Node

# Музыкальные треки
var music_tracks = {
	"menu": "res://audio/music/menu_theme.mp3",
	"game": "res://audio/music/game_theme.mp3",
	"boss": "res://audio/music/boss_theme.mp3"
}

# Звуковые эффекты
var sound_effects = {
	"shoot": "res://audio/sfx/shoot.mp3",
	"enemy_shoot": "res://audio/sfx/enemy_shoot.mp3",
	"explosion": "res://audio/sfx/explosion.mp3",
	"hit": "res://audio/sfx/hit.wav",
	"powerup": "res://audio/sfx/powerup.mp3",
	"boss_appear": "res://audio/sfx/boss_appear.wav",
	"game_over": "res://audio/sfx/game_over.wav",
	"button_click": "res://audio/sfx/button_click.wav",
	"ship_select": "res://audio/sfx/ship_select.wav",
	"purchase": "res://audio/sfx/purchase.wav"
}

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_players = 16
var current_music = ""

var music_volume = 0.8
var sfx_volume = 0.7
var music_enabled = true
var sfx_enabled = true

func _ready():
	# Создаем музыкальный плеер
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	
	# Создаем пул звуковых плееров
	for i in max_sfx_players:
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)
	
	# Загружаем настройки
	load_settings()

func play_music(track_name: String, fade_duration: float = 1.0):
	if not music_enabled:
		return
		
	if current_music == track_name and music_player.playing:
		return
	
	if not music_tracks.has(track_name):
		push_error("Music track not found: " + track_name)
		return
	
	var new_stream = load(music_tracks[track_name])
	if new_stream == null:
		push_error("Failed to load music: " + music_tracks[track_name])
		return
	
	# Затухание текущей музыки
	if music_player.playing:
		var fade_out_tween = create_tween()
		fade_out_tween.tween_property(music_player, "volume_db", -80, fade_duration)
		await fade_out_tween.finished
	
	# Запуск новой музыки
	music_player.stream = new_stream
	music_player.volume_db = -80
	music_player.play()
	current_music = track_name
	
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), fade_duration)

func stop_music(fade_duration: float = 1.0):
	if music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80, fade_duration)
		await tween.finished
		music_player.stop()
		current_music = ""

func play_sfx(sfx_name: String, pitch_scale: float = 1.0):
	if not sfx_enabled:
		return
		
	if not sound_effects.has(sfx_name):
		push_error("Sound effect not found: " + sfx_name)
		return
	
	var stream = load(sound_effects[sfx_name])
	if stream == null:
		push_error("Failed to load sound: " + sound_effects[sfx_name])
		return
	
	# Находим свободный плеер
	var player: AudioStreamPlayer = null
	for p in sfx_players:
		if not p.playing:
			player = p
			break
	
	if player == null:
		player = sfx_players[0]  # Используем первый, если все заняты
	
	player.stream = stream
	player.volume_db = linear_to_db(sfx_volume)
	player.pitch_scale = pitch_scale
	player.play()

func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	music_player.volume_db = linear_to_db(music_volume)
	save_settings()

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	save_settings()

func toggle_music():
	music_enabled = not music_enabled
	if not music_enabled:
		music_player.volume_db = -80
	else:
		music_player.volume_db = linear_to_db(music_volume)
	save_settings()

func toggle_sfx():
	sfx_enabled = not sfx_enabled
	save_settings()

func save_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "music_enabled", music_enabled)
	config.set_value("audio", "sfx_enabled", sfx_enabled)
	config.save("user://audio_settings.cfg")

func load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://audio_settings.cfg")
	if err == OK:
		music_volume = config.get_value("audio", "music_volume", 0.8)
		sfx_volume = config.get_value("audio", "sfx_volume", 0.7)
		music_enabled = config.get_value("audio", "music_enabled", true)
		sfx_enabled = config.get_value("audio", "sfx_enabled", true)
