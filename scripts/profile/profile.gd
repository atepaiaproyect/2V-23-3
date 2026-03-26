extends Control

# --- Referencias izquierda ---
@onready var portrait_image = $HBoxMain/ColLeft/PortraitBg/PortraitImage
@onready var label_name     = $HBoxMain/ColLeft/StatsPanel/VBoxStats/LabelName
@onready var label_class    = $HBoxMain/ColLeft/StatsPanel/VBoxStats/LabelClass
@onready var label_level    = $HBoxMain/ColLeft/StatsPanel/VBoxStats/LabelLevel
@onready var label_hp       = $HBoxMain/ColLeft/StatsPanel/VBoxStats/LabelHP
@onready var bar_hp         = $HBoxMain/ColLeft/StatsPanel/VBoxStats/BarHPBg/BarHP
@onready var label_xp       = $HBoxMain/ColLeft/StatsPanel/VBoxStats/LabelXP
@onready var bar_xp         = $HBoxMain/ColLeft/StatsPanel/VBoxStats/BarXPBg/BarXP
@onready var label_str      = $HBoxMain/ColLeft/StatsPanel/VBoxStats/RowStr/LabelStr
@onready var label_agi      = $HBoxMain/ColLeft/StatsPanel/VBoxStats/RowAgi/LabelAgi
@onready var label_dex      = $HBoxMain/ColLeft/StatsPanel/VBoxStats/RowDex/LabelDex
@onready var label_cha      = $HBoxMain/ColLeft/StatsPanel/VBoxStats/RowCha/LabelCha
@onready var label_con      = $HBoxMain/ColLeft/StatsPanel/VBoxStats/RowCon/LabelCon
@onready var label_int      = $HBoxMain/ColLeft/StatsPanel/VBoxStats/RowInt/LabelInt
@onready var label_atk      = $HBoxMain/ColLeft/StatsPanel/VBoxStats/RowAtk/LabelAtk
@onready var label_def      = $HBoxMain/ColLeft/StatsPanel/VBoxStats/RowDef/LabelDef

# Filas para tooltip
@onready var row_str = $HBoxMain/ColLeft/StatsPanel/VBoxStats/RowStr
@onready var row_agi = $HBoxMain/ColLeft/StatsPanel/VBoxStats/RowAgi
@onready var row_dex = $HBoxMain/ColLeft/StatsPanel/VBoxStats/RowDex
@onready var row_cha = $HBoxMain/ColLeft/StatsPanel/VBoxStats/RowCha
@onready var row_con = $HBoxMain/ColLeft/StatsPanel/VBoxStats/RowCon
@onready var row_int = $HBoxMain/ColLeft/StatsPanel/VBoxStats/RowInt
@onready var row_atk = $HBoxMain/ColLeft/StatsPanel/VBoxStats/RowAtk
@onready var row_def = $HBoxMain/ColLeft/StatsPanel/VBoxStats/RowDef

# --- Referencias perfil público ---
@onready var label_public_view = $HBoxMain/ColRight/PublicPanel/VBoxPublic/LabelPublicView
@onready var text_public       = $HBoxMain/ColRight/PublicPanel/VBoxPublic/TextEditPublic
@onready var line_medal        = $HBoxMain/ColRight/PublicPanel/VBoxPublic/LineEditMedal
@onready var vbox_medals       = $HBoxMain/ColRight/PublicPanel/VBoxPublic/VBoxMedals
@onready var btn_edit          = $HBoxMain/ColRight/PublicPanel/VBoxPublic/BtnEdit
@onready var btn_add_medal     = $HBoxMain/ColRight/PublicPanel/VBoxPublic/BtnAddMedal
@onready var btn_save          = $HBoxMain/ColRight/PublicPanel/VBoxPublic/BtnSavePublic

# --- Inventario ---
@onready var grid_inv = $HBoxMain/ColCenter/InvPanel/VBoxInv/GridInv

# --- Tooltip ---
@onready var tooltip       = $Tooltip
@onready var tooltip_label = $Tooltip/TooltipLabel

var editing_mode: bool = false

const TOOLTIPS = {
    "str": "Fuerza: Aumenta el daño y la probabilidad de resistir un golpe crítico o mortal quedando en 1 de vida.",
    "agi": "Agilidad: Aumenta la probabilidad de esquivar y el daño de los golpes críticos.",
    "dex": "Destreza: Aumenta la probabilidad de doble golpe y golpe crítico.",
    "cha": "Carisma: Aumenta el agro en peleas y la probabilidad de bloquear ataques.",
    "con": "Constitución: Aumenta los puntos de vida y la regeneración por hora.",
    "int": "Inteligencia: Reduce precios en tiendas y subastas. Aumenta bonificaciones del clan.",
    "atk": "Daño: Valor total del ataque. Incluye % de golpe crítico y doble golpe.",
    "def": "Armadura: Valor total de la armadura. Incluye % de esquiva y bloqueo.",
}

# ─────────────────────────────────────
func _ready():
    _load_profile()
    _setup_tooltips()
    _set_edit_mode(false)
    btn_edit.pressed.connect(_on_btn_edit_pressed)
    btn_save.pressed.connect(_on_save_public)
    btn_add_medal.pressed.connect(_on_add_medal)
    _cargar_inventario()
    EquipmentManager.stats_changed.connect(_refresh_stats)

func _load_profile():
    var path = "res://assets/portraits/" + GameData.player_portrait + ".png"
    if ResourceLoader.exists(path):
        portrait_image.texture = load(path)
    label_name.text  = GameData.player_name
    label_class.text = GameData.player_class.capitalize()
    label_level.text = "Nivel " + str(GameData.level)
    _refresh_stats()
    var bio = GameData.get("public_bio") if GameData.get("public_bio") != null else ""
    label_public_view.text = bio if bio != "" else "Sin descripción."
    text_public.text = bio

# ─────────────────────────────────────
# REFRESCO DE STATS
# Se llama al cargar y cada vez que se equipa/desequipa algo
# ─────────────────────────────────────
func _refresh_stats():
    label_hp.text = "❤ HP: " + str(GameData.hp) + "/" + str(GameData.hp_max)
    bar_hp.anchor_right = clamp(float(GameData.hp) / float(GameData.hp_max), 0.0, 1.0)
    label_xp.text = "⭐ XP: " + str(GameData.xp) + "/" + str(GameData.xp_next)
    bar_xp.anchor_right = clamp(float(GameData.xp) / float(GameData.xp_next), 0.0, 1.0)

    label_str.text = str(GameData.attr_strength)
    label_agi.text = str(GameData.attr_agility)
    label_dex.text = str(GameData.attr_dexterity)
    label_cha.text = str(GameData.attr_charisma)
    label_con.text = str(GameData.attr_constitution)
    label_int.text = str(GameData.attr_intelligence)

    # Daño = base (fuerza) + bonus del arma equipada
    var base_min = 5  + GameData.attr_strength
    var base_max = 10 + GameData.attr_strength * 2
    label_atk.text = str(base_min + GameData.damage_min) + "-" + str(base_max + GameData.damage_max)

    # Armadura = constitución * 5 + armadura del equipo
    label_def.text = str(GameData.attr_constitution * 5 + GameData.armor)

# ─────────────────────────────────────
# MODO EDICIÓN
# ─────────────────────────────────────
func _set_edit_mode(editing: bool):
    editing_mode = editing
    label_public_view.visible = not editing
    text_public.visible    = editing
    line_medal.visible     = editing
    btn_add_medal.visible  = editing
    btn_save.visible       = editing
    btn_edit.text = "✏  EDITAR" if not editing else "✕  Cancelar"

func _on_btn_edit_pressed():
    _set_edit_mode(not editing_mode)

func _on_save_public():
    GameData.set("public_bio", text_public.text)
    label_public_view.text = text_public.text if text_public.text != "" else "Sin descripción."
    _set_edit_mode(false)

func _on_add_medal():
    var code = line_medal.text.strip_edges()
    if code == "":
        return
    var medal_label = Label.new()
    medal_label.text = "🏅  " + code
    medal_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3, 1))
    medal_label.add_theme_font_size_override("font_size", 12)
    vbox_medals.add_child(medal_label)
    line_medal.text = ""

# ─────────────────────────────────────
# TOOLTIPS
# ─────────────────────────────────────
func _setup_tooltips():
    var rows = {
        row_str: "str", row_agi: "agi", row_dex: "dex",
        row_cha: "cha", row_con: "con", row_int: "int",
        row_atk: "atk", row_def: "def"
    }
    for row in rows:
        row.mouse_entered.connect(_show_tooltip.bind(rows[row]))
        row.mouse_exited.connect(_hide_tooltip)

func _show_tooltip(key: String):
    tooltip_label.text = TOOLTIPS.get(key, "")
    tooltip.visible = true

func _hide_tooltip():
    tooltip.visible = false

func _process(_delta):
    if tooltip.visible:
        var mouse = get_global_mouse_position()
        tooltip.global_position = mouse + Vector2(12, 12)
        var screen = get_viewport_rect().size
        if tooltip.global_position.x + tooltip.size.x > screen.x:
            tooltip.global_position.x = mouse.x - tooltip.size.x - 12
        if tooltip.global_position.y + tooltip.size.y > screen.y:
            tooltip.global_position.y = mouse.y - tooltip.size.y - 12

# ─────────────────────────────────────
# INVENTARIO
# ─────────────────────────────────────
func _cargar_inventario() -> void:
    if not FileAccess.file_exists("res://data/items_database/items_database.json"):
        print("ERROR: No se encontró items_database.json")
        return
    var contenido = FileAccess.get_file_as_string("res://data/items_database/items_database.json")
    var db = JSON.parse_string(contenido)
    if db == null:
        print("ERROR: El JSON tiene un problema de formato")
        return

    # Construir lista de IDs ya equipados para no ponerlos en el inventario
    var equipados_ids: Array = []
    for item in [GameData.equipped_weapon, GameData.equipped_shield, GameData.equipped_chest,
                 GameData.equipped_helmet, GameData.equipped_boots, GameData.equipped_gloves,
                 GameData.equipped_neck,   GameData.equipped_ring_l, GameData.equipped_ring_r,
                 GameData.equipped_cape]:
        if not item.is_empty():
            equipados_ids.append(item.get("id", ""))

    var todos_los_items: Array = []
    for categoria in ["armas", "pecho"]:
        if db.has(categoria):
            for item in db[categoria]:
                # Saltar ítems que ya están equipados
                if item.get("id", "") in equipados_ids:
                    continue
                var item_con_cat = item.duplicate()
                item_con_cat["categoria"] = categoria
                todos_los_items.append(item_con_cat)

    var slots = grid_inv.get_children()
    for i in range(min(todos_los_items.size(), slots.size())):
        var slot = slots[i]
        if slot.has_method("set_item"):
            slot.set_item(todos_los_items[i])

    # Restaurar visualmente los ítems equipados en sus slots
    _restaurar_equipo()

func _restaurar_equipo() -> void:
    # Mapa: slot_name → variable de GameData
    var mapa := {
        "mano_d": GameData.equipped_weapon,
        "mano_i": GameData.equipped_shield,
        "pecho":  GameData.equipped_chest,
        "casco":  GameData.equipped_helmet,
        "pies":   GameData.equipped_boots,
        "manos":  GameData.equipped_gloves,
        "cuello": GameData.equipped_neck,
        "anillo": GameData.equipped_ring_l,
        "capa":   GameData.equipped_cape,
    }
    var equip_slots = get_tree().get_nodes_in_group("equip_slots")
    for slot in equip_slots:
        var item = mapa.get(slot.slot_name, {})
        if not item.is_empty():
            slot.set_equipped(item)
