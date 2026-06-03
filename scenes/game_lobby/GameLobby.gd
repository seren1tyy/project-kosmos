extends Node3D

@onready var ship_model = $ShipModel
@onready var hud = $HUDLayer/HUD

func _ready():
	print("🌌 GameLobby: _ready()")
	
	if GameSession.character_id == 0:
		push_error("❌ No character selected!")
		get_tree().change_scene_to_file("res://scenes/login/Login.tscn")
		return
	
	print("🚢 Entered lobby as: %s (ID: %d)" % [GameSession.character_name, GameSession.character_id])
	hud.update_character(GameSession.character_name)
