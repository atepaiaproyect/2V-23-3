extends Control

# ─────────────────────────────────────────────────────────
# CLASIFICACIÓN — Tabla global con columnas fijas
# ─────────────────────────────────────────────────────────

const COL_WIDTHS = {
    "pos":    32,
    "nombre": 160,
    "nivel":  40,
    "liga":   65,
    "kills":  50,
    "oro":    70,
    "craft":  60,
    "clan":   60,
    "btn":    40,
}

var _http:      HTTPRequest
var _jugadores: Array = []
var _filtro:    String = ""

var _vbox_tabla:   VBoxContainer
var _input_buscar: LineEdit
var _lbl_status:   Label

func _ready() -> void:
    _http = HTTPRequest.new()
    add_child(_http)
    _http.request_completed.connect(_on_http)
    _construir_ui()
    _cargar_jugadores()

func _construir_ui() -> void:
    var bg = ColorRect.new()
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.color = Color(0.05, 0.03, 0.02, 1)
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
    margin.add_theme_constant_override("margin_top",    12)
    margin.add_theme_constant_override("margin_bottom", 14)
    outer.add_child(margin)

    var inner = VBoxContainer.new()
    inner.add_theme_constant_override("separation", 8)
    margin.add_child(inner)

    var lbl_titulo = _lbl("📊  CLASIFICACIÓN GENERAL", 18, Color(0.9, 0.75, 0.3, 1))
    lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    inner.add_child(lbl_titulo)

    var lbl_desc = _lbl("Historial completo del servidor. Atacar fuera de liga otorga solo 2 XP.", 11, Color(0.55, 0.55, 0.5, 1))
    lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
    inner.add_child(lbl_desc)

    # Buscador
    var hbox_buscar = HBoxContainer.new()
    inner.add_child(hbox_buscar)
    _input_buscar = LineEdit.new()
    _input_buscar.placeholder_text = "🔍  Buscar jugador por nombre..."
    _input_buscar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _input_buscar.add_theme_font_size_override("font_size", 12)
    _input_buscar.text_changed.connect(func(t): _filtro = t.strip_edges().to_lower(); _poblar_tabla())
    hbox_buscar.add_child(_input_buscar)

    _lbl_status = _lbl("Cargando...", 11, Color(0.5, 0.5, 0.5, 1))
    _lbl_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    inner.add_child(_lbl_status)

    inner.add_child(HSeparator.new())
    inner.add_child(_crear_cabecera())
    inner.add_child(HSeparator.new())

    _vbox_tabla = VBoxContainer.new()
    _vbox_tabla.add_theme_constant_override("separation", 2)
    inner.add_child(_vbox_tabla)

func _crear_cabecera() -> HBoxContainer:
    var hbox = HBoxContainer.new()
    hbox.add_theme_constant_override("separation", 0)
    var cols = [
        { "txt": "#",        "key": "pos",    "color": Color(0.7, 0.65, 0.5, 1) },
        { "txt": "Nombre",   "key": "nombre", "color": Color(0.9, 0.75, 0.3, 1) },
        { "txt": "Nv.",      "key": "nivel",  "color": Color(0.7, 0.65, 0.5, 1) },
        { "txt": "Liga",     "key": "liga",   "color": Color(0.6, 0.75, 0.9, 1) },
        { "txt": "Kills",    "key": "kills",  "color": Color(0.9, 0.3,  0.3, 1) },
        { "txt": "Oro rob.", "key": "oro",    "color": Color(1.0, 0.85, 0.2, 1) },
        { "txt": "Craft",    "key": "craft",  "color": Color(0.4, 0.9,  0.5, 1) },
        { "txt": "Clan",     "key": "clan",   "color": Color(0.6, 0.8,  1.0, 1) },
        { "txt": "",         "key": "btn",    "color": Color.WHITE               },
    ]
    for col in cols:
        var lbl = _lbl(col["txt"], 11, col["color"])
        lbl.custom_minimum_size = Vector2(COL_WIDTHS[col["key"]], 0)
        lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL if col["key"] == "nombre" else Control.SIZE_SHRINK_BEGIN
        hbox.add_child(lbl)
    return hbox

func _cargar_jugadores() -> void:
    _lbl_status.text = "Cargando..."
    var url = "https://firestore.googleapis.com/v1/projects/" + GameData.FIREBASE_PROJECT_ID
    url += "/databases/(default)/documents:runQuery"
    var query = {
        "structuredQuery": {
            "from": [{ "collectionId": "players" }],
            "orderBy": [{ "field": { "fieldPath": "level" }, "direction": "DESCENDING" }],
            "limit": 200
        }
    }
    var headers = PackedStringArray(["Content-Type: application/json",
        "Authorization: Bearer " + GameData.id_token])
    if _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
        _http.cancel_request()
    _http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(query))

func _on_http(_result, response_code, _headers_r, body) -> void:
    if response_code != 200:
        _lbl_status.text = "Error al cargar. Código: " + str(response_code)
        return
    var data = JSON.parse_string(body.get_string_from_utf8())
    _jugadores = []
    if data != null:
        for doc in data:
            if doc.has("document") and doc["document"].has("fields"):
                var f = doc["document"]["fields"]
                var parts = doc["document"]["name"].split("/")
                _jugadores.append({
                    "player_id":    parts[parts.size()-1],
                    "nombre":       f.get("username",     {}).get("stringValue", "???"),
                    "nivel":        int(f.get("level",    {}).get("integerValue", "1")),
                    "pvp_kills":    int(f.get("pvp_kills",{}).get("integerValue", "0")),
                    "gold_stolen":  int(f.get("gold_stolen",{}).get("integerValue","0")),
                    "craft_points": int(f.get("craft_points",{}).get("integerValue","0")),
                    "clan_tag":     f.get("clan_tag",     {}).get("stringValue", "-"),
                    "hp":           int(f.get("hp",       {}).get("integerValue","100")),
                    "hp_max":       int(f.get("hp_max",   {}).get("integerValue","100")),
                })
    _lbl_status.text = str(_jugadores.size()) + " jugadores en el servidor"
    _poblar_tabla()

func _poblar_tabla() -> void:
    for child in _vbox_tabla.get_children():
        child.queue_free()
    var lista = _jugadores.filter(func(j):
        return _filtro == "" or _filtro in j["nombre"].to_lower()
    )
    if lista.is_empty():
        _vbox_tabla.add_child(_lbl("Sin resultados.", 11, Color(0.5,0.5,0.5,1)))
        return
    for i in range(lista.size()):
        _vbox_tabla.add_child(_crear_fila(i + 1, lista[i]))

func _crear_fila(pos: int, j: Dictionary) -> PanelContainer:
    var es_yo  = j["player_id"] == GameData.player_id
    var panel  = PanelContainer.new()

    if es_yo:
        var style = StyleBoxFlat.new()
        style.bg_color        = Color(0.08, 0.18, 0.08, 0.7)
        style.border_color    = Color(0.3, 0.8, 0.3, 0.8)
        style.border_width_left   = 2
        style.border_width_right  = 2
        style.border_width_top    = 1
        style.border_width_bottom = 1
        panel.add_theme_stylebox_override("panel", style)

    var m = MarginContainer.new()
    m.add_theme_constant_override("margin_left",   6)
    m.add_theme_constant_override("margin_right",  6)
    m.add_theme_constant_override("margin_top",    4)
    m.add_theme_constant_override("margin_bottom", 4)
    panel.add_child(m)

    var hbox = HBoxContainer.new()
    hbox.add_theme_constant_override("separation", 0)
    m.add_child(hbox)

    # — Posición —
    var medallas = ["🥇","🥈","🥉"]
    var pos_txt  = medallas[pos-1] if pos <= 3 else str(pos) + "."
    var c_pos    = Color(1.0,0.85,0.2,1) if pos <= 3 else Color(0.55,0.55,0.5,1)
    hbox.add_child(_celda(pos_txt, "pos", 12, c_pos, false))

    # — Nombre —
    var c_nom = Color(0.3, 0.9, 0.3, 1) if es_yo else Color(0.9, 0.85, 0.7, 1)
    var nom   = j["nombre"] + (" ◀" if es_yo else "")
    hbox.add_child(_celda(nom, "nombre", 12, c_nom, true))

    # — Nivel —
    hbox.add_child(_celda(str(j["nivel"]), "nivel", 11, Color(0.7,0.85,1.0,1), false))

    # — Liga —
    var liga_n   = max(1, ceili(float(j["nivel"]) / 10.0))
    var liga_txt = str((liga_n-1)*10+1) + "-" + str(liga_n*10)
    hbox.add_child(_celda(liga_txt, "liga", 10, Color(0.6,0.75,0.9,1), false))

    # — Kills —
    hbox.add_child(_celda(str(j["pvp_kills"]), "kills", 11, Color(0.9,0.3,0.3,1), false))

    # — Oro robado —
    hbox.add_child(_celda(_fmt(j["gold_stolen"]), "oro", 11, Color(1.0,0.85,0.2,1), false))

    # — Crafteo —
    hbox.add_child(_celda(str(j["craft_points"]), "craft", 11, Color(0.4,0.9,0.5,1), false))

    # — Clan —
    hbox.add_child(_celda(j.get("clan_tag", "-"), "clan", 10, Color(0.6,0.8,1.0,1), false))

    # — Botón atacar —
    if not es_yo:
        var btn = Button.new()
        btn.text = "⚔"
        btn.custom_minimum_size = Vector2(COL_WIDTHS["btn"], 28)
        btn.add_theme_font_size_override("font_size", 14)
        btn.tooltip_text = "Atacar (fuera de liga: solo 2 XP)"
        btn.pressed.connect(_on_atacar.bind(j))
        hbox.add_child(btn)
    else:
        hbox.add_child(_celda("", "btn", 11, Color.WHITE, false))

    return panel

func _celda(txt: String, col_key: String, size: int, color: Color, expandir: bool) -> Label:
    var l = _lbl(txt, size, color)
    l.custom_minimum_size = Vector2(COL_WIDTHS.get(col_key, 60), 0)
    l.clip_text = true
    l.size_flags_horizontal = Control.SIZE_EXPAND_FILL if expandir else Control.SIZE_SHRINK_BEGIN
    return l

func _on_atacar(j: Dictionary) -> void:
    var ficha = {
        "nombre": j.get("nombre","?"), "nivel": j.get("nivel",1),
        "hp": j.get("hp",100), "hp_max": j.get("hp_max",100),
        "ataque_min": 5 + j.get("nivel",1) * 2,
        "ataque_max": 10 + j.get("nivel",1) * 4,
        "armadura": j.get("nivel",1) * 8,
        "crit_chance": 0.05, "crit_damage": 1.5, "dodge_chance": 0.05,
        "block_chance": 0.05, "block_reduction": 1.0,
        "double_hit_chance": 0.05, "resist_mortal": 0.0,
    }
    var yo       = CombatEngine.get_ficha_jugador()
    var resultado = CombatEngine.run_pvp(yo, ficha)
    if resultado.get("jugador_gano", false):
        GameData.xp += 2; GameData.xp_total += 2
        SaveManager.save_clan_stats(2, 0, 0, 0)
    SaveManager.save_progress()
    _lbl_status.text = ("✔ Victoria" if resultado.get("jugador_gano",false) else "✖ Derrota") + \
        " vs " + j.get("nombre","?") + (" (+2 XP)" if resultado.get("jugador_gano",false) else "")

func _fmt(n: int) -> String:
    if n >= 1_000_000: return str(snappedf(float(n)/1_000_000.0,0.1)) + "M"
    elif n >= 1_000:   return str(snappedf(float(n)/1_000.0,0.1)) + "K"
    return str(n)

func _lbl(txt: String, size: int, color: Color) -> Label:
    var l = Label.new()
    l.text = txt
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    return l
