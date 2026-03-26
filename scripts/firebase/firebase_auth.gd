# ==================================================
# ARCHIVO: scripts/firebase/firebase_auth.gd
# AUTOLOAD: FirebaseAuth
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
signal delete_success
signal delete_failed(error_message)

func _ready() -> void:
    BASE_URL = "https://firestore.googleapis.com/v1/projects/atepaia-2v/databases/(default)/documents"

# ==================================================
# NORMALIZAR EMAIL — saca los puntos antes del @
# ==================================================
func _normalizar_email(email: String) -> String:
    var partes = email.split("@")
    if partes.size() != 2:
        return email
    var local = partes[0].replace(".", "")
    return local + "@" + partes[1]

# ==================================================
# LOGIN POR USERNAME
# ==================================================
func login_by_username(username: String, password: String) -> void:
    var url = BASE_URL + "/usernames/" + username.to_lower()
    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(_on_username_lookup.bind(http, password))
    http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_GET)

func _on_username_lookup(_result, response_code, _headers, body, http: HTTPRequest, password: String) -> void:
    http.queue_free()
    if response_code == 200:
        var json = JSON.new()
        json.parse(body.get_string_from_utf8())
        var data = json.get_data()
        var email = data.get("fields", {}).get("email", {}).get("stringValue", "")
        var username = data.get("fields", {}).get("username", {}).get("stringValue", "")
        if email != "":
            GameData.player_name = username.to_lower()
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

func _on_login_completed(_result, response_code, _headers, body, http: HTTPRequest) -> void:
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
# ==================================================
func register(username: String, email: String, password: String) -> void:
    var email_norm = _normalizar_email(email)
    var url = BASE_URL + "/usernames/" + username.to_lower()
    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(_on_username_check.bind(http, username, email_norm, password))
    http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_GET)

func _on_username_check(_result, response_code, _headers, _body, http: HTTPRequest, username: String, email: String, password: String) -> void:
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

func _on_auth_created(_result, response_code, _headers, body, http: HTTPRequest, username: String, email: String) -> void:
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
    var url = "https://firestore.googleapis.com/v1/projects/atepaia-2v/databases/(default)/documents/usernames/?documentId=" + username.to_lower() + "&key=" + GameData.FIREBASE_API_KEY
    var body = JSON.stringify({
        "fields": {
            "email":    { "stringValue": _normalizar_email(email) },
            "username": { "stringValue": username }
        }
    })
    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(_on_username_saved.bind(http))
    http.request(url, ["Content-Type: application/json", "Authorization: Bearer " + auth_token], HTTPClient.METHOD_POST, body)

func _on_username_saved(_result, _response_code, _headers, _body, http: HTTPRequest) -> void:
    http.queue_free()
    emit_signal("register_success", current_user)

# ==================================================
# RECUPERAR CONTRASEÑA
# ==================================================
func send_password_reset(email: String) -> void:
    var url = AUTH_URL + "sendOobCode?key=" + GameData.FIREBASE_API_KEY
    var body = JSON.stringify({
        "requestType": "PASSWORD_RESET",
        "email": _normalizar_email(email)
    })
    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(_on_reset_sent.bind(http))
    http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)

func _on_reset_sent(_result, _response_code, _headers, _body, http: HTTPRequest) -> void:
    http.queue_free()

# ==================================================
# ELIMINAR CUENTA
# ==================================================
func delete_account() -> void:
    if auth_token == "":
        emit_signal("delete_failed", "No hay sesión activa.")
        return
    var url = AUTH_URL + "delete?key=" + GameData.FIREBASE_API_KEY
    var body = JSON.stringify({ "idToken": auth_token })
    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(_on_account_deleted.bind(http))
    http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)

func _on_account_deleted(_result, response_code, _headers, body, http: HTTPRequest) -> void:
    http.queue_free()
    if response_code == 200:
        var username = GameData.player_name
        var url = "https://firestore.googleapis.com/v1/projects/atepaia-2v/databases/(default)/documents/usernames/" + username + "?key=" + GameData.FIREBASE_API_KEY
        var http2 = HTTPRequest.new()
        add_child(http2)
        http2.request_completed.connect(_on_username_deleted.bind(http2))
        http2.request(url, ["Content-Type: application/json", "Authorization: Bearer " + auth_token], HTTPClient.METHOD_DELETE)
    else:
        var json = JSON.new()
        json.parse(body.get_string_from_utf8())
        var data = json.get_data()
        var error = data.get("error", {}).get("message", "Error al eliminar.")
        emit_signal("delete_failed", error)

func _on_username_deleted(_result, _response_code, _headers, _body, http: HTTPRequest) -> void:
    http.queue_free()
    current_user = {}
    auth_token = ""
    GameData.is_logged_in = false
    GameData.player_email = ""
    GameData.player_name = ""
    emit_signal("delete_success")
