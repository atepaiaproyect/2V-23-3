extends PanelContainer

var item_data: Dictionary = {}

# Colores de calidad — fondo del slot del ítem
const RARITY_COLORS := {
    # Sistema nuevo de 5 calidades
    "normal":     Color(0.22, 0.22, 0.22, 0.0 ),   # Blanco / sin fondo
    "bueno":      Color(0.10, 0.42, 0.10, 0.60),   # Verde
    "epico":      Color(0.35, 0.08, 0.50, 0.65),   # Morado
    "inmortal":   Color(0.55, 0.05, 0.05, 0.65),   # Rojo
    "legendario": Color(0.55, 0.45, 0.00, 0.70),   # Dorado
    # Sistema viejo (compatibilidad)
    "comun":      Color(0.22, 0.22, 0.22, 0.0 ),
    "inusual":    Color(0.10, 0.42, 0.10, 0.55),
    "magico":     Color(0.10, 0.20, 0.50, 0.55),
    "raro":       Color(0.55, 0.45, 0.00, 0.55),
}

# Labels de calidad para mostrar en tooltip
const CALIDAD_LABELS := {
    "normal":     "Normal",
    "bueno":      "Bueno",
    "epico":      "Épico",
    "inmortal":   "Inmortal",
    "legendario": "Legendario",
    "comun":      "Común",
    "inusual":    "Inusual",
    "magico":     "Mágico",
    "raro":       "Raro",
}

# Color del texto de calidad para tooltip
const CALIDAD_TEXT_COLORS := {
    "normal":     Color(0.90, 0.90, 0.90, 1),
    "bueno":      Color(0.30, 0.90, 0.30, 1),
    "epico":      Color(0.80, 0.40, 1.00, 1),
    "inmortal":   Color(1.00, 0.30, 0.30, 1),
    "legendario": Color(1.00, 0.85, 0.20, 1),
    "comun":      Color(0.90, 0.90, 0.90, 1),
    "inusual":    Color(0.30, 0.90, 0.30, 1),
    "magico":     Color(0.40, 0.60, 1.00, 1),
    "raro":       Color(1.00, 0.85, 0.20, 1),
}

# Timer para hover de 1 segundo
var _hover_timer: float = 0.0
var _mouse_inside: bool = false
const HOVER_DELAY: float = 1.0

@onready var item_icon:      TextureRect = $ItemIcon
@onready var cantidad_label: Label       = $CantidadLabel
@onready var rarity_bg:      ColorRect   = $RarityBg

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    item_icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    item_icon.size_flags_vertical   = Control.SIZE_EXPAND_FILL
    item_icon.expand_mode           = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
    item_icon.stretch_mode          = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)

func _process(delta: float) -> void:
    # Contar tiempo de hover solo si el mouse está dentro y hay ítem
    if _mouse_inside and not item_data.is_empty():
        _hover_timer += delta
        if _hover_timer >= HOVER_DELAY:
            _hover_timer = HOVER_DELAY  # no seguir sumando
            ItemTooltip.show_tooltip(item_data, get_global_rect().position)

# ─────────────────────────────────────
# Poner un ítem en este slot
# ─────────────────────────────────────
func set_item(data: Dictionary) -> void:
    item_data = data
    if data.is_empty():
        item_icon.texture = null
        item_icon.visible = false
        rarity_bg.color   = RARITY_COLORS["comun"]
        return
    var ruta = data.get("icono", "")
    if ruta != "":
        var tex = load(ruta)
        if tex != null:
            item_icon.texture = tex
            item_icon.visible = true
        else:
            print("AVISO: no se encontró el ícono: ", ruta)
            item_icon.texture = null
            item_icon.visible = false
    else:
        item_icon.texture = null
        item_icon.visible = false
    rarity_bg.color = RARITY_COLORS.get(data.get("rareza", "comun"), RARITY_COLORS["comun"])

func clear_slot() -> void:
    item_data = {}
    item_icon.texture = null
    item_icon.visible = false
    rarity_bg.color   = RARITY_COLORS["comun"]

# ─────────────────────────────────────
# MOUSE ENTER / EXIT
# ─────────────────────────────────────
func _on_mouse_entered() -> void:
    _mouse_inside = true
    _hover_timer  = 0.0

func _on_mouse_exited() -> void:
    _mouse_inside = false
    _hover_timer  = 0.0
    # Cerrar tooltip al salir del slot
    ItemTooltip.hide_tooltip()

# ─────────────────────────────────────
# CLICK
# ─────────────────────────────────────
func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if item_data.is_empty():
                ItemTooltip.hide_tooltip()
                return
            if event.double_click:
                ItemTooltip.hide_tooltip()
                EquipmentManager.auto_equip(item_data, self)
            else:
                # Click simple → mostrar tooltip inmediatamente
                ItemTooltip.show_tooltip(item_data, get_global_rect().position)

# ─────────────────────────────────────
# DRAG
# ─────────────────────────────────────
func _get_drag_data(_at_position: Vector2) -> Variant:
    if item_data.is_empty():
        return null
    ItemTooltip.hide_tooltip()
    var preview = TextureRect.new()
    preview.texture             = item_icon.texture
    preview.custom_minimum_size = Vector2(55, 55)
    preview.expand_mode         = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
    preview.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    set_drag_preview(preview)
    EquipmentManager.start_drag(item_data)
    return { "item": item_data, "source_slot": self }

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
    return data is Dictionary and data.has("item")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
    var incoming_item = data.get("item", {})
    var source_slot   = data.get("source_slot", null)
    if incoming_item.is_empty():
        return
    var my_item = item_data.duplicate()
    if source_slot and source_slot.has_method("set_item"):
        source_slot.set_item(my_item)
    elif source_slot and source_slot.has_method("set_equipped"):
        source_slot.set_equipped(my_item)
        if not my_item.is_empty():
            EquipmentManager.apply_item_stats(my_item)
    set_item(incoming_item)

func _notification(what: int) -> void:
    if what == NOTIFICATION_DRAG_END:
        EquipmentManager.end_drag()
