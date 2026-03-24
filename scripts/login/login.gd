# ==================================================
# ARCHIVO: scripts/login/login.gd
# REEMPLAZA el login.gd actual completo
# ==================================================

extends Control

const SAVE_PATH = "user://remember.cfg"

# Panel login
@onready var username_input  = $Panel/VBoxLogin/UsernameInput
@onready var password_input  = $Panel/VBoxLogin/HBoxPass/PasswordInput
@onready var eye_button      = $Panel/VBoxLogin/HBoxPass/EyeButton
@onready var remember_check  = $Panel/VBoxLogin/HBoxOpciones/RememberCheck
@onready var server_option   = $Panel/VBoxLogin/HBoxOpciones/ServerOption
@onready var login_button    = $Panel/VBoxLogin/HBoxBotones/LoginButton
@onready var register_button = $Panel/VBoxLogin/HBoxBotones/RegisterButton
@onready var recover_button  = $Panel/VBoxLogin/RecoverButton
@onready var delete_button   = $Panel/VBoxLogin/DeleteButton
@onready var status_login    = $Panel/VBoxLogin/StatusLabel

# Panel registro
@onready var vbox_registro   = $Panel/VBoxRegistro
@onready var reg_user_input  = $Panel/VBoxRegistro/RegUsernameInput
@onready var reg_email_input = $Panel/VBoxRegistro/RegEmailInput
@onready var reg_pass_input  = $Panel/VBoxRegistro/HBoxRegPass/RegPasswordInput
@onready var reg_eye_button  = $Panel/VBoxRegistro/HBoxRegPass/RegEyeButton
@onready var reg_confirm_btn = $Panel/VBoxRegistro/HBoxRegBotones/ConfirmRegBtn
@onready var reg_cancel_btn  = $Panel/VBoxRegistro/HBoxRegBotones/CancelRegBtn
@onready var status_registro = $Panel/VBoxRegistro/StatusLabel

# Panel recuperar
@onready var vbox_recuperar    = $Panel/VBoxRecuperar
@onready var rec_email_input   = $Panel/VBoxRecuperar/RecEmailInput
@onready var rec_email_confirm = $Panel/VBoxRecuperar/RecEmailConfirm
@onready var rec_confirm_btn   = $Panel/VBoxRecuperar/HBoxRecBotones/RecConfirmBtn
@onready var rec_cancel_btn    = $Panel/VBoxRecuperar/HBoxRecBotones/RecCancelBtn
@onready var status_recuperar  = $Panel/VBoxRecuperar/StatusLabel

# Panel eliminar cuenta
@onready var vbox_eliminar   = $Panel/VBoxEliminar
@onready var del_confirm_btn = $Panel/VBoxEliminar/HBoxDelBotones/DelConfirmBtn
@onready var del_cancel_btn  = $Panel/VBoxEliminar/HBoxDelBotones/DelCancelBtn
@onready var status_eliminar = $Panel/VBoxEliminar/StatusLabel

var pass_visible: bool = false
var reg_pass_visible: bool = false
var _deleting_mode: bool = false

func _ready() -> void:
	FirebaseAuth.login_success.connect(_on_login_success)
	FirebaseAuth.login_failed.connect(_on_login_failed)
	FirebaseAuth.register_success.connect(_on_register_success)
	FirebaseAuth.register_failed.connect(_on_register_failed)
	FirebaseAuth.delete_success.connect(_on_delete_success)
	FirebaseAuth.delete_failed.connect(_on_delete_failed)

	login_button.pressed.connect(_on_login_pressed)
	register_button.pressed.connect(_show_registro)
	recover_button.pressed.connect(_show_recuperar)
	delete_button.pressed.connect(_show_eliminar)
	eye_button.pressed.connect(_toggle_pass)
	reg_eye_button.pressed.connect(_toggle_reg_pass)
	reg_confirm_btn.pressed.connect(_on_confirm_register)
	reg_cancel_btn.pressed.connect(_hide_all)
	rec_confirm_btn.pressed.connect(_on_confirm_recover)
	rec_cancel_btn.pressed.connect(_hide_all)
	del_confirm_btn.pressed.connect(_on_confirm_delete)
	del_cancel_btn.pressed.connect(_hide_all)

	server_option.add_item("Servidor 1 — S1")
	server_option.add_item("Servidor 2 — S2")

	vbox_registro.visible  = false
	vbox_recuperar.visible = false
	vbox_eliminar.visible  = false
	_load_remembered()

# --- OJO ---
func _toggle_pass() -> void:
	pass_visible = !pass_visible
	password_input.secret = !pass_visible
	eye_button.text = "●" if pass_visible else "○"

func _toggle_reg_pass() -> void:
	reg_pass_visible = !reg_pass_visible
	reg_pass_input.secret = !reg_pass_visible
	reg_eye_button.text = "●" if reg_pass_visible else "○"

# --- RECORDAR ---
func _load_remembered() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		username_input.text = cfg.get_value("auth", "username", "")
		password_input.text = cfg.get_value("auth", "password", "")
		remember_check.button_pressed = true

func _save_credentials(username: String, password: String) -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("auth", "username", username)
	cfg.set_value("auth", "password", password)
	cfg.save(SAVE_PATH)

func _clear_credentials() -> void:
	ConfigFile.new().save(SAVE_PATH)

# --- PANELES ---
func _show_registro() -> void:
	$Panel/VBoxLogin.visible = false
	vbox_registro.visible    = true
	vbox_recuperar.visible   = false
	vbox_eliminar.visible    = false
	reg_user_input.text = ""
	reg_email_input.text = ""
	reg_pass_input.text = ""
	status_registro.text = ""

func _show_recuperar() -> void:
	$Panel/VBoxLogin.visible = false
	vbox_registro.visible    = false
	vbox_recuperar.visible   = true
	vbox_eliminar.visible    = false
	rec_email_input.text = ""
	rec_email_confirm.text = ""
	status_recuperar.text = ""

func _show_eliminar() -> void:
	$Panel/VBoxLogin.visible = false
	vbox_registro.visible    = false
	vbox_recuperar.visible   = false
	vbox_eliminar.visible    = true
	status_eliminar.text = "¿Seguro que querés eliminar tu cuenta?\nEsta acción no se puede deshacer."

func _hide_all() -> void:
	$Panel/VBoxLogin.visible = true
	vbox_registro.visible    = false
	vbox_recuperar.visible   = false
	vbox_eliminar.visible    = false

# --- LOGIN ---
func _on_login_pressed() -> void:
	var username = username_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	if username == "" or password == "":
		status_login.text = "Completá todos los campos."
		return
	_set_login_buttons(false)
	status_login.text = "Conectando..."
	if remember_check.button_pressed:
		_save_credentials(username, password)
	else:
		_clear_credentials()
	FirebaseAuth.login_by_username(username, password)

func _on_login_failed(error: String) -> void:
	if _deleting_mode:
		_deleting_mode = false
		status_eliminar.text = _traducir_error(error)
		del_confirm_btn.disabled = false
		del_cancel_btn.disabled  = false
	else:
		status_login.text = _traducir_error(error)
		_set_login_buttons(true)

func _set_login_buttons(enabled: bool) -> void:
	login_button.disabled    = not enabled
	register_button.disabled = not enabled

# --- REGISTRO ---
func _on_confirm_register() -> void:
	var username = reg_user_input.text.strip_edges()
	var email    = reg_email_input.text.strip_edges()
	var password = reg_pass_input.text.strip_edges()
	if username == "" or email == "" or password == "":
		status_registro.text = "Completá todos los campos."
		return
	if username.length() < 3:
		status_registro.text = "El usuario necesita mínimo 3 caracteres."
		return
	if " " in username:
		status_registro.text = "El usuario no puede tener espacios."
		return
	if not "@" in email or not "." in email:
		status_registro.text = "Email inválido."
		return
	if password.length() < 8:
		status_registro.text = "La contraseña necesita mínimo 8 caracteres."
		return
	if not _tiene_mayuscula(password):
		status_registro.text = "La contraseña necesita al menos una mayúscula."
		return
	if not _tiene_numero(password):
		status_registro.text = "La contraseña necesita al menos un número."
		return
	reg_confirm_btn.disabled = true
	reg_cancel_btn.disabled  = true
	status_registro.text     = "Creando cuenta..."
	FirebaseAuth.register(username, email, password)

func _on_register_success(_user_data: Dictionary) -> void:
	status_registro.text     = "¡Cuenta creada! Ya podés ingresar."
	reg_confirm_btn.disabled = false
	reg_cancel_btn.disabled  = false
	await get_tree().create_timer(2.0).timeout
	_hide_all()

func _on_register_failed(error: String) -> void:
	status_registro.text     = _traducir_error(error)
	reg_confirm_btn.disabled = false
	reg_cancel_btn.disabled  = false

# --- RECUPERAR ---
func _on_confirm_recover() -> void:
	var email   = rec_email_input.text.strip_edges()
	var confirm = rec_email_confirm.text.strip_edges()
	if email == "" or confirm == "":
		status_recuperar.text = "Completá los dos campos."
		return
	if email != confirm:
		status_recuperar.text = "Los emails no coinciden."
		return
	if not "@" in email or not "." in email:
		status_recuperar.text = "Email inválido."
		return
	rec_confirm_btn.disabled = true
	rec_cancel_btn.disabled  = true
	status_recuperar.text    = "Enviando..."
	FirebaseAuth.send_password_reset(email)
	await get_tree().create_timer(1.5).timeout
	status_recuperar.text = "Si el email está registrado recibirás un enlace para restablecer tu contraseña."
	await get_tree().create_timer(3.0).timeout
	_hide_all()
	rec_confirm_btn.disabled = false
	rec_cancel_btn.disabled  = false

# --- ELIMINAR CUENTA ---
func _on_confirm_delete() -> void:
	var username = username_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	if username == "" or password == "":
		status_eliminar.text = "Completá usuario y contraseña en el login antes de continuar."
		return
	_deleting_mode = true
	del_confirm_btn.disabled = true
	del_cancel_btn.disabled  = true
	status_eliminar.text = "Verificando..."
	FirebaseAuth.login_by_username(username, password)

func _on_login_success(_user_data: Dictionary) -> void:
	if _deleting_mode:
		_deleting_mode = false
		status_eliminar.text = "Eliminando cuenta..."
		FirebaseAuth.delete_account()
	else:
		status_login.text = "¡Bienvenido!"
		get_tree().change_scene_to_file("res://scenes/character_creation.tscn")

func _on_delete_success() -> void:
	_clear_credentials()
	username_input.text = ""
	password_input.text = ""
	remember_check.button_pressed = false
	status_eliminar.text = "Cuenta eliminada."
	await get_tree().create_timer(2.0).timeout
	_hide_all()
	del_confirm_btn.disabled = false
	del_cancel_btn.disabled  = false

func _on_delete_failed(error: String) -> void:
	status_eliminar.text     = "Error: " + error
	del_confirm_btn.disabled = false
	del_cancel_btn.disabled  = false

# --- HELPERS ---
func _tiene_mayuscula(s: String) -> bool:
	for c in s:
		if c == c.to_upper() and c != c.to_lower():
			return true
	return false

func _tiene_numero(s: String) -> bool:
	for c in s:
		if c.is_valid_int():
			return true
	return false

func _traducir_error(error: String) -> String:
	match error:
		"EMAIL_NOT_FOUND":                      return "Email no registrado."
		"INVALID_PASSWORD":                     return "Contraseña incorrecta."
		"USER_DISABLED":                        return "Usuario deshabilitado."
		"EMAIL_EXISTS":                         return "El email ya está registrado."
		"INVALID_EMAIL":                        return "Email inválido."
		"INVALID_LOGIN_CREDENTIALS":            return "Usuario o contraseña incorrectos."
		"El nombre de usuario ya está en uso.": return "Ese nombre de usuario ya está en uso."
		"Usuario no encontrado.":               return "Usuario no encontrado."
		"WEAK_PASSWORD : Password should be at least 6 characters": return "Contraseña muy corta."
		_:                                      return "Error: " + error
