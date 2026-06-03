extends Control

@onready var char_list = $MarginContainer/HBoxContainer/RightPanel/CharList
@onready var prev_btn = $MarginContainer/HBoxContainer/RightPanel/Pager/PrevBtn
@onready var next_btn = $MarginContainer/HBoxContainer/RightPanel/Pager/NextBtn
@onready var page_lbl = $MarginContainer/HBoxContainer/RightPanel/Pager/PageLabel
@onready var create_btn = $MarginContainer/HBoxContainer/RightPanel/Pager/CreateBtn
@onready var enter_btn = $MarginContainer/HBoxContainer/LeftPanel/EnterBtn
@onready var logout_btn = $MarginContainer/HBoxContainer/LeftPanel/LogoutBtn

@onready var sel_name_lbl = $MarginContainer/HBoxContainer/LeftPanel/CharInfo/VBoxContainer/SelectedName
@onready var sel_race_lbl = $MarginContainer/HBoxContainer/LeftPanel/CharInfo/VBoxContainer/SelectedRace
@onready var sel_blood_lbl = $MarginContainer/HBoxContainer/LeftPanel/CharInfo/VBoxContainer/SelectedBloodline

var selected_char_id: int = 0
var total_chars: int = 0
var current_page: int = 0
var chars_per_page: int = 8
var cached_chars: Array = []

func _ready():
	print("🎯 CharacterSelect: _ready()")
	
	prev_btn.pressed.connect(_on_prev_page)
	next_btn.pressed.connect(_on_next_page)
	create_btn.pressed.connect(_on_create_pressed)
	enter_btn.pressed.connect(_on_enter_pressed)
	logout_btn.pressed.connect(_on_logout_pressed)
	
	NetManager.fetch_chars_result.connect(_on_fetch_result)
	NetManager.enter_game_result.connect(_on_enter_result)
	
	current_page = 0
	_load_page()

func _load_page():
	NetManager.send_fetch_characters(current_page)

func _on_fetch_result(success: bool, characters: Array, total: int, page: int):
	print("[UI] Fetched: success=%s, chars=%d, total=%d, page=%d" % [success, characters.size(), total, page])
	if not success:
		print("❌ Failed to fetch characters")
		return
	
	cached_chars = characters
	total_chars = total
	current_page = page
	
	# Очищаем список
	for child in char_list.get_children():
		child.queue_free()
	
	# Добавляем строки для каждого персонажа
	for c in characters:
		var row = _create_char_row(c)
		char_list.add_child(row)
	
	# Если список пуст — показываем подсказку
	if characters.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No pilots yet. Create one to begin."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_color_override("font_color", Color.GRAY)
		char_list.add_child(empty_lbl)
	
	# Обновляем пагинацию
	var total_pages = max(1, (total + chars_per_page - 1) / chars_per_page)
	page_lbl.text = "Page %d / %d" % [current_page + 1, total_pages]
	prev_btn.disabled = (current_page == 0)
	next_btn.disabled = (current_page >= total_pages - 1)
	
	# Авто-выбор первого, если ничего не выбрано
	if selected_char_id == 0 and not characters.is_empty():
		_select_char(int(characters[0].get("id", 0)))

func _create_char_row(c: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 50)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.text = "%s\n  [%s]" % [c.get("name", "Unknown"), c.get("race", "Unknown")]
	btn.set_meta("char_id", int(c.get("id", 0)))
	btn.pressed.connect(func(): _select_char(int(c.get("id", 0))))
	return btn

func _select_char(char_id: int):
	selected_char_id = char_id
	enter_btn.disabled = false
	
	# Обновляем подсветку
	for row in char_list.get_children():
		if row is Button and row.has_meta("char_id"):
			var is_selected = row.get_meta("char_id") == char_id
			if is_selected:
				row.add_theme_color_override("font_color", Color.GREEN_YELLOW)
			else:
				row.remove_theme_color_override("font_color")
	
	# Заполняем инфо-панель
	var char_data = _find_char(char_id)
	if char_data.size() > 0:
		sel_name_lbl.text = char_data.get("name", "")
		sel_race_lbl.text = "Race: %s" % char_data.get("race", "Unknown")
		sel_blood_lbl.text = "Bloodline: %s" % char_data.get("bloodline", "Unknown")

func _find_char(char_id: int) -> Dictionary:
	for c in cached_chars:
		if int(c.get("id", 0)) == char_id:
			return c
	return {}

func _on_prev_page():
	print("Prev page pressed. current=%d" % current_page)
	if current_page > 0:
		current_page -= 1
		selected_char_id = 0
		enter_btn.disabled = true
		# Сброс инфо-панели
		sel_name_lbl.text = "No pilot selected"
		sel_race_lbl.text = ""
		sel_blood_lbl.text = ""
		_load_page()

func _on_next_page():
	print("Next page pressed. current=%d, total=%d" % [current_page, total_chars])
	var total_pages = max(1, (total_chars + chars_per_page - 1) / chars_per_page)
	if current_page < total_pages - 1:
		current_page += 1
		selected_char_id = 0
		enter_btn.disabled = true
		sel_name_lbl.text = "No pilot selected"
		sel_race_lbl.text = ""
		sel_blood_lbl.text = ""
		_load_page()

func _on_create_pressed():
	get_tree().change_scene_to_file("res://scenes/character_editor/CharacterEditor.tscn")

func _on_enter_pressed():
	if selected_char_id == 0: return
	enter_btn.disabled = true
	enter_btn.text = "Connecting..."
	NetManager.send_enter_game(selected_char_id)

func _on_enter_result(success: bool, char_id: int, char_name: String):
	enter_btn.text = "Enter Game"
	enter_btn.disabled = false
	if success:
		GameSession.set_character(char_id, char_name)
		GameSession.ship_type_id = 582 
		
		get_tree().change_scene_to_file("res://scenes/game_lobby/GameLobby.tscn")
	else:
		print("Enter game failed")

func _on_logout_pressed():
	GameSession.logout()
	NetManager.session_token = ""
	get_tree().change_scene_to_file("res://scenes/login/Login.tscn")
