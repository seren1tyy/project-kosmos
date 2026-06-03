extends Control

@onready var ship_name_lbl = $TopBar/ShipName
@onready var char_name_lbl = $TopBar/CharName
@onready var location_lbl = $TopBar/LocationLbl  # <-- Новый узел
@onready var status_lbl = $StatusLbl
@onready var undock_btn = $BottomBar/UndockBtn
@onready var logout_btn = $BottomBar/LogOutBtn

func _ready():
	undock_btn.pressed.connect(_on_undock_pressed)
	logout_btn.pressed.connect(_on_logout_pressed)
	
	# Подписка на получение локации
	NetManager.location_result.connect(_on_location_result)
	
	# Запрашиваем локацию при загрузке HUD
	if GameSession.character_id > 0:
		NetManager.send_get_location(GameSession.character_id)

func update_character(char_name: String) -> void:
	char_name_lbl.text = char_name
	ship_name_lbl.text = "Ship: Wisp"

func _on_location_result(success: bool, loc: Dictionary):
	if success:
		var station = loc.get("station", "Unknown Station")
		var system = loc.get("system", "Unknown System")
		var region = loc.get("region", "Unknown Region")
		
		location_lbl.text = "%s, %s [%s]" % [station, system, region]
		
		# Сохраняем в GameSession для будущего использования
		GameSession.current_station_name = station
		GameSession.current_system_name = system
		GameSession.current_region_name = region
		
		status_lbl.text = "Docked. Systems nominal."
	else:
		location_lbl.text = "Location data unavailable"
		status_lbl.text = "Docked. (Location error)"

func _on_undock_pressed():
	# Пока просто заглушка, так как инфраструктура андока ещё не готова
	status_lbl.text = "Undock sequence initiated... (WIP)"
	# В будущем здесь будет NetManager.send_undock()

func _on_logout_pressed():
	GameSession.logout()
	get_tree().change_scene_to_file("res://scenes/login/Login.tscn")
