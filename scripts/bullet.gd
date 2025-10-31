extends Area2D

@export var speed = -250
@onready var sprite = $Sprite2D

func start(pos):
	position = pos

func set_color(color: Color):
	sprite.modulate = color
	
func _process(delta):
	position.y += speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_area_entered(area):
	if area.is_in_group("enemies"):
		area.hit(1)
		queue_free()
	elif area.is_in_group("boss"):
		area.hit(1)
		queue_free()
