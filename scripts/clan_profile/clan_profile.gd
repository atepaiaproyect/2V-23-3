extends Control

# ============================================================
# ClanProfile — Perfil de clan estilo Travian
# Archivo: scripts/clan_profile/clan_profile.gd
# ============================================================

const FIREBASE_URL = "https://firestore.googleapis.com/v1/projects/atepaia-2v/databases/(default)/documents"

var _clan_id:    String = ""
var _clan_data:  Dictionary = {}
var _es_lider:   bool = false
var _editando:   bool = false

var _lbl_nombre:          Label
var _lbl_tag:             Label
var _lbl_lider:           Label
var _lbl_miembros_count:  Label
var _lbl_fundacion:       Label
var _lbl_pvp:             Label
var _lbl_xp:              Label
var _lbl_craft:           Label
var _lista_miembros:      VBoxContainer
var _lbl_descripcion:     Label
var _txt_descripcion:     TextEdit
var _btn_guardar_desc:    Button
var _medallas_hbox:       HBoxContainer
var _tabs:                Array = []
var _panels:              Array = []
var _tab_activa:          int   = 0
var _es_miembro:          bool  = false  # true si pertenece a este clan

const C_ORO    = Color(0.95, 0.80, 0.35, 1)
const C_TITULO = Color(0.85, 0.70, 0.25, 1)
const C_TEXTO  = Color(0.88, 0.84, 0.72, 1)
const C_TENUE  = Color(0.55, 0.52, 0.45, 1)
const C_AZUL   = Color(0.45, 0.75, 1.00, 1)
const C_VERDE  = Color(0.35, 0.88, 0.45, 1)
const C_ROJO   = Color(0.95, 0.35, 0.30, 1)
const C_BG     = Color(0.07, 0.05, 0.03, 1)
const C_PANEL  = Color(0.11, 0.08, 0.05, 1)
const C_BORDE  = Color(0.35, 0.27, 0.13, 1)
const C_HEADER = Color(0.18, 0.13, 0.06, 1)


func _ready() -> void:
    _construir_ui()


func _construir_ui() -> void:
    var overlay = ColorRect.new()
    overlay.color = Color(0, 0, 0, 0.80)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(overlay)

    var panel = PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.custom_minimum_size = Vector2(680, 740)
    panel.position = Vector2(-340, -370)
    var style_panel = StyleBoxFlat.new()
    style_panel.bg_color     = C_BG
    style_panel.border_color = C_BORDE
    style_panel.border_width_left   = 2
    style_panel.border_width_right  = 2
    style_panel.border_width_top    = 2
    style_panel.border_width_bottom = 2
    style_panel.corner_radius_top_left     = 6
    style_panel.corner_radius_top_right    = 6
    style_panel.corner_radius_bottom_left  = 6
    style_panel.corner_radius_bottom_right = 6
    panel.add_theme_stylebox_override("panel", style_panel)
    add_child(panel)

    var vbox_root = VBoxContainer.new()
    vbox_root.add_theme_constant_override("separation", 0)
    panel.add_child(vbox_root)

    _construir_header(vbox_root)
    _construir_tabs(vbox_root)
    _construir_contenido(vbox_root)


func _construir_header(parent: VBoxContainer) -> void:
    var header_panel = PanelContainer.new()
    var style_h = StyleBoxFlat.new()
    style_h.bg_color     = C_HEADER
    style_h.border_color = C_BORDE
    style_h.border_width_bottom = 2
    style_h.corner_radius_top_left  = 5
    style_h.corner_radius_top_right = 5
    header_panel.add_theme_stylebox_override("panel", style_h)
    parent.add_child(header_panel)

    var h_margin = MarginContainer.new()
    h_margin.add_theme_constant_override("margin_left",   16)
    h_margin.add_theme_constant_override("margin_right",  16)
    h_margin.add_theme_constant_override("margin_top",    12)
    h_margin.add_theme_constant_override("margin_bottom", 12)
    header_panel.add_child(h_margin)

    var h_hbox = HBoxContainer.new()
    h_hbox.add_theme_constant_override("separation", 12)
    h_margin.add_child(h_hbox)

    var clan_icon = PanelContainer.new()
    clan_icon.custom_minimum_size = Vector2(64, 64)
    var style_icon = StyleBoxFlat.new()
    style_icon.bg_color     = Color(0.12, 0.10, 0.06, 1)
    style_icon.border_color = C_BORDE
    style_icon.border_width_left   = 1
    style_icon.border_width_right  = 1
    style_icon.border_width_top    = 1
    style_icon.border_width_bottom = 1
    style_icon.corner_radius_top_left     = 4
    style_icon.corner_radius_top_right    = 4
    style_icon.corner_radius_bottom_left  = 4
    style_icon.corner_radius_bottom_right = 4
    clan_icon.add_theme_stylebox_override("panel", style_icon)
    var lbl_icon = Label.new()
    lbl_icon.text = "🏰"
    lbl_icon.add_theme_font_size_override("font_size", 32)
    lbl_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl_icon.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
    clan_icon.add_child(lbl_icon)
    h_hbox.add_child(clan_icon)

    var info_vbox = VBoxContainer.new()
    info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info_vbox.add_theme_constant_override("separation", 3)
    h_hbox.add_child(info_vbox)

    _lbl_nombre = Label.new()
    _lbl_nombre.text = "Cargando..."
    _lbl_nombre.add_theme_font_size_override("font_size", 22)
    _lbl_nombre.add_theme_color_override("font_color", C_ORO)
    info_vbox.add_child(_lbl_nombre)

    _lbl_tag = Label.new()
    _lbl_tag.text = ""
    _lbl_tag.add_theme_font_size_override("font_size", 13)
    _lbl_tag.add_theme_color_override("font_color", C_AZUL)
    info_vbox.add_child(_lbl_tag)

    _lbl_lider = Label.new()
    _lbl_lider.text = "Lider: ..."
    _lbl_lider.add_theme_font_size_override("font_size", 12)
    _lbl_lider.add_theme_color_override("font_color", C_TENUE)
    info_vbox.add_child(_lbl_lider)

    var info2_hbox = HBoxContainer.new()
    info2_hbox.add_theme_constant_override("separation", 16)
    info_vbox.add_child(info2_hbox)

    _lbl_miembros_count = _mini_lbl(info2_hbox, "👥 ... miembros")
    _lbl_fundacion      = _mini_lbl(info2_hbox, "📅 ...")

    var btn_cerrar = Button.new()
    btn_cerrar.text = "✕"
    btn_cerrar.custom_minimum_size = Vector2(36, 36)
    btn_cerrar.add_theme_font_size_override("font_size", 16)
    btn_cerrar.pressed.connect(_cerrar)
    h_hbox.add_child(btn_cerrar)


func _mini_lbl(parent: HBoxContainer, texto: String) -> Label:
    var lbl = Label.new()
    lbl.text = texto
    lbl.add_theme_font_size_override("font_size", 11)
    lbl.add_theme_color_override("font_color", C_TENUE)
    parent.add_child(lbl)
    return lbl


func _construir_tabs(parent: VBoxContainer) -> void:
    var tabs_panel = PanelContainer.new()
    var style_t = StyleBoxFlat.new()
    style_t.bg_color     = Color(0.13, 0.10, 0.05, 1)
    style_t.border_color = C_BORDE
    style_t.border_width_bottom = 2
    tabs_panel.add_theme_stylebox_override("panel", style_t)
    parent.add_child(tabs_panel)

    var tabs_hbox = HBoxContainer.new()
    tabs_hbox.add_theme_constant_override("separation", 0)
    tabs_panel.add_child(tabs_hbox)

    var nombres = ["⚔ General", "👥 Miembros", "📜 Descripcion", "⚙ Opciones"]
    for i in range(nombres.size()):
        var btn = Button.new()
        btn.text = nombres[i]
        btn.custom_minimum_size = Vector2(0, 36)
        btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        btn.add_theme_font_size_override("font_size", 12)
        btn.flat = true
        var idx = i
        btn.pressed.connect(func(): _cambiar_tab(idx))
        tabs_hbox.add_child(btn)
        _tabs.append(btn)

    _actualizar_estilo_tabs()


func _cambiar_tab(idx: int) -> void:
    _tab_activa = idx
    for i in range(_panels.size()):
        _panels[i].visible = (i == idx)
    _actualizar_estilo_tabs()


func _actualizar_estilo_tabs() -> void:
    for i in range(_tabs.size()):
        if i == _tab_activa:
            _tabs[i].add_theme_color_override("font_color", C_ORO)
        else:
            _tabs[i].add_theme_color_override("font_color", C_TENUE)


func _construir_contenido(parent: VBoxContainer) -> void:
    var contenido = MarginContainer.new()
    contenido.size_flags_vertical = Control.SIZE_EXPAND_FILL
    contenido.add_theme_constant_override("margin_left",   14)
    contenido.add_theme_constant_override("margin_right",  14)
    contenido.add_theme_constant_override("margin_top",    10)
    contenido.add_theme_constant_override("margin_bottom", 14)
    parent.add_child(contenido)

    var stack = Control.new()
    stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stack.size_flags_vertical   = Control.SIZE_EXPAND_FILL
    contenido.add_child(stack)

    _panels.append(_construir_panel_general(stack))
    _panels.append(_construir_panel_miembros(stack))
    _panels.append(_construir_panel_descripcion(stack))
    _panels.append(_construir_panel_opciones(stack))

    _cambiar_tab(0)


func _construir_panel_general(parent: Control) -> Control:
    var scroll = ScrollContainer.new()
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    parent.add_child(scroll)

    var vbox = VBoxContainer.new()
    vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vbox.add_theme_constant_override("separation", 10)
    scroll.add_child(vbox)

    _agregar_titulo_seccion(vbox, "🏴 Estandarte del Clan")
    var card_est = _crear_card(vbox)
    _lbl_fundacion = _agregar_fila_info(card_est, "Fundado por:", "...")
    _agregar_fila_info(card_est, "Fecha de fundacion:", "...")

    vbox.add_child(HSeparator.new())
    _agregar_titulo_seccion(vbox, "📊 Estadisticas del Clan")
    var card_stats = _crear_card(vbox)
    _lbl_pvp   = _agregar_fila_info(card_stats, "⚔ Puntos PvP:",       "0")
    _lbl_xp    = _agregar_fila_info(card_stats, "📚 XP Total:",         "0")
    _lbl_craft = _agregar_fila_info(card_stats, "⚒ Puntos Artesano:",   "0")

    vbox.add_child(HSeparator.new())
    _agregar_titulo_seccion(vbox, "🏅 Medallas")
    _medallas_hbox = HBoxContainer.new()
    _medallas_hbox.add_theme_constant_override("separation", 8)
    vbox.add_child(_medallas_hbox)

    return scroll


func _agregar_titulo_seccion(parent: VBoxContainer, texto: String) -> void:
    var lbl = Label.new()
    lbl.text = texto
    lbl.add_theme_font_size_override("font_size", 14)
    lbl.add_theme_color_override("font_color", C_TITULO)
    parent.add_child(lbl)


func _crear_card(parent: VBoxContainer) -> VBoxContainer:
    var card = PanelContainer.new()
    var style = StyleBoxFlat.new()
    style.bg_color     = C_PANEL
    style.border_color = C_BORDE
    style.border_width_left   = 1
    style.border_width_right  = 1
    style.border_width_top    = 1
    style.border_width_bottom = 1
    style.corner_radius_top_left     = 4
    style.corner_radius_top_right    = 4
    style.corner_radius_bottom_left  = 4
    style.corner_radius_bottom_right = 4
    card.add_theme_stylebox_override("panel", style)
    parent.add_child(card)

    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left",   12)
    margin.add_theme_constant_override("margin_right",  12)
    margin.add_theme_constant_override("margin_top",    8)
    margin.add_theme_constant_override("margin_bottom", 8)
    card.add_child(margin)

    var vbox = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 5)
    margin.add_child(vbox)
    return vbox


func _agregar_fila_info(parent: VBoxContainer, etiqueta: String, valor: String) -> Label:
    var hbox = HBoxContainer.new()
    hbox.add_theme_constant_override("separation", 8)
    parent.add_child(hbox)

    var lbl_e = Label.new()
    lbl_e.text = etiqueta
    lbl_e.custom_minimum_size = Vector2(160, 0)
    lbl_e.add_theme_font_size_override("font_size", 12)
    lbl_e.add_theme_color_override("font_color", C_TENUE)
    hbox.add_child(lbl_e)

    var lbl_v = Label.new()
    lbl_v.text = valor
    lbl_v.add_theme_font_size_override("font_size", 12)
    lbl_v.add_theme_color_override("font_color", C_TEXTO)
    lbl_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hbox.add_child(lbl_v)
    return lbl_v


func _construir_panel_miembros(parent: Control) -> Control:
    var scroll = ScrollContainer.new()
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    parent.add_child(scroll)

    var vbox = VBoxContainer.new()
    vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vbox.add_theme_constant_override("separation", 2)
    scroll.add_child(vbox)

    var header_panel = PanelContainer.new()
    var style_h = StyleBoxFlat.new()
    style_h.bg_color = C_HEADER
    style_h.corner_radius_top_left  = 4
    style_h.corner_radius_top_right = 4
    header_panel.add_theme_stylebox_override("panel", style_h)
    vbox.add_child(header_panel)

    var header = HBoxContainer.new()
    header.add_theme_constant_override("separation", 0)
    header_panel.add_child(header)

    _cab_col(header, "#",      28,  false)
    _cab_col(header, "Nombre", 0,   true)
    _cab_col(header, "Nv.",    45,  false)
    _cab_col(header, "Clase",  110, false)

    vbox.add_child(HSeparator.new())

    _lista_miembros = VBoxContainer.new()
    _lista_miembros.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _lista_miembros.add_theme_constant_override("separation", 2)
    vbox.add_child(_lista_miembros)

    return scroll


func _cab_col(parent: HBoxContainer, texto: String, ancho: int, expandir: bool) -> void:
    var lbl = Label.new()
    lbl.text = texto
    lbl.add_theme_font_size_override("font_size", 12)
    lbl.add_theme_color_override("font_color", C_ORO)
    if expandir:
        lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    else:
        lbl.custom_minimum_size = Vector2(ancho, 0)
    parent.add_child(lbl)


func _construir_panel_descripcion(parent: Control) -> Control:
    var scroll = ScrollContainer.new()
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    parent.add_child(scroll)

    var vbox = VBoxContainer.new()
    vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vbox.add_theme_constant_override("separation", 10)
    scroll.add_child(vbox)

    _agregar_titulo_seccion(vbox, "📜 Descripcion Publica")

    var lbl_ayuda = Label.new()
    lbl_ayuda.text = "Aqui pueden escribir los requisitos, reglas y descripcion del clan."
    lbl_ayuda.add_theme_font_size_override("font_size", 11)
    lbl_ayuda.add_theme_color_override("font_color", C_TENUE)
    lbl_ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    vbox.add_child(lbl_ayuda)

    _lbl_descripcion = Label.new()
    _lbl_descripcion.text = "Este clan aun no tiene descripcion."
    _lbl_descripcion.add_theme_font_size_override("font_size", 13)
    _lbl_descripcion.add_theme_color_override("font_color", C_TEXTO)
    _lbl_descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    vbox.add_child(_lbl_descripcion)

    _txt_descripcion = TextEdit.new()
    _txt_descripcion.custom_minimum_size = Vector2(0, 200)
    _txt_descripcion.add_theme_font_size_override("font_size", 13)
    _txt_descripcion.visible = false
    _txt_descripcion.placeholder_text = "Escribi la descripcion del clan: requisitos, reglas, objetivos..."
    vbox.add_child(_txt_descripcion)

    _btn_guardar_desc = Button.new()
    _btn_guardar_desc.text = "✏ Editar descripcion"
    _btn_guardar_desc.visible = false
    _btn_guardar_desc.pressed.connect(_toggle_editar_descripcion)
    vbox.add_child(_btn_guardar_desc)

    return scroll


func _construir_panel_opciones(parent: Control) -> Control:
    var scroll = ScrollContainer.new()
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    parent.add_child(scroll)

    var vbox = VBoxContainer.new()
    vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vbox.add_theme_constant_override("separation", 10)
    scroll.add_child(vbox)

    var lbl_solo_lider = Label.new()
    lbl_solo_lider.name = "LblSoloLider"
    lbl_solo_lider.text = "🔒 Solo el lider del clan puede ver estas opciones."
    lbl_solo_lider.add_theme_font_size_override("font_size", 12)
    lbl_solo_lider.add_theme_color_override("font_color", C_TENUE)
    lbl_solo_lider.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl_solo_lider.visible = false
    vbox.add_child(lbl_solo_lider)

    _agregar_titulo_seccion(vbox, "⚙ Configuracion")
    var card_c = _crear_card(vbox)
    _agregar_opcion_btn(card_c, "✏  Editar descripcion del clan", func(): _cambiar_tab(2))
    _agregar_opcion_btn(card_c, "🏴  Cambiar nombre del clan",    func(): pass)

    _agregar_titulo_seccion(vbox, "👥 Gestion de Miembros")
    var card_m = _crear_card(vbox)
    _agregar_opcion_btn(card_m, "📨  Invitar jugador (proximamente)", func(): pass)
    _agregar_opcion_btn(card_m, "🚪  Expulsar miembro (proximamente)", func(): pass)

    _agregar_titulo_seccion(vbox, "⚠ Zona Peligrosa")
    var card_d = _crear_card(vbox)
    var btn_d = _agregar_opcion_btn(card_d, "💀  Disolver el clan", func(): pass)
    btn_d.add_theme_color_override("font_color", C_ROJO)

    return scroll


func _agregar_opcion_btn(parent: VBoxContainer, texto: String, callback: Callable) -> Button:
    var btn = Button.new()
    btn.text = texto
    btn.flat = true
    btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
    btn.add_theme_font_size_override("font_size", 13)
    btn.add_theme_color_override("font_color", C_AZUL)
    btn.pressed.connect(callback)
    parent.add_child(btn)
    return btn


# ============================================================
# CARGA DE DATOS
# ============================================================
func cargar_clan(clan_id: String) -> void:
    _clan_id = clan_id
    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(func(_r, code, _h, body):
        http.queue_free()
        _on_clan_cargado(code, body)
    )
    http.request(FIREBASE_URL + "/clanes/" + clan_id, _get_headers(), HTTPClient.METHOD_GET)


func _on_clan_cargado(code: int, body: PackedByteArray) -> void:
    if code != 200:
        _lbl_nombre.text = "Error al cargar"
        return

    var json = JSON.new()
    json.parse(body.get_string_from_utf8())
    var data = json.get_data()
    if not data is Dictionary or not data.has("fields"):
        return

    var f = data["fields"]
    var nombre      = _leer_string(f, "nombre")
    var tag         = _leer_string(f, "tag")
    var lider_name  = _leer_string(f, "lider_name")
    var lider_id    = _leer_string(f, "lider_id")
    var created_at  = _leer_string(f, "created_at")
    var descripcion = _leer_string(f, "descripcion")
    var miembros    = _leer_int(f,    "miembros")
    var pvp         = _leer_int(f,    "pvp_points")
    var xp          = _leer_int(f,    "xp_total")
    var craft       = _leer_int(f,    "craft_points")
    var medallas    = _leer_array_strings(f, "medallas")

    _lbl_nombre.text         = nombre
    _lbl_tag.text            = tag
    _lbl_lider.text          = "Lider: " + lider_name
    _lbl_miembros_count.text = "👥 " + str(miembros) + " miembros"
    _lbl_fundacion.text      = "Fundado por: " + lider_name + "  •  " + created_at

    if _lbl_pvp:   _lbl_pvp.text   = str(pvp)   + " pts"
    if _lbl_xp:    _lbl_xp.text    = str(xp)     + " XP"
    if _lbl_craft: _lbl_craft.text = str(craft)  + " pts"

    _lbl_descripcion.text = descripcion if descripcion != "" else "Este clan aun no tiene descripcion."
    if _txt_descripcion: _txt_descripcion.text = descripcion

    _es_lider   = (GameData.player_id == lider_id)
    _es_miembro = (GameData.player_clan_id == _clan_id)

    if _btn_guardar_desc:
        _btn_guardar_desc.visible = _es_lider

    # Mostrar u ocultar la tab Opciones segun si es miembro del clan
    if _tabs.size() > 3:
        _tabs[3].visible = _es_miembro

    if _panels.size() > 3:
        var lbl_lock = _panels[3].find_child("LblSoloLider", true, false)
        if lbl_lock:
            lbl_lock.visible = not _es_lider

    for child in _medallas_hbox.get_children():
        child.queue_free()
    if medallas.is_empty():
        var lbl_nm = Label.new()
        lbl_nm.text = "Sin medallas aun."
        lbl_nm.add_theme_color_override("font_color", C_TENUE)
        lbl_nm.add_theme_font_size_override("font_size", 12)
        _medallas_hbox.add_child(lbl_nm)
    else:
        for med in medallas:
            var lbl_m = Label.new()
            lbl_m.text = "🏅 " + str(med)
            lbl_m.add_theme_font_size_override("font_size", 13)
            _medallas_hbox.add_child(lbl_m)

    _cargar_miembros()


func _cargar_miembros() -> void:
    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(func(_r, code, _h, body):
        http.queue_free()
        _on_miembros_cargados(code, body)
    )
    # Busca jugadores cuyo player_clan_id coincida con este clan
    # Si no hay resultados, _on_miembros_cargados intentara con clan_members
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
    http.request("https://firestore.googleapis.com/v1/projects/atepaia-2v/databases/(default)/documents:runQuery",
        _get_headers(), HTTPClient.METHOD_POST, JSON.stringify(query))


func _cargar_miembros_fallback() -> void:
    # Fallback: buscar en clan_members si players no dio resultados
    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(func(_r, code, _h, body):
        http.queue_free()
        _on_miembros_fallback(code, body)
    )
    var query = {
        "structuredQuery": {
            "from": [{"collectionId": "clan_members"}],
            "where": {
                "fieldFilter": {
                    "field": {"fieldPath": "clan_id"},
                    "op": "EQUAL",
                    "value": {"stringValue": _clan_id}
                }
            },
            "limit": 50
        }
    }
    http.request("https://firestore.googleapis.com/v1/projects/atepaia-2v/databases/(default)/documents:runQuery",
        _get_headers(), HTTPClient.METHOD_POST, JSON.stringify(query))


func _on_miembros_fallback(code: int, body: PackedByteArray) -> void:
    if code != 200: return
    var json = JSON.new()
    json.parse(body.get_string_from_utf8())
    var data = json.get_data()
    if not data is Array: return

    for child in _lista_miembros.get_children():
        child.queue_free()

    var pos = 1
    for entry in data:
        if not entry.has("document"): continue
        var doc = entry["document"]
        if not doc.has("fields"):    continue
        var f     = doc["fields"]
        var pname = _leer_string(f, "player_name")
        if pname == "": continue

        var fila = PanelContainer.new()
        var style_f = StyleBoxFlat.new()
        style_f.bg_color = Color(0.12, 0.09, 0.05, 1) if pos % 2 == 0 else Color(0.09, 0.07, 0.04, 1)
        style_f.corner_radius_top_left     = 3
        style_f.corner_radius_top_right    = 3
        style_f.corner_radius_bottom_left  = 3
        style_f.corner_radius_bottom_right = 3
        fila.add_theme_stylebox_override("panel", style_f)
        var row = HBoxContainer.new()
        fila.add_child(row)
        var lbl_pos = Label.new()
        lbl_pos.text = str(pos) + "."
        lbl_pos.custom_minimum_size = Vector2(28, 0)
        lbl_pos.add_theme_font_size_override("font_size", 11)
        lbl_pos.add_theme_color_override("font_color", C_TENUE)
        row.add_child(lbl_pos)
        var lbl_n = Label.new()
        lbl_n.text = pname
        lbl_n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        lbl_n.add_theme_font_size_override("font_size", 12)
        lbl_n.add_theme_color_override("font_color", C_AZUL)
        row.add_child(lbl_n)
        _lista_miembros.add_child(fila)
        pos += 1

    if pos == 1:
        var lbl_v = Label.new()
        lbl_v.text = "No se encontraron miembros. Pedi a los miembros que vuelvan a ingresar al juego."
        lbl_v.add_theme_color_override("font_color", C_TENUE)
        lbl_v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        _lista_miembros.add_child(lbl_v)


func _on_miembros_cargados(code: int, body: PackedByteArray) -> void:
    if code != 200: return
    var json = JSON.new()
    json.parse(body.get_string_from_utf8())
    var data = json.get_data()
    if not data is Array: return

    for child in _lista_miembros.get_children():
        child.queue_free()

    var pos = 1
    for entry in data:
        if not entry.has("document"): continue
        var doc = entry["document"]
        if not doc.has("fields"):    continue

        var f      = doc["fields"]
        var pname  = _leer_string(f, "username")
        if pname == "": pname = _leer_string(f, "player_name")
        if pname == "": pname = "Jugador"
        var plevel = _leer_int(f, "level")
        var pclass = _leer_string(f, "class")
        if pclass == "": pclass = _leer_string(f, "player_class")
        var partes = doc.get("name", "").split("/")
        var pid    = partes[partes.size() - 1]
        var es_yo  = (pid == GameData.player_id)

        var fila = PanelContainer.new()
        var style_f = StyleBoxFlat.new()
        style_f.bg_color = Color(0.12, 0.09, 0.05, 1) if pos % 2 == 0 else Color(0.09, 0.07, 0.04, 1)
        if es_yo:
            style_f.bg_color     = Color(0.10, 0.20, 0.10, 1)
            style_f.border_color = C_VERDE
            style_f.border_width_left = 2
        style_f.corner_radius_top_left     = 3
        style_f.corner_radius_top_right    = 3
        style_f.corner_radius_bottom_left  = 3
        style_f.corner_radius_bottom_right = 3
        fila.add_theme_stylebox_override("panel", style_f)

        var row = HBoxContainer.new()
        row.add_theme_constant_override("separation", 0)
        fila.add_child(row)

        var lbl_pos = Label.new()
        lbl_pos.text = str(pos) + "."
        lbl_pos.custom_minimum_size = Vector2(28, 0)
        lbl_pos.add_theme_font_size_override("font_size", 11)
        lbl_pos.add_theme_color_override("font_color", C_TENUE)
        row.add_child(lbl_pos)

        var btn_nom = Button.new()
        btn_nom.text = pname + (" ◀" if es_yo else "")
        btn_nom.flat = true
        btn_nom.alignment = HORIZONTAL_ALIGNMENT_LEFT
        btn_nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        btn_nom.add_theme_font_size_override("font_size", 12)
        btn_nom.add_theme_color_override("font_color", C_VERDE if es_yo else C_AZUL)
        var pid_c = pid
        btn_nom.pressed.connect(func(): _abrir_perfil_jugador(pid_c))
        row.add_child(btn_nom)

        var lbl_nv = Label.new()
        lbl_nv.text = str(plevel)
        lbl_nv.custom_minimum_size = Vector2(45, 0)
        lbl_nv.add_theme_font_size_override("font_size", 12)
        lbl_nv.add_theme_color_override("font_color", C_TEXTO)
        row.add_child(lbl_nv)

        var lbl_cl = Label.new()
        lbl_cl.text = pclass.capitalize()
        lbl_cl.custom_minimum_size = Vector2(110, 0)
        lbl_cl.add_theme_font_size_override("font_size", 12)
        lbl_cl.add_theme_color_override("font_color", C_TENUE)
        row.add_child(lbl_cl)

        _lista_miembros.add_child(fila)
        pos += 1

    if pos == 1:
        # Sin resultados en players, intentar con clan_members
        _cargar_miembros_fallback()


func _toggle_editar_descripcion() -> void:
    _editando = !_editando
    if _editando:
        _lbl_descripcion.visible = false
        _txt_descripcion.visible = true
        _btn_guardar_desc.text   = "💾 Guardar descripcion"
    else:
        var nueva = _txt_descripcion.text.strip_edges()
        _lbl_descripcion.text    = nueva if nueva != "" else "Este clan aun no tiene descripcion."
        _lbl_descripcion.visible = true
        _txt_descripcion.visible = false
        _btn_guardar_desc.text   = "✏ Editar descripcion"
        _guardar_descripcion(nueva)


func _guardar_descripcion(desc: String) -> void:
    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(func(_r, _c, _h, _b): http.queue_free())
    http.request(FIREBASE_URL + "/clanes/" + _clan_id + "?updateMask.fieldPaths=descripcion",
        _get_headers(), HTTPClient.METHOD_PATCH,
        JSON.stringify({"fields": {"descripcion": {"stringValue": desc}}}))


func _abrir_perfil_jugador(player_id: String) -> void:
    var perfil = preload("res://scenes/player_profile/PlayerProfile.tscn").instantiate()
    get_parent().add_child(perfil)
    perfil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    perfil.z_index = 300
    perfil.cargar_jugador(player_id)


func _cerrar() -> void:
    queue_free()


func _get_headers() -> Array:
    var h = ["Content-Type: application/json"]
    if GameData.id_token != "":
        h.append("Authorization: Bearer " + GameData.id_token)
    return h

func _leer_string(f: Dictionary, k: String) -> String:
    if f.has(k) and f[k].has("stringValue"): return f[k]["stringValue"]
    return ""

func _leer_int(f: Dictionary, k: String) -> int:
    if f.has(k):
        if f[k].has("integerValue"): return int(f[k]["integerValue"])
        if f[k].has("doubleValue"):  return int(f[k]["doubleValue"])
    return 0

func _leer_array_strings(f: Dictionary, k: String) -> Array:
    if f.has(k) and f[k].has("arrayValue"):
        var av = f[k]["arrayValue"]
        if av.has("values"):
            var r: Array = []
            for v in av["values"]:
                if v.has("stringValue"): r.append(v["stringValue"])
            return r
    return []
