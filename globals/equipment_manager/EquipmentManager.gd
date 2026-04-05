extends Node

signal drag_started(item_data: Dictionary)
signal drag_ended()
signal stats_changed()

var dragging_item: Dictionary = {}

const SLOT_RULES := {
    "mano_d":   ["armas"],
    "mano_i":   ["escudos"],
    "pecho":    ["pecho"],
    "casco":    ["cascos"],
    "pies":     ["botas"],
    "manos":    ["guantes"],
    "cuello":   ["collares"],
    "anillo":   ["anillos"],
    "anillo_r": ["anillos"],
    "capa":     ["capas"],
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
    var cat = item.get("categoria", "")
    match cat:
        "armas":
            GameData.equipped_weapon = item
            GameData.damage_min = item.get("ataque_min", 0)
            GameData.damage_max = item.get("ataque_max", 0)
        "escudos":
            GameData.equipped_shield = item
            GameData.armor       += item.get("defensa", 0)
            GameData.block_chance = min(GameData.block_chance + item.get("bloqueo_bonus", 0.0), GameData.MAX_CHANCE)
        "pecho":
            GameData.equipped_chest = item
            GameData.armor += item.get("defensa", 0)
            GameData.attr_constitution += item.get("constitucion_bonus", 0)
            _recalcular_hp()
        "cascos":
            GameData.equipped_helmet = item
            GameData.armor += item.get("defensa", 0)
        "guantes":
            GameData.equipped_gloves = item
            GameData.armor += item.get("defensa", 0)
        "botas":
            GameData.equipped_boots = item
            GameData.armor += item.get("defensa", 0)
        "collares":
            GameData.equipped_neck = item
            _aplicar_bonus_accesorio(item)
        "anillos":
            # Determinar si va al ring_l o ring_r
            if GameData.equipped_ring_l.is_empty():
                GameData.equipped_ring_l = item
            else:
                GameData.equipped_ring_r = item
            _aplicar_bonus_accesorio(item)
    emit_signal("stats_changed")


func _aplicar_bonus_accesorio(item: Dictionary) -> void:
    match item.get("bonus_tipo", ""):
        "armadura":
            GameData.armor += item.get("defensa", 0)
        "ataque":
            GameData.damage_min += item.get("ataque_min", 0)
            GameData.damage_max += item.get("ataque_max", 0)
        "all_stats":
            var bonus = item.get("all_stats_bonus", 0.0)
            GameData.attr_strength     = int(GameData.attr_strength     * (1.0 + bonus))
            GameData.attr_agility      = int(GameData.attr_agility      * (1.0 + bonus))
            GameData.attr_dexterity    = int(GameData.attr_dexterity    * (1.0 + bonus))
            GameData.attr_constitution = int(GameData.attr_constitution * (1.0 + bonus))
            GameData.attr_intelligence = int(GameData.attr_intelligence * (1.0 + bonus))
            GameData.attr_charisma     = int(GameData.attr_charisma     * (1.0 + bonus))
            GameData.recalcular_stats()

# ─────────────────────────────────────
# REMOVER STATS al desequipar
# ─────────────────────────────────────
func remove_item_stats(item: Dictionary) -> void:
    if item.is_empty():
        return
    var cat = item.get("categoria", "")
    match cat:
        "armas":
            GameData.equipped_weapon = {}
            GameData.damage_min = 0
            GameData.damage_max = 0
        "escudos":
            GameData.equipped_shield = {}
            GameData.armor        -= item.get("defensa", 0)
            GameData.block_chance  = max(GameData.block_chance - item.get("bloqueo_bonus", 0.0), 0.0)
        "pecho":
            GameData.equipped_chest = {}
            GameData.armor -= item.get("defensa", 0)
            GameData.attr_constitution -= item.get("constitucion_bonus", 0)
            _recalcular_hp()
        "cascos":
            GameData.equipped_helmet = {}
            GameData.armor -= item.get("defensa", 0)
        "guantes":
            GameData.equipped_gloves = {}
            GameData.armor -= item.get("defensa", 0)
        "botas":
            GameData.equipped_boots = {}
            GameData.armor -= item.get("defensa", 0)
        "collares":
            GameData.equipped_neck = {}
            _remover_bonus_accesorio(item)
        "anillos":
            if GameData.equipped_ring_l.get("id","") == item.get("id",""):
                GameData.equipped_ring_l = {}
            else:
                GameData.equipped_ring_r = {}
            _remover_bonus_accesorio(item)
    emit_signal("stats_changed")


func _remover_bonus_accesorio(item: Dictionary) -> void:
    match item.get("bonus_tipo", ""):
        "armadura":
            GameData.armor -= item.get("defensa", 0)
        "ataque":
            GameData.damage_min -= item.get("ataque_min", 0)
            GameData.damage_max -= item.get("ataque_max", 0)
        "all_stats":
            # Recalcular desde cero para no acumular errores de float
            GameData.recalcular_stats()

# ─────────────────────────────────────
# HELPERS
# ─────────────────────────────────────
func _recalcular_hp() -> void:
    GameData.hp_max = 100 + GameData.attr_constitution * 10
    GameData.hp = min(GameData.hp, GameData.hp_max)
