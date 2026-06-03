extends Node3D

@export var target: Node3D
@export var min_distance: float = 2.0
@export var max_distance: float = 15.0
@export var min_pitch: float = -60.0
@export var max_pitch: float = 30.0
@export var rotate_sensitivity: float = 0.3
@export var zoom_sensitivity: float = 0.5

@export var idle_threshold: float = 120.0   # секунд неактивности до автовращения
@export var auto_rotate_speed: float = 5.0  # градусов в секунду
@export var inertia_damping: float = 3.0    # чем больше, тем быстрее торможение

var _yaw: float = 0.0
var _pitch: float = -10.0
var _distance: float = 6.0

# Инерция
var _velocity_yaw: float = 0.0
var _velocity_pitch: float = 0.0

# Состояние
var _is_dragging: bool = false
var _idle_time: float = 0.0

func _ready():
	if target:
		global_position = target.global_position
	_apply_camera()

func _unhandled_input(event):
	# 🔘 ЛКМ — вращение
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_is_dragging = event.pressed
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _is_dragging else Input.MOUSE_MODE_VISIBLE
			if _is_dragging:
				# Нажали — сбрасываем инерцию и таймер простоя
				_velocity_yaw = 0.0
				_velocity_pitch = 0.0
				_idle_time = 0.0

		# Колёсико — зум
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_distance = clamp(_distance - zoom_sensitivity, min_distance, max_distance)
			_idle_time = 0.0
			_apply_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_distance = clamp(_distance + zoom_sensitivity, min_distance, max_distance)
			_idle_time = 0.0
			_apply_camera()

	# Движение мыши с зажатой ЛКМ
	if event is InputEventMouseMotion and _is_dragging:
		var dx = -event.relative.x * rotate_sensitivity
		var dy = -event.relative.y * rotate_sensitivity
		_yaw += dx
		_pitch = clamp(_pitch + dy, min_pitch, max_pitch)

		# Сохраняем velocity для инерции
		_velocity_yaw = dx
		_velocity_pitch = dy
		_idle_time = 0.0
		_apply_camera()

func _process(delta):
	# Плавно следуем за целью
	if target:
		global_position = global_position.lerp(target.global_position, 10.0 * delta)

	if not _is_dragging:
		# 1. Инерция — если есть остаточная скорость
		if abs(_velocity_yaw) > 0.001 or abs(_velocity_pitch) > 0.001:
			_yaw += _velocity_yaw
			_pitch = clamp(_pitch + _velocity_pitch, min_pitch, max_pitch)

			# Затухание (экспоненциальное)
			var damp = max(0.0, 1.0 - inertia_damping * delta)
			_velocity_yaw *= damp
			_velocity_pitch *= damp
			_apply_camera()

			# Пока инерция работает — таймер простоя не тикает
		else:
			# 2. Инерции нет — обнуляем и считаем простой
			_velocity_yaw = 0.0
			_velocity_pitch = 0.0
			_idle_time += delta

			# 3. Автовращение при простое
			if _idle_time > idle_threshold:
				_yaw += auto_rotate_speed * delta
				_apply_camera()

func _apply_camera():
	rotation_degrees = Vector3(_pitch, _yaw, 0)
	var cam = get_node_or_null("Camera3D")
	if cam:
		cam.position.z = _distance
