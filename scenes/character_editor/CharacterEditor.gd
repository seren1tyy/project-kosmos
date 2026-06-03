extends Control

var name_input: LineEdit
var race_select: OptionButton
var bloodline_select: OptionButton
var create_btn: Button
var back_btn: Button
var status_lbl: Label

var is_checking: bool = false

func _ready():
	print("🎨 CharacterEditor: _ready() started")
	
	name_input = _safe_find("NameInput") as LineEdit
	race_select = _safe_find("RaceSelect") as OptionButton
	bloodline_select = _safe_find("BloodlineSelect") as OptionButton
	create_btn = _safe_find("CreateBtn") as Button
	back_btn = _safe_find("BackBtn") as Button
	status_lbl = _safe_find("Label") as Label

	var missing := []
	if not name_input: missing.append("NameInput")
	if not race_select: missing.append("RaceSelect")
	if not bloodline_select: missing.append("BloodlineSelect")
	if not create_btn: missing.append("CreateBtn")
	if not back_btn: missing.append("BackBtn")
	if not status_lbl: missing.append("Label")

	if missing.size() > 0:
		var err_text = "❌ MISSING: " + ", ".join(missing)
		print(err_text)
		var temp = Label.new()
		temp.text = err_text
		temp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		temp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(temp)
		return

	print("✅ All UI nodes found.")
	race_select.clear(); bloodline_select.clear()
	race_select.add_item("Deer"); race_select.add_item("Fox")
	race_select.add_item("Cat"); race_select.add_item("Tanuki")
	bloodline_select.add_item("Placeholder"); bloodline_select.add_item("Placeholder 2")

	create_btn.pressed.connect(_on_create_pressed)
	#back_btn.pressed.connect(_on_back_pressed)

	NetManager.create_result.connect(_on_create_result)
	NetManager.check_name_result.connect(_on_check_name_result)
	status_lbl.text = "Ready to create pilot."

# ✅ FIX: переименовали name -> target_name, чтобы не тенить Node.name
func _safe_find(target_name: String) -> Node:
	var queue: Array = [self]
	while not queue.is_empty():
		var node: Node = queue.pop_front()
		if node.name == target_name: return node
		for child in node.get_children():
			queue.append(child)
	return null

func _on_create_pressed():
	if is_checking: return
	
	var char_name: String = name_input.text.strip_edges()
	if char_name.length() < 3 or char_name.length() > 30:
		status_lbl.text = "⚠️ Name must be 3-30 chars."
		return

	is_checking = true
	create_btn.disabled = true
	status_lbl.text = "🔍 Checking name..."
	NetManager.send_check_name(char_name)

func _on_check_name_result(is_taken: bool):
	is_checking = false
	create_btn.disabled = false
	
	if is_taken:
		status_lbl.text = "❌ Name already taken."
		return
	
	var race: String = race_select.get_item_text(race_select.selected)
	var bloodline: String = bloodline_select.get_item_text(bloodline_select.selected)
	var final_name: String = name_input.text.strip_edges()
	
	create_btn.disabled = true
	status_lbl.text = "🔄 Creating character..."
	NetManager.send_create_character(final_name, race, bloodline)
	
	get_tree().create_timer(5.0).timeout.connect(_on_create_timeout, Object.CONNECT_ONE_SHOT)

func _on_create_timeout():
	if is_checking:
		is_checking = false
		create_btn.disabled = false
		status_lbl.text = "⏱️ Server response timeout. Try again."
		print("⚠️ [Editor] Create operation timed out.")

# ✅ FIX: _char_id вместо char_id (подавляем UNUSED_PARAMETER)
func _on_create_result(success: bool, message: String, _char_id: int):
	print("📥 [Editor] create_result -> success: %s, msg: %s" % [success, message])
	status_lbl.text = message
	create_btn.disabled = false
	is_checking = false
	
	if success:
		status_lbl.text = "✅ Created! Redirecting..."
		var tree = get_tree()
		if tree:
			tree.call_deferred("change_scene_to_file", "res://scenes/character_select/CharacterSelect.tscn")
