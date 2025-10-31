extends Control

@onready var final_score_label = $Panel/VBoxContainer/FinalScoreLabel
@onready var coins_earned_label = $Panel/VBoxContainer/CoinsEarnedLabel
@onready var high_score_label = $Panel/VBoxContainer/HighScoreLabel
@onready var retry_button = $Panel/VBoxContainer/RetryButton
@onready var menu_button = $Panel/VBoxContainer/MenuButton

func _ready():
	hide()

func show_game_over(score: int, coins: int):
	final_score_label.text = "SCORE: %d" % score
	coins_earned_label.text = "COINS EARNED: %d" % coins
	
	if score > GameManager.high_score:
		high_score_label.text = "NEW HIGH SCORE!"
		high_score_label.modulate = Color(1, 1, 0)
	else:
		high_score_label.text = "HIGH SCORE: %d" % GameManager.high_score
		high_score_label.modulate = Color(1, 1, 1)
	
	show()
	
	# Анимация появления
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _on_retry_button_pressed():
	AudioManager.play_sfx("button_click")
	get_parent().get_parent().new_game()
	hide()

func _on_menu_button_pressed():
	AudioManager.play_sfx("button_click")
	get_parent().get_parent().return_to_menu()
