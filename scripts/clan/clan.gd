extends Control

# ─────────────────────────────────────────────────────────
# CLANES
# Crear clan / Buscar clan / Chat interno
# ─────────────────────────────────────────────────────────

var _http: HTTPRequest
var _http_chat: HTTPRequest
var _mi_clan: Dictionary = {}
var _clanes_lista: Array = []

var _http_membresia: HTTPRequest

func _ready() -> void:
    _http = HTTPRequest.new()
    add_child(_http)
    _http_chat = HTTPRequest.new()
    add_child(_http_chat)
    _http_membresia = HTTPRequest.new()
    add_child(_http_membresia)
    _http.request_completed.connect(_on_http_completed)
    _http_chat.request_completed.connect(_on_chat_completed)
    _http_membresia.request_completed.connect(_on_membresia_completed)
    _construir_ui()
    _cargar_mi_clan()

# ─────────────────────────────────────
# UI
# ─────────────────────────────────────
var _panel_sin_clan:  Control
var _panel_con_clan:  Control
var _lbl_clan_nombre: Label
var _lbl_clan_tag:    Label
var _lbl_clan_miembros: Label
var _vbox_chat:       VBoxContainer
var _input_chat:      LineEdit
var _scroll_chat:     ScrollContainer
var _grid_clanes:     VBoxContainer
var _input_buscar:    LineEdit
var _lbl_status:      Label

func _construir_ui() -> void:
    var bg = ColorRect.new()
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.color = Color(0.06, 0.04, 0.03, 1)
    add_child(bg)

    var scroll = ScrollContainer.new()
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(scroll)

    var outer = VBoxContainer.new()
    outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(outer)

    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left",   14)
    margin.add_theme_constant_override("margin_right",  14)
    margin.add_theme_constant_override("margin_top",    10)
    margin.add_theme_constant_override("margin_bottom", 14)
    outer.add_child(margin)

    var inner = VBoxContainer.new()
    inner.add_theme_constant_override("separation", 12)
    margin.add_child(inner)

    # Título
    var lbl_titulo = Label.new()
    lbl_titulo.text = "— CLANES —"
    lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl_titulo.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3, 1))
    lbl_titulo.add_theme_font_size_override("font_size", 18)
    inner.add_child(lbl_titulo)

    # Label de status
    _lbl_status = Label.new()
    _lbl_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _lbl_status.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
    _lbl_status.add_theme_font_size_override("font_size", 11)
    inner.add_child(_lbl_status)

    inner.add_child(HSeparator.new())

    # ── Panel SIN clan ────────────────────────────────
    _panel_sin_clan = VBoxContainer.new()
    _panel_sin_clan.add_theme_constant_override("separation", 10)
    inner.add_child(_panel_sin_clan)

    var lbl_crear_titulo = Label.new()
    lbl_crear_titulo.text = "Crear nuevo clan"
    lbl_crear_titulo.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3, 1))
    lbl_crear_titulo.add_theme_font_size_override("font_size", 13)
    _panel_sin_clan.add_child(lbl_crear_titulo)

    var input_nombre = LineEdit.new()
    input_nombre.name = "InputNombreClan"
    input_nombre.placeholder_text = "Nombre del clan (mín 3 caracteres)"
    input_nombre.add_theme_font_size_override("font_size", 12)
    _panel_sin_clan.add_child(input_nombre)

    var input_tag = LineEdit.new()
    input_tag.name = "InputTagClan"
    input_tag.placeholder_text = "TAG del clan (3 letras, ej: ATK)"
    input_tag.max_length = 4
    input_tag.add_theme_font_size_override("font_size", 12)
    _panel_sin_clan.add_child(input_tag)

    var btn_crear = Button.new()
    btn_crear.text = "⚑  Fundar Clan"
    btn_crear.add_theme_font_size_override("font_size", 13)
    btn_crear.pressed.connect(_on_crear_clan)
    _panel_sin_clan.add_child(btn_crear)

    _panel_sin_clan.add_child(HSeparator.new())

    var lbl_buscar_titulo = Label.new()
    lbl_buscar_titulo.text = "Buscar clan"
    lbl_buscar_titulo.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3, 1))
    lbl_buscar_titulo.add_theme_font_size_override("font_size", 13)
    _panel_sin_clan.add_child(lbl_buscar_titulo)

    var hbox_buscar = HBoxContainer.new()
    _panel_sin_clan.add_child(hbox_buscar)

    _input_buscar = LineEdit.new()
    _input_buscar.placeholder_text = "Nombre del clan..."
    _input_buscar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _input_buscar.add_theme_font_size_override("font_size", 12)
    hbox_buscar.add_child(_input_buscar)

    var btn_buscar = Button.new()
    btn_buscar.text = "🔍"
    btn_buscar.pressed.connect(_on_buscar_clan)
    hbox_buscar.add_child(btn_buscar)

    var lbl_todos = Label.new()
    lbl_todos.text = "Todos los clanes:"
    lbl_todos.add_theme_color_override("font_color", Color(0.7, 0.7, 0.6, 1))
    lbl_todos.add_theme_font_size_override("font_size", 11)
    _panel_sin_clan.add_child(lbl_todos)

    _grid_clanes = VBoxContainer.new()
    _grid_clanes.add_theme_constant_override("separation", 6)
    _panel_sin_clan.add_child(_grid_clanes)

    _cargar_lista_clanes()

    # ── Panel CON clan ────────────────────────────────
    _panel_con_clan = VBoxContainer.new()
    _panel_con_clan.add_theme_constant_override("separation", 10)
    _panel_con_clan.visible = false
    inner.add_child(_panel_con_clan)

    _lbl_clan_nombre = Label.new()
    _lbl_clan_nombre.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3, 1))
    _lbl_clan_nombre.add_theme_font_size_override("font_size", 16)
    _panel_con_clan.add_child(_lbl_clan_nombre)

    _lbl_clan_tag = Label.new()
    _lbl_clan_tag.add_theme_color_override("font_color", Color(0.7, 0.7, 0.6, 1))
    _lbl_clan_tag.add_theme_font_size_override("font_size", 12)
    _panel_con_clan.add_child(_lbl_clan_tag)

    _lbl_clan_miembros = Label.new()
    _lbl_clan_miembros.add_theme_color_override("font_color", Color(0.6, 0.85, 0.6, 1))
    _lbl_clan_miembros.add_theme_font_size_override("font_size", 11)
    _panel_con_clan.add_child(_lbl_clan_miembros)

    var btn_salir_clan = Button.new()
    btn_salir_clan.text = "🚪  Abandonar clan"
    btn_salir_clan.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4, 1))
    btn_salir_clan.add_theme_font_size_override("font_size", 11)
    btn_salir_clan.pressed.connect(_on_salir_clan)
    _panel_con_clan.add_child(btn_salir_clan)

    _panel_con_clan.add_child(HSeparator.new())

    # Chat del clan
    var lbl_chat = Label.new()
    lbl_chat.text = "💬  Chat del clan"
    lbl_chat.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3, 1))
    lbl_chat.add_theme_font_size_override("font_size", 13)
    _panel_con_clan.add_child(lbl_chat)

    _scroll_chat = ScrollContainer.new()
    _scroll_chat.custom_minimum_size = Vector2(0, 200)
    _panel_con_clan.add_child(_scroll_chat)

    _vbox_chat = VBoxContainer.new()
    _vbox_chat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _vbox_chat.add_theme_constant_override("separation", 4)
    _scroll_chat.add_child(_vbox_chat)

    var hbox_input = HBoxContainer.new()
    _panel_con_clan.add_child(hbox_input)

    _input_chat = LineEdit.new()
    _input_chat.placeholder_text = "Escribe un mensaje..."
    _input_chat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _input_chat.add_theme_font_size_override("font_size", 12)
    hbox_input.add_child(_input_chat)

    var btn_enviar = Button.new()
    btn_enviar.text = "▶"
    btn_enviar.pressed.connect(_on_enviar_chat)
    hbox_input.add_child(btn_enviar)

# ─────────────────────────────────────
# LÓGICA
# ─────────────────────────────────────
var _accion_actual: String = ""

func _cargar_mi_clan() -> void:
    _lbl_status.text = "Verificando membresía..."
    _accion_actual = "check_miembro"
    var url = GameData.FIRESTORE_URL + "clan_members/" + GameData.player_id
    _http_get(url)

func _cargar_lista_clanes(_filtro: String = "") -> void:
    _accion_actual = "lista_clanes"
    var url = "https://firestore.googleapis.com/v1/projects/" + GameData.FIREBASE_PROJECT_ID
    url += "/databases/(default)/documents:runQuery"
    var query: Dictionary = {
        "structuredQuery": {
            "from": [{ "collectionId": "clanes" }],
            "orderBy": [{ "field": { "fieldPath": "nombre" }, "direction": "ASCENDING" }],
            "limit": 20
        }
    }
    _http_post(url, JSON.stringify(query))

func _on_buscar_clan() -> void:
    _cargar_lista_clanes(_input_buscar.text.strip_edges())

func _on_crear_clan() -> void:
    var input_n = _panel_sin_clan.get_node_or_null("InputNombreClan")
    var input_t = _panel_sin_clan.get_node_or_null("InputTagClan")
    if input_n == null or input_t == null:
        return
    var nombre = input_n.text.strip_edges()
    var tag    = input_t.text.strip_edges().to_upper()
    if nombre.length() < 3:
        _lbl_status.text = "El nombre del clan necesita mínimo 3 caracteres."
        return
    if tag.length() < 2:
        _lbl_status.text = "El TAG necesita 2-4 letras."
        return
    _lbl_status.text = "Creando clan..."
    _accion_actual = "crear_clan"
    var clan_id = GameData.player_id + "_clan"
    var url = GameData.FIRESTORE_URL + "clanes/" + clan_id
    var fecha = Time.get_datetime_string_from_system()
    var body = JSON.stringify({ "fields": {
        "nombre":       { "stringValue": nombre },
        "tag":          { "stringValue": "[" + tag + "]" },
        "lider_id":     { "stringValue": GameData.player_id },
        "lider_name":   { "stringValue": GameData.player_name },
        "miembros":     { "integerValue": "1" },
        "created_at":   { "stringValue": fecha },
        "descripcion":  { "stringValue": "" },
        "pvp_points":   { "integerValue": "0" },
        "gold_stolen":  { "integerValue": "0" },
        "xp_total":     { "integerValue": "0" },
        "craft_points": { "integerValue": "0" },
        "clan_id":      { "stringValue": clan_id },
        "medallas":     { "arrayValue": { "values": [] } },
    }})
    # Guardar en GameData para el estandarte
    GameData.player_clan_name = nombre
    GameData.player_clan_tag  = "[" + tag + "]"
    GameData.clan_founded_by  = GameData.player_name
    GameData.clan_created_at  = fecha
    _mi_clan = { "nombre": nombre, "tag": "[" + tag + "]", "clan_id": clan_id }
    _http_patch(url, body)

func _on_salir_clan() -> void:
    if _mi_clan.is_empty():
        return
    _lbl_status.text = "Abandonando clan..."
    _accion_actual = "salir_clan"
    var url = GameData.FIRESTORE_URL + "clan_members/" + GameData.player_id
    _http_delete(url)

func _on_unirse_clan(clan: Dictionary) -> void:
    _lbl_status.text = "Uniéndose a " + clan.get("nombre", "?") + "..."
    _accion_actual = "unirse_clan"
    _mi_clan = clan
    var url = GameData.FIRESTORE_URL + "clan_members/" + GameData.player_id
    var body = JSON.stringify({ "fields": {
        "clan_id":    { "stringValue": clan.get("clan_id", "") },
        "clan_nombre":{ "stringValue": clan.get("nombre", "") },
        "player_name":{ "stringValue": GameData.player_name },
        "joined_at":  { "stringValue": Time.get_datetime_string_from_system() },
    }})
    _http_patch(url, body)

func _on_enviar_chat() -> void:
    var msg = _input_chat.text.strip_edges()
    if msg == "" or _mi_clan.is_empty():
        return
    _input_chat.text = ""
    var msg_id = str(Time.get_unix_time_from_system()) + "_" + GameData.player_id
    var url    = GameData.FIRESTORE_URL + "clan_chat/" + msg_id
    var body   = JSON.stringify({ "fields": {
        "clan_id":    { "stringValue": _mi_clan.get("clan_id", "") },
        "autor":      { "stringValue": GameData.player_name },
        "mensaje":    { "stringValue": msg },
        "timestamp":  { "integerValue": str(int(Time.get_unix_time_from_system())) },
    }})
    _http_chat.request(url, _headers(), HTTPClient.METHOD_PATCH, body)
    _agregar_mensaje_chat(GameData.player_name, msg)

func _agregar_mensaje_chat(autor: String, texto: String) -> void:
    var lbl = Label.new()
    lbl.text = "[" + autor + "]: " + texto
    lbl.add_theme_font_size_override("font_size", 11)
    lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
    if autor == GameData.player_name:
        lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5, 1))
    else:
        lbl.add_theme_color_override("font_color", Color(0.85, 0.82, 0.7, 1))
    _vbox_chat.add_child(lbl)
    await get_tree().process_frame
    _scroll_chat.scroll_vertical = 999999

# ─────────────────────────────────────
# CALLBACKS HTTP
# ─────────────────────────────────────
func _on_http_completed(_result, response_code, _headers_r, body) -> void:
    var data = JSON.parse_string(body.get_string_from_utf8())
    match _accion_actual:
        "check_miembro":
            if response_code == 200 and data != null and data.has("fields"):
                var f = data["fields"]
                _mi_clan = {
                    "clan_id": f.get("clan_id", {}).get("stringValue", ""),
                    "nombre":  f.get("clan_nombre", {}).get("stringValue", "Sin nombre"),
                }
                _mostrar_panel_clan()
            else:
                _lbl_status.text = "No pertenecés a ningún clan."
                _panel_sin_clan.visible = true
                _panel_con_clan.visible = false
        "lista_clanes":
            _clanes_lista = []
            if data != null:
                for doc in data:
                    if doc.has("document") and doc["document"].has("fields"):
                        var f = doc["document"]["fields"]
                        _clanes_lista.append({
                            "nombre":  f.get("nombre",   {}).get("stringValue", "?"),
                            "tag":     f.get("tag",      {}).get("stringValue", ""),
                            "miembros":int(f.get("miembros", {}).get("integerValue", "1")),
                            "clan_id": f.get("clan_id",  {}).get("stringValue", ""),
                            "lider_name": f.get("lider_name", {}).get("stringValue", ""),
                        })
            _poblar_lista_clanes()
        "crear_clan", "unirse_clan":
            if response_code == 200 or response_code == 201:
                # Guardar membresía en nodo HTTP separado
                var url = GameData.FIRESTORE_URL + "clan_members/" + GameData.player_id
                var body2 = JSON.stringify({ "fields": {
                    "clan_id":    { "stringValue": _mi_clan.get("clan_id", "") },
                    "clan_nombre":{ "stringValue": _mi_clan.get("nombre", "") },
                    "player_name":{ "stringValue": GameData.player_name },
                    "joined_at":  { "stringValue": Time.get_datetime_string_from_system() },
                }})
                _http_membresia.request(url, _headers(), HTTPClient.METHOD_PATCH, body2)
            else:
                _lbl_status.text = "Error al crear/unirse al clan. Código: " + str(response_code)
        "cargar_detalle":
            if response_code == 200 and data != null and data.has("fields"):
                var f = data["fields"]
                _mi_clan["descripcion"] = f.get("descripcion", {}).get("stringValue", "")
                _mi_clan["lider_name"]  = f.get("lider_name",  {}).get("stringValue", "")
                _mi_clan["created_at"]  = f.get("created_at",  {}).get("stringValue", "")
                GameData.clan_founded_by = _mi_clan["lider_name"]
                GameData.clan_created_at = _mi_clan["created_at"]
                _actualizar_descripcion_panel()

        "salir_clan":
            _mi_clan = {}
            GameData.player_clan_id   = ""
            GameData.player_clan_name = ""
            GameData.player_clan_tag  = ""
            _lbl_status.text = "Abandonaste el clan."
            _panel_sin_clan.visible = true
            _panel_con_clan.visible = false
            _cargar_lista_clanes()

func _on_membresia_completed(_result, response_code, _headers_r, _body) -> void:
    if response_code == 200 or response_code == 201:
        _lbl_status.text = "¡Clan actualizado correctamente!"
        _mostrar_panel_clan()
    else:
        _lbl_status.text = "Error al guardar membresía. Código: " + str(response_code)

func _on_chat_completed(_r, _c, _h, _b) -> void:
    pass  # Mensaje ya mostrado localmente

func _mostrar_panel_clan() -> void:
    _panel_sin_clan.visible = false
    _panel_con_clan.visible = true
    _lbl_clan_nombre.text   = _mi_clan.get("nombre", "Mi Clan")
    _lbl_clan_tag.text      = _mi_clan.get("tag", "") + "  —  Toca el nombre para ver el perfil del clan"
    _lbl_clan_miembros.text = ""
    _lbl_status.text        = "Clan cargado."
    # Guardar info del clan en GameData
    GameData.player_clan_id   = _mi_clan.get("clan_id", "")
    GameData.player_clan_name = _mi_clan.get("nombre", "")
    GameData.player_clan_tag  = _mi_clan.get("tag", "")
    GameData.clan_founded_by  = _mi_clan.get("lider_name", "")
    GameData.clan_created_at  = _mi_clan.get("created_at", "")
    # Hacer el nombre clickeable para abrir el perfil del clan
    var cid = _mi_clan.get("clan_id", "")
    if cid != "":
        _lbl_clan_nombre.mouse_filter = Control.MOUSE_FILTER_STOP
        _lbl_clan_nombre.add_theme_color_override("font_color", Color(0.55, 0.88, 1.0, 1))
        # Desconectar si ya estaba conectado para evitar dobles
        if not _lbl_clan_nombre.gui_input.is_connected(_on_lbl_clan_click):
            _lbl_clan_nombre.gui_input.connect(_on_lbl_clan_click)
    _cargar_detalle_clan()

func _cargar_detalle_clan() -> void:
    if GameData.player_clan_id == "":
        return
    var url = GameData.FIRESTORE_URL + "clanes/" + GameData.player_clan_id
    _accion_actual = "cargar_detalle"
    _http_get(url)

func _actualizar_descripcion_panel() -> void:
    # Actualizar la descripción visible si el panel está abierto
    var lbl_desc = _panel_con_clan.find_child("LblDescClan", true, false)
    if lbl_desc:
        lbl_desc.text = _mi_clan.get("descripcion", "(Sin descripción)")

func _poblar_lista_clanes() -> void:
    for child in _grid_clanes.get_children():
        child.queue_free()
    for clan in _clanes_lista:
        var panel = PanelContainer.new()
        var margin = MarginContainer.new()
        margin.add_theme_constant_override("margin_left",   8)
        margin.add_theme_constant_override("margin_right",  8)
        margin.add_theme_constant_override("margin_top",    6)
        margin.add_theme_constant_override("margin_bottom", 6)
        panel.add_child(margin)
        var hbox = HBoxContainer.new()
        margin.add_child(hbox)
        var vbox = VBoxContainer.new()
        vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        hbox.add_child(vbox)
        var btn_n = Button.new()
        btn_n.text = clan.get("tag", "") + "  " + clan.get("nombre", "?")
        btn_n.flat = true
        btn_n.alignment = HORIZONTAL_ALIGNMENT_LEFT
        btn_n.add_theme_color_override("font_color", Color(0.9, 0.82, 0.5, 1))
        btn_n.add_theme_font_size_override("font_size", 12)
        var cid = clan.get("clan_id", "")
        if cid != "":
            btn_n.pressed.connect(_abrir_perfil_clan.bind(cid))
        vbox.add_child(btn_n)
        var lbl_m = Label.new()
        lbl_m.text = "Lider: " + clan.get("lider_name", "?") + "  |  Miembros: " + str(clan.get("miembros", 1))
        lbl_m.add_theme_color_override("font_color", Color(0.6, 0.6, 0.55, 1))
        lbl_m.add_theme_font_size_override("font_size", 10)
        vbox.add_child(lbl_m)
        var btn = Button.new()
        btn.text = "Unirse"
        btn.add_theme_font_size_override("font_size", 11)
        btn.pressed.connect(_on_unirse_clan.bind(clan))
        hbox.add_child(btn)
        _grid_clanes.add_child(panel)

# ─────────────────────────────────────
# HELPERS HTTP
# ─────────────────────────────────────
func _headers() -> PackedStringArray:
    return PackedStringArray([
        "Content-Type: application/json",
        "Authorization: Bearer " + GameData.id_token
    ])

func _cancelar_si_ocupado(h: HTTPRequest) -> void:
    if h.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
        h.cancel_request()

func _http_get(url: String) -> void:
    _cancelar_si_ocupado(_http)
    _http.request(url, _headers(), HTTPClient.METHOD_GET)

func _http_patch(url: String, body: String) -> void:
    _cancelar_si_ocupado(_http)
    _http.request(url, _headers(), HTTPClient.METHOD_PATCH, body)

func _http_post(url: String, body: String) -> void:
    _cancelar_si_ocupado(_http)
    _http.request(url, _headers(), HTTPClient.METHOD_POST, body)

func _http_delete(url: String) -> void:
    _cancelar_si_ocupado(_http)
    _http.request(url, _headers(), HTTPClient.METHOD_DELETE)

func _on_lbl_clan_click(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var cid = _mi_clan.get("clan_id", "")
        if cid != "":
            _abrir_perfil_clan(cid)

func _abrir_perfil_clan(clan_id: String) -> void:
    if clan_id == "":
        return
    var script = load("res://scripts/clan_profile/clan_profile.gd")
    if script == null:
        print("ERROR: No se encuentra clan_profile.gd")
        return
    var perfil = Control.new()
    perfil.set_script(script)
    add_child(perfil)
    perfil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    perfil.z_index = 100
    perfil.cargar_clan(clan_id)
