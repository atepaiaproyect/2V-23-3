extends Control

# ─────────────────────────────────────────────────────────
# ARENA — Sistema PvP por ligas
# ─────────────────────────────────────────────────────────

const BOUNTY_PER_MINUTE := 5        # bronce/min que acumula el #1
const MAX_ATTACKS_VALID  := 10       # ataques con recompensa por jugador/24h
const ATTACK_COOLDOWN_H  := 24       # horas para reset del contador

var _http:        HTTPRequest
var _http2:       HTTPRequest        # para queries secundarias sin bloquear
var _jugadores_liga:  Array = []     # jugadores en mi liga, ordenados por pos
var _mis_rivales:     Array = []     # los 4 inmediatamente superiores
var _top5_liga:       Array = []     # top 5 de mi liga
var _ataque_activo:   Dictionary = {}
var _accion:          String = ""

# UI refs
var _lbl_liga:        Label
var _lbl_pos:         Label
var _lbl_bounty:      Label
var _vbox_top5:       VBoxContainer
var _vbox_rivales:    VBoxContainer
var _lbl_status:      Label
var _panel_combate:   PanelContainer
var _lbl_resultado:   Label
var _lbl_log:         Label
var _btn_volver:      Button

func _ready() -> void:
    _http  = HTTPRequest.new(); add_child(_http)
    _http2 = HTTPRequest.new(); add_child(_http2)
    _http.request_completed.connect(_on_http)
    _http2.request_completed.connect(_on_http2)
    _construir_ui()
    _cargar_liga()

# ─────────────────────────────────────
# UI
# ─────────────────────────────────────
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
    inner.add_theme_constant_override("separation", 14)
    margin.add_child(inner)

    # Título
    var lbl_titulo = _lbl("⚔  ARENA", 20, Color(0.95, 0.7, 0.2, 1), true)
    lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    inner.add_child(lbl_titulo)

    # Info de liga del jugador
    var panel_info = PanelContainer.new()
    inner.add_child(panel_info)
    var info_margin = MarginContainer.new()
    info_margin.add_theme_constant_override("margin_left",   12)
    info_margin.add_theme_constant_override("margin_right",  12)
    info_margin.add_theme_constant_override("margin_top",    10)
    info_margin.add_theme_constant_override("margin_bottom", 10)
    panel_info.add_child(info_margin)
    var info_vbox = VBoxContainer.new()
    info_vbox.add_theme_constant_override("separation", 4)
    info_margin.add_child(info_vbox)

    _lbl_liga = _lbl("", 14, Color(0.9, 0.75, 0.3, 1), true)
    _lbl_liga.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info_vbox.add_child(_lbl_liga)

    _lbl_pos = _lbl("", 12, Color(0.7, 0.85, 1.0, 1), false)
    _lbl_pos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info_vbox.add_child(_lbl_pos)

    _lbl_bounty = _lbl("", 12, Color(0.8, 0.6, 0.3, 1), false)
    _lbl_bounty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    info_vbox.add_child(_lbl_bounty)

    _lbl_status = _lbl("Cargando...", 11, Color(0.55, 0.55, 0.55, 1), false)
    _lbl_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    inner.add_child(_lbl_status)

    inner.add_child(HSeparator.new())

    # Grid 2 columnas: Top 5 | Mis rivales
    var grid = GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 12)
    inner.add_child(grid)

    # Panel Top 5
    var panel_top = _crear_panel_lista("🏆  TOP 5 DE TU LIGA", Color(1.0, 0.75, 0.15, 1))
    grid.add_child(panel_top)
    _vbox_top5 = panel_top.find_child("VBoxLista", true, false)

    # Panel Rivales
    var panel_rivales = _crear_panel_lista("⚔  TUS RIVALES", Color(0.9, 0.3, 0.3, 1))
    grid.add_child(panel_rivales)
    _vbox_rivales = panel_rivales.find_child("VBoxLista", true, false)

    inner.add_child(HSeparator.new())

    # Panel de resultado de combate (oculto al inicio)
    _panel_combate = PanelContainer.new()
    _panel_combate.visible = false
    inner.add_child(_panel_combate)

    var comb_margin = MarginContainer.new()
    comb_margin.add_theme_constant_override("margin_left",  12)
    comb_margin.add_theme_constant_override("margin_right", 12)
    comb_margin.add_theme_constant_override("margin_top",   10)
    comb_margin.add_theme_constant_override("margin_bottom",10)
    _panel_combate.add_child(comb_margin)

    var comb_vbox = VBoxContainer.new()
    comb_vbox.add_theme_constant_override("separation", 8)
    comb_margin.add_child(comb_vbox)

    _lbl_resultado = _lbl("", 16, Color(0.9, 0.75, 0.3, 1), true)
    _lbl_resultado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    comb_vbox.add_child(_lbl_resultado)

    var scroll_log = ScrollContainer.new()
    scroll_log.custom_minimum_size = Vector2(0, 260)
    comb_vbox.add_child(scroll_log)

    _lbl_log = _lbl("", 11, Color(0.8, 0.78, 0.7, 1), false)
    _lbl_log.autowrap_mode = TextServer.AUTOWRAP_WORD
    _lbl_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll_log.add_child(_lbl_log)

    _btn_volver = Button.new()
    _btn_volver.text = "◀  Volver a la Arena"
    _btn_volver.add_theme_font_size_override("font_size", 12)
    _btn_volver.pressed.connect(_on_volver_arena)
    comb_vbox.add_child(_btn_volver)

func _crear_panel_lista(titulo: String, color: Color) -> PanelContainer:
    var panel = PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left",   10)
    margin.add_theme_constant_override("margin_right",  10)
    margin.add_theme_constant_override("margin_top",    10)
    margin.add_theme_constant_override("margin_bottom", 10)
    panel.add_child(margin)
    var vbox = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 6)
    margin.add_child(vbox)
    var lbl = _lbl(titulo, 13, color, true)
    lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(lbl)
    vbox.add_child(HSeparator.new())
    var lista = VBoxContainer.new()
    lista.name = "VBoxLista"
    lista.add_theme_constant_override("separation", 5)
    vbox.add_child(lista)
    return panel

# ─────────────────────────────────────
# CARGAR LIGA — query a Firestore
# ─────────────────────────────────────
func _cargar_liga() -> void:
    _lbl_liga.text  = GameData.get_arena_league_name()
    _lbl_pos.text   = "Tu posición: " + (str(GameData.arena_pos) if GameData.arena_pos < 9999 else "Sin clasificar")
    _lbl_bounty.text = ""
    _lbl_status.text = "Cargando clasificación..."

    # Buscar todos los jugadores de mi liga ordenados por arena_pos
    var url = "https://firestore.googleapis.com/v1/projects/" + GameData.FIREBASE_PROJECT_ID
    url += "/databases/(default)/documents:runQuery"
    var liga_id = GameData.get_arena_league_id()
    # Filtrar por rango de nivel (no requiere campo arena_league en Firestore)
    var liga     = GameData.get_arena_league()
    var min_lvl  = (liga - 1) * 10 + 1
    var max_lvl  = liga * 10
    # integerValue debe ser int, no string
    # Sin orderBy para evitar requerir índice compuesto — ordenamos localmente
    var query = {
        "structuredQuery": {
            "from": [{ "collectionId": "players" }],
            "where": {
                "compositeFilter": {
                    "op": "AND",
                    "filters": [
                        {
                            "fieldFilter": {
                                "field": { "fieldPath": "level" },
                                "op": "GREATER_THAN_OR_EQUAL",
                                "value": { "integerValue": min_lvl }
                            }
                        },
                        {
                            "fieldFilter": {
                                "field": { "fieldPath": "level" },
                                "op": "LESS_THAN_OR_EQUAL",
                                "value": { "integerValue": max_lvl }
                            }
                        }
                    ]
                }
            },
            "limit": 100
        }
    }
    _accion = "cargar_liga"
    _http_post(url, JSON.stringify(query))

# ─────────────────────────────────────
# HTTP CALLBACKS
# ─────────────────────────────────────
func _on_http(_result, response_code, _headers_r, body) -> void:
    var data = JSON.parse_string(body.get_string_from_utf8())
    match _accion:
        "cargar_liga":
            print("Arena response_code: ", response_code)
            print("Arena body: ", body.get_string_from_utf8().left(300))
            _jugadores_liga = []
            if data != null:
                for doc in data:
                    if doc.has("document") and doc["document"].has("fields"):
                        var f = doc["document"]["fields"]
                        _jugadores_liga.append({
                            "player_id":  _extraer_id(doc["document"].get("name", "")),
                            "nombre":     f.get("username",    {}).get("stringValue", "???"),
                            "nivel":      int(f.get("level",   {}).get("integerValue", "1")),
                            "arena_pos":  int(f.get("arena_pos",{}).get("integerValue", "9999")),
                            "arena_bounty": int(f.get("arena_bounty",{}).get("integerValue","0")),
                            "arena_is_top1": f.get("arena_is_top1",{}).get("booleanValue", false),
                            "pvp_points": int(f.get("pvp_points",{}).get("integerValue","0")),
                            "hp":         int(f.get("hp",    {}).get("integerValue", "100")),
                            "hp_max":     int(f.get("hp_max",{}).get("integerValue", "100")),
                            "level":      int(f.get("level", {}).get("integerValue", "1")),
                        })
            # Si el jugador no tiene posición, asignarlo al final
            if GameData.arena_pos >= 9999:
                GameData.arena_pos = _jugadores_liga.size() + 1
                _registrar_en_liga()
            _calcular_rivales()
            _poblar_ui()
            _lbl_status.text = str(_jugadores_liga.size()) + " jugadores en tu liga"

        "atacar":
            if response_code == 200 or response_code == 201:
                _resolver_combate_pvp()
            else:
                _lbl_status.text = "Error al registrar ataque."

        "guardar_resultado":
            _lbl_status.text = "¡Resultado guardado!"
            _cargar_liga()

func _on_http2(_r, _c, _h, _b) -> void:
    pass  # requests secundarios

# ─────────────────────────────────────
# CALCULAR RIVALES (4 posiciones superiores)
# ─────────────────────────────────────
func _calcular_rivales() -> void:
    _top5_liga   = []
    _mis_rivales = []

    # Ordenar por pvp_points DESC para determinar posiciones reales
    var lista = _jugadores_liga.duplicate()
    lista.sort_custom(func(a, b): return a["pvp_points"] > b["pvp_points"])

    # Asignar posiciones reales según orden en la lista
    for i in range(lista.size()):
        lista[i]["pos_real"] = i + 1
        if lista[i]["player_id"] == GameData.player_id:
            GameData.arena_pos = i + 1

    # Top 5
    _top5_liga = lista.slice(0, min(5, lista.size()))

    # Mis rivales: los 4 jugadores inmediatamente por encima de mí
    var mi_pos_real = GameData.arena_pos
    for j in lista:
        if j["pos_real"] < mi_pos_real and j["pos_real"] >= mi_pos_real - 4:
            _mis_rivales.append(j)

# ─────────────────────────────────────
# POBLAR UI
# ─────────────────────────────────────
func _poblar_ui() -> void:
    _lbl_pos.text = "Tu posición: #" + str(GameData.arena_pos)

    # Top 5
    for child in _vbox_top5.get_children(): child.queue_free()
    if _top5_liga.is_empty():
        _vbox_top5.add_child(_lbl("Aún no hay jugadores en esta liga.", 11, Color(0.5,0.5,0.5,1), false))
    else:
        var medallas = ["🥇","🥈","🥉","4.","5."]
        for i in range(min(_top5_liga.size(), 5)):
            var j = _top5_liga[i]
            var es_yo = j["player_id"] == GameData.player_id
            _vbox_top5.add_child(_crear_fila_jugador(
                medallas[i], j, es_yo, false
            ))

    # Rivales
    for child in _vbox_rivales.get_children(): child.queue_free()
    if _mis_rivales.is_empty():
        var msg = "¡Sos el primero en tu liga!\nNadie por encima." if GameData.arena_pos == 1 \
                  else "No hay rivales cerca.\nSeguí subiendo."
        _vbox_rivales.add_child(_lbl(msg, 11, Color(0.5,0.85,0.5,1), false))
    else:
        for j in _mis_rivales:
            _vbox_rivales.add_child(_crear_fila_jugador("⚔", j, false, true))

func _crear_fila_jugador(icono: String, jugador: Dictionary, es_yo: bool, con_boton: bool) -> HBoxContainer:
    var hbox = HBoxContainer.new()
    hbox.add_theme_constant_override("separation", 8)

    var lbl_pos = _lbl(icono, 13, Color(0.9,0.75,0.3,1), false)
    lbl_pos.custom_minimum_size = Vector2(28, 0)
    hbox.add_child(lbl_pos)

    var vbox_info = VBoxContainer.new()
    vbox_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vbox_info.add_theme_constant_override("separation", 2)
    hbox.add_child(vbox_info)

    var color_nombre = Color(0.4, 0.9, 0.4, 1) if es_yo else Color(0.9, 0.85, 0.7, 1)
    var nombre_txt = jugador.get("nombre", "?") + (" (vos)" if es_yo else "")
    vbox_info.add_child(_lbl(nombre_txt, 12, color_nombre, false))

    var info_txt = "Nv." + str(jugador.get("nivel", 1))
    if jugador.get("arena_is_top1", false):
        info_txt += "  🏆 #1  💰 " + _fmt(jugador.get("arena_bounty", 0)) + " bronce"
        info_txt += "  ← ¡BOTÍN!"
    vbox_info.add_child(_lbl(info_txt, 10, Color(0.6,0.6,0.55,1), false))

    if con_boton and not es_yo:
        var btn = Button.new()
        btn.text = "⚔  Atacar"
        btn.custom_minimum_size = Vector2(80, 32)
        btn.add_theme_font_size_override("font_size", 11)
        btn.pressed.connect(_on_atacar_jugador.bind(jugador))
        hbox.add_child(btn)

    return hbox

# ─────────────────────────────────────
# ATACAR JUGADOR
# ─────────────────────────────────────
func _on_atacar_jugador(rival: Dictionary) -> void:
    # Cooldown global de 1 minuto entre ataques PvP
    var ahora = int(Time.get_unix_time_from_system())
    var segundos_restantes = 60 - (ahora - GameData.pvp_last_attack_time)
    if segundos_restantes > 0:
        _lbl_status.text = "⏳ Podés atacar en " + str(segundos_restantes) + " segundos."
        return
    # Verificar límite de 10 ataques/24h
    var ataques_hoy = _contar_ataques_hoy(rival["player_id"])
    if ataques_hoy >= MAX_ATTACKS_VALID:
        _lbl_status.text = "⚠ Límite de " + str(MAX_ATTACKS_VALID) + " ataques válidos alcanzado.\nPodés seguir atacando pero sin recompensa."
        # Mostrar diálogo de confirmación
        _mostrar_dialogo_sin_recompensa(rival)
        return
    _ataque_activo = rival
    _ejecutar_ataque(rival, true)

func _mostrar_dialogo_sin_recompensa(rival: Dictionary) -> void:
    # Crear panel de confirmación
    var content_area = _buscar_content_area()
    if content_area == null:
        return
    var dialog = PanelContainer.new()
    dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    dialog.z_index = 100
    add_child(dialog)

    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left",  40)
    margin.add_theme_constant_override("margin_right", 40)
    margin.add_theme_constant_override("margin_top",   40)
    margin.add_theme_constant_override("margin_bottom",40)
    dialog.add_child(margin)

    var vbox = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 12)
    margin.add_child(vbox)

    vbox.add_child(_lbl("⚠  Límite de ataques alcanzado", 14, Color(1.0,0.8,0.2,1), true))
    vbox.add_child(_lbl("Atacaste a " + rival.get("nombre","?") + " más de " + str(MAX_ATTACKS_VALID) + " veces hoy.\nNo recibirás bronce ni puntos de arena.", 11, Color(0.8,0.75,0.6,1), false))
    vbox.add_child(_lbl("¿Querés atacar de todas formas?", 12, Color(0.9,0.85,0.7,1), false))

    var hbox_btns = HBoxContainer.new()
    hbox_btns.add_theme_constant_override("separation", 12)
    vbox.add_child(hbox_btns)

    var btn_si = Button.new()
    btn_si.text = "⚔  Atacar sin recompensa"
    btn_si.add_theme_font_size_override("font_size", 12)
    btn_si.pressed.connect(func():
        dialog.queue_free()
        _ataque_activo = rival
        _ejecutar_ataque(rival, false)  # sin recompensa
    )
    hbox_btns.add_child(btn_si)

    var btn_no = Button.new()
    btn_no.text = "✕  Cancelar"
    btn_no.add_theme_font_size_override("font_size", 12)
    btn_no.pressed.connect(func(): dialog.queue_free())
    hbox_btns.add_child(btn_no)

func _ejecutar_ataque(rival: Dictionary, con_recompensa: bool) -> void:
    rival["_con_recompensa"] = con_recompensa
    _ataque_activo = rival
    _lbl_status.text = "Combatiendo contra " + rival.get("nombre","?") + "..."
    # Registrar cooldown global
    GameData.pvp_last_attack_time = int(Time.get_unix_time_from_system())
    _registrar_ataque(rival["player_id"])
    _resolver_combate_pvp()

func _resolver_combate_pvp() -> void:
    var rival = _ataque_activo
    if rival.is_empty(): return

    var jugador = CombatEngine.get_ficha_jugador()

    # Construir ficha del rival desde los datos cargados
    var ficha_rival: Dictionary = {
        "nombre":            rival.get("nombre", "?"),
        "nivel":             rival.get("nivel", 1),
        "hp":                rival.get("hp", 100),
        "hp_max":            rival.get("hp_max", 100),
        "ataque_min":        5 + rival.get("nivel", 1) * 2,
        "ataque_max":        10 + rival.get("nivel", 1) * 4,
        "armadura":          rival.get("nivel", 1) * 8,
        "crit_chance":       0.05 + rival.get("nivel", 1) * 0.002,
        "crit_damage":       1.5,
        "dodge_chance":      0.05,
        "block_chance":      0.05,
        "block_reduction":   1.0,
        "double_hit_chance": 0.05,
        "resist_mortal":     0.0,
        "icono":             "res://assets/portraits/players/portrait_male_1.png",
    }

    var resultado = CombatEngine.run_pvp(jugador, ficha_rival)
    var con_recompensa = rival.get("_con_recompensa", true)
    _aplicar_resultado_pvp(resultado, rival, con_recompensa)
    _mostrar_resultado_pvp(resultado, jugador, ficha_rival, con_recompensa)

func _aplicar_resultado_pvp(resultado: Dictionary, rival: Dictionary, con_recompensa: bool) -> void:
    var gane = resultado.get("jugador_gano", false)

    if con_recompensa:
        if gane:
            # Sumar puntos
            GameData.pvp_points += 5

            # Robar oro (1-10% del oro del rival)
            var oro_robado = randi_range(1, max(1, rival.get("nivel", 1) * 10))
            GameData.gold_hand  += oro_robado
            GameData.gold_stolen += oro_robado

            # Ascender posición — tomar la posición del rival
            var pos_rival = rival.get("arena_pos", GameData.arena_pos)
            if pos_rival < GameData.arena_pos:
                GameData.arena_pos = pos_rival

            # Si le quitó el puesto #1: robar botín y resetear el del rival
            if rival.get("arena_is_top1", false) and rival.get("arena_bounty", 0) > 0:
                var botin = rival.get("arena_bounty", 0)
                GameData.bronze_hand += botin
                # Guardar en Firestore que el rival ya no tiene botín ni es #1
                _resetear_botin_rival(rival.get("player_id", ""))
            # Mi propio botín empieza desde 0 al tomar el #1
            GameData.arena_bounty = 0

        else:
            # Perder baja un puesto (pero no más de 5 posiciones)
            pass  # el atacante no baja, solo el defensor podría subir si ganara

    var xp_pvp = resultado.get("xp_ganada", 0)
    GameData.xp_total += xp_pvp
    GameData.xp       += xp_pvp

    # Actualizar si somos top 1
    GameData.arena_is_top1 = (GameData.arena_pos == 1)

    SaveManager.save_progress()
    AchievementManager.check_all()

    # Actualizar puntos del clan si el jugador pertenece a uno
    if con_recompensa and gane:
        var oro_clan  = randi_range(1, max(1, rival.get("nivel", 1) * 10))
        SaveManager.save_clan_stats(xp_pvp, 5, oro_clan, 0)
    elif con_recompensa:
        SaveManager.save_clan_stats(xp_pvp, 0, 0, 0)

    # Guardar resultado en Firestore para actualizar ranking
    _guardar_resultado_firestore(rival, gane, con_recompensa)

    # ── Guardar reporte de combate PvP ──────────────────────
    _guardar_reportes_pvp(resultado, rival, gane)


func _guardar_reportes_pvp(resultado: Dictionary, rival: Dictionary, gane: bool) -> void:
    var nombre_j   = GameData.player_name
    var nombre_r   = rival.get("nombre", "Rival")
    var rival_id   = rival.get("player_id", "")
    var log_txt    = MessageManager.construir_log_pvp(resultado, nombre_j, nombre_r)

    # Esperar un frame para asegurarse que el token esté disponible
    await get_tree().process_frame

    # Reporte para el atacante (yo)
    var titulo_atac = ("⚔ Victoria vs " if gane else "💀 Derrota vs ") + nombre_r
    MessageManager.guardar_reporte(
        GameData.player_id,
        nombre_r,
        "pvp_ataque",
        titulo_atac,
        log_txt
    )

    # Reporte de defensa para el rival (si tenemos su ID)
    if rival_id != "":
        var titulo_def = ("🛡 Fuiste atacado por " + nombre_j +
            (" — Sobreviviste" if not gane else " — Fuiste derrotado"))
        MessageManager.guardar_reporte(
            rival_id,
            nombre_j,
            "pvp_defensa",
            titulo_def,
            log_txt
        )

func _resetear_botin_rival(rival_player_id: String) -> void:
    if rival_player_id == "":
        return
    var url = GameData.FIRESTORE_URL + "players/" + rival_player_id
    url += "?updateMask.fieldPaths=arena_bounty&updateMask.fieldPaths=arena_is_top1"
    var body = JSON.stringify({ "fields": {
        "arena_bounty":  { "integerValue": "0" },
        "arena_is_top1": { "booleanValue": false },
    }})
    _http2.request(url, _headers(), HTTPClient.METHOD_PATCH, body)

func _guardar_resultado_firestore(rival: Dictionary, gane: bool, con_recompensa: bool) -> void:
    if not con_recompensa:
        return
    # Actualizar liga_ranking en Firestore
    _accion = "guardar_resultado"
    var url = GameData.FIRESTORE_URL + "arena_results/" + str(int(Time.get_unix_time_from_system()))
    var body = JSON.stringify({ "fields": {
        "attacker_id":   { "stringValue": GameData.player_id },
        "attacker_name": { "stringValue": GameData.player_name },
        "defender_id":   { "stringValue": rival.get("player_id", "") },
        "defender_name": { "stringValue": rival.get("nombre", "") },
        "winner":        { "stringValue": GameData.player_name if gane else rival.get("nombre","") },
        "timestamp":     { "integerValue": str(int(Time.get_unix_time_from_system())) },
        "liga":          { "stringValue": GameData.get_arena_league_id() },
    }})
    _http_patch(url, body)

# ─────────────────────────────────────
# MOSTRAR RESULTADO
# ─────────────────────────────────────
func _mostrar_resultado_pvp(resultado: Dictionary, jugador: Dictionary, rival: Dictionary, con_recompensa: bool) -> void:
    _panel_combate.visible = true

    var gane     = resultado.get("jugador_gano", false)
    var nombre_j = jugador.get("nombre", "Vos")
    var nombre_r = rival.get("nombre", "Rival")

    if gane:
        _lbl_resultado.text = "⚔  ¡VICTORIA!"
        _lbl_resultado.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2, 1))
    else:
        _lbl_resultado.text = "💀  DERROTA"
        _lbl_resultado.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2, 1))

    if not con_recompensa:
        _lbl_resultado.text += "\n(Sin recompensa — límite diario alcanzado)"

    # Log de combate
    var combat_log: Array = resultado.get("log", [])
    var txt = ""
    for ronda_data in combat_log:
        var r = ronda_data.get("ronda", 0)
        txt += "\nRonda " + str(r) + "\n"
        for ev in ronda_data.get("eventos", []):
            txt += _formatear_evento(ev, nombre_j, nombre_r) + "\n"

    txt += "\n"
    if gane:
        txt += "⚔  " + nombre_j + " ganó tras " + str(resultado.get("rondas", 0)) + " rondas."
    else:
        txt += "💀  " + nombre_j + " fue derrotado tras " + str(resultado.get("rondas", 0)) + " rondas."

    _lbl_log.text = txt

func _formatear_evento(ev: Dictionary, nombre_j: String, nombre_r: String) -> String:
    var tipo     = ev.get("tipo", "golpe")
    var atacante = ev.get("atacante", "?")
    var defensor = ev.get("defensor", "?")
    var dano     = ev.get("dano", 0)
    var esquivo  = ev.get("esquivo", false)
    var critico  = ev.get("critico", false)

    match tipo:
        "muerte":
            return "*" + ev.get("nombre", "?") + " muere*"
        "resistencia":
            return "★ " + ev.get("nombre", "?") + " resistió el golpe mortal y sobrevive con 1 HP"
        "doble":
            if dano <= 0: return atacante + " ataca a " + defensor + ".\nfallado"
            return atacante + " ataca a " + defensor + ".\n" + defensor + " recibe " + str(dano) + " de daño (doble golpe)"
        _:
            var linea = atacante + " ataca a " + defensor + "."
            if esquivo or dano <= 0:
                linea += "\nfallado"
            elif critico:
                linea += "\n*" + defensor + " recibe " + str(dano) + " de daño (¡CRÍTICO!)*"
            else:
                linea += "\n" + defensor + " recibe " + str(dano) + " de daño"
            return linea

func _on_volver_arena() -> void:
    _panel_combate.visible = false
    _cargar_liga()

# ─────────────────────────────────────
# REGISTRO EN LIGA — primera vez
# ─────────────────────────────────────
func _registrar_en_liga() -> void:
    var url = GameData.FIRESTORE_URL + "players/" + GameData.player_id
    url += "?updateMask.fieldPaths=arena_pos&updateMask.fieldPaths=arena_league"
    var body = JSON.stringify({ "fields": {
        "arena_pos":    { "integerValue": str(GameData.arena_pos) },
        "arena_league": { "stringValue": GameData.get_arena_league_id() },
    }})
    _http2.request(url, _headers(), HTTPClient.METHOD_PATCH, body)

# ─────────────────────────────────────
# CONTROL DE ATAQUES — localStorage simple con diccionario en memoria
# (en producción esto iría en Firestore pero para testing funciona así)
# ─────────────────────────────────────
var _ataques_hoy: Dictionary = {}   # player_id → {count, timestamp_inicio}

func _contar_ataques_hoy(rival_id: String) -> int:
    if not _ataques_hoy.has(rival_id):
        return 0
    var data = _ataques_hoy[rival_id]
    var ahora = int(Time.get_unix_time_from_system())
    # Si pasaron más de 24h, resetear
    if ahora - data["inicio"] > ATTACK_COOLDOWN_H * 3600:
        _ataques_hoy.erase(rival_id)
        return 0
    return data["count"]

func _registrar_ataque(rival_id: String) -> void:
    var ahora = int(Time.get_unix_time_from_system())
    if not _ataques_hoy.has(rival_id):
        _ataques_hoy[rival_id] = { "count": 0, "inicio": ahora }
    _ataques_hoy[rival_id]["count"] += 1

# ─────────────────────────────────────
# TIMER DE BOTÍN (acumula mientras sos #1)
# ─────────────────────────────────────
var _bounty_timer: float = 0.0
const BOUNTY_TICK_SECONDS := 60.0

func _process(delta: float) -> void:
    if not GameData.arena_is_top1:
        return
    _bounty_timer += delta
    if _bounty_timer >= BOUNTY_TICK_SECONDS:
        _bounty_timer = 0.0
        GameData.arena_bounty += BOUNTY_PER_MINUTE
        if _lbl_bounty:
            _lbl_bounty.text = "💰 Botín acumulado: " + _fmt(GameData.arena_bounty) + " bronce"
        SaveManager.save_progress()

# ─────────────────────────────────────
# HELPERS
# ─────────────────────────────────────
func _extraer_id(path: String) -> String:
    var partes = path.split("/")
    return partes[partes.size() - 1] if partes.size() > 0 else ""

func _headers() -> PackedStringArray:
    return PackedStringArray([
        "Content-Type: application/json",
        "Authorization: Bearer " + GameData.id_token
    ])

func _http_post(url: String, body: String) -> void:
    if _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
        _http.cancel_request()
    _http.request(url, _headers(), HTTPClient.METHOD_POST, body)

func _http_patch(url: String, body: String) -> void:
    if _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
        _http.cancel_request()
    _http.request(url, _headers(), HTTPClient.METHOD_PATCH, body)

func _buscar_content_area() -> Node:
    var node = get_parent()
    while node != null:
        var candidate = node.find_child("ContentArea", true, false)
        if candidate: return candidate
        node = node.get_parent()
    return null

func _fmt(n: int) -> String:
    if n >= 1_000_000: return str(snappedf(float(n)/1_000_000.0, 0.1)) + "M"
    elif n >= 1_000:   return str(snappedf(float(n)/1_000.0, 0.1)) + "K"
    return str(n)

func _lbl(txt: String, size: int, color: Color, bold: bool) -> Label:
    var l = Label.new()
    l.text = txt
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    return l
