extends Node

# ─────────────────────────────────────────────────────────
# SAVE MANAGER — Autoload
# Guarda y carga progreso + equipo en Firestore.
# ─────────────────────────────────────────────────────────

var _http: HTTPRequest

func _ready() -> void:
    _http = HTTPRequest.new()
    add_child(_http)

# ─────────────────────────────────────
# GUARDAR
# ─────────────────────────────────────
func save_progress() -> void:
    if GameData.player_id == "" or GameData.id_token == "":
        return

    var url = GameData.FIRESTORE_URL + "players/" + GameData.player_id
    url += "?updateMask.fieldPaths=level&updateMask.fieldPaths=xp"
    url += "&updateMask.fieldPaths=xp_next&updateMask.fieldPaths=hp"
    url += "&updateMask.fieldPaths=hp_max&updateMask.fieldPaths=bronze_hand"
    url += "&updateMask.fieldPaths=gold_hand&updateMask.fieldPaths=gold_vault"
    url += "&updateMask.fieldPaths=attr_strength&updateMask.fieldPaths=attr_agility"
    url += "&updateMask.fieldPaths=attr_dexterity&updateMask.fieldPaths=attr_constitution"
    url += "&updateMask.fieldPaths=attr_intelligence&updateMask.fieldPaths=attr_charisma"
    url += "&updateMask.fieldPaths=eq_weapon&updateMask.fieldPaths=eq_shield"
    url += "&updateMask.fieldPaths=eq_chest&updateMask.fieldPaths=eq_helmet"
    url += "&updateMask.fieldPaths=eq_boots&updateMask.fieldPaths=eq_gloves"
    url += "&updateMask.fieldPaths=eq_neck&updateMask.fieldPaths=eq_ring_l"
    url += "&updateMask.fieldPaths=eq_ring_r&updateMask.fieldPaths=eq_cape"

    var fields: Dictionary = {
        "level":            { "integerValue": str(GameData.level) },
        "xp":               { "integerValue": str(GameData.xp) },
        "xp_next":          { "integerValue": str(GameData.xp_next) },
        "hp":               { "integerValue": str(GameData.hp) },
        "hp_max":           { "integerValue": str(GameData.hp_max) },
        "bronze_hand":      { "integerValue": str(GameData.bronze_hand) },
        "gold_hand":        { "integerValue": str(GameData.gold_hand) },
        "gold_vault":       { "integerValue": str(GameData.gold_vault) },
        "attr_strength":    { "integerValue": str(GameData.attr_strength) },
        "attr_agility":     { "integerValue": str(GameData.attr_agility) },
        "attr_dexterity":   { "integerValue": str(GameData.attr_dexterity) },
        "attr_constitution":{ "integerValue": str(GameData.attr_constitution) },
        "attr_intelligence":{ "integerValue": str(GameData.attr_intelligence) },
        "attr_charisma":    { "integerValue": str(GameData.attr_charisma) },
        # Guardar IDs del equipo (vacío si no hay nada equipado)
        "eq_weapon":  { "stringValue": GameData.equipped_weapon.get("id",  "") },
        "eq_shield":  { "stringValue": GameData.equipped_shield.get("id",  "") },
        "eq_chest":   { "stringValue": GameData.equipped_chest.get("id",   "") },
        "eq_helmet":  { "stringValue": GameData.equipped_helmet.get("id",  "") },
        "eq_boots":   { "stringValue": GameData.equipped_boots.get("id",   "") },
        "eq_gloves":  { "stringValue": GameData.equipped_gloves.get("id",  "") },
        "eq_neck":    { "stringValue": GameData.equipped_neck.get("id",    "") },
        "eq_ring_l":  { "stringValue": GameData.equipped_ring_l.get("id",  "") },
        "eq_ring_r":  { "stringValue": GameData.equipped_ring_r.get("id",  "") },
        "eq_cape":    { "stringValue": GameData.equipped_cape.get("id",    "") },
    }

    var headers = [
        "Content-Type: application/json",
        "Authorization: Bearer " + GameData.id_token
    ]
    _http.request(url, headers, HTTPClient.METHOD_PATCH, JSON.stringify({"fields": fields}))

# ─────────────────────────────────────
# CARGAR desde Firestore
# ─────────────────────────────────────
static func cargar_desde_fields(fields: Dictionary) -> void:
    GameData.level       = int(fields.get("level",       {}).get("integerValue", "1"))
    GameData.xp          = int(fields.get("xp",          {}).get("integerValue", "0"))
    GameData.hp          = int(fields.get("hp",          {}).get("integerValue", "120"))
    GameData.hp_max      = int(fields.get("hp_max",      {}).get("integerValue", "120"))
    GameData.bronze_hand = int(fields.get("bronze_hand", {}).get("integerValue", "500"))
    GameData.gold_hand   = int(fields.get("gold_hand",   {}).get("integerValue", "100"))
    GameData.gold_vault  = int(fields.get("gold_vault",  {}).get("integerValue", "0"))
    GameData.xp_next     = GameData.xp_para_nivel(GameData.level)

    GameData.attr_strength     = max(2, int(fields.get("attr_strength",     {}).get("integerValue", "2")))
    GameData.attr_agility      = max(2, int(fields.get("attr_agility",      {}).get("integerValue", "2")))
    GameData.attr_dexterity    = max(2, int(fields.get("attr_dexterity",    {}).get("integerValue", "2")))
    GameData.attr_constitution = max(2, int(fields.get("attr_constitution", {}).get("integerValue", "2")))
    GameData.attr_intelligence = max(2, int(fields.get("attr_intelligence", {}).get("integerValue", "2")))
    GameData.attr_charisma     = max(2, int(fields.get("attr_charisma",     {}).get("integerValue", "2")))
    GameData.recalcular_hp_max()

    # Cargar IDs de equipo y reconstruir ítems desde el JSON
    var eq_ids = {
        "eq_weapon":  fields.get("eq_weapon",  {}).get("stringValue", ""),
        "eq_shield":  fields.get("eq_shield",  {}).get("stringValue", ""),
        "eq_chest":   fields.get("eq_chest",   {}).get("stringValue", ""),
        "eq_helmet":  fields.get("eq_helmet",  {}).get("stringValue", ""),
        "eq_boots":   fields.get("eq_boots",   {}).get("stringValue", ""),
        "eq_gloves":  fields.get("eq_gloves",  {}).get("stringValue", ""),
        "eq_neck":    fields.get("eq_neck",    {}).get("stringValue", ""),
        "eq_ring_l":  fields.get("eq_ring_l",  {}).get("stringValue", ""),
        "eq_ring_r":  fields.get("eq_ring_r",  {}).get("stringValue", ""),
        "eq_cape":    fields.get("eq_cape",    {}).get("stringValue", ""),
    }
    _restaurar_equipo_desde_ids(eq_ids)
    print("SaveManager: cargado. Nivel: ", GameData.level, " XP: ", GameData.xp, " Bronce: ", GameData.bronze_hand)

static func _restaurar_equipo_desde_ids(eq_ids: Dictionary) -> void:
    if not FileAccess.file_exists("res://data/items_database/items_database.json"):
        return
    var db = JSON.parse_string(FileAccess.get_file_as_string("res://data/items_database/items_database.json"))
    if db == null:
        return

    # Construir índice id → item para búsqueda rápida
    var indice: Dictionary = {}
    for categoria in ["armas", "escudos", "pecho", "cascos", "botas", "guantes", "collares", "anillos", "capas"]:
        if db.has(categoria):
            for item in db[categoria]:
                var item_c = item.duplicate()
                item_c["categoria"] = categoria
                indice[item_c["id"]] = item_c

    # Restaurar cada slot
    var slot_map = {
        "eq_weapon": "equipped_weapon",
        "eq_shield": "equipped_shield",
        "eq_chest":  "equipped_chest",
        "eq_helmet": "equipped_helmet",
        "eq_boots":  "equipped_boots",
        "eq_gloves": "equipped_gloves",
        "eq_neck":   "equipped_neck",
        "eq_ring_l": "equipped_ring_l",
        "eq_ring_r": "equipped_ring_r",
        "eq_cape":   "equipped_cape",
    }
    for eq_key in slot_map:
        var item_id = eq_ids.get(eq_key, "")
        if item_id != "" and indice.has(item_id):
            var item = indice[item_id]
            GameData.set(slot_map[eq_key], item)
            # Aplicar stats del ítem equipado
            _aplicar_stats_item(item)

static func _aplicar_stats_item(item: Dictionary) -> void:
    var categoria = item.get("categoria", "")
    match categoria:
        "armas":
            GameData.damage_min += item.get("ataque_min", 0)
            GameData.damage_max += item.get("ataque_max", 0)
        "escudos":
            GameData.block_chance = min(GameData.block_chance + item.get("bloqueo_bonus", 0.0), GameData.MAX_CHANCE)
        "pecho":
            GameData.attr_constitution += item.get("constitucion_bonus", 0)
            GameData.armor += item.get("defensa", 0)
            GameData.recalcular_hp_max()
