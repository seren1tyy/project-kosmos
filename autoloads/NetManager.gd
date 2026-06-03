extends Node

signal connection_established
signal connection_failed(reason)
signal auth_success(user_id, has_character, session_token)
signal auth_failed(reason)
signal connection_lost(reason)
signal create_result(success: bool, message: String, char_id: int)
signal fetch_chars_result(success: bool, characters: Array, total: int, page: int)
signal enter_game_result(success: bool, char_id: int, char_name: String)
signal check_name_result(is_taken: bool)
signal inventory_result(success: bool, assets: Array)
signal location_result(success: bool, location_data: Dictionary)

var SERVER_IP: String
var SERVER_PORT: int
var SHARED_KEY: String

var stream
var session_token = ""

func _ready():
	_network_loop()

func _network_loop():
	SERVER_IP = ClientConfig.server_ip
	SERVER_PORT = ClientConfig.server_port
	SHARED_KEY = ClientConfig.crypto_key

	if SHARED_KEY.length() != 32:
		push_error("❌ Crypto key must be 32 chars! Got: %d" % SHARED_KEY.length())
		connection_failed.emit("invalid_config")
		return
	
	stream = StreamPeerTCP.new()
	var err = stream.connect_to_host(SERVER_IP, SERVER_PORT)
	if err != OK:
		connection_failed.emit("init_failed")
		return

	while stream.get_status() == StreamPeerTCP.STATUS_CONNECTING:
		stream.poll()
		await get_tree().process_frame

	if stream.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		connection_failed.emit("connection_refused")
		return

	connection_established.emit()

	# Handshake
	_send_packet({"type": "ping"})
	await _flush()
	if (await _receive_packet_timeout()).get("type") != "pong":
		connection_failed.emit("handshake_failed")
		return

	_send_packet({"type": "ready"})
	await _flush()
	if (await _receive_packet_timeout()).get("type") != "server_status":
		connection_failed.emit("handshake_failed")
		return

	# 🔁 ОСНОВНОЙ ЦИКЛ С ЖЁСТКОЙ ПРОВЕРКОЙ СТАТУСА
	while true:
		stream.poll()
		var status = stream.get_status()
		if status != StreamPeerTCP.STATUS_CONNECTED:
			connection_lost.emit("server_closed")
			_show_global_popup("⚠️ Connection Lost", "Server disconnected. Returning to login.", _go_to_login)
			return

		if stream.get_available_bytes() >= 4:
			var pkt = await _receive_packet()
			if pkt.is_empty():
				connection_lost.emit("read_error")
				_show_global_popup("⚠️ Connection Error", "Failed to read data.", _go_to_login)
				return

			match pkt.get("type"):
				"session_kicked":
					var msg = pkt.get("message")
					var reason = "Account logged in elsewhere." if msg == "account_logged_in_elsewhere" else "Session terminated."
					connection_lost.emit(reason)
					_show_global_popup("Session Ended", reason, _go_to_login)
					return
				"auth_result":
					if pkt.get("success", false):
						auth_success.emit(pkt.get("user_id", 0), pkt.get("has_character", false), pkt.get("session_token", ""))
					else:
						auth_failed.emit(pkt.get("message", "unknown"))
				"check_name_result":
					check_name_result.emit(pkt.get("is_taken", false))
				"create_result":  #
					print("🌐 NetManager: create_result received -> ", pkt)
					create_result.emit(pkt.get("success", false), pkt.get("message", ""), pkt.get("char_id", 0))
				"fetch_chars_result":
					fetch_chars_result.emit(pkt.get("success", false), pkt.get("characters", []), int(pkt.get("total", 0)), int(pkt.get("page", 0)))
				"enter_game_result":
					enter_game_result.emit(pkt.get("success", false), int(pkt.get("char_id", 0)), pkt.get("char_name", ""))
				"inventory_result":
					inventory_result.emit(pkt.get("success", false), pkt.get("assets", []))
				"location_result":
					location_result.emit(pkt.get("success", false), pkt.get("location", {}))
		await get_tree().process_frame
	

func send_auth(login, password):
	var payload = JSON.stringify({"login": login, "password": password})
	var encrypted = _encrypt(payload)
	var b64 = Marshalls.raw_to_base64(encrypted)
	_send_packet({"type": "auth", "data": b64})
	await _flush()

func _send_packet(data):
	if stream == null or stream.get_status() != StreamPeerTCP.STATUS_CONNECTED: return
	var json_str = JSON.stringify(data)
	var payload = json_str.to_utf8_buffer()
	var header = PackedByteArray()
	header.resize(4)
	header[0] = (payload.size() >> 24) & 0xFF
	header[1] = (payload.size() >> 16) & 0xFF
	header[2] = (payload.size() >> 8) & 0xFF
	header[3] = payload.size() & 0xFF
	stream.put_data(header)
	stream.put_data(payload)

func _flush():
	await get_tree().process_frame
	stream.poll()

func _receive_packet():
	while stream.get_available_bytes() < 4:
		stream.poll()
		if stream.get_status() != StreamPeerTCP.STATUS_CONNECTED: return {}
		await get_tree().process_frame

	var res = stream.get_data(4)
	if res[0] != OK: return {}
	var lb = res[1]
	var length = (lb[0] << 24) | (lb[1] << 16) | (lb[2] << 8) | lb[3]
	if length < 1 or length > 1048576: return {}

	while stream.get_available_bytes() < length:
		stream.poll()
		if stream.get_status() != StreamPeerTCP.STATUS_CONNECTED: return {}
		await get_tree().process_frame

	var raw = stream.get_data(length)[1]
	var parsed = JSON.parse_string(raw.get_string_from_utf8())
	return parsed if parsed is Dictionary else {}

func _receive_packet_timeout():
	for _i in range(100):
		stream.poll()
		if stream.get_available_bytes() >= 4: return await _receive_packet()
		await get_tree().process_frame
	return {}

func _encrypt(plain):
	var key = SHARED_KEY.to_utf8_buffer()
	var data = plain.to_utf8_buffer()
	var out = PackedByteArray()
	out.resize(data.size())
	for i in range(data.size()):
		out[i] = data[i] ^ key[i % key.size()]
	return out

# 🌍 ГЛОБАЛЬНЫЙ ПОПАП (работает независимо от текущей сцены)
func _show_global_popup(title, text, on_confirm):
	var root = Engine.get_main_loop().root
	if not root: return

	var dialog = AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = text
	dialog.size = Vector2(350, 120)
	dialog.confirmed.connect(on_confirm)
	root.add_child(dialog)
	dialog.popup_centered()

func _go_to_login():
	get_tree().change_scene_to_file("res://scenes/login/Login.tscn")

func send_create_character(char_name: String, race: String, bloodline: String):
	print("📤 [NetManager] DISPATCHING create_character for: ", char_name)
	print("🔑 [NetManager] Session token present: ", session_token != "")
	var payload = JSON.stringify({
		"name": char_name, "race": race, "bloodline": bloodline
	})
	var b64 = Marshalls.raw_to_base64(_encrypt(payload))
	_send_packet({
		"type": "create_character",
		"data": b64,
		"token": session_token # Обязательно для серверной валидации
	})
	await _flush()
	
var chars_page: int = 0
var chars_per_page: int = 8

func send_fetch_characters(page: int = 0) -> void:
	chars_page = page
	print("📤 [Net] fetch_characters -> page=%d, per_page=%d" % [page, chars_per_page])
	var payload = JSON.stringify({"page": page, "per_page": chars_per_page})
	var b64 = Marshalls.raw_to_base64(_encrypt(payload))
	_send_packet({"type": "fetch_characters", "data": b64, "token": session_token})
	await _flush()

func send_enter_game(char_id: int) -> void:
	print("📡 NetManager: Sending enter_game for char_id: ", char_id)
	var payload = JSON.stringify({"char_id": char_id})
	var b64 = Marshalls.raw_to_base64(_encrypt(payload))
	_send_packet({"type": "enter_game", "data": b64, "token": session_token})
	await _flush()

func send_check_name(char_name: String) -> void:
	var payload = JSON.stringify({"name": char_name})
	var b64 = Marshalls.raw_to_base64(_encrypt(payload))
	_send_packet({"type": "check_name", "data": b64})
	await _flush()

func send_get_inventory(char_id: int) -> void:
	print("📤 [Net] Requesting inventory for char: ", char_id)
	_send_packet({"type": "get_inventory", "char_id": char_id, "token": session_token})
	await _flush()

func send_get_location(char_id: int) -> void:
	print("📤 [Net] Requesting location for char: ", char_id)
	_send_packet({"type": "get_location", "char_id": char_id, "token": session_token})
	await _flush()
