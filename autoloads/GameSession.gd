extends Node

# --- Данные персонажа ---
var character_id: int = 0
var character_name: String = ""
var in_game: bool = false

# --- Данные локации ---
var current_station_name: String = ""
var current_system_name: String = ""
var current_region_name: String = ""

# --- Данные корабля ---
var ship_type_id: int = 582  # 🔑 ПО ЯВЛЕНИЮ: ID стартового корабля (Wisp)

# 🔑 РЕЕСТР МОДЕЛЕЙ: Связывает type_id из БД с .glb файлом
const SHIP_MODELS = {
	582: preload("res://assets/ships/wisp.glb")
	# В будущем добавишь сюда другие корабли, например:
	# 583: preload("res://assets/ships/other_ship.glb")
}

func set_character(char_id: int, char_name: String) -> void:
	character_id = char_id
	character_name = char_name
	in_game = true
	print("🎮 GameSession: Loaded character '%s' (ID: %d)" % [char_name, character_id])

func get_ship_scene(type_id: int) -> PackedScene:
	var scene = SHIP_MODELS.get(type_id, null)
	if scene == null:
		push_warning("⚠️ No 3D model found for ship type_id: %d" % type_id)
	return scene

func logout() -> void:
	character_id = 0
	character_name = ""
	in_game = false
	current_station_name = ""
	current_system_name = ""
	current_region_name = ""
	ship_type_id = 582  # Сбрасываем к дефолтному при выходе
