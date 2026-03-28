extends Control

# ============================================================
# ClanProfile — Perfil de clan clickeable
# Archivo: scripts/clan_profile/clan_profile.gd
# ============================================================

# --- Nodos (construidos en código) ---
var _lbl_nombre: Label
var _lbl_tag: Label
var _lbl_lider: Label
var _lbl_miembros_count: Label
var _tab_container: TabContainer
var _lista_miembros: VBoxContainer
var _lbl_descripcion: Label
var _txt_descripcion: TextEdit
var _btn_editar: Button
var _lbl_estandarte: Label
var _medallas_container: HBoxContainer

# --- Estado ---
var _clan_id: String = ""
var _es_lider: bool = false
var _editando: bool = false

const FIREBASE_URL = "https://firestore.googleapis.com/v1/projects/atepaia-2v/databases/(default)/documents"


func _ready() -> void:
    _construir_ui()


# ============================================================
# CONSTRUCCIÓN DE LA UI EN CÓDIGO
# ============================================================
func _construir_ui() -> void:
    # Fondo oscuro semitransparente que cubre toda la pantalla
    var overlay = ColorRect.new()
    overlay.color = Color(0, 0, 0, 0.75)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(overlay)

    # Panel central
    var panel = PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.custom_minimum_size = Vector2(620, 720)
    panel.position = Vector2(-310, -360)
    add_child(panel)

    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 16)
    margin.add_theme_constant_override("margin_right", 16)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_bottom", 12)
    panel.add_child(margin)

    var vbox_root = VBoxContainer.new()
    vbox_root.add_theme_constant_override("separation", 8)
    margin.add_child(vbox_root)

    # --- Barra de título ---
    var title_bar = HBoxContainer.new()
    vbox_root.add_child(title_bar)

    var titulo_vbox = VBoxContainer.new()
    titulo_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_bar.add_child(titulo_vbox)

    _lbl_nombre = Label.new()
    _lbl_nombre.text = "Cargando..."
    _lbl_nombre.add_theme_font_size_override("font_size", 22)
    titulo_vbox.add_child(_lbl_nombre)

    _lbl_tag = Label.new()
    _lbl_tag.text = ""
    _lbl_tag.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0))
    titulo_vbox.add_child(_lbl_tag)

    var btn_cerrar = Button.new()
    btn_cerrar.text = "✕"
    btn_cerrar.custom_minimum_size = Vector2(40, 40)
    btn_cerrar.pressed.connect(_cerrar)
    title_bar.add_child(btn_cerrar)

    # --- Info rápida (líder + cantidad de miembros) ---
    var info_hbox = HBoxContainer.new()
    vbox_root.add_child(info_hbox)

    _lbl_lider = Label.new()
    _lbl_lider.text = "Líder: ..."
    _lbl_lider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info_hbox.add_child(_lbl_lider)

    _lbl_miembros_count = Label.new()
    _lbl_miembros_count.text = "Miembros: ..."
    info_hbox.add_child(_lbl_miembros_count)

    vbox_root.add_child(HSeparator.new())

    # --- TabContainer ---
    _tab_container = TabContainer.new()
    _tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vbox_root.add_child(_tab_container)

    _construir_tab_miembros()
    _construir_tab_info()


func _construir_tab_miembros() -> void:
    var scroll = ScrollContainer.new()
    scroll.name = "Miembros"
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _tab_container.add_child(scroll)

    _lista_miembros = VBoxContainer.new()
    _lista_miembros.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _lista_miembros.add_theme_constant_override("separation", 4)
    scroll.add_child(_lista_miembros)

    # Cabecera de la tabla
    var header = HBoxContainer.new()
    _agregar_label_header(header, "Nombre", true)
    _agregar_label_header(header, "Nv.", false, 50)
    _agregar_label_header(header, "Clase", false, 110)
    _lista_miembros.add_child(header)
    _lista_miembros.add_child(HSeparator.new())


func _agregar_label_header(parent: HBoxContainer, texto: String, expandir: bool, ancho: int = 0) -> void:
    var lbl = Label.new()
    lbl.text = texto
    lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.3))
    lbl.add_theme_font_size_override("font_size", 13)
    if expandir:
        lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    else:
        lbl.custom_minimum_size = Vector2(ancho, 0)
    parent.add_child(lbl)


func _construir_tab_info() -> void:
    var scroll2 = ScrollContainer.new()
    scroll2.name = "Información"
    scroll2.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _tab_container.add_child(scroll2)

    var vbox = VBoxContainer.new()
    vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vbox.add_theme_constant_override("separation", 10)
    scroll2.add_child(vbox)

    # Estandarte
    _agregar_seccion_titulo(vbox, "🏴 Estandarte del Clan")

    _lbl_estandarte = Label.new()
    _lbl_estandarte.text = ""
    _lbl_estandarte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _lbl_estandarte.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
    vbox.add_child(_lbl_estandarte)

    vbox.add_child(HSeparator.new())

    # Descripción
    _agregar_seccion_titulo(vbox, "📜 Descripción del Clan")

    _lbl_descripcion = Label.new()
    _lbl_descripcion.text = "Sin descripción."
    _lbl_descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _lbl_descripcion.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
    vbox.add_child(_lbl_descripcion)

    _txt_descripcion = TextEdit.new()
    _txt_descripcion.custom_minimum_size = Vector2(0, 90)
    _txt_descripcion.visible = false
    vbox.add_child(_txt_descripcion)

    _btn_editar = Button.new()
    _btn_editar.text = "✏ Editar descripción"
    _btn_editar.visible = false
    _btn_editar.pressed.connect(_toggle_editar_descripcion)
    vbox.add_child(_btn_editar)

    vbox.add_child(HSeparator.new())

    # Medallas
    _agregar_seccion_titulo(vbox, "🏅 Medallas del Clan")

    _medallas_container = HBoxContainer.new()
    _medallas_container.add_theme_constant_override("separation", 8)
    vbox.add_child(_medallas_container)


func _agregar_seccion_titulo(parent: VBoxContainer, texto: String) -> void:
    var lbl = Label.new()
    lbl.text = texto
    lbl.add_theme_font_size_override("font_size", 16)
    lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
    parent.add_child(lbl)


# ============================================================
# CARGA DE DATOS DESDE FIRESTORE
# ============================================================
func cargar_clan(clan_id: String) -> void:
    _clan_id = clan_id

    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(func(result, code, hds, body):
        http.queue_free()
        _on_clan_cargado(code, body)
    )

    var url = FIREBASE_URL + "/clanes/" + clan_id
    var headers = _get_headers()
    http.request(url, headers, HTTPClient.METHOD_GET)


func _on_clan_cargado(response_code: int, body: PackedByteArray) -> void:
    if response_code != 200:
        _lbl_nombre.text = "Error al cargar clan"
        return

    var json = JSON.new()
    json.parse(body.get_string_from_utf8())
    var data = json.get_data()
    if not data is Dictionary or not data.has("fields"):
        return

    var f = data["fields"]
    var nombre       = _leer_string(f, "nombre")
    var tag          = _leer_string(f, "tag")
    var lider_name   = _leer_string(f, "lider_name")
    var lider_id     = _leer_string(f, "lider_id")
    var created_at   = _leer_string(f, "created_at")
    var descripcion  = _leer_string(f, "descripcion")
    var miembros_cnt = _leer_int(f, "miembros")
    var medallas     = _leer_array_strings(f, "medallas")

    # Rellenar header
    _lbl_nombre.text = nombre
    _lbl_tag.text = "[" + tag + "]"
    _lbl_lider.text = "Líder: " + lider_name
    _lbl_miembros_count.text = "Miembros: " + str(miembros_cnt)

    # Estandarte
    _lbl_estandarte.text = (
        "Clan: " + nombre + " [" + tag + "]\n" +
        "Fundado por: " + lider_name + "\n" +
        "Fecha: " + created_at
    )

    # Descripción
    if descripcion != "":
        _lbl_descripcion.text = descripcion
    _txt_descripcion.text = descripcion

    # Solo el líder puede editar la descripción
    _es_lider = (GameData.player_id == lider_id)
    _btn_editar.visible = _es_lider

    # Medallas
    for child in _medallas_container.get_children():
        child.queue_free()

    if medallas.is_empty():
        var lbl_no_med = Label.new()
        lbl_no_med.text = "Este clan aún no tiene medallas."
        lbl_no_med.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
        _medallas_container.add_child(lbl_no_med)
    else:
        for med in medallas:
            var lbl_med = Label.new()
            lbl_med.text = "🏅 " + str(med)
            _medallas_container.add_child(lbl_med)

    # Ahora cargar la lista de miembros
    _cargar_miembros()


func _cargar_miembros() -> void:
    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(func(result, code, hds, body):
        http.queue_free()
        _on_miembros_cargados(code, body)
    )

    var query = {
        "structuredQuery": {
            "from": [{"collectionId": "players"}],
            "where": {
                "fieldFilter": {
                    "field": {"fieldPath": "player_clan_id"},
                    "op": "EQUAL",
                    "value": {"stringValue": _clan_id}
                }
            },
            "orderBy": [{"field": {"fieldPath": "level"}, "direction": "DESCENDING"}],
            "limit": 50
        }
    }

    var url = "https://firestore.googleapis.com/v1/projects/atepaia-2v/databases/(default)/documents:runQuery"
    var headers = _get_headers()
    http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(query))


func _on_miembros_cargados(response_code: int, body: PackedByteArray) -> void:
    if response_code != 200:
        return

    var json = JSON.new()
    json.parse(body.get_string_from_utf8())
    var data = json.get_data()

    if not data is Array:
        return

    var encontrados = 0
    for entry in data:
        if not entry.has("document"):
            continue
        var doc = entry["document"]
        if not doc.has("fields"):
            continue

        var f = doc["fields"]
        var pname  = _leer_string(f, "player_name")
        var plevel = _leer_int(f, "level")
        var pclass = _leer_string(f, "player_class")

        # Extraer el player_id del path del documento
        var doc_name = doc.get("name", "")
        var partes = doc_name.split("/")
        var pid = partes[partes.size() - 1]

        var row = HBoxContainer.new()

        # Botón clickeable con el nombre
        var btn_nombre = Button.new()
        btn_nombre.text = pname
        btn_nombre.flat = true
        btn_nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        btn_nombre.alignment = HORIZONTAL_ALIGNMENT_LEFT
        btn_nombre.add_theme_color_override("font_color", Color(0.55, 0.88, 1.0))
        # Capturar pid en una variable local para el closure
        var pid_capturado = pid
        btn_nombre.pressed.connect(func():
            _abrir_perfil_jugador(pid_capturado)
        )
        row.add_child(btn_nombre)

        var lbl_nivel = Label.new()
        lbl_nivel.text = str(plevel)
        lbl_nivel.custom_minimum_size = Vector2(50, 0)
        row.add_child(lbl_nivel)

        var lbl_clase = Label.new()
        lbl_clase.text = pclass
        lbl_clase.custom_minimum_size = Vector2(110, 0)
        row.add_child(lbl_clase)

        _lista_miembros.add_child(row)
        encontrados += 1

    if encontrados == 0:
        var lbl_vacio = Label.new()
        lbl_vacio.text = "No se encontraron miembros."
        lbl_vacio.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
        _lista_miembros.add_child(lbl_vacio)


# ============================================================
# EDITAR DESCRIPCIÓN (solo el líder)
# ============================================================
func _toggle_editar_descripcion() -> void:
    _editando = !_editando
    if _editando:
        _lbl_descripcion.visible = false
        _txt_descripcion.visible = true
        _btn_editar.text = "💾 Guardar descripción"
    else:
        var nueva = _txt_descripcion.text.strip_edges()
        _lbl_descripcion.text = nueva if nueva != "" else "Sin descripción."
        _lbl_descripcion.visible = true
        _txt_descripcion.visible = false
        _btn_editar.text = "✏ Editar descripción"
        _guardar_descripcion(nueva)


func _guardar_descripcion(desc: String) -> void:
    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(func(r, c, h, b): http.queue_free())

    var url = FIREBASE_URL + "/clanes/" + _clan_id + "?updateMask.fieldPaths=descripcion"
    var headers = _get_headers()
    var body_data = JSON.stringify({
        "fields": {
            "descripcion": {"stringValue": desc}
        }
    })
    http.request(url, headers, HTTPClient.METHOD_PATCH, body_data)


# ============================================================
# ABRIR PERFIL DE JUGADOR (desde lista de miembros)
# ============================================================
func _abrir_perfil_jugador(player_id: String) -> void:
    var perfil = preload("res://scenes/player_profile/PlayerProfile.tscn").instantiate()
    get_parent().add_child(perfil)
    perfil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    perfil.z_index = 200
    perfil.cargar_perfil(player_id)


func _cerrar() -> void:
    queue_free()


# ============================================================
# HELPERS FIRESTORE
# ============================================================
func _get_headers() -> Array:
    var headers = ["Content-Type: application/json"]
    if GameData.id_token != "":
        headers.append("Authorization: Bearer " + GameData.id_token)
    return headers


func _leer_string(fields: Dictionary, key: String) -> String:
    if fields.has(key) and fields[key].has("stringValue"):
        return fields[key]["stringValue"]
    return ""


func _leer_int(fields: Dictionary, key: String) -> int:
    if fields.has(key):
        if fields[key].has("integerValue"):
            return int(fields[key]["integerValue"])
        if fields[key].has("doubleValue"):
            return int(fields[key]["doubleValue"])
    return 0


func _leer_array_strings(fields: Dictionary, key: String) -> Array:
    if fields.has(key) and fields[key].has("arrayValue"):
        var av = fields[key]["arrayValue"]
        if av.has("values"):
            var result: Array = []
            for v in av["values"]:
                if v.has("stringValue"):
                    result.append(v["stringValue"])
            return result
    return []
