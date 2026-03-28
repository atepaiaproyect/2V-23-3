extends Control

# ─────────────────────────────────────────────────────────
# CRAFTEO — Sistema básico
# Combinar ítems para crear versiones mejoradas
# Los puntos de artesano = nivel_item crafteado
# ─────────────────────────────────────────────────────────

# Recetas básicas: 2 ítems del mismo tipo y nivel → 1 ítem nivel+1
# Ejemplo: 2x Katana Oxidada (lvl1) → 1x Espada de Bronce (lvl2)

var _http: HTTPRequest
var _inventario_items: Array = []

var _vbox_recetas: VBoxContainer
var _lbl_status:   Label
var _lbl_puntos:   Label

func _ready() -> void:
    _http = HTTPRequest.new()
    add_child(_http)
    _construir_ui()
    _cargar_inventario()

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
    margin.add_theme_constant_override("margin_left",   16)
    margin.add_theme_constant_override("margin_right",  16)
    margin.add_theme_constant_override("margin_top",    12)
    margin.add_theme_constant_override("margin_bottom", 14)
    outer.add_child(margin)

    var inner = VBoxContainer.new()
    inner.add_theme_constant_override("separation", 12)
    margin.add_child(inner)

    # Título
    var lbl_titulo = _lbl("⚒  HERRERÍA", 20, Color(0.9, 0.75, 0.3, 1))
    lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    inner.add_child(lbl_titulo)

    # Puntos de artesano
    _lbl_puntos = _lbl("Puntos de artesano: " + str(GameData.craft_points), 13, Color(0.4, 0.9, 0.5, 1))
    _lbl_puntos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    inner.add_child(_lbl_puntos)

    var lbl_desc = _lbl("Combiná 2 ítems iguales del mismo nivel para crear uno mejor.", 11, Color(0.6, 0.6, 0.55, 1))
    lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
    inner.add_child(lbl_desc)

    _lbl_status = _lbl("Cargando inventario...", 11, Color(0.55, 0.55, 0.55, 1))
    _lbl_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    inner.add_child(_lbl_status)

    inner.add_child(HSeparator.new())

    var lbl_recetas = _lbl("— RECETAS DISPONIBLES —", 13, Color(0.9, 0.75, 0.3, 1))
    lbl_recetas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    inner.add_child(lbl_recetas)

    _vbox_recetas = VBoxContainer.new()
    _vbox_recetas.add_theme_constant_override("separation", 8)
    inner.add_child(_vbox_recetas)

func _cargar_inventario() -> void:
    if not FileAccess.file_exists("res://data/items_database/items_database.json"):
        _lbl_status.text = "Error: no se encontró la base de ítems."
        return
    var db = JSON.parse_string(FileAccess.get_file_as_string("res://data/items_database/items_database.json"))
    if db == null:
        return

    # Contar ítems en el inventario del jugador (los que NO están equipados)
    _inventario_items = []
    var equipados_ids: Array = []
    for item in [GameData.equipped_weapon, GameData.equipped_shield, GameData.equipped_chest,
                 GameData.equipped_helmet, GameData.equipped_boots, GameData.equipped_gloves,
                 GameData.equipped_neck, GameData.equipped_ring_l, GameData.equipped_ring_r, GameData.equipped_cape]:
        if not item.is_empty():
            equipados_ids.append(item.get("id", ""))

    for categoria in ["armas", "escudos", "pecho"]:
        if db.has(categoria):
            for item in db[categoria]:
                if item.get("id", "") not in equipados_ids:
                    var i = item.duplicate()
                    i["categoria"] = categoria
                    _inventario_items.append(i)

    _lbl_status.text = str(_inventario_items.size()) + " ítems disponibles en inventario"
    _construir_recetas(db)

func _construir_recetas(db: Dictionary) -> void:
    for child in _vbox_recetas.get_children():
        child.queue_free()

    # Buscar combinaciones posibles: 2 del mismo ítem
    var conteo: Dictionary = {}
    for item in _inventario_items:
        var id = item.get("id", "")
        if not conteo.has(id):
            conteo[id] = { "item": item, "cantidad": 0 }
        conteo[id]["cantidad"] += 1

    var recetas_validas: Array = []
    for id in conteo:
        if conteo[id]["cantidad"] >= 2:
            var item_base = conteo[id]["item"]
            var item_resultado = _buscar_siguiente_nivel(db, item_base)
            if item_resultado != null:
                recetas_validas.append({
                    "ingrediente": item_base,
                    "resultado":   item_resultado,
                    "cantidad":    conteo[id]["cantidad"],
                })

    if recetas_validas.is_empty():
        _vbox_recetas.add_child(_lbl("No tenés ítems suficientes para craftear nada.\nNecesitás 2 copias del mismo ítem.", 11, Color(0.5, 0.5, 0.5, 1)))
        return

    for receta in recetas_validas:
        _vbox_recetas.add_child(_crear_card_receta(receta))

func _buscar_siguiente_nivel(db: Dictionary, item_base: Dictionary) -> Dictionary:
    var categoria = item_base.get("categoria", "")
    var nivel_base = item_base.get("nivel", 1)
    if not db.has(categoria):
        return {}
    for item in db[categoria]:
        if item.get("nivel", 1) == nivel_base + 1:
            var r = item.duplicate()
            r["categoria"] = categoria
            return r
    return {}

func _crear_card_receta(receta: Dictionary) -> PanelContainer:
    var panel = PanelContainer.new()
    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left",   12)
    margin.add_theme_constant_override("margin_right",  12)
    margin.add_theme_constant_override("margin_top",    10)
    margin.add_theme_constant_override("margin_bottom", 10)
    panel.add_child(margin)

    var hbox = HBoxContainer.new()
    hbox.add_theme_constant_override("separation", 16)
    margin.add_child(hbox)

    # Ingredientes
    var vbox_ing = VBoxContainer.new()
    vbox_ing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vbox_ing.add_theme_constant_override("separation", 3)
    hbox.add_child(vbox_ing)

    var ing = receta["ingrediente"]
    var cant = receta["cantidad"]
    vbox_ing.add_child(_lbl("INGREDIENTES:", 10, Color(0.6, 0.6, 0.55, 1)))
    vbox_ing.add_child(_lbl("2x " + ing.get("nombre", "?") + "  (tienes " + str(cant) + ")", 12, Color(0.9, 0.85, 0.7, 1)))
    vbox_ing.add_child(_lbl("Nivel " + str(ing.get("nivel", 1)), 10, Color(0.6, 0.6, 0.55, 1)))

    # Flecha
    hbox.add_child(_lbl("→", 18, Color(0.9, 0.75, 0.3, 1)))

    # Resultado
    var vbox_res = VBoxContainer.new()
    vbox_res.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vbox_res.add_theme_constant_override("separation", 3)
    hbox.add_child(vbox_res)

    var res = receta["resultado"]
    var pts = res.get("nivel", 1)
    vbox_res.add_child(_lbl("RESULTADO:", 10, Color(0.6, 0.6, 0.55, 1)))
    vbox_res.add_child(_lbl("1x " + res.get("nombre", "?"), 12, Color(0.4, 0.9, 0.5, 1)))
    vbox_res.add_child(_lbl("Nivel " + str(res.get("nivel", 1)) + "  ⚒ +" + str(pts) + " pts artesano", 10, Color(0.4, 0.7, 0.4, 1)))

    # Botón craftear
    var btn = Button.new()
    btn.text = "⚒  Craftear"
    btn.custom_minimum_size = Vector2(100, 40)
    btn.add_theme_font_size_override("font_size", 12)
    btn.pressed.connect(_on_craftear.bind(receta))
    hbox.add_child(btn)

    return panel

func _on_craftear(receta: Dictionary) -> void:
    var ingrediente = receta["ingrediente"]
    var resultado   = receta["resultado"]

    # Quitar 2 ingredientes del inventario (en los slots)
    var quitados = 0
    for slot in get_tree().get_nodes_in_group("inventory_slots"):
        if quitados >= 2:
            break
        if slot.item_data.get("id", "") == ingrediente.get("id", ""):
            slot.clear_slot()
            quitados += 1

    if quitados < 2:
        _lbl_status.text = "Error: no se encontraron los ítems en el inventario."
        return

    # Agregar resultado al primer slot libre
    for slot in get_tree().get_nodes_in_group("inventory_slots"):
        if slot.item_data.is_empty():
            slot.set_item(resultado)
            break

    # Sumar puntos de artesano
    var pts = resultado.get("nivel", 1)
    GameData.craft_points += pts
    _lbl_puntos.text = "Puntos de artesano: " + str(GameData.craft_points)
    _lbl_status.text = "✔ ¡Crafteaste " + resultado.get("nombre","?") + "! +" + str(pts) + " pts"

    # Guardar progreso y actualizar clan
    SaveManager.save_progress()
    SaveManager.save_clan_stats(0, 0, 0, pts)

    # Recargar recetas
    _cargar_inventario()

func _lbl(txt: String, size: int, color: Color) -> Label:
    var l = Label.new()
    l.text = txt
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    return l
