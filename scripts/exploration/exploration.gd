extends Control

var zonas_db: Array = []
var zona_actual: Dictionary = {}

var _hover_timer: float = 0.0
var _mob_hover_card = null
const HOVER_DELAY := 1.0

@onready var hbox_zonas  = $ScrollMain/VBoxMain/MarginZonas/HBoxZonas
@onready var lbl_desc    = $ScrollMain/VBoxMain/MarginDesc/PanelDesc/LblDescripcion
@onready var margin_mobs = $ScrollMain/VBoxMain/MarginMobs
@onready var hbox_mobs   = $ScrollMain/VBoxMain/MarginMobs/VBoxMobs/HBoxMobs

func _ready() -> void:
    _cargar_db()
    _construir_zona_cards()

func _cargar_db() -> void:
    var path = "res://data/enemies/enemies_database.json"
    if not FileAccess.file_exists(path):
        push_error("Exploration: No se encontró " + path)
        return
    var result = JSON.parse_string(FileAccess.get_file_as_string(path))
    if result == null:
        push_error("Exploration: Error al parsear enemies_database.json")
        return
    zonas_db = result.get("zonas", [])

func _construir_zona_cards() -> void:
    for child in hbox_zonas.get_children():
        child.queue_free()
    for zona in zonas_db:
        var card = _crear_zona_card(zona)
        hbox_zonas.add_child(card)

func _crear_zona_card(zona: Dictionary) -> Button:
    var btn = Button.new()
    btn.custom_minimum_size = Vector2(0, 200)
    btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    btn.clip_contents = true

    var bg = TextureRect.new()
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bg.size_flags_vertical   = Control.SIZE_EXPAND_FILL
    bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    var tex = load(zona.get("imagen", ""))
    if tex:
        bg.texture = tex
    btn.add_child(bg)

    var overlay = ColorRect.new()
    overlay.layout_mode   = 1
    overlay.anchor_top    = 0.55
    overlay.anchor_right  = 1.0
    overlay.anchor_bottom = 1.0
    overlay.color = Color(0.0, 0.0, 0.0, 0.72)
    btn.add_child(overlay)

    var vbox = VBoxContainer.new()
    vbox.layout_mode   = 1
    vbox.anchor_top    = 0.55
    vbox.anchor_right  = 1.0
    vbox.anchor_bottom = 1.0
    vbox.add_theme_constant_override("separation", 2)
    btn.add_child(vbox)

    var lbl_nombre = Label.new()
    lbl_nombre.text = zona.get("nombre", "?")
    lbl_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl_nombre.add_theme_font_size_override("font_size", 14)
    lbl_nombre.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3, 1))
    vbox.add_child(lbl_nombre)

    var lbl_nivel = Label.new()
    lbl_nivel.text = "Nivel recomendado: " + str(zona.get("nivel_recomendado", 1)) + "+"
    lbl_nivel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl_nivel.add_theme_font_size_override("font_size", 10)
    lbl_nivel.add_theme_color_override("font_color", Color(0.8, 0.75, 0.6, 1))
    vbox.add_child(lbl_nivel)

    var lbl_explorar = Label.new()
    lbl_explorar.text = "▶  Explorar"
    lbl_explorar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl_explorar.add_theme_font_size_override("font_size", 11)
    lbl_explorar.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5, 1))
    vbox.add_child(lbl_explorar)

    btn.pressed.connect(_on_zona_seleccionada.bind(zona))
    return btn

func _on_zona_seleccionada(zona: Dictionary) -> void:
    zona_actual = zona
    lbl_desc.text = zona.get("descripcion", "")
    _construir_mob_cards(zona.get("mobs", []))
    margin_mobs.visible = true

func _construir_mob_cards(mobs: Array) -> void:
    for child in hbox_mobs.get_children():
        child.queue_free()
    for mob in mobs:
        var card = _crear_mob_card(mob)
        hbox_mobs.add_child(card)

func _crear_mob_card(mob: Dictionary) -> PanelContainer:
    var card = PanelContainer.new()
    card.custom_minimum_size = Vector2(0, 260)
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    if mob.get("es_jefe", false):
        var style = StyleBoxFlat.new()
        style.border_color        = Color(1.0, 0.75, 0.1, 1)
        style.border_width_left   = 2
        style.border_width_right  = 2
        style.border_width_top    = 2
        style.border_width_bottom = 2
        style.bg_color = Color(0.1, 0.08, 0.05, 0.9)
        card.add_theme_stylebox_override("panel", style)

    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left",   6)
    margin.add_theme_constant_override("margin_right",  6)
    margin.add_theme_constant_override("margin_top",    6)
    margin.add_theme_constant_override("margin_bottom", 6)
    card.add_child(margin)

    var vbox = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 5)
    margin.add_child(vbox)

    var lbl_nombre = Label.new()
    lbl_nombre.text = mob.get("nombre", "?")
    lbl_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl_nombre.add_theme_font_size_override("font_size", 11)
    lbl_nombre.add_theme_color_override("font_color",
        Color(1.0, 0.75, 0.1, 1) if mob.get("es_jefe", false) else Color(0.9, 0.85, 0.7, 1))
    vbox.add_child(lbl_nombre)

    var portrait = TextureRect.new()
    portrait.custom_minimum_size   = Vector2(0, 160)
    portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    portrait.size_flags_vertical   = Control.SIZE_EXPAND_FILL
    portrait.expand_mode           = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
    portrait.stretch_mode          = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var tex = load(mob.get("icono", ""))
    if tex:
        portrait.texture = tex
    vbox.add_child(portrait)

    var lbl_nivel = Label.new()
    lbl_nivel.text = "Nivel " + str(mob.get("nivel", 1))
    lbl_nivel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl_nivel.add_theme_font_size_override("font_size", 10)
    lbl_nivel.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65, 1))
    vbox.add_child(lbl_nivel)

    var btn = Button.new()
    btn.text = "⚔  Atacar"
    btn.add_theme_font_size_override("font_size", 11)
    btn.pressed.connect(_on_atacar.bind(mob))
    vbox.add_child(btn)

    card.mouse_entered.connect(_on_mob_enter.bind(mob, card))
    card.mouse_exited.connect(_on_mob_exit)
    card.gui_input.connect(_on_mob_input.bind(mob, card))
    return card

func _process(delta: float) -> void:
    if _mob_hover_card != null:
        _hover_timer += delta
        if _hover_timer >= HOVER_DELAY:
            _hover_timer = HOVER_DELAY
            var mob = _mob_hover_card.get_meta("mob_data", {})
            ItemTooltip.show_tooltip_mob(mob, _mob_hover_card.get_global_rect().position)

func _on_mob_enter(mob: Dictionary, card: PanelContainer) -> void:
    _hover_timer = 0.0
    card.set_meta("mob_data", mob)
    _mob_hover_card = card

func _on_mob_exit() -> void:
    _hover_timer    = 0.0
    _mob_hover_card = null
    ItemTooltip.hide_tooltip()

func _on_mob_input(event: InputEvent, mob: Dictionary, card: PanelContainer) -> void:
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            ItemTooltip.show_tooltip_mob(mob, card.get_global_rect().position)

func _on_atacar(mob: Dictionary) -> void:
    ItemTooltip.hide_tooltip()
    GameData.enemigo_actual = mob
    _cargar_subscena("res://scenes/combat/Combat.tscn")

func _cargar_subscena(path: String) -> void:
    var content_area = _buscar_content_area()
    if content_area:
        for child in content_area.get_children():
            child.queue_free()
        var scene = load(path).instantiate()
        content_area.add_child(scene)
    else:
        get_tree().change_scene_to_file(path)

func _buscar_content_area() -> Node:
    var node = get_parent()
    while node != null:
        var candidate = node.find_child("ContentArea", true, false)
        if candidate:
            return candidate
        node = node.get_parent()
    return null
