extends Node3D

@export var default_ship_type_id: int = 582

# Настройки анимации простоя
#@export var rotation_speed: float = 0.15      # Скорость вращения (рад/сек)
@export var hover_amplitude: float = 0.05     # Амплитуда парения
@export var hover_speed: float = 1.0          # Скорость парения

var current_instance: Node3D = null
var _time: float = 0.0

func _ready():
	load_ship(default_ship_type_id)

func load_ship(type_id: int) -> void:
	print("🔄 [ShipDisplay] Loading ship type_id: ", type_id)
	
	# 1. Очищаем старую модель
	if current_instance:
		current_instance.queue_free()
		current_instance = null
	
	# 2. Получаем сцену из реестра
	var ship_scene: PackedScene = GameSession.get_ship_scene(type_id)
	
	if ship_scene:
		# 3. Создаём и добавляем модель
		current_instance = ship_scene.instantiate()
		add_child(current_instance)
		
		# 🔧 ТЕСТ: Принудительно красим в ярко-зелёный, чтобы ГАРАНТИРОВАННО увидеть модель,
		# даже если экспорт из Wings3D потерял материалы.
		_apply_flat_shading_material(current_instance)
		
		print("✅ [ShipDisplay] Successfully loaded model for type_id: ", type_id)
	else:
		print("❌ [ShipDisplay] Failed to load model. Falling back to debug cube.")
		_create_debug_cube()

func _process(delta: float) -> void:
	if current_instance:
		_time += delta
		
		# Медленное вращение вокруг своей оси Y
		#current_instance.rotate_y(rotation_speed * delta)
		
		# Плавное парение вверх-вниз по синусоиде
		current_instance.position.y = sin(_time * hover_speed) * hover_amplitude

# Рекурсивно красит все части модели в ярко-зелёный для отладки
func _apply_flat_shading_material(node: Node) -> void:
	if node is MeshInstance3D:
		# 1. Создаём код шейдера для плоского затенения
		var shader_code = """
		shader_type spatial;
		render_mode diffuse_lambert, specular_schlick_ggx;
		
		// Параметры, которые мы можем менять из GDScript
		uniform vec4 albedo : source_color;
		uniform float metallic : hint_range(0, 1);
		uniform float roughness : hint_range(0, 1);

		void fragment() {
			ALBEDO = albedo.rgb;
			METALLIC = metallic;
			ROUGHNESS = roughness;
			NORMAL = -normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
		}
		"""
		
		# 2. Создаём и настраиваем шейдер
		var shader = Shader.new()
		shader.code = shader_code
		
		var mat = ShaderMaterial.new()
		mat.shader = shader
		
		# 3. Задаём красивые "космические" параметры материала
		mat.set_shader_parameter("albedo", Color(0.35, 0.45, 0.55)) # Серо-синий цвет корпуса
		mat.set_shader_parameter("metallic", 0.3)                   # Лёгкий металлический блеск
		mat.set_shader_parameter("roughness", 0.6)                  # Матовая поверхность (убирает "мыльные" блики)
		
		# 4. Применяем к модели
		node.material_override = mat
	
	# Рекурсивно применяем ко всем дочерним узлам (если модель состоит из нескольких частей)
	for child in node.get_children():
		_apply_flat_shading_material(child)
# Заглушка, если модель по каким-то причинам не найдена
func _create_debug_cube() -> void:
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = BoxMesh.new()
	mesh_inst.mesh.size = Vector3(1, 0.3, 2)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0, 0) # Красный = ошибка загрузки
	mesh_inst.material_override = mat
	add_child(mesh_inst)
	current_instance = mesh_inst
