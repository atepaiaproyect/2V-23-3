extends Control

# ─────────────────────────────────────────────────────────
# CLASIFICACIÓN — Tabla global de todos los jugadores
# Ordenada por nivel DESC. Permite atacar a cualquiera
# (sin recompensa de liga, solo 2 XP)
# ─────────────────────────────────────────────────────────

var _http:      HTTPRequest
var _jugadores: Array = []
var _filtro:    String = ""

var _scroll:     ScrollContainer
var _vbox_tabla: VBoxContainer
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

    _scroll = ScrollContainer.new()
    _scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(_scroll)

    var outer = VBoxContainer.new()
    outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _scroll.add_child(outer)

    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left",   14)
    margin.add_theme_constant_override("margin_right",  14)
    margin.add_theme_constant_override("margin_top",    12)
    margin.add_theme_constant_override("margin_bottom", 14)
    outer.add_child(margin)

    var inner = VBoxContainer.new()
    inner.add_theme_constant_override("separation", 10)
    margin.add_child(inner)

    # Título
    var lbl_titulo = _lbl("📊  CLASIFICACIÓN GENERAL", 18, Color(0.9, 0.75, 0.3, 1))
    lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    inner.add_child(lbl_titulo)

    var lbl_desc = _lbl("Historial completo del servidor. Podés atacar a cualquier jugador.", 11, Color(0.6, 0.6, 0.55, 1))
    lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
    inner.add_child(lbl_desc)

    # Buscador
    var hbox_buscar = HBoxContainer.new()
    hbox_buscar.add_theme_constant_override("separation", 8)
    inner.add_child(hbox_buscar)

    _input_buscar = LineEdit.new()
    _input_buscar.placeholder_text = "🔍  Buscar jugador..."
    _input_buscar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _input_buscar.add_theme_font_size_override("font_size", 12)
    _input_buscar.text_changed.connect(_on_buscar)
    hbox_buscar.add_child(_input_buscar)

    _lbl_status = _lbl("Cargando...", 11, Color(0.55, 0.55, 0.55, 1))
    _lbl_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    inner.add_child(_lbl_status)

    inner.add_child(HSeparator.new())

    # Cabecera de tabla
    inner.add_child(_crear_cabecera())

    # Cuerpo de tabla
    _vbox_tabla = VBoxContainer.new()
    _vbox_tabla.add_theme_constant_override("separation", 3)
    inner.add_child(_vbox_tabla)

func _crear_cabecera() -> HBoxContainer:
    var hbox = HBoxContainer.new()
    hbox.add_theme_constant_override("separation", 6)

    var cols = [
        { "txt": "#",       "min": 28,  "color": Color(0.7,0.65,0.5,1) },
        { "txt": "Nombre",  "min": 120, "color": Color(0.9,0.75,0.3,1) },
        { "txt": "Nv.",     "min": 35,  "color": Color(0.7,0.65,0.5,1) },
        { "txt": "Liga",    "min": 70,  "color": Color(0.7,0.65,0.5,1) },
        { "txt": "Kills",   "min": 45,  "color": Color(0.9,0.3,0.3,1)  },
        { "txt": "Oro rob.", "min": 60, "color": Color(1.0,0.85,0.2,1) },
        { "txt": "Crafteo", "min": 55,  "color": Color(0.4,0.9,0.5,1)  },
        { "txt": "Clan",    "min": 55,  "color": Color(0.6,0.8,1.0,1)  },
        { "txt": "",        "min": 70,  "color": Color.WHITE            },
    ]
    for col in cols:
        var lbl = _lbl(col["txt"], 11, col["color"])
        lbl.custom_minimum_size = Vector2(col["min"], 0)
        if col["txt"] == "Nombre":
            lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        hbox.add_child(lbl)
    return hbox

func _cargar_jugadores() -> void:
    _lbl_status.text = "Cargando jugadores..."
    var url = "https://firestore.googleapis.com/v1/projects/" + GameData.FIREBASE_PROJECT_ID
    url += "/databases/(default)/documents:runQuery"
    var query = {
        "structuredQuery": {
            "from": [{ "collectionId": "players" }],
            "orderBy": [{ "field": { "fieldPath": "level" }, "direction": "DESCENDING" }],
            "limit": 200
        }
    }
    var headers = PackedStringArray([
        "Content-Type: application/json",
        "Authorization: Bearer " + GameData.id_token
    ])
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
                    "nombre":       f.get("username",    {}).get("stringValue", "???"),
                    "nivel":        int(f.get("level",   {}).get("integerValue", "1")),
                    "pvp_kills":    int(f.get("pvp_kills",{}).get("integerValue","0")),
                    "gold_stolen":  int(f.get("gold_stolen",{}).get("integerValue","0")),
                    "craft_points": int(f.get("craft_points",{}).get("integerValue","0")),
                    "clan_tag":     f.get("clan_tag",    {}).get("stringValue", "-"),
                    "arena_pos":    int(f.get("arena_pos",{}).get("integerValue","9999")),
                    "hp":           int(f.get("hp",      {}).get("integerValue","100")),
                    "hp_max":       int(f.get("hp_max",  {}).get("integerValue","100")),
                })
    _lbl_status.text = str(_jugadores.size()) + " jugadores en el servidor"
    _poblar_tabla()

func _on_buscar(texto: String) -> void:
    _filtro = texto.strip_edges().to_lower()
    _poblar_tabla()

func _poblar_tabla() -> void:
    for child in _vbox_tabla.get_children():
        child.queue_free()

    var lista = _jugadores
    if _filtro != "":
        lista = _jugadores.filter(func(j): return _filtro in j["nombre"].to_lower())

    if lista.is_empty():
        _vbox_tabla.add_child(_lbl("No se encontraron jugadores.", 11, Color(0.5,0.5,0.5,1)))
        return

    for i in range(lista.size()):
        var j = lista[i]
        var es_yo = j["player_id"] == GameData.player_id
        _vbox_tabla.add_child(_crear_fila(i + 1, j, es_yo))

func _crear_fila(pos: int, jugador: Dictionary, es_yo: bool) -> PanelContainer:
    var panel = PanelContainer.new()
    if es_yo:
        var style = StyleBoxFlat.new()
        style.bg_color = Color(0.1, 0.2, 0.1, 0.6)
        style.border_color = Color(0.3, 0.8, 0.3, 0.8)
        style.border_width_left   = 2
        style.border_width_right  = 2
        style.border_width_top    = 1
        style.border_width_bottom = 1
        panel.add_theme_stylebox_override("panel", style)

    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left",   8)
    margin.add_theme_constant_override("margin_right",  8)
    margin.add_theme_constant_override("margin_top",    5)
    margin.add_theme_constant_override("margin_bottom", 5)
    panel.add_child(margin)

    var hbox = HBoxContainer.new()
    hbox.add_theme_constant_override("separation", 6)
    margin.add_child(hbox)

    # Posición
    var color_pos = Color(1.0,0.85,0.2,1) if pos <= 3 else Color(0.6,0.6,0.55,1)
    var pos_txt = ["🥇","🥈","🥉"][pos-1] if pos <= 3 else str(pos) + "."
    var lbl_pos = _lbl(pos_txt, 12, color_pos)
    lbl_pos.custom_minimum_size = Vector2(28, 0)
    hbox.add_child(lbl_pos)

    # Nombre
    var color_nombre = Color(0.4, 0.9, 0.4, 1) if es_yo else Color(0.9, 0.85, 0.7, 1)
    var lbl_nombre = _lbl(jugador["nombre"] + (" ←" if es_yo else ""), 12, color_nombre)
    lbl_nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hbox.add_child(lbl_nombre)

    # Nivel
    var lbl_nivel = _lbl(str(jugador["nivel"]), 11, Color(0.7,0.85,1.0,1))
    lbl_nivel.custom_minimum_size = Vector2(35, 0)
    hbox.add_child(lbl_nivel)

    # Liga
    var liga_num = max(1, ceili(float(jugador["nivel"]) / 10.0))
    var lbl_liga = _lbl(str((liga_num-1)*10+1)+"-"+str(liga_num*10), 10, Color(0.6,0.75,0.9,1))
    lbl_liga.custom_minimum_size = Vector2(70, 0)
    hbox.add_child(lbl_liga)

    # Kills
    var lbl_kills = _lbl(str(jugador["pvp_kills"]), 11, Color(0.9,0.3,0.3,1))
    lbl_kills.custom_minimum_size = Vector2(45, 0)
    hbox.add_child(lbl_kills)

    # Oro robado
    var lbl_oro = _lbl(_fmt(jugador["gold_stolen"]), 11, Color(1.0,0.85,0.2,1))
    lbl_oro.custom_minimum_size = Vector2(60, 0)
    hbox.add_child(lbl_oro)

    # Crafteo
    var lbl_craft = _lbl(str(jugador["craft_points"]), 11, Color(0.4,0.9,0.5,1))
    lbl_craft.custom_minimum_size = Vector2(55, 0)
    hbox.add_child(lbl_craft)

    # Clan
    var lbl_clan = _lbl(jugador.get("clan_tag", "-"), 10, Color(0.6,0.8,1.0,1))
    lbl_clan.custom_minimum_size = Vector2(55, 0)
    hbox.add_child(lbl_clan)

    # Botón atacar (solo si no sos vos)
    if not es_yo:
        var btn = Button.new()
        btn.text = "⚔"
        btn.custom_minimum_size = Vector2(36, 28)
        btn.add_theme_font_size_override("font_size", 14)
        btn.tooltip_text = "Atacar (sin puntos de liga — solo 2 XP)"
        btn.pressed.connect(_on_atacar_clasificacion.bind(jugador))
        hbox.add_child(btn)

    return panel

func _on_atacar_clasificacion(jugador: Dictionary) -> void:
    # Ataque sin recompensa de liga — solo 2 XP
    var ficha_rival: Dictionary = {
        "nombre":            jugador.get("nombre", "?"),
        "nivel":             jugador.get("nivel", 1),
        "hp":                jugador.get("hp", 100),
        "hp_max":            jugador.get("hp_max", 100),
        "ataque_min":        5 + jugador.get("nivel", 1) * 2,
        "ataque_max":        10 + jugador.get("nivel", 1) * 4,
        "armadura":          jugador.get("nivel", 1) * 8,
        "crit_chance":       0.05,
        "crit_damage":       1.5,
        "dodge_chance":      0.05,
        "block_chance":      0.05,
        "block_reduction":   1.0,
        "double_hit_chance": 0.05,
        "resist_mortal":     0.0,
    }
    var jugador_ficha = CombatEngine.get_ficha_jugador()
    var resultado     = CombatEngine.run_pvp(jugador_ficha, ficha_rival)

    if resultado.get("jugador_gano", false):
        GameData.xp       += 2
        GameData.xp_total += 2

    SaveManager.save_progress()
    _lbl_status.text = "Combate vs " + jugador.get("nombre","?") + " — " + \
        ("¡Victoria! +2 XP" if resultado.get("jugador_gano",false) else "Derrota.")

func _fmt(n: int) -> String:
    if n >= 1_000_000: return str(snappedf(float(n)/1_000_000.0,0.1))+"M"
    elif n >= 1_000:   return str(snappedf(float(n)/1_000.0,0.1))+"K"
    return str(n)

func _lbl(txt: String, size: int, color: Color) -> Label:
    var l = Label.new()
    l.text = txt
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    return l
