extends Node

# Имя файла
const CONFIG_FILE := "client_config.json"

# Значения по умолчанию
var server_ip: String = "127.0.0.1"
var server_port: int = 12345
var crypto_key: String = "12345678901234567890123456789012"

# Реальный путь к файлу (заполнится в _ready)
var _config_path: String = ""

func _ready():
	_config_path = _resolve_config_path()
	print("⚙️ [Config] Using path: ", _config_path)
	_load()

# 🎯 Определяем путь: рядом с .exe (экспорт) или в res:// (редактор)
func _resolve_config_path() -> String:
	if OS.has_feature("editor"):
		# В редакторе кладём конфиг прямо в проект
		return "res://" + CONFIG_FILE
	else:
		# В экспорте — рядом с исполняемым файлом
		var exe_dir = OS.get_executable_path().get_base_dir()
		return exe_dir.path_join(CONFIG_FILE)

func _load():
	if not FileAccess.file_exists(_config_path):
		print("⚙️ [Config] File not found, creating defaults...")
		_save()
		return

	var file = FileAccess.open(_config_path, FileAccess.READ)
	if not file:
		push_warning("⚙️ [Config] Cannot open file, using defaults")
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_text) != OK:
		push_warning("⚙️ [Config] Parse error, using defaults")
		return

	var data = json.data
	if data is Dictionary:
		server_ip = str(data.get("server_ip", server_ip))
		server_port = int(data.get("server_port", server_port))
		crypto_key = str(data.get("crypto_key", crypto_key))
		print("⚙️ [Config] Loaded -> ip=%s, port=%d, key_len=%d" % [
			server_ip, server_port, crypto_key.length()
		])
	else:
		push_warning("⚙️ [Config] Invalid format, using defaults")

func _save():
	var data = {
		"server_ip": server_ip,
		"server_port": server_port,
		"crypto_key": crypto_key
	}
	var file = FileAccess.open(_config_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("⚙️ [Config] Saved to %s" % _config_path)
	else:
		push_warning("⚙️ [Config] Cannot write to %s" % _config_path)
