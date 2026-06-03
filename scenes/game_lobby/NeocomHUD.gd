extends Control

# НЕОКОМ
@onready var inv_btn = $VBoxContainer/InvBtn
@onready var wallet_btn = $VBoxContainer/WalletBtn
@onready var map_btn = $VBoxContainer/MapBtn
@onready var char_btn = $VBoxContainer/CharBtn
@onready var settings_btn = $VBoxContainer/SettingsBtn

# Окно инвентаря
@onready var inv_window = $InventoryWindow
@onready var inv_header = $InventoryWindow/VBoxContainer/Header
@onready var inv_list = $InventoryWindow/VBoxContainer/Body/ItemList
@onready var inv_footer = $InventoryWindow/VBoxContainer/Footer
@onready var inv_close_btn = $InventoryWindow/VBoxContainer/Header/CloseBtn

# Resize handles
@onready var edge_n = $InventoryWindow/ResizeHandles/EdgeN
@onready var edge_s = $InventoryWindow/ResizeHandles/EdgeS
@onready var edge_w = $InventoryWindow/ResizeHandles/EdgeW
@onready var edge_e = $InventoryWindow/ResizeHandles/EdgeE
@onready var corner_nw = $InventoryWindow/ResizeHandles/CornerNW
@onready var corner_ne = $InventoryWindow/ResizeHandles/CornerNE
@onready var corner_sw = $InventoryWindow/ResizeHandles/CornerSW
@onready var corner_se = $InventoryWindow/ResizeHandles/CornerSE

const MIN_SIZE := Vector2(480, 380)
const ICON_SIZE := Vector2(48, 48)

var _inventory_cache: Array = []

# Drag-window
var _win_dragging: bool = false
var _win_drag_offset: Vector2

# Resize
var _resizing: bool = false
var _resize_dir: Vector2
var _resize_origin: Vector2
var _resize_start_size: Vector2
var _resize_start_mouse: Vector2

func _ready():
	# Кнопки НЕОКОМ
	inv_btn.pressed.connect(_toggle_inventory)
	wallet_btn.pressed.connect(func(): _stub("Wallet", "ISK balance coming soon."))
	map_btn.pressed.connect(func(): _stub("Star Map", "Navigation coming soon."))
	char_btn.pressed.connect(func(): _stub("Character", "Pilot profile coming soon."))
	settings_btn.pressed.connect(func(): _stub("Settings", "Options coming soon."))
	
	# Окно инвентаря
	inv_close_btn.pressed.connect(_close_inventory)
	inv_header.gui_input.connect(_on_header_gui_input)
	
	# Resize handles
	_connect_handle(edge_n,    Vector2( 0, -1))
	_connect_handle(edge_s,    Vector2( 0,  1))
	_connect_handle(edge_w,    Vector2(-1,  0))
	_connect_handle(edge_e,    Vector2( 1,  0))
	_connect_handle(corner_nw, Vector2(-1, -1))
	_connect_handle(corner_ne, Vector2( 1, -1))
	_connect_handle(corner_sw, Vector2(-1,  1))
	_connect_handle(corner_se, Vector2( 1,  1))
	
	# Настройки ItemList
	inv_list.icon_mode = ItemList.ICON_MODE_TOP
	inv_list.fixed_icon_size = ICON_SIZE
	inv_list.max_columns = 3                              # было 4
	inv_list.same_column_width = true
	inv_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # ✅ новое
	inv_list.size_flags_stretch_ratio = 2.0   
	
	inv_window.hide()
	if NetManager.has_signal("inventory_result"):
		NetManager.inventory_result.connect(_on_inventory_result)
	_load_inventory()

func _connect_handle(node: Control, dir: Vector2):
	if node == null: return
	node.gui_input.connect(func(ev): _on_resize_gui_input(ev, dir))
	node.mouse_entered.connect(func(): _set_resize_cursor(dir))
	node.mouse_exited.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_ARROW))

func _set_resize_cursor(dir: Vector2):
	if abs(dir.x) == 1 and abs(dir.y) == 1:
		Input.set_default_cursor_shape(Input.CURSOR_FDIAGSIZE)
	elif abs(dir.y) == 1:
		Input.set_default_cursor_shape(Input.CURSOR_VSIZE)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_HSIZE)

# --- Drag: перемещение окна ---
func _on_header_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_win_dragging = true
			_win_drag_offset = event.global_position - inv_window.global_position
			accept_event()
		else:
			_win_dragging = false
	elif event is InputEventMouseMotion and _win_dragging:
		inv_window.global_position = event.global_position - _win_drag_offset
		accept_event()

# --- Drag: изменение размера ---
func _on_resize_gui_input(event: InputEvent, dir: Vector2):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_resizing = true
			_resize_dir = dir
			_resize_origin = inv_window.global_position
			_resize_start_size = inv_window.size
			_resize_start_mouse = event.global_position
			accept_event()
		else:
			_resizing = false
	
	elif event is InputEventMouseMotion and _resizing:
		var delta: Vector2 = event.global_position - _resize_start_mouse
		var new_size: Vector2 = _resize_start_size
		var new_pos: Vector2 = _resize_origin
		
		if _resize_dir.x == 1:
			new_size.x = max(_resize_start_size.x + delta.x, MIN_SIZE.x)
		elif _resize_dir.x == -1:
			var w: float = max(_resize_start_size.x - delta.x, MIN_SIZE.x)
			new_size.x = w
			new_pos.x = _resize_origin.x + (_resize_start_size.x - w)
		
		if _resize_dir.y == 1:
			new_size.y = max(_resize_start_size.y + delta.y, MIN_SIZE.y)
		elif _resize_dir.y == -1:
			var h: float = max(_resize_start_size.y - delta.y, MIN_SIZE.y)
			new_size.y = h
			new_pos.y = _resize_origin.y + (_resize_start_size.y - h)
		
		inv_window.size = new_size
		inv_window.global_position = new_pos
		accept_event()

# --- Инвентарь ---
func _load_inventory():
	if GameSession.character_id == 0:
		return
	NetManager.send_get_inventory(GameSession.character_id)

func _on_inventory_result(success: bool, assets: Array):
	if not success:
		inv_footer.text = "Failed to load"
		return
	
	_inventory_cache = assets
	inv_list.clear()
	
	if assets.is_empty():
		inv_footer.text = "0 items"
		return
	
	for asset in assets:
		var item_name: String = str(asset.get("name", "?"))
		var qty: int = int(asset.get("quantity", 1))
		var location: String = str(asset.get("location", ""))
		var type_id: int = int(asset.get("type_id", 0))
		
		var label: String = item_name
		if qty > 1: label += "\n(x%d)" % qty
		if location != "": label += "\n[%s]" % location
		
		var icon: Texture2D = _make_icon(type_id, item_name)
		inv_list.add_item(label, icon, true)
	
	inv_footer.text = "%d item(s)" % assets.size()

func _make_icon(type_id: int, item_name: String) -> Texture2D:
	var color: Color
	if type_id <= 15:
		color = Color(0.3, 0.3, 0.5)
	else:
		var hash: int = 0
		for ch in item_name:
			hash = (hash * 31 + ch.unicode_at(0)) % 1000
		var hue: float = float(hash) / 1000.0
		color = Color.from_hsv(hue, 0.6, 0.8)
	
	var img := Image.create(int(ICON_SIZE.x), int(ICON_SIZE.y), false, Image.FORMAT_RGBA8)
	img.fill(color)
	for x in range(int(ICON_SIZE.x)):
		img.set_pixel(x, 0, Color.BLACK)
		img.set_pixel(x, int(ICON_SIZE.y) - 1, Color.BLACK)
	for y in range(int(ICON_SIZE.y)):
		img.set_pixel(0, y, Color.BLACK)
		img.set_pixel(int(ICON_SIZE.x) - 1, y, Color.BLACK)
	return ImageTexture.create_from_image(img)

func _toggle_inventory():
	if inv_window.visible:
		_close_inventory()
	else:
		inv_window.show()
		await get_tree().process_frame
		_load_inventory()

func _close_inventory():
	inv_window.hide()

func _stub(title: String, message: String):
	var d = AcceptDialog.new()
	d.title = title
	d.dialog_text = message
	d.size = Vector2(320, 100)
	get_tree().root.add_child(d)
	d.popup_centered()
	d.confirmed.connect(d.queue_free)
