extends Control

# ============================================================
# Mailbox — Buzón de mensajes y reportes
# Archivo: scripts/mailbox/mailbox.gd
# Abierto como overlay desde main_hub
# ============================================================

const FIRESTORE_URL = "https://firestore.googleapis.com/v1/projects/atepaia-2v/databases/(default)/documents"

# Colores del tema
const C_ORO    = Color(0.95, 0.80, 0.35, 1)
const C_TITULO = Color(0.85, 0.70, 0.25, 1)
const C_TEXTO  = Color(0.88, 0.84, 0.72, 1)
const C_TENUE  = Color(0.55, 0.52, 0.45, 1)
const C_AZUL   = Color(0.45, 0.75, 1.00, 1)
const C_VERDE  = Color(0.35, 0.88, 0.45, 1)
const C_ROJO   = Color(0.95, 0.35, 0.30, 1)
const C_AMARILLO = Color(1.0, 0.85, 0.20, 1)
const C_BG     = Color(0.06, 0.04, 0.03, 1)
const C_PANEL  = Color(0.10, 0.07, 0.04, 1)
const C_BORDE  = Color(0.32, 0.24, 0.10, 1)
const C_HEADER = Color(0.16, 0.11, 0.05, 1)

# Tabs
var _tabs:       Array = []
var _panels:     Array = []
var _tab_activa: int   = 0

# UI refs
var _vbox_inbox:     VBoxContainer
var _vbox_enviados:  VBoxContainer
var _vbox_reportes:  VBoxContainer
var _lbl_status:     Label

# Para escribir mensajes
var _input_destinatario: LineEdit
var _input_asunto:       LineEdit
var _txt_mensaje:        TextEdit
var _lbl_envio_status:   Label

# Mensajes cargados
var _mensajes_inbox:    Array = []
var _mensajes_enviados: Array = []
var _mensajes_reportes: Array = []

# Para ver detalle
var _panel_detalle: Control = null


func _ready() -> void:
    _construir_ui()
    _cargar_inbox()


# ============================================================
# UI PRINCIPAL
# ============================================================
func _construir_ui() -> void:
    # Overlay oscuro
    var overlay = ColorRect.new()
    overlay.color = Color(0, 0, 0, 0.82)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(overlay)

    # Panel principal
    var panel = PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.custom_minimum_size = Vector2(720, 760)
    panel.position = Vector2(-360, -380)
    var sp = StyleBoxFlat.new()
    sp.bg_color     = C_BG
    sp.border_color = C_BORDE
    sp.border_width_left   = 2
    sp.border_width_right  = 2
    sp.border_width_top    = 2
    sp.border_width_bottom = 2
    sp.corner_radius_top_left     = 6
    sp.corner_radius_top_right    = 6
    sp.corner_radius_bottom_left  = 6
    sp.corner_radius_bottom_right = 6
    panel.add_theme_stylebox_override("panel", sp)
    add_child(panel)

    var vbox_root = VBoxContainer.new()
    vbox_root.add_theme_constant_override("separation", 0)
    panel.add_child(vbox_root)

    _construir_header(vbox_root)
    _construir_tabs_bar(vbox_root)
    _construir_contenido(vbox_root)


func _construir_header(parent: VBoxContainer) -> void:
    var hp = PanelContainer.new()
    var sh = StyleBoxFlat.new()
    sh.bg_color     = C_HEADER
    sh.border_color = C_BORDE
    sh.border_width_bottom = 2
    sh.corner_radius_top_left  = 5
    sh.corner_radius_top_right = 5
    hp.add_theme_stylebox_override("panel", sh)
    parent.add_child(hp)

    var hm = MarginContainer.new()
    hm.add_theme_constant_override("margin_left",   16)
    hm.add_theme_constant_override("margin_right",  16)
    hm.add_theme_constant_override("margin_top",    12)
    hm.add_theme_constant_override("margin_bottom", 12)
    hp.add_child(hm)

    var hbox = HBoxContainer.new()
    hm.add_child(hbox)

    var lbl_icono = Label.new()
    lbl_icono.text = "✉"
    lbl_icono.add_theme_font_size_override("font_size", 26)
    lbl_icono.add_theme_color_override("font_color", C_ORO)
    hbox.add_child(lbl_icono)

    var lbl_titulo = Label.new()
    lbl_titulo.text = "  Mensajes e Informes"
    lbl_titulo.add_theme_font_size_override("font_size", 20)
    lbl_titulo.add_theme_color_override("font_color", C_ORO)
    lbl_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hbox.add_child(lbl_titulo)

    _lbl_status = Label.new()
    _lbl_status.text = ""
    _lbl_status.add_theme_font_size_override("font_size", 11)
    _lbl_status.add_theme_color_override("font_color", C_TENUE)
    hbox.add_child(_lbl_status)

    var btn_cerrar = Button.new()
    btn_cerrar.text = "✕"
    btn_cerrar.custom_minimum_size = Vector2(36, 36)
    btn_cerrar.add_theme_font_size_override("font_size", 16)
    btn_cerrar.pressed.connect(queue_free)
    hbox.add_child(btn_cerrar)


func _construir_tabs_bar(parent: VBoxContainer) -> void:
    var tp = PanelContainer.new()
    var st = StyleBoxFlat.new()
    st.bg_color     = Color(0.12, 0.09, 0.05, 1)
    st.border_color = C_BORDE
    st.border_width_bottom = 2
    tp.add_theme_stylebox_override("panel", st)
    parent.add_child(tp)

    var hbox = HBoxContainer.new()
    hbox.add_theme_constant_override("separation", 0)
    tp.add_child(hbox)

    var tab_info = [
        ["📥 Entrada",  C_AZUL],
        ["✏ Escribir",  C_VERDE],
        ["📤 Enviados",  C_AMARILLO],
        ["⚔ Reportes",  C_ROJO],
    ]

    for i in range(tab_info.size()):
        var btn = Button.new()
        btn.text = tab_info[i][0]
        btn.custom_minimum_size = Vector2(0, 38)
        btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        btn.add_theme_font_size_override("font_size", 13)
        btn.flat = true
        var idx = i
        btn.pressed.connect(func(): _cambiar_tab(idx))
        hbox.add_child(btn)
        _tabs.append(btn)

    _actualizar_estilo_tabs()


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

    _panels.append(_construir_panel_inbox(stack))
    _panels.append(_construir_panel_escribir(stack))
    _panels.append(_construir_panel_enviados(stack))
    _panels.append(_construir_panel_reportes(stack))

    _cambiar_tab(0)


# ── PANEL INBOX ───────────────────────────────────────────────
func _construir_panel_inbox(parent: Control) -> Control:
    var vbox = VBoxContainer.new()
    vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    vbox.add_theme_constant_override("separation", 6)
    parent.add_child(vbox)

    # Botones de acción
    var hbox_acc = HBoxContainer.new()
    hbox_acc.add_theme_constant_override("separation", 8)
    vbox.add_child(hbox_acc)

    var btn_recargar = Button.new()
    btn_recargar.text = "↻ Actualizar"
    btn_recargar.add_theme_font_size_override("font_size", 12)
    btn_recargar.pressed.connect(_cargar_inbox)
    hbox_acc.add_child(btn_recargar)

    var btn_marcar_todos = Button.new()
    btn_marcar_todos.text = "✓ Marcar todos como leídos"
    btn_marcar_todos.add_theme_font_size_override("font_size", 12)
    btn_marcar_todos.pressed.connect(_marcar_todos_inbox)
    hbox_acc.add_child(btn_marcar_todos)

    # Cabecera tabla
    var header = _crear_cabecera_tabla(["Asunto", "De", "Fecha"])
    vbox.add_child(header)
    vbox.add_child(_separador())

    # Scroll con lista
    var scroll = ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vbox.add_child(scroll)

    _vbox_inbox = VBoxContainer.new()
    _vbox_inbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _vbox_inbox.add_theme_constant_override("separation", 2)
    scroll.add_child(_vbox_inbox)

    return vbox


# ── PANEL ESCRIBIR ────────────────────────────────────────────
func _construir_panel_escribir(parent: Control) -> Control:
    var vbox = VBoxContainer.new()
    vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    vbox.add_theme_constant_override("separation", 10)
    parent.add_child(vbox)

    var lbl_titulo = _lbl("✏ Nuevo Mensaje", 16, C_TITULO)
    vbox.add_child(lbl_titulo)

    vbox.add_child(_lbl("Destinatario (nombre exacto del jugador):", 12, C_TENUE))
    _input_destinatario = LineEdit.new()
    _input_destinatario.placeholder_text = "Nombre del jugador..."
    _input_destinatario.add_theme_font_size_override("font_size", 13)
    vbox.add_child(_input_destinatario)

    vbox.add_child(_lbl("Asunto:", 12, C_TENUE))
    _input_asunto = LineEdit.new()
    _input_asunto.placeholder_text = "Asunto del mensaje..."
    _input_asunto.add_theme_font_size_override("font_size", 13)
    vbox.add_child(_input_asunto)

    vbox.add_child(_lbl("Mensaje:", 12, C_TENUE))
    _txt_mensaje = TextEdit.new()
    _txt_mensaje.custom_minimum_size = Vector2(0, 200)
    _txt_mensaje.placeholder_text = "Escribí tu mensaje aquí..."
    _txt_mensaje.add_theme_font_size_override("font_size", 13)
    _txt_mensaje.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vbox.add_child(_txt_mensaje)

    var btn_enviar = Button.new()
    btn_enviar.text = "📨 Enviar Mensaje"
    btn_enviar.add_theme_font_size_override("font_size", 14)
    btn_enviar.add_theme_color_override("font_color", C_VERDE)
    btn_enviar.pressed.connect(_on_enviar_mensaje)
    vbox.add_child(btn_enviar)

    _lbl_envio_status = _lbl("", 12, C_VERDE)
    _lbl_envio_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(_lbl_envio_status)

    return vbox


# ── PANEL ENVIADOS ────────────────────────────────────────────
func _construir_panel_enviados(parent: Control) -> Control:
    var vbox = VBoxContainer.new()
    vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    vbox.add_theme_constant_override("separation", 6)
    parent.add_child(vbox)

    var btn_recargar = Button.new()
    btn_recargar.text = "↻ Actualizar"
    btn_recargar.add_theme_font_size_override("font_size", 12)
    btn_recargar.pressed.connect(_cargar_enviados)
    vbox.add_child(btn_recargar)

    var header = _crear_cabecera_tabla(["Asunto", "Para", "Fecha"])
    vbox.add_child(header)
    vbox.add_child(_separador())

    var scroll = ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vbox.add_child(scroll)

    _vbox_enviados = VBoxContainer.new()
    _vbox_enviados.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _vbox_enviados.add_theme_constant_override("separation", 2)
    scroll.add_child(_vbox_enviados)

    return vbox


# ── PANEL REPORTES ────────────────────────────────────────────
func _construir_panel_reportes(parent: Control) -> Control:
    var vbox = VBoxContainer.new()
    vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    vbox.add_theme_constant_override("separation", 6)
    parent.add_child(vbox)

    var hbox_acc = HBoxContainer.new()
    hbox_acc.add_theme_constant_override("separation", 8)
    vbox.add_child(hbox_acc)

    var btn_recargar = Button.new()
    btn_recargar.text = "↻ Actualizar"
    btn_recargar.add_theme_font_size_override("font_size", 12)
    btn_recargar.pressed.connect(_cargar_reportes)
    hbox_acc.add_child(btn_recargar)

    var lbl_nota = _lbl("Los reportes se borran automáticamente después de 60 días.", 10, C_TENUE)
    hbox_acc.add_child(lbl_nota)

    var header = _crear_cabecera_tabla(["Informe", "Rival", "Resultado", "Fecha"])
    vbox.add_child(header)
    vbox.add_child(_separador())

    var scroll = ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    vbox.add_child(scroll)

    _vbox_reportes = VBoxContainer.new()
    _vbox_reportes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _vbox_reportes.add_theme_constant_override("separation", 2)
    scroll.add_child(_vbox_reportes)

    return vbox


# ============================================================
# CARGA DE DATOS
# ============================================================
func _cargar_inbox() -> void:
    _lbl_status.text = "Cargando..."
    for child in _vbox_inbox.get_children(): child.queue_free()

    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(func(_r, code, _h, body):
        http.queue_free()
        _on_inbox_cargado(code, body)
    )

    var query = {
        "structuredQuery": {
            "from": [{"collectionId": "messages"}],
            "where": {
                "compositeFilter": {
                    "op": "AND",
                    "filters": [
                        {"fieldFilter": {"field": {"fieldPath": "to_player_id"}, "op": "EQUAL", "value": {"stringValue": GameData.player_id}}},
                        {"fieldFilter": {"field": {"fieldPath": "type"}, "op": "EQUAL", "value": {"stringValue": "mensaje"}}}
                    ]
                }
            },
            "orderBy": [{"field": {"fieldPath": "timestamp"}, "direction": "DESCENDING"}],
            "limit": 50
        }
    }
    _http_query(http, query)


func _on_inbox_cargado(code: int, body: PackedByteArray) -> void:
    _lbl_status.text = ""
    if code != 200: return
    var data = JSON.parse_string(body.get_string_from_utf8())
    _mensajes_inbox = _parsear_mensajes(data)
    _poblar_lista(_vbox_inbox, _mensajes_inbox, "inbox")
    MessageManager.cargar_no_leidos()


func _cargar_enviados() -> void:
    for child in _vbox_enviados.get_children(): child.queue_free()

    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(func(_r, code, _h, body):
        http.queue_free()
        _on_enviados_cargado(code, body)
    )

    var query = {
        "structuredQuery": {
            "from": [{"collectionId": "messages"}],
            "where": {
                "compositeFilter": {
                    "op": "AND",
                    "filters": [
                        {"fieldFilter": {"field": {"fieldPath": "from_player_id"}, "op": "EQUAL", "value": {"stringValue": GameData.player_id}}},
                        {"fieldFilter": {"field": {"fieldPath": "type"}, "op": "EQUAL", "value": {"stringValue": "mensaje"}}}
                    ]
                }
            },
            "orderBy": [{"field": {"fieldPath": "timestamp"}, "direction": "DESCENDING"}],
            "limit": 50
        }
    }
    _http_query(http, query)


func _on_enviados_cargado(code: int, body: PackedByteArray) -> void:
    if code != 200: return
    var data = JSON.parse_string(body.get_string_from_utf8())
    _mensajes_enviados = _parsear_mensajes(data)
    _poblar_lista(_vbox_enviados, _mensajes_enviados, "enviados")


func _cargar_reportes() -> void:
    for child in _vbox_reportes.get_children(): child.queue_free()
    _mensajes_reportes = []
    # Cargar los 3 tipos de reporte por separado (evita NOT_EQUAL que requiere índice)
    _cargar_reportes_tipo("pve")
    _cargar_reportes_tipo("pvp_ataque")
    _cargar_reportes_tipo("pvp_defensa")


func _cargar_reportes_tipo(tipo: String) -> void:
    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(func(_r, code, _h, body):
        http.queue_free()
        _on_reportes_tipo_cargado(code, body)
    )
    var query = {
        "structuredQuery": {
            "from": [{"collectionId": "messages"}],
            "where": {
                "compositeFilter": {
                    "op": "AND",
                    "filters": [
                        {"fieldFilter": {"field": {"fieldPath": "to_player_id"}, "op": "EQUAL", "value": {"stringValue": GameData.player_id}}},
                        {"fieldFilter": {"field": {"fieldPath": "type"}, "op": "EQUAL", "value": {"stringValue": tipo}}}
                    ]
                }
            },
            "orderBy": [{"field": {"fieldPath": "timestamp"}, "direction": "DESCENDING"}],
            "limit": 50
        }
    }
    _http_query(http, query)


func _on_reportes_tipo_cargado(code: int, body: PackedByteArray) -> void:
    if code != 200:
        print("Mailbox error cargando reportes: ", code)
        return
    var data = JSON.parse_string(body.get_string_from_utf8())
    var nuevos = _parsear_mensajes(data)
    _mensajes_reportes.append_array(nuevos)
    # Ordenar por timestamp descendente y repoblar
    _mensajes_reportes.sort_custom(func(a, b): return a.get("timestamp", 0) > b.get("timestamp", 0))
    _poblar_reportes()


func _on_reportes_cargado(code: int, body: PackedByteArray) -> void:
    pass  # Reemplazado por _on_reportes_tipo_cargado


# ============================================================
# POBLAR LISTAS
# ============================================================
func _parsear_mensajes(data) -> Array:
    var lista = []
    if not data is Array: return lista
    for entry in data:
        if not entry.has("document"): continue
        var doc  = entry["document"]
        if not doc.has("fields"): continue
        var f    = doc["fields"]
        var parts = doc.get("name", "").split("/")
        lista.append({
            "id":        parts[parts.size() - 1],
            "from_name": _ls(f, "from_name"),
            "to_name":   _ls(f, "to_name"),
            "type":      _ls(f, "type"),
            "title":     _ls(f, "title"),
            "body":      _ls(f, "body"),
            "leido":     f.get("leido", {}).get("booleanValue", false),
            "timestamp": int(_ls(f, "timestamp")),
        })
    return lista


func _poblar_lista(vbox: VBoxContainer, lista: Array, modo: String) -> void:
    for child in vbox.get_children(): child.queue_free()

    if lista.is_empty():
        var lbl = _lbl("No hay mensajes.", 13, C_TENUE)
        lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        vbox.add_child(lbl)
        return

    for msg in lista:
        var fila = _crear_fila_mensaje(msg, modo)
        vbox.add_child(fila)


func _crear_fila_mensaje(msg: Dictionary, modo: String) -> PanelContainer:
    var fila = PanelContainer.new()
    var sf = StyleBoxFlat.new()
    sf.bg_color = Color(0.13, 0.09, 0.05, 1) if msg.get("leido", true) else Color(0.15, 0.12, 0.06, 1)
    if not msg.get("leido", true):
        sf.border_color = C_ORO
        sf.border_width_left = 3
    sf.corner_radius_top_left     = 3
    sf.corner_radius_top_right    = 3
    sf.corner_radius_bottom_left  = 3
    sf.corner_radius_bottom_right = 3
    fila.add_theme_stylebox_override("panel", sf)

    var hbox = HBoxContainer.new()
    hbox.add_theme_constant_override("separation", 8)
    fila.add_child(hbox)

    # Ícono leído/no leído
    var lbl_dot = _lbl("●" if not msg.get("leido", true) else "○", 12,
        C_ORO if not msg.get("leido", true) else C_TENUE)
    lbl_dot.custom_minimum_size = Vector2(16, 0)
    hbox.add_child(lbl_dot)

    # Asunto (clickeable para ver detalle)
    var btn_asunto = Button.new()
    btn_asunto.text = msg.get("title", "Sin asunto")
    btn_asunto.flat = true
    btn_asunto.alignment = HORIZONTAL_ALIGNMENT_LEFT
    btn_asunto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    btn_asunto.add_theme_font_size_override("font_size", 12)
    btn_asunto.add_theme_color_override("font_color",
        C_TEXTO if msg.get("leido", true) else Color(1.0, 0.95, 0.7, 1))
    var msg_c = msg.duplicate()
    btn_asunto.pressed.connect(func(): _abrir_mensaje(msg_c))
    hbox.add_child(btn_asunto)

    # De / Para
    var nombre_secundario = msg.get("from_name", "?") if modo == "inbox" else msg.get("to_name", "?")
    var lbl_de = _lbl(nombre_secundario, 11, C_TENUE)
    lbl_de.custom_minimum_size = Vector2(130, 0)
    lbl_de.clip_text = true
    hbox.add_child(lbl_de)

    # Fecha
    var fecha = _timestamp_a_fecha(msg.get("timestamp", 0))
    var lbl_fecha = _lbl(fecha, 10, C_TENUE)
    lbl_fecha.custom_minimum_size = Vector2(80, 0)
    hbox.add_child(lbl_fecha)

    # Botón borrar
    var btn_borrar = Button.new()
    btn_borrar.text = "🗑"
    btn_borrar.flat = true
    btn_borrar.add_theme_font_size_override("font_size", 12)
    var id_c = msg.get("id", "")
    var fila_c = fila
    btn_borrar.pressed.connect(func():
        MessageManager.borrar_mensaje(id_c)
        fila_c.queue_free()
        MessageManager.cargar_no_leidos()
    )
    hbox.add_child(btn_borrar)

    return fila


func _poblar_reportes() -> void:
    for child in _vbox_reportes.get_children(): child.queue_free()

    if _mensajes_reportes.is_empty():
        var lbl = _lbl("No hay reportes de batalla.", 13, C_TENUE)
        lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        _vbox_reportes.add_child(lbl)
        return

    # Cabecera estilo Gladiatus
    var header = HBoxContainer.new()
    header.add_theme_constant_override("separation", 0)
    var hp = PanelContainer.new()
    var sh = StyleBoxFlat.new()
    sh.bg_color = Color(0.18, 0.13, 0.07, 1)
    hp.add_theme_stylebox_override("panel", sh)
    hp.add_child(header)
    _vbox_reportes.add_child(hp)

    _cab_reporte(header, "Fecha",    110)
    _cab_reporte(header, "Nombre",   0,   true)
    _cab_reporte(header, "Botín",    80)
    _cab_reporte(header, "",         90)

    _vbox_reportes.add_child(_separador())

    for msg in _mensajes_reportes:
        var fila = _crear_fila_reporte(msg)
        _vbox_reportes.add_child(fila)


func _cab_reporte(parent: HBoxContainer, texto: String, ancho: int, expandir: bool = false) -> void:
    var lbl = _lbl(texto, 11, C_ORO)
    if expandir:
        lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    else:
        lbl.custom_minimum_size = Vector2(ancho, 0)
    parent.add_child(lbl)


func _crear_fila_reporte(msg: Dictionary) -> PanelContainer:
    var tipo = msg.get("type", "pve")
    var leido = msg.get("leido", true)

    # Verde = ataque mío (pve o pvp_ataque), Rojo = me atacaron (pvp_defensa)
    var es_ataque_mio = (tipo == "pve" or tipo == "pvp_ataque")
    var color_fila = Color(0.05, 0.14, 0.05, 1) if es_ataque_mio else Color(0.16, 0.04, 0.04, 1)
    var color_borde = C_VERDE if es_ataque_mio else C_ROJO
    var color_texto = Color(0.55, 0.95, 0.55, 1) if es_ataque_mio else Color(0.95, 0.55, 0.55, 1)

    if leido:
        color_fila = Color(color_fila.r * 0.6, color_fila.g * 0.6, color_fila.b * 0.6, 1)

    var fila = PanelContainer.new()
    var sf = StyleBoxFlat.new()
    sf.bg_color     = color_fila
    sf.border_color = color_borde
    sf.border_width_left = 3 if not leido else 1
    sf.border_width_right = 0
    sf.border_width_top = 0
    sf.border_width_bottom = 0
    sf.corner_radius_top_left     = 2
    sf.corner_radius_top_right    = 2
    sf.corner_radius_bottom_left  = 2
    sf.corner_radius_bottom_right = 2
    fila.add_theme_stylebox_override("panel", sf)

    var hbox = HBoxContainer.new()
    hbox.add_theme_constant_override("separation", 0)
    fila.add_child(hbox)

    # Fecha
    var lbl_fecha = _lbl(_timestamp_a_fecha(msg.get("timestamp", 0)), 11, C_TENUE)
    lbl_fecha.custom_minimum_size = Vector2(110, 0)
    hbox.add_child(lbl_fecha)

    # Nombre (título del reporte) — clickeable
    var btn_nom = Button.new()
    btn_nom.text = msg.get("title", "Informe")
    btn_nom.flat = true
    btn_nom.alignment = HORIZONTAL_ALIGNMENT_LEFT
    btn_nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    btn_nom.add_theme_font_size_override("font_size", 12)
    btn_nom.add_theme_color_override("font_color", color_texto if not leido else C_TENUE)
    var msg_c = msg.duplicate()
    btn_nom.pressed.connect(func(): _abrir_reporte_detalle(msg_c))
    hbox.add_child(btn_nom)

    # Botín (extraído del body si existe)
    var botin_txt = _extraer_botin(msg.get("body", ""))
    var lbl_botin = _lbl(botin_txt, 11, C_AMARILLO)
    lbl_botin.custom_minimum_size = Vector2(80, 0)
    hbox.add_child(lbl_botin)

    # Botón Ver detalles
    var btn_ver = Button.new()
    btn_ver.text = "Ver detalles →"
    btn_ver.add_theme_font_size_override("font_size", 11)
    btn_ver.add_theme_color_override("font_color", color_borde)
    btn_ver.flat = true
    btn_ver.custom_minimum_size = Vector2(90, 0)
    btn_ver.pressed.connect(func(): _abrir_reporte_detalle(msg_c))
    hbox.add_child(btn_ver)

    # Borrar
    var btn_borrar = Button.new()
    btn_borrar.text = "🗑"
    btn_borrar.flat = true
    btn_borrar.add_theme_font_size_override("font_size", 11)
    var id_c = msg.get("id", "")
    var fila_c = fila
    btn_borrar.pressed.connect(func():
        MessageManager.borrar_mensaje(id_c)
        fila_c.queue_free()
        MessageManager.cargar_no_leidos()
    )
    hbox.add_child(btn_borrar)

    return fila


func _extraer_botin(body: String) -> String:
    # Busca "🪙 Bronce ganado: +XXX" en el body
    var lineas = body.split("
")
    for linea in lineas:
        if "Bronce" in linea and "+" in linea:
            var partes = linea.split("+")
            if partes.size() > 1:
                return "🪙 " + partes[1].strip_edges().split("
")[0]
    return ""


func _abrir_reporte_detalle(msg: Dictionary) -> void:
    # Marcar como leído
    if not msg.get("leido", false):
        MessageManager.marcar_leido(msg.get("id", ""))

    if _panel_detalle:
        _panel_detalle.queue_free()

    _panel_detalle = PanelContainer.new()
    _panel_detalle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _panel_detalle.z_index = 50

    var tipo = msg.get("type", "pve")
    var es_ataque_mio = (tipo == "pve" or tipo == "pvp_ataque")
    var color_acento = C_VERDE if es_ataque_mio else C_ROJO

    var sd = StyleBoxFlat.new()
    sd.bg_color     = Color(0.05, 0.03, 0.02, 0.98)
    sd.border_color = color_acento
    sd.border_width_top = 2
    _panel_detalle.add_theme_stylebox_override("panel", sd)
    add_child(_panel_detalle)

    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left",   18)
    margin.add_theme_constant_override("margin_right",  18)
    margin.add_theme_constant_override("margin_top",    14)
    margin.add_theme_constant_override("margin_bottom", 14)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _panel_detalle.add_child(margin)

    var inner = VBoxContainer.new()
    inner.add_theme_constant_override("separation", 10)
    margin.add_child(inner)

    # Encabezado del reporte
    var hbox_top = HBoxContainer.new()
    inner.add_child(hbox_top)

    var lbl_titulo = _lbl(msg.get("title", "Informe de Batalla"), 20, color_acento)
    lbl_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hbox_top.add_child(lbl_titulo)

    var btn_volver = Button.new()
    btn_volver.text = "◀ Volver"
    btn_volver.add_theme_font_size_override("font_size", 13)
    btn_volver.pressed.connect(func():
        _panel_detalle.queue_free()
        _panel_detalle = null
        _cargar_reportes()
    )
    hbox_top.add_child(btn_volver)

    # Fecha
    var lbl_meta = _lbl(_timestamp_a_fecha(msg.get("timestamp", 0)) + "   •   " + msg.get("from_name", ""), 11, C_TENUE)
    inner.add_child(lbl_meta)

    inner.add_child(_separador())

    # Body con scroll
    var scroll_body = ScrollContainer.new()
    scroll_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    inner.add_child(scroll_body)

    var lbl_body = Label.new()
    lbl_body.text = msg.get("body", "")
    lbl_body.add_theme_font_size_override("font_size", 12)
    lbl_body.add_theme_color_override("font_color", C_TEXTO)
    lbl_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    lbl_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll_body.add_child(lbl_body)


# ============================================================
# VER DETALLE DEL MENSAJE
# ============================================================
func _abrir_mensaje(msg: Dictionary) -> void:
    # Marcar como leído
    if not msg.get("leido", false):
        MessageManager.marcar_leido(msg.get("id", ""))
        msg["leido"] = true

    # Crear overlay de detalle
    if _panel_detalle:
        _panel_detalle.queue_free()

    _panel_detalle = PanelContainer.new()
    _panel_detalle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _panel_detalle.z_index = 50
    var sd = StyleBoxFlat.new()
    sd.bg_color     = Color(0.05, 0.03, 0.02, 0.97)
    sd.border_color = C_BORDE
    sd.border_width_left   = 1
    sd.border_width_right  = 1
    sd.border_width_top    = 1
    sd.border_width_bottom = 1
    _panel_detalle.add_theme_stylebox_override("panel", sd)
    add_child(_panel_detalle)

    var vbox = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 10)
    _panel_detalle.add_child(vbox)

    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left",   20)
    margin.add_theme_constant_override("margin_right",  20)
    margin.add_theme_constant_override("margin_top",    14)
    margin.add_theme_constant_override("margin_bottom", 14)
    _panel_detalle.add_child(margin)

    var inner = VBoxContainer.new()
    inner.add_theme_constant_override("separation", 10)
    margin.add_child(inner)

    # Header del detalle
    var hbox_top = HBoxContainer.new()
    inner.add_child(hbox_top)

    var lbl_asunto = _lbl(msg.get("title", ""), 18, C_ORO)
    lbl_asunto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    lbl_asunto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hbox_top.add_child(lbl_asunto)

    var btn_cerrar_detalle = Button.new()
    btn_cerrar_detalle.text = "✕ Volver"
    btn_cerrar_detalle.add_theme_font_size_override("font_size", 12)
    btn_cerrar_detalle.pressed.connect(func(): _panel_detalle.queue_free(); _panel_detalle = null)
    hbox_top.add_child(btn_cerrar_detalle)

    # Meta info
    var tipo = msg.get("type", "mensaje")
    var color_tipo = C_VERDE if tipo == "pve" else (C_ROJO if tipo == "pvp_ataque" else (C_AMARILLO if tipo == "pvp_defensa" else C_AZUL))
    var meta = "De: " + msg.get("from_name", "?") + "   •   " + _timestamp_a_fecha(msg.get("timestamp", 0))
    var lbl_meta = _lbl(meta, 11, C_TENUE)
    inner.add_child(lbl_meta)

    inner.add_child(_separador())

    # Cuerpo del mensaje con scroll
    var scroll_body = ScrollContainer.new()
    scroll_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    inner.add_child(scroll_body)

    var lbl_body = _lbl(msg.get("body", ""), 12, C_TEXTO)
    lbl_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    lbl_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll_body.add_child(lbl_body)

    # Actualizar lista después de marcar leído
    if tipo == "mensaje":
        _cargar_inbox()
    else:
        _cargar_reportes()


# ============================================================
# ENVIAR MENSAJE
# ============================================================
func _on_enviar_mensaje() -> void:
    var dest   = _input_destinatario.text.strip_edges()
    var asunto = _input_asunto.text.strip_edges()
    var cuerpo = _txt_mensaje.text.strip_edges()

    if dest == "" or asunto == "" or cuerpo == "":
        _lbl_envio_status.text = "Completa todos los campos."
        _lbl_envio_status.add_theme_color_override("font_color", C_ROJO)
        return

    if dest == GameData.player_name:
        _lbl_envio_status.text = "No podés enviarte mensajes a vos mismo."
        _lbl_envio_status.add_theme_color_override("font_color", C_ROJO)
        return

    _lbl_envio_status.text = "Buscando jugador..."
    _lbl_envio_status.add_theme_color_override("font_color", C_TENUE)

    # Buscar directamente en players por username (el nick del juego)
    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(func(_r, code, _h, body):
        http.queue_free()
        _on_player_encontrado(code, body, dest, asunto, cuerpo)
    )
    var query = {
        "structuredQuery": {
            "from": [{"collectionId": "players"}],
            "where": {
                "fieldFilter": {
                    "field": {"fieldPath": "username"},
                    "op": "EQUAL",
                    "value": {"stringValue": dest}
                }
            },
            "limit": 1
        }
    }
    _http_query(http, query)


func _on_player_encontrado(code: int, body: PackedByteArray,
                            dest_name: String, asunto: String, cuerpo: String) -> void:
    if code != 200:
        _lbl_envio_status.text = "Error de conexion. Intenta de nuevo."
        _lbl_envio_status.add_theme_color_override("font_color", C_ROJO)
        return

    var data = JSON.parse_string(body.get_string_from_utf8())
    if not data is Array or data.is_empty() or not data[0].has("document"):
        _lbl_envio_status.text = "Jugador '" + dest_name + "' no encontrado."
        _lbl_envio_status.add_theme_color_override("font_color", C_ROJO)
        return

    var doc     = data[0]["document"]
    var parts   = doc.get("name", "").split("/")
    var dest_id = parts[parts.size() - 1]

    # Guardar el mensaje
    var ahora  = int(Time.get_unix_time_from_system())
    var msg_id = str(ahora) + "_msg_" + GameData.player_id.substr(0, 6)

    var fields = {
        "to_player_id":   {"stringValue": dest_id},
        "to_name":        {"stringValue": dest_name},
        "from_player_id": {"stringValue": GameData.player_id},
        "from_name":      {"stringValue": GameData.player_name},
        "type":           {"stringValue": "mensaje"},
        "title":          {"stringValue": asunto},
        "body":           {"stringValue": cuerpo},
        "leido":          {"booleanValue": false},
        "timestamp":      {"integerValue": str(ahora)},
        "expires_at":     {"integerValue": str(ahora + 60 * 86400)},
    }

    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(func(_r, c, _h, _b):
        http.queue_free()
        if c == 200 or c == 201:
            _lbl_envio_status.text = "✅ Mensaje enviado a " + dest_name + "."
            _lbl_envio_status.add_theme_color_override("font_color", C_VERDE)
            _input_destinatario.text = ""
            _input_asunto.text = ""
            _txt_mensaje.text = ""
        else:
            _lbl_envio_status.text = "❌ Error al enviar. Código: " + str(c)
            _lbl_envio_status.add_theme_color_override("font_color", C_ROJO)
    )

    var url = GameData.FIRESTORE_URL + "messages/" + msg_id
    http.request(url, _headers(), HTTPClient.METHOD_PATCH, JSON.stringify({"fields": fields}))


# ============================================================
# MARCAR TODOS COMO LEÍDOS
# ============================================================
func _marcar_todos_inbox() -> void:
    for msg in _mensajes_inbox:
        if not msg.get("leido", false):
            MessageManager.marcar_leido(msg.get("id", ""))
    await get_tree().create_timer(0.5).timeout
    _cargar_inbox()


# ============================================================
# CAMBIO DE TABS
# ============================================================
func _cambiar_tab(idx: int) -> void:
    _tab_activa = idx
    for i in range(_panels.size()):
        _panels[i].visible = (i == idx)
    _actualizar_estilo_tabs()

    # Cargar datos según tab
    match idx:
        0: _cargar_inbox()
        2: _cargar_enviados()
        3: _cargar_reportes()


func _actualizar_estilo_tabs() -> void:
    var colores = [C_AZUL, C_VERDE, C_AMARILLO, C_ROJO]
    for i in range(_tabs.size()):
        if i == _tab_activa:
            _tabs[i].add_theme_color_override("font_color", colores[i])
        else:
            _tabs[i].add_theme_color_override("font_color", C_TENUE)


# ============================================================
# HELPERS
# ============================================================
func _crear_cabecera_tabla(columnas: Array) -> HBoxContainer:
    var hbox = HBoxContainer.new()
    hbox.add_theme_constant_override("separation", 8)
    for i in range(columnas.size()):
        var lbl = _lbl(columnas[i], 11, C_ORO)
        if i == 0:
            lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        else:
            lbl.custom_minimum_size = Vector2(100 if i == 1 else 80, 0)
        hbox.add_child(lbl)
    # Espacio para botón borrar
    var lbl_acc = _lbl("", 11, C_TENUE)
    lbl_acc.custom_minimum_size = Vector2(28, 0)
    hbox.add_child(lbl_acc)
    return hbox


func _separador() -> HSeparator:
    return HSeparator.new()


func _lbl(txt: String, size: int, color: Color) -> Label:
    var l = Label.new()
    l.text = txt
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    return l


func _timestamp_a_fecha(ts: int) -> String:
    if ts == 0: return "—"
    var dt = Time.get_datetime_dict_from_unix_time(ts)
    return "%02d/%02d  %02d:%02d" % [dt.day, dt.month, dt.hour, dt.minute]


func _http_query(http: HTTPRequest, query: Dictionary) -> void:
    var url = "https://firestore.googleapis.com/v1/projects/atepaia-2v/databases/(default)/documents:runQuery"
    http.request(url, _headers(), HTTPClient.METHOD_POST, JSON.stringify(query))


func _headers() -> PackedStringArray:
    return PackedStringArray([
        "Content-Type: application/json",
        "Authorization: Bearer " + GameData.id_token
    ])


func _ls(f: Dictionary, k: String) -> String:
    if f.has(k):
        if f[k].has("stringValue"):  return f[k]["stringValue"]
        if f[k].has("integerValue"): return f[k]["integerValue"]
    return ""
