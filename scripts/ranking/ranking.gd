extends Control

# ─────────────────────────────────────────────────────────
# RANKING — 4 tops clanes (arriba) + 4 tops jugadores (abajo)
# Actualización aleatoria cada 40-60 segundos
# ─────────────────────────────────────────────────────────

var _http: HTTPRequest
var _timer: float = 0.0
var _intervalo: float = 0.0

const TABLAS_CONFIG = [
    { "key": "guerreros_clan",  "campo": "pvp_points",   "titulo": "⚔  CLANES — Guerreros",  "sufijo": " pts", "color": Color(0.9, 0.3, 0.3, 1),  "coleccion": "clanes",  "nombre_campo": "nombre" },
    { "key": "ladrones_clan",   "campo": "gold_stolen",  "titulo": "🪙 CLANES — Ladrones",   "sufijo": " oro", "color": Color(1.0, 0.85, 0.2, 1), "coleccion": "clanes",  "nombre_campo": "nombre" },
    { "key": "eruditos_clan",   "campo": "xp_total",     "titulo": "📚 CLANES — Eruditos",   "sufijo": " XP",  "color": Color(0.4, 0.7, 1.0, 1),  "coleccion": "clanes",  "nombre_campo": "nombre" },
    { "key": "artesanos_clan",  "campo": "craft_points", "titulo": "⚒  CLANES — Artesanos",  "sufijo": " pts", "color": Color(0.4, 0.9, 0.5, 1),  "coleccion": "clanes",  "nombre_campo": "nombre" },
    { "key": "guerreros",       "campo": "pvp_points",   "titulo": "⚔  TOP 10 Guerreros",    "sufijo": " pts", "color": Color(0.9, 0.3, 0.3, 1),  "coleccion": "players", "nombre_campo": "username" },
    { "key": "ladrones",        "campo": "gold_stolen",  "titulo": "🪙 TOP 10 Ladrones",     "sufijo": " oro", "color": Color(1.0, 0.85, 0.2, 1), "coleccion": "players", "nombre_campo": "username" },
    { "key": "eruditos",        "campo": "xp_total",     "titulo": "📚 TOP 10 Eruditos",     "sufijo": " XP",  "color": Color(0.4, 0.7, 1.0, 1),  "coleccion": "players", "nombre_campo": "username" },
    { "key": "artesanos",       "campo": "craft_points", "titulo": "⚒  TOP 10 Artesanos",    "sufijo": " pts", "color": Color(0.4, 0.9, 0.5, 1),  "coleccion": "players", "nombre_campo": "username" },
]

var _contenedores: Dictionary = {}
var _lbl_actualizado: Label = null

# Cola de consultas
var _cola: Array = []
var _consultando: bool = false
var _datos: Dictionary = {}

func _ready() -> void:
    _http = HTTPRequest.new()
    add_child(_http)
    _http.request_completed.connect(_on_query_completed)
    _construir_ui()
    _nuevo_intervalo()
    _lanzar_consultas()

func _nuevo_intervalo() -> void:
    _intervalo = randf_range(40.0, 60.0)
    _timer = 0.0

func _process(delta: float) -> void:
    _timer += delta
    if _timer >= _intervalo and not _consultando:
        _nuevo_intervalo()
        _lanzar_consultas()
    if _lbl_actualizado and not _consultando:
        _lbl_actualizado.text = "Próxima actualización en ~" + str(int(_intervalo - _timer)) + "s"

# ─────────────────────────────────────
# UI
# ─────────────────────────────────────
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
    inner.add_theme_constant_override("separation", 14)
    margin.add_child(inner)

    var lbl_titulo = Label.new()
    lbl_titulo.text = "— RANKING SEMANAL —"
    lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl_titulo.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3, 1))
    lbl_titulo.add_theme_font_size_override("font_size", 18)
    inner.add_child(lbl_titulo)

    _lbl_actualizado = Label.new()
    _lbl_actualizado.text = "Cargando..."
    _lbl_actualizado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _lbl_actualizado.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
    _lbl_actualizado.add_theme_font_size_override("font_size", 10)
    inner.add_child(_lbl_actualizado)

    inner.add_child(HSeparator.new())

    # Sección clanes
    var lbl_clanes = Label.new()
    lbl_clanes.text = "🏰  RANKING DE CLANES"
    lbl_clanes.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl_clanes.add_theme_color_override("font_color", Color(0.8, 0.65, 0.3, 1))
    lbl_clanes.add_theme_font_size_override("font_size", 14)
    inner.add_child(lbl_clanes)

    var grid_clanes = GridContainer.new()
    grid_clanes.columns = 2
    grid_clanes.add_theme_constant_override("h_separation", 10)
    grid_clanes.add_theme_constant_override("v_separation", 10)
    inner.add_child(grid_clanes)

    for t in TABLAS_CONFIG:
        if "clan" in t["key"]:
            var panel = _crear_tabla(t["titulo"], t["color"])
            grid_clanes.add_child(panel)
            _contenedores[t["key"]] = panel.find_child("VBoxRows", true, false)

    inner.add_child(HSeparator.new())

    # Sección jugadores
    var lbl_jugadores = Label.new()
    lbl_jugadores.text = "⚔  RANKING DE JUGADORES"
    lbl_jugadores.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl_jugadores.add_theme_color_override("font_color", Color(0.8, 0.65, 0.3, 1))
    lbl_jugadores.add_theme_font_size_override("font_size", 14)
    inner.add_child(lbl_jugadores)

    var grid_jugadores = GridContainer.new()
    grid_jugadores.columns = 2
    grid_jugadores.add_theme_constant_override("h_separation", 10)
    grid_jugadores.add_theme_constant_override("v_separation", 10)
    inner.add_child(grid_jugadores)

    for t in TABLAS_CONFIG:
        if "clan" not in t["key"]:
            var panel = _crear_tabla(t["titulo"], t["color"])
            grid_jugadores.add_child(panel)
            _contenedores[t["key"]] = panel.find_child("VBoxRows", true, false)

func _crear_tabla(titulo: String, color: Color) -> PanelContainer:
    var panel = PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left",   10)
    margin.add_theme_constant_override("margin_right",  10)
    margin.add_theme_constant_override("margin_top",    10)
    margin.add_theme_constant_override("margin_bottom", 10)
    panel.add_child(margin)
    var vbox = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 4)
    margin.add_child(vbox)
    var lbl = Label.new()
    lbl.text = titulo
    lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl.add_theme_color_override("font_color", color)
    lbl.add_theme_font_size_override("font_size", 12)
    vbox.add_child(lbl)
    vbox.add_child(HSeparator.new())
    var rows = VBoxContainer.new()
    rows.name = "VBoxRows"
    rows.add_theme_constant_override("separation", 3)
    vbox.add_child(rows)
    var lbl_loading = Label.new()
    lbl_loading.text = "Cargando..."
    lbl_loading.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
    lbl_loading.add_theme_font_size_override("font_size", 11)
    rows.add_child(lbl_loading)
    return panel

# ─────────────────────────────────────
# CONSULTAS EN COLA
# ─────────────────────────────────────
func _lanzar_consultas() -> void:
    _cola = []
    _datos = {}
    for t in TABLAS_CONFIG:
        _cola.append(t.duplicate())
    _consultando = true
    _consultar_siguiente()

var _tabla_actual: Dictionary = {}

func _consultar_siguiente() -> void:
    if _cola.is_empty():
        _consultando = false
        _poblar_tablas()
        return
    _tabla_actual = _cola.pop_front()
    var url = "https://firestore.googleapis.com/v1/projects/" + GameData.FIREBASE_PROJECT_ID
    url += "/databases/(default)/documents:runQuery"
    var query = {
        "structuredQuery": {
            "from": [{ "collectionId": _tabla_actual["coleccion"] }],
            "orderBy": [{ "field": { "fieldPath": _tabla_actual["campo"] }, "direction": "DESCENDING" }],
            "limit": 10
        }
    }
    var headers = PackedStringArray([
        "Content-Type: application/json",
        "Authorization: Bearer " + GameData.id_token
    ])
    _http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(query))

func _on_query_completed(_result, response_code, _headers_r, body) -> void:
    if response_code == 200:
        var data = JSON.parse_string(body.get_string_from_utf8())
        if data != null:
            var lista: Array = []
            var nombre_campo = _tabla_actual.get("nombre_campo", "username")
            for doc in data:
                if doc.has("document") and doc["document"].has("fields"):
                    var f = doc["document"]["fields"]
                    lista.append({
                        "nombre": f.get(nombre_campo, {}).get("stringValue", "???"),
                        "valor":  int(f.get(_tabla_actual["campo"], {}).get("integerValue", "0"))
                    })
            _datos[_tabla_actual["key"]] = lista
    _consultar_siguiente()

# ─────────────────────────────────────
# POBLAR TABLAS
# ─────────────────────────────────────
func _poblar_tablas() -> void:
    for t in TABLAS_CONFIG:
        var key       = t["key"]
        var vbox_rows = _contenedores.get(key)
        var lista     = _datos.get(key, [])
        if vbox_rows == null:
            continue
        for child in vbox_rows.get_children():
            child.queue_free()
        if lista.is_empty():
            var lbl = Label.new()
            lbl.text = "Sin datos aún."
            lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
            lbl.add_theme_font_size_override("font_size", 11)
            vbox_rows.add_child(lbl)
            continue
        var medallas = ["🥇", "🥈", "🥉"]
        for i in range(lista.size()):
            var j    = lista[i]
            var hbox = HBoxContainer.new()
            hbox.add_theme_constant_override("separation", 6)
            vbox_rows.add_child(hbox)
            var lbl_pos = Label.new()
            lbl_pos.text = medallas[i] if i < 3 else str(i + 1) + "."
            lbl_pos.custom_minimum_size = Vector2(26, 0)
            lbl_pos.add_theme_font_size_override("font_size", 12)
            hbox.add_child(lbl_pos)
            var lbl_nombre = Label.new()
            lbl_nombre.text = j["nombre"]
            lbl_nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            lbl_nombre.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 1))
            lbl_nombre.add_theme_font_size_override("font_size", 11)
            hbox.add_child(lbl_nombre)
            var lbl_valor = Label.new()
            lbl_valor.text = _fmt(j["valor"]) + t["sufijo"]
            lbl_valor.add_theme_color_override("font_color", t["color"])
            lbl_valor.add_theme_font_size_override("font_size", 11)
            hbox.add_child(lbl_valor)

    if _lbl_actualizado:
        _lbl_actualizado.text = "Actualizado: " + Time.get_time_string_from_system()

func _fmt(n: int) -> String:
    if n >= 1_000_000:
        return str(snappedf(float(n) / 1_000_000.0, 0.1)) + "M"
    elif n >= 1_000:
        return str(snappedf(float(n) / 1_000.0, 0.1)) + "K"
    return str(n)
