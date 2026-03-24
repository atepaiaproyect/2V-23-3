# ==================================================
# ARCHIVO: scripts/firebase/firebase_auth.gd
# AUTOLOAD: FirebaseAuth
# QUÉ HACE: Maneja login, registro y recuperación
#           de contraseña contra Firebase Auth y Firestore
# ==================================================

extends Node

const AUTH_URL = "https://identitytoolkit.googleapis.com/v1/accounts:"
var BASE_URL: String
var current_user: Dictionary = {}
var auth_token: String = ""

signal login_success(user_data)
signal login_failed(error_message)
signal register_success(user_data)
signal register_failed(error_message)

func _ready() -> void:
	BASE_URL = "https://firestore.googleapis.com/v1/projects/atepaia-2v/databases/(default)/documents"

# ==================================================
# LOGIN POR USERNAME
# Busca el email en Firestore y luego hace login
# ==================================================
func login_by_username(username: String, password: String) -> void:
	var url = BASE_URL + "/usernames/" + username.to_lower()
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_username_lookup.bind(http, password))
	http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_GET)

func _on_username_lookup(result, response_code, headers, body, http: HTTPRequest, password: String) -> void:
	http.queue_free()
	if response_code == 200:
		var json = JSON.new()
		json.parse(body.get_string_from_utf8())
		var data = json.get_data()
		var email = data.get("fields", {}).get("email", {}).get("stringValue", "")
		if email != "":
			_do_login(email, password)
		else:
			emit_signal("login_failed", "Usuario no encontrado.")
	else:
		emit_signal("login_failed", "Usuario no encontrado.")

func _do_login(email: String, password: String) -> void:
	var url = AUTH_URL + "signInWithPassword?key=" + GameData.FIREBASE_API_KEY
	var body = JSON.stringify({
		"email": email,
		"password": password,
		"returnSecureToken": true
	})
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_login_completed.bind(http))
	http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)

func _on_login_completed(result, response_code, headers, body, http: HTTPRequest) -> void:
	http.queue_free()
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var data = json.get_data()
	if response_code == 200:
		current_user = data
		auth_token = data.get("idToken", "")
		GameData.player_email = data.get("email", "")
		GameData.is_logged_in = true
		emit_signal("login_success", data)
	else:
		var error = data.get("error", {}).get("message", "Error desconocido")
		emit_signal("login_failed", error)

# ==================================================
# REGISTRO
# Verifica username único → crea auth → guarda en Firestore
# ==================================================
func register(username: String, email: String, password: String) -> void:
	var url = BASE_URL + "/usernames/" + username.to_lower()
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_username_check.bind(http, username, email, password))
	http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_GET)

func _on_username_check(result, response_code, headers, body, http: HTTPRequest, username: String, email: String, password: String) -> void:
	http.queue_free()
	if response_code == 200:
		emit_signal("register_failed", "El nombre de usuario ya está en uso.")
		return
	var auth_url = AUTH_URL + "signUp?key=" + GameData.FIREBASE_API_KEY
	var body_str = JSON.stringify({
		"email": email,
		"password": password,
		"returnSecureToken": true
	})
	var http2 = HTTPRequest.new()
	add_child(http2)
	http2.request_completed.connect(_on_auth_created.bind(http2, username, email))
	http2.request(auth_url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body_str)

func _on_auth_created(result, response_code, headers, body, http: HTTPRequest, username: String, email: String) -> void:
	http.queue_free()
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var data = json.get_data()
	if response_code == 200:
		current_user = data
		auth_token = data.get("idToken", "")
		_save_username(username, email)
	else:
		var error = data.get("error", {}).get("message", "Error desconocido")
		emit_signal("register_failed", error)

func _save_username(username: String, email: String) -> void:
	var url = "https://firestore.googleapis.com/v1/projects/atepaia-2v/databases/(default)/documents/usernames?documentId=" + username.to_lower() + "&key=" + GameData.FIREBASE_API_KEY
	var body = JSON.stringify({
		"fields": {
			"email":    { "stringValue": email },
			"username": { "stringValue": username }
		}
	})
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_username_saved.bind(http))
	http.request(url, ["Content-Type: application/json", "Authorization: Bearer " + auth_token], HTTPClient.METHOD_POST, body)
	
func _on_username_saved(result, response_code, headers, body, http: HTTPRequest) -> void:
	http.queue_free()
	print("USERNAME SAVED - code: ", response_code)
	print("USERNAME SAVED - body: ", body.get_string_from_utf8())
	emit_signal("register_success", current_user)

# ==================================================
# RECUPERAR CONTRASEÑA
# Manda mail de reset — siempre mismo mensaje
# ==================================================
func send_password_reset(email: String) -> void:
	var url = AUTH_URL + "sendOobCode?key=" + GameData.FIREBASE_API_KEY
	var body = JSON.stringify({
		"requestType": "PASSWORD_RESET",
		"email": email
	})
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_reset_sent.bind(http))
	http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)

func _on_reset_sent(result, _response_code, _headers, _body, http: HTTPRequest) -> void:
	http.queue_free()
	# No hacemos nada acá — la pantalla maneja el mensaje
