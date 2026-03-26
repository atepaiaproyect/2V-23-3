extends Node

signal drag_started(item_data: Dictionary)
signal drag_ended()
signal stats_changed()

var dragging_item: Dictionary = {}

const SLOT_RULES := {
    "mano_d":  ["armas"],
    "mano_i":  ["escudos"],
    "pecho":   ["pecho"],
    "casco":   ["cascos"],
    "pies":    ["botas"],
    "manos":   ["guantes"],
    "cuello":  ["collares"],
    "anillo":  ["anillos"],
    "capa":    ["capas"]
}

# ─────────────────────────────────────
# DRAG
# ─────────────────────────────────────
func start_drag(item: Dictionary) -> void:
    dragging_item = item
    emit_signal("drag_started", item)

func end_drag() -> void:
    dragging_item = {}
    emit_signal("drag_ended")

# ─────────────────────────────────────
# ¿Puede ir este ítem en este slot?
# ─────────────────────────────────────
func can_equip(item: Dictionary, slot_name: String) -> bool:
    if item.is_empty():
        return false
    var categoria = item.get("categoria", "")
    return categoria in SLOT_RULES.get(slot_name, [])

# ─────────────────────────────────────
# DOBLE CLICK → slot predefinido
# ─────────────────────────────────────
func auto_equip(item: Dictionary, source_slot) -> void:
    var slot_destino = item.get("slot", "")
    for slot in get_tree().get_nodes_in_group("equip_slots"):
        if slot.slot_name == slot_destino:
            slot.receive_item(item, source_slot)
            return

# ─────────────────────────────────────
# APLICAR STATS al equipar
# ─────────────────────────────────────
func apply_item_stats(item: Dictionary) -> void:
    if item.is_empty():
        return
    match item.get("categoria", ""):
        "armas":
            GameData.equipped_weapon = item
            GameData.damage_min = item.get("ataque_min", 0)
            GameData.damage_max = item.get("ataque_max", 0)
        "escudos":
            GameData.equipped_shield = item
            GameData.block_chance += item.get("bloqueo_bonus", 0.0)
            GameData.block_chance = min(GameData.block_chance, GameData.MAX_CHANCE)
        "pecho":
            GameData.equipped_chest = item
            GameData.attr_constitution += item.get("constitucion_bonus", 0)
            GameData.armor += item.get("defensa", 0)
            _recalcular_hp()
    emit_signal("stats_changed")

# ─────────────────────────────────────
# REMOVER STATS al desequipar
# ─────────────────────────────────────
func remove_item_stats(item: Dictionary) -> void:
    if item.is_empty():
        return
    match item.get("categoria", ""):
        "armas":
            GameData.equipped_weapon = {}
            GameData.damage_min = 0
            GameData.damage_max = 0
        "escudos":
            GameData.equipped_shield = {}
            GameData.block_chance -= item.get("bloqueo_bonus", 0.0)
            GameData.block_chance = max(GameData.block_chance, 0.0)
        "pecho":
            GameData.equipped_chest = {}
            GameData.attr_constitution -= item.get("constitucion_bonus", 0)
            GameData.armor -= item.get("defensa", 0)
            _recalcular_hp()
    emit_signal("stats_changed")

# ─────────────────────────────────────
# HELPERS
# ─────────────────────────────────────
func _recalcular_hp() -> void:
    GameData.hp_max = 100 + GameData.attr_constitution * 10
    GameData.hp = min(GameData.hp, GameData.hp_max)
