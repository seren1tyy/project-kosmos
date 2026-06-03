extends Control

@onready var login_line = $VBoxContainer/LoginLine
@onready var pass_line = $VBoxContainer/PasswordLine
@onready var btn = $VBoxContainer/ConnectBtn
@onready var status = $VBoxContainer/StatusLabel

func _ready():
	btn.pressed.connect(_on_connect_pressed)
	NetManager.connection_established.connect(func(): 
		status.text = "Ready. Enter credentials."
		btn.disabled = false
	)
	NetManager.auth_success.connect(_on_auth_success)
	NetManager.auth_failed.connect(func(reason): 
		status.text = "❌ " + str(reason)
		btn.disabled = false
	)
	status.text = "Connecting..."

func _on_connect_pressed():
	var l = login_line.text.strip_edges()
	var p = pass_line.text
	if l.is_empty() or p.is_empty():
		status.text = "Fields cannot be empty"
		return
	
	btn.disabled = true
	status.text = "Authenticating..."
	NetManager.send_auth(l, p)

func _on_auth_success(uid, has_char, token):
	NetManager.session_token = token
	status.text = "✅ Connected (UID: %d)" % uid
	if has_char:
		get_tree().change_scene_to_file("res://scenes/character_select/CharacterSelect.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/character_editor/CharacterEditor.tscn")
