extends PanelContainer

@export var slot_name: String = ""

var equipped_item: Dictionary = {}

const COLOR_NORMAL   := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_VALIDO   := Color(0.2, 1.0, 0.2, 0.6)
const COLOR_INVALIDO := Color(1.0, 0.2, 0.2, 0.6)

@onready var item_icon:  TextureRect = $ItemIcon
@onready var slot_label: Label       = $SlotLabel

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    add_to_group("equip_slots")
    item_icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    item_icon.size_flags_vertical   = Control.SIZE_EXPAND_FILL
    item_icon.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
    item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    EquipmentManager.drag_started.connect(_on_drag_started)
    EquipmentManager.drag_ended.connect(_on_drag_ended)
    if slot_label:
        slot_label.text = _nombre_visible(slot_name)

func _cargar_icono(ruta: String) -> Texture2D:
    if ruta == "":
        return null
    var tex = load(ruta)
    if tex == null:
        print("AVISO: no se encontró el ícono: ", ruta)
    return tex

func set_equipped(data: Dictionary) -> void:
    equipped_item = data
    if data.is_empty():
        item_icon.texture  = null
        item_icon.visible  = false
        if slot_label:
            slot_label.text    = _nombre_visible(slot_name)
            slot_label.visible = true
    else:
        var tex = _cargar_icono(data.get("icono", ""))
        item_icon.texture = tex
        item_icon.visible = tex != null
        if slot_label:
            slot_label.visible = false

func receive_item(item: Dictionary, source_slot) -> void:
    if not equipped_item.is_empty():
        if source_slot and source_slot.has_method("set_item"):
            source_slot.set_item(equipped_item)
        else:
            _devolver_al_inventario(equipped_item)
    else:
        if source_slot and source_slot.has_method("clear_slot"):
            source_slot.clear_slot()
    EquipmentManager.remove_item_stats(equipped_item)
    set_equipped(item)
    EquipmentManager.apply_item_stats(item)
    print("Equipado: ", item.get("nombre", "?"), " en slot: ", slot_name)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
    if not data is Dictionary:
        return false
    return EquipmentManager.can_equip(data.get("item", {}), slot_name)

func _drop_data(_at_position: Vector2, data: Variant) -> void:
    receive_item(data.get("item", {}), data.get("source_slot", null))

func _on_drag_started(item: Dictionary) -> void:
    modulate = COLOR_VALIDO if EquipmentManager.can_equip(item, slot_name) else COLOR_INVALIDO

func _on_drag_ended() -> void:
    modulate = COLOR_NORMAL

func _devolver_al_inventario(item: Dictionary) -> void:
    for slot in get_tree().get_nodes_in_group("inventory_slots"):
        if slot.item_data.is_empty():
            slot.set_item(item)
            return
    print("ADVERTENCIA: Inventario lleno, no se pudo devolver: ", item.get("nombre", "?"))

func _nombre_visible(sn: String) -> String:
    match sn:
        "mano_d": return "Mano D"
        "mano_i": return "Mano I"
        "pecho":  return "Pecho"
        "casco":  return "Casco"
        "pies":   return "Pies"
        "manos":  return "Manos"
        "cuello": return "Cuello"
        "anillo": return "Anillo"
        "capa":   return "Capa/Alas"
        _:        return sn
