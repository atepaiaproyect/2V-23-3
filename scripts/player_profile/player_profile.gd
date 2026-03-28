extends Control

# ─────────────────────────────────────────────────────────
# PLAYER PROFILE — Perfil público de otro jugador
# Muestra: atributos, equipo, descripción pública, clan
# Pestaña 2: logros del jugador
# ─────────────────────────────────────────────────────────

var _player_data: Dictionary = {}
var _player_id:   String = ""
var _http:        HTTPRequest

# UI
var _tab_perfil:   Button
var _tab_logros:   Button
var _panel_perfil: Control
var _panel_logros: Control
var _lbl_nombre:   Label
var _lbl_nivel:    Label
var _lbl_clan:     Label
var _lbl_bio:      Label
var _vbox_attrs:   VBoxContainer
var _vbox_logros:  VBoxContainer
var _lbl_status:   Label

func _ready() -> void:
    _http = HTTPRequest.new()
    add_child(_http)
    _http.request_completed.connect(_on_http)
    _construir_ui()

func cargar_jugador(player_id: String) -> void:
    _player_id = player_id
    _lbl_status.text = "Cargando perfil..."
    var url = GameData.FIRESTORE_URL + "players/" + player_id
    var headers = PackedStringArray([
        "Content-Type: application/json",
        "Authorization: Bearer " + GameData.id_token
    ])
    _http.request(url, headers, HTTPClient.METHOD_GET)

# ─────────────────────────────────────
# UI
# ─────────────────────────────────────
func _construir_ui() -> void:
    var bg = ColorRect.new()
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.color = Color(0.06, 0.04, 0.03, 0.97)
    add_child(bg)

    var vbox_main = VBoxContainer.new()
    vbox_main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    vbox_main.add_theme_constant_override("separation", 0)
    add_child(vbox_main)

    # Header con nombre y botón cerrar
    var header = HBoxContainer.new()
    header.add_theme_constant_override("separation", 10)
    vbox_main.add_child(header)

    var header_margin = MarginContainer.new()
    header_margin.add_theme_constant_override("margin_left",  14)
    header_margin.add_theme_constant_override("margin_right", 14)
    header_margin.add_theme_constant_override("margin_top",   10)
    header_margin.add_theme_constant_override("margin_bottom",6)
    header_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vbox_main.add_child(header_margin)

    var header_hbox = HBoxContainer.new()
    header_margin.add_child(header_hbox)

    _lbl_nombre = _lbl("Cargando...", 18, Color(0.9, 0.75, 0.3, 1))
    _lbl_nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header_hbox.add_child(_lbl_nombre)

    var btn_cerrar = Button.new()
    btn_cerrar.text = "✕"
    btn_cerrar.add_theme_font_size_override("font_size", 16)
    btn_cerrar.pressed.connect(queue_free)
    header_hbox.add_child(btn_cerrar)

    # Info rápida
    var info_margin = MarginContainer.new()
    info_margin.add_theme_constant_override("margin_left", 14)
    info_margin.add_theme_constant_override("margin_right", 14)
    vbox_main.add_child(info_margin)

    var info_vbox = VBoxContainer.new()
    info_vbox.add_theme_constant_override("separation", 3)
    info_margin.add_child(info_vbox)

    _lbl_nivel = _lbl("", 12, Color(0.7, 0.85, 1.0, 1))
    info_vbox.add_child(_lbl_nivel)

    _lbl_clan = _lbl("", 12, Color(0.6, 0.8, 1.0, 1))
    _lbl_clan.mouse_filter = Control.MOUSE_FILTER_STOP
    info_vbox.add_child(_lbl_clan)

    _lbl_status = _lbl("", 10, Color(0.5, 0.5, 0.5, 1))
    info_vbox.add_child(_lbl_status)

    # Botones de acción
    var btns_margin = MarginContainer.new()
    btns_margin.add_theme_constant_override("margin_left",  14)
    btns_margin.add_theme_constant_override("margin_right", 14)
    btns_margin.add_theme_constant_override("margin_top",   6)
    btns_margin.add_theme_constant_override("margin_bottom",6)
    vbox_main.add_child(btns_margin)

    var btns_hbox = HBoxContainer.new()
    btns_hbox.add_theme_constant_override("separation", 10)
    btns_margin.add_child(btns_hbox)

    var btn_atacar = Button.new()
    btn_atacar.text = "⚔  Atacar"
    btn_atacar.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1))
    btn_atacar.add_theme_font_size_override("font_size", 12)
    btn_atacar.pressed.connect(_on_atacar)
    btns_hbox.add_child(btn_atacar)

    var btn_mensaje = Button.new()
    btn_mensaje.text = "💬  Mensaje"
    btn_mensaje.add_theme_font_size_override("font_size", 12)
    btn_mensaje.pressed.connect(_on_mensaje)
    btns_hbox.add_child(btn_mensaje)

    vbox_main.add_child(HSeparator.new())

    # Tabs
    var tabs_margin = MarginContainer.new()
    tabs_margin.add_theme_constant_override("margin_left", 14)
    tabs_margin.add_theme_constant_override("margin_right", 14)
    tabs_margin.add_theme_constant_override("margin_top", 6)
    vbox_main.add_child(tabs_margin)

    var tabs_hbox = HBoxContainer.new()
    tabs_margin.add_child(tabs_hbox)

    _tab_perfil = Button.new()
    _tab_perfil.text = "👤  Perfil"
    _tab_perfil.add_theme_font_size_override("font_size", 12)
    _tab_perfil.pressed.connect(func(): _mostrar_tab(true))
    tabs_hbox.add_child(_tab_perfil)

    _tab_logros = Button.new()
    _tab_logros.text = "🏆  Logros"
    _tab_logros.add_theme_font_size_override("font_size", 12)
    _tab_logros.pressed.connect(func(): _mostrar_tab(false))
    tabs_hbox.add_child(_tab_logros)

    # Scroll contenido
    var scroll = ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vbox_main.add_child(scroll)

    var contenido = VBoxContainer.new()
    contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(contenido)

    var contenido_margin = MarginContainer.new()
    contenido_margin.add_theme_constant_override("margin_left",   14)
    contenido_margin.add_theme_constant_override("margin_right",  14)
    contenido_margin.add_theme_constant_override("margin_top",    8)
    contenido_margin.add_theme_constant_override("margin_bottom", 14)
    contenido.add_child(contenido_margin)

    var contenido_inner = VBoxContainer.new()
    contenido_inner.add_theme_constant_override("separation", 10)
    contenido_margin.add_child(contenido_inner)

    # Panel Perfil
    _panel_perfil = VBoxContainer.new()
    _panel_perfil.add_theme_constant_override("separation", 8)
    contenido_inner.add_child(_panel_perfil)

    _lbl_bio = _lbl("", 11, Color(0.75, 0.7, 0.6, 1))
    _lbl_bio.autowrap_mode = TextServer.AUTOWRAP_WORD
    _panel_perfil.add_child(_lbl_bio)

    _panel_perfil.add_child(HSeparator.new())

    var lbl_attrs = _lbl("ATRIBUTOS", 11, Color(0.6, 0.6, 0.55, 1))
    _panel_perfil.add_child(lbl_attrs)

    _vbox_attrs = VBoxContainer.new()
    _vbox_attrs.add_theme_constant_override("separation", 3)
    _panel_perfil.add_child(_vbox_attrs)

    # Panel Logros
    _panel_logros = VBoxContainer.new()
    _panel_logros.add_theme_constant_override("separation", 6)
    _panel_logros.visible = false
    contenido_inner.add_child(_panel_logros)

    _vbox_logros = VBoxContainer.new()
    _vbox_logros.add_theme_constant_override("separation", 4)
    _panel_logros.add_child(_vbox_logros)

func _mostrar_tab(es_perfil: bool) -> void:
    _panel_perfil.visible = es_perfil
    _panel_logros.visible = not es_perfil

# ─────────────────────────────────────
# HTTP
# ─────────────────────────────────────
func _on_http(_result, response_code, _headers_r, body) -> void:
    if response_code != 200:
        _lbl_status.text = "No se pudo cargar el perfil."
        return
    var data = JSON.parse_string(body.get_string_from_utf8())
    if data == null or not data.has("fields"):
        _lbl_status.text = "Perfil no encontrado."
        return
    _player_data = data["fields"]
    _poblar_ui()

func _poblar_ui() -> void:
    var f = _player_data
    var nombre  = f.get("username",    {}).get("stringValue", "???")
    var nivel   = int(f.get("level",   {}).get("integerValue", "1"))
    var clase   = f.get("class",       {}).get("stringValue", "")
    var bio     = f.get("public_bio",  {}).get("stringValue", "Sin descripción.")
    var clan_n  = f.get("player_clan_name", {}).get("stringValue", "")
    var clan_t  = f.get("player_clan_tag",  {}).get("stringValue", "")
    var clan_id = f.get("player_clan_id",   {}).get("stringValue", "")

    _lbl_nombre.text = nombre
    _lbl_nivel.text  = "Nivel " + str(nivel) + "  •  " + clase.capitalize()
    _lbl_clan.text   = (clan_t + "  " + clan_n) if clan_n != "" else "Sin clan"
    _lbl_bio.text    = "\"" + bio + "\""
    _lbl_status.text = ""

    # Hacer el clan clickeable solo si tiene clan_id válido
    if clan_id != "":
        _lbl_clan.mouse_filter = Control.MOUSE_FILTER_STOP
        _lbl_clan.add_theme_color_override("font_color", Color(0.55, 0.88, 1.0, 1))
        _lbl_clan.tooltip_text = "Ver perfil del clan"
        if _lbl_clan.gui_input.is_connected(_on_lbl_clan_click):
            _lbl_clan.gui_input.disconnect(_on_lbl_clan_click)
        _lbl_clan.gui_input.connect(_on_lbl_clan_click.bind(clan_id))
    else:
        _lbl_clan.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _lbl_clan.tooltip_text = ""
        if _lbl_clan.gui_input.is_connected(_on_lbl_clan_click):
            _lbl_clan.gui_input.disconnect(_on_lbl_clan_click)
        _lbl_clan.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))

    # Atributos
    for child in _vbox_attrs.get_children(): child.queue_free()
    var attrs = [
        ["⚔ Fuerza",      "attr_strength"],
        ["🦅 Agilidad",   "attr_agility"],
        ["🎯 Destreza",   "attr_dexterity"],
        ["🛡 Constitución","attr_constitution"],
        ["📚 Inteligencia","attr_intelligence"],
        ["👑 Carisma",    "attr_charisma"],
    ]
    for pair in attrs:
        var val = int(f.get(pair[1], {}).get("integerValue", "2"))
        var hbox = HBoxContainer.new()
        hbox.add_theme_constant_override("separation", 8)
        var lbl_n = _lbl(pair[0], 11, Color(0.7, 0.7, 0.6, 1))
        lbl_n.custom_minimum_size = Vector2(120, 0)
        hbox.add_child(lbl_n)
        hbox.add_child(_lbl(str(val), 11, Color(0.9, 0.85, 0.7, 1)))
        _vbox_attrs.add_child(hbox)

    # Logros
    for child in _vbox_logros.get_children(): child.queue_free()
    var logros_raw = f.get("achievements_unlocked", {}).get("arrayValue", {})
    var logros_lista: Array = []
    if logros_raw.has("values"):
        for v in logros_raw["values"]:
            logros_lista.append(v.get("stringValue", ""))

    var lbl_count = _lbl("Logros desbloqueados: " + str(logros_lista.size()) + " / 100", 12, Color(0.9, 0.75, 0.3, 1))
    _vbox_logros.add_child(lbl_count)

    if logros_lista.is_empty():
        _vbox_logros.add_child(_lbl("Este jugador aún no desbloqueó ningún logro.", 11, Color(0.5,0.5,0.5,1)))
    else:
        for ach_id in logros_lista:
            var ach_data = AchievementManager.get_progress(ach_id)
            if ach_data.is_empty(): continue
            var hbox = HBoxContainer.new()
            hbox.add_theme_constant_override("separation", 8)
            hbox.add_child(_lbl(ach_data.get("icono","🏆"), 14, Color.WHITE))
            hbox.add_child(_lbl(ach_data.get("nombre","?"), 12, Color(0.9,0.85,0.7,1)))
            _vbox_logros.add_child(hbox)

# ─────────────────────────────────────
# ACCIONES
# ─────────────────────────────────────
func _on_atacar() -> void:
    if _player_data.is_empty():
        return
    # Usar el sistema de clasificación — ataque fuera de liga
    var rival = {
        "player_id": _player_id,
        "nombre":    _player_data.get("username",{}).get("stringValue","?"),
        "nivel":     int(_player_data.get("level",{}).get("integerValue","1")),
        "hp":        int(_player_data.get("hp",{}).get("integerValue","100")),
        "hp_max":    int(_player_data.get("hp_max",{}).get("integerValue","100")),
    }
    var ficha = {
        "nombre":            rival["nombre"],
        "nivel":             rival["nivel"],
        "hp":                rival["hp"],
        "hp_max":            rival["hp_max"],
        "ataque_min":        5 + rival["nivel"] * 2,
        "ataque_max":        10 + rival["nivel"] * 4,
        "armadura":          rival["nivel"] * 8,
        "crit_chance":       0.05, "crit_damage": 1.5,
        "dodge_chance":      0.05, "block_chance": 0.05,
        "block_reduction":   1.0,  "double_hit_chance": 0.05,
        "resist_mortal":     0.0,
    }
    var yo       = CombatEngine.get_ficha_jugador()
    var resultado = CombatEngine.run_pvp(yo, ficha)
    if resultado.get("jugador_gano", false):
        GameData.xp += 2; GameData.xp_total += 2
        SaveManager.save_clan_stats(2, 0, 0, 0)
    SaveManager.save_progress()
    AchievementManager.check_all()
    _lbl_status.text = ("⚔ Victoria +2 XP" if resultado.get("jugador_gano",false) else "💀 Derrota") + " vs " + rival["nombre"]

func _on_mensaje() -> void:
    # Por ahora abre el chat del clan si es del mismo clan — futuro: mensajes privados
    _lbl_status.text = "💬 Mensajes privados — próximamente."

func _lbl(txt: String, size: int, color: Color) -> Label:
    var l = Label.new()
    l.text = txt
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    return l

func _on_lbl_clan_click(event: InputEvent, clan_id: String) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _abrir_perfil_clan(clan_id)

func _abrir_perfil_clan(clan_id: String) -> void:
    if clan_id == "":
        return
    var script = load("res://scripts/clan_profile/clan_profile.gd")
    if script == null:
        print("ERROR: No se encuentra clan_profile.gd")
        return
    var perfil = Control.new()
    perfil.set_script(script)
    get_parent().add_child(perfil)
    perfil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    perfil.z_index = 200
    perfil.cargar_clan(clan_id)
