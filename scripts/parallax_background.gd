extends ParallaxBackground

@export var scroll_speed = 50
@export var layer_speeds = [0.2, 0.5, 1.0]  # Множители скорости для каждого слоя

func _ready():
	# Настраиваем каждый слой
	for i in range(get_child_count()):
		var layer = get_child(i)
		if layer is ParallaxLayer:
			layer.motion_scale.y = layer_speeds[min(i, layer_speeds.size() - 1)]

func _process(delta):
	scroll_offset.y += scroll_speed * delta
