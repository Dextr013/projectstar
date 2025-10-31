extends Node

# Базовое разрешение игры (пиксель-арт)
const BASE_WIDTH = 240
const BASE_HEIGHT = 320
const BASE_ASPECT = float(BASE_WIDTH) / float(BASE_HEIGHT)

# Текущий масштаб
var current_scale = 1.0
var current_offset = Vector2.ZERO

# Референсы для безопасных зон
var safe_area_margins = {
	"top": 0,
	"bottom": 0,
	"left": 0,
	"right": 0
}

func _ready():
	# Подключаем сигнал изменения размера окна
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	
	# Начальная настройка
	_on_viewport_size_changed()
	
	# Для веб-версии (Poki.com)
	if OS.has_feature("web"):
		setup_web_canvas()
	
	print("Screen Manager initialized")
	print("Base resolution: ", BASE_WIDTH, "x", BASE_HEIGHT)

func _on_viewport_size_changed():
	var window_size = get_viewport().get_visible_rect().size
	var window_aspect = window_size.x / window_size.y
	
	print("Window size changed: ", window_size, " Aspect: ", window_aspect)
	
	# Рассчитываем масштаб
	var scale_x = window_size.x / BASE_WIDTH
	var scale_y = window_size.y / BASE_HEIGHT
	
	# Для пиксель-арта используем целочисленный масштаб
	if scale_x > 1.0 and scale_y > 1.0:
		current_scale = min(floor(scale_x), floor(scale_y))
	else:
		current_scale = 1.0
	
	# Рассчитываем итоговый размер
	var scaled_width = BASE_WIDTH * current_scale
	var scaled_height = BASE_HEIGHT * current_scale
	
	# Рассчитываем отступы для центрирования
	current_offset.x = (window_size.x - scaled_width) / 2
	current_offset.y = (window_size.y - scaled_height) / 2
	
	# Устанавливаем размер viewport
	get_viewport().size = Vector2(BASE_WIDTH, BASE_HEIGHT)
	
	# Обновляем безопасные зоны
	update_safe_areas()
	
	# Испускаем сигналы
	screen_resized.emit(window_size, current_scale)
	safe_area_changed.emit(safe_area_margins)
	
	print("Scale: ", current_scale, " Offset: ", current_offset)
	print("Scaled size: ", scaled_width, "x", scaled_height)

func update_safe_areas():
	var _screen_size = get_viewport().get_visible_rect().size  # Префикс _ для неиспользуемой переменной
	
	# Для мобильных устройств учитываем вырез и контролы
	if is_mobile():
		safe_area_margins.top = get_safe_area_margin_top()
		safe_area_margins.bottom = get_safe_area_margin_bottom()
		safe_area_margins.left = get_safe_area_margin_left()
		safe_area_margins.right = get_safe_area_margin_right()
	else:
		# Для десктопа оставляем небольшие отступы
		safe_area_margins.top = 20 * current_scale
		safe_area_margins.bottom = 20 * current_scale
		safe_area_margins.left = 20 * current_scale
		safe_area_margins.right = 20 * current_scale

func get_safe_area_margin_top() -> float:
	# Реализация для получения безопасной зоны сверху
	if OS.has_feature("mobile"):
		return 50.0 * current_scale  # Пример для статус бара
	return 20.0 * current_scale

func get_safe_area_margin_bottom() -> float:
	# Реализация для получения безопасной зоны снизу
	if OS.has_feature("mobile"):
		return 80.0 * current_scale  # Пример для навигационной панели
	return 20.0 * current_scale

func get_safe_area_margin_left() -> float:
	# Реализация для получения безопасной зоны слева
	if OS.has_feature("mobile"):
		return 20.0 * current_scale
	return 20.0 * current_scale

func get_safe_area_margin_right() -> float:
	# Реализация для получения безопасной зоны справа
	if OS.has_feature("mobile"):
		return 20.0 * current_scale
	return 20.0 * current_scale

func setup_web_canvas():
	# Настройка для веб-платформ (Poki.com)
	print("Setting up Web Canvas for Poki.com")
	
	# Устанавливаем режим окна
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# Отключаем контекстное меню правой кнопки мыши
	JavaScriptBridge.eval("""
		document.addEventListener('contextmenu', function(e) {
			e.preventDefault();
		});
		
		// Предотвращаем масштабирование на мобильных устройствах
		document.addEventListener('touchmove', function(e) {
			if (e.scale !== 1) {
				e.preventDefault();
			}
		}, { passive: false });
		
		// Оптимизация для Poki
		if (typeof PokiSDK !== 'undefined') {
			PokiSDK.setDebug(true);
		}
	""", true)

# Публичные методы для доступа из других скриптов

func get_scale() -> float:
	return current_scale

func get_base_size() -> Vector2:
	return Vector2(BASE_WIDTH, BASE_HEIGHT)

func get_scaled_size() -> Vector2:
	return Vector2(BASE_WIDTH * current_scale, BASE_HEIGHT * current_scale)

func get_offset() -> Vector2:
	return current_offset

func get_safe_area() -> Dictionary:
	return safe_area_margins.duplicate()

func get_safe_rect() -> Rect2:
	var screen_size = get_viewport().get_visible_rect().size
	return Rect2(
		safe_area_margins.left,
		safe_area_margins.top,
		screen_size.x - safe_area_margins.left - safe_area_margins.right,
		screen_size.y - safe_area_margins.top - safe_area_margins.bottom
	)

# Конвертация позиций между разными системами координат

func screen_to_world(screen_pos: Vector2) -> Vector2:
	return (screen_pos - current_offset) / current_scale

func world_to_screen(world_pos: Vector2) -> Vector2:
	return world_pos * current_scale + current_offset

func get_adjusted_position(base_pos: Vector2) -> Vector2:
	return base_pos * current_scale + current_offset

func get_adjusted_size(base_size: Vector2) -> Vector2:
	return base_size * current_scale

# Утилиты для определения платформы

func is_mobile() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")

func is_desktop() -> bool:
	return OS.has_feature("windows") or OS.has_feature("osx") or OS.has_feature("linux")

func is_web() -> bool:
	return OS.has_feature("web")

func is_touch_device() -> bool:
	return DisplayServer.is_touchscreen_available() or is_mobile()

# Управление полноэкранным режимом

func toggle_fullscreen():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func set_fullscreen(enabled: bool):
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# Получение информации о дисплее

func get_screen_info() -> Dictionary:
	var screen_size = get_viewport().get_visible_rect().size
	var dpi = DisplayServer.screen_get_dpi()
	var scale_factor = DisplayServer.screen_get_scale()
	
	return {
		"width": screen_size.x,
		"height": screen_size.y,
		"aspect_ratio": screen_size.x / screen_size.y,
		"dpi": dpi,
		"scale_factor": scale_factor,
		"game_scale": current_scale,
		"is_mobile": is_mobile(),
		"is_touch": is_touch_device(),
		"is_web": is_web()
	}

# Сигналы для уведомления других систем

signal screen_resized(new_size: Vector2, new_scale: float)
signal safe_area_changed(margins: Dictionary)
signal orientation_changed(is_landscape: bool)

var _last_orientation = false

func _process(_delta):
	# Проверяем изменение ориентации
	var is_landscape = get_viewport().get_visible_rect().size.x > get_viewport().get_visible_rect().size.y
	if is_landscape != _last_orientation:
		_last_orientation = is_landscape
		orientation_changed.emit(is_landscape)
		print("Orientation changed: ", "Landscape" if is_landscape else "Portrait")

# Методы для UI элементов

func setup_ui_for_safe_area(control_node: Control):
	if not control_node:
		return
	
	var safe_rect = get_safe_rect()
	var screen_size = get_viewport().get_visible_rect().size
	
	# Настраиваем анкоры для адаптивности
	control_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Устанавливаем отступы от безопасных зон
	control_node.set_anchor(SIDE_LEFT, safe_rect.position.x / screen_size.x)
	control_node.set_anchor(SIDE_TOP, safe_rect.position.y / screen_size.y)
	control_node.set_anchor(SIDE_RIGHT, (safe_rect.position.x + safe_rect.size.x) / screen_size.x)
	control_node.set_anchor(SIDE_BOTTOM, (safe_rect.position.y + safe_rect.size.y) / screen_size.y)
	
	control_node.set_offsets_preset(Control.PRESET_FULL_RECT)

func create_scaled_font(base_size: int) -> Font:
	# Создание шрифта с учетом масштаба
	var font = FontFile.new()
	font.size = base_size * current_scale
	return font

# Дебаг информация

func _input(event):
	# Показ информации о экране при нажатии F1
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		var info = get_screen_info()
		print("=== SCREEN INFO ===")
		for key in info:
			print(key, ": ", info[key])
		print("=================")

# Очистка ресурсов

func _exit_tree():
	# Отключаем сигналы при выходе
	if get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.disconnect(_on_viewport_size_changed)
