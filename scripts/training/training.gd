extends Control

var _attr_cards: Dictionary = {}

func _ready() -> void:
    _construir_ui()

func _construir_ui() -> void:
    var bg = ColorRect.new()
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.color = Color(0.06, 0.04, 0.03, 1)
    add_child(bg)

    var scroll = ScrollContainer.new()
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(scroll)

    var vbox_outer = VBoxContainer.new()
    vbox_outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(vbox_outer)

    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left",   16)
    margin.add_theme_constant_override("margin_right",  16)
    margin.add_theme_constant_override("margin_top",    12)
    margin.add_theme_constant_override("margin_bottom", 12)
    vbox_outer.add_child(margin)

    var inner = VBoxContainer.new()
    inner.add_theme_constant_override("separation", 10)
    margin.add_child(inner)

    var lbl_titulo = Label.new()
    lbl_titulo.text = "— ENTRENAMIENTO —"
    lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl_titulo.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3, 1))
    lbl_titulo.add_theme_font_size_override("font_size", 18)
    inner.add_child(lbl_titulo)

    var lbl_bronze = Label.new()
    lbl_bronze.name = "LblBronze"
    lbl_bronze.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl_bronze.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3, 1))
    lbl_bronze.add_theme_font_size_override("font_size", 13)
    inner.add_child(lbl_bronze)

    inner.add_child(HSeparator.new())

    var lbl_desc = Label.new()
    lbl_desc.text = "Gastá bronce para mejorar tus atributos permanentemente.\nGanás bronce derrotando enemigos en la exploración."
    lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl_desc.add_theme_color_override("font_color", Color(0.65, 0.6, 0.5, 1))
    lbl_desc.add_theme_font_size_override("font_size", 11)
    lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
    inner.add_child(lbl_desc)

    var attrs = [
        { "key": "attr_strength",     "nombre": "⚔  Fuerza",       "desc": "Aumenta el daño en combate" },
        { "key": "attr_agility",      "nombre": "🦅  Agilidad",     "desc": "Aumenta esquiva y daño crítico" },
        { "key": "attr_dexterity",    "nombre": "🎯  Destreza",     "desc": "Aumenta golpe crítico y doble golpe" },
        { "key": "attr_constitution", "nombre": "🛡  Constitución", "desc": "Aumenta HP máximo" },
        { "key": "attr_intelligence", "nombre": "📚  Inteligencia", "desc": "Reduce costos en mercado y subastas" },
        { "key": "attr_charisma",     "nombre": "👑  Carisma",      "desc": "Aumenta bloqueo y agro en clanes" },
    ]

    for attr in attrs:
        var card = _crear_card(attr)
        inner.add_child(card)
        _attr_cards[attr["key"]] = card

    _actualizar_todo()

func _crear_card(attr: Dictionary) -> PanelContainer:
    var card = PanelContainer.new()
    card.name = "Card_" + attr["key"]

    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left",   12)
    margin.add_theme_constant_override("margin_right",  12)
    margin.add_theme_constant_override("margin_top",    10)
    margin.add_theme_constant_override("margin_bottom", 10)
    card.add_child(margin)

    var hbox = HBoxContainer.new()
    hbox.add_theme_constant_override("separation", 12)
    margin.add_child(hbox)

    var vbox_info = VBoxContainer.new()
    vbox_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    vbox_info.add_theme_constant_override("separation", 3)
    hbox.add_child(vbox_info)

    var lbl_nombre = Label.new()
    lbl_nombre.text = attr["nombre"]
    lbl_nombre.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 1))
    lbl_nombre.add_theme_font_size_override("font_size", 14)
    vbox_info.add_child(lbl_nombre)

    var lbl_desc = Label.new()
    lbl_desc.text = attr["desc"]
    lbl_desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.55, 1))
    lbl_desc.add_theme_font_size_override("font_size", 10)
    vbox_info.add_child(lbl_desc)

    var lbl_valor = Label.new()
    lbl_valor.name = "LblValor"
    lbl_valor.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0, 1))
    lbl_valor.add_theme_font_size_override("font_size", 13)
    vbox_info.add_child(lbl_valor)

    var vbox_btn = VBoxContainer.new()
    vbox_btn.add_theme_constant_override("separation", 5)
    hbox.add_child(vbox_btn)

    var lbl_costo = Label.new()
    lbl_costo.name = "LblCosto"
    lbl_costo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl_costo.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3, 1))
    lbl_costo.add_theme_font_size_override("font_size", 11)
    vbox_btn.add_child(lbl_costo)

    var btn = Button.new()
    btn.name = "BtnSubir"
    btn.text = "▲ Mejorar"
    btn.custom_minimum_size = Vector2(110, 36)
    btn.add_theme_font_size_override("font_size", 12)
    btn.pressed.connect(_on_mejorar.bind(attr["key"], card))
    vbox_btn.add_child(btn)

    return card

func _actualizar_todo() -> void:
    var lbl_bronze = find_child("LblBronze", true, false)
    if lbl_bronze:
        lbl_bronze.text = "🪙 Bronce disponible: " + str(GameData.bronze_hand)

    var attrs_map = {
        "attr_strength":     GameData.attr_strength,
        "attr_agility":      GameData.attr_agility,
        "attr_dexterity":    GameData.attr_dexterity,
        "attr_constitution": GameData.attr_constitution,
        "attr_intelligence": GameData.attr_intelligence,
        "attr_charisma":     GameData.attr_charisma,
    }

    for key in _attr_cards:
        var card        = _attr_cards[key]
        var valor       = attrs_map.get(key, 2)
        var costo       = GameData.costo_entrenamiento(valor)
        var lbl_valor   = card.find_child("LblValor", true, false)
        var lbl_costo_n = card.find_child("LblCosto",  true, false)
        var btn         = card.find_child("BtnSubir",  true, false)
        if lbl_valor:
            lbl_valor.text = "Nivel actual: " + str(valor)
        if lbl_costo_n:
            lbl_costo_n.text = "Costo: " + _fmt(costo) + " 🪙"
        if btn:
            btn.disabled = GameData.bronze_hand < costo

func _on_mejorar(attr_key: String, _card: PanelContainer) -> void:
    var valor = GameData.get(attr_key)
    var costo = GameData.costo_entrenamiento(valor)
    if GameData.bronze_hand < costo:
        return
    GameData.bronze_hand -= costo
    GameData.set(attr_key, valor + 1)
    if attr_key == "attr_constitution":
        GameData.recalcular_hp_max()
    SaveManager.save_progress()
    _actualizar_todo()
    EquipmentManager.emit_signal("stats_changed")

func _fmt(n: int) -> String:
    if n >= 1_000_000:
        return str(snappedf(float(n) / 1_000_000.0, 0.1)) + "M"
    elif n >= 1_000:
        return str(snappedf(float(n) / 1_000.0, 0.1)) + "K"
    return str(n)
