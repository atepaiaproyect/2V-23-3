extends Node

# ─────────────────────────────────────────────────────────
# SAVE MANAGER — Autoload
# Guarda progreso en Firestore + maneja regeneración offline.
# ─────────────────────────────────────────────────────────

var _http: HTTPRequest

var _http_clan: HTTPRequest

func _ready() -> void:
    _http = HTTPRequest.new()
    add_child(_http)
    _http_clan = HTTPRequest.new()
    add_child(_http_clan)

# ─────────────────────────────────────
# GUARDAR PROGRESO
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
    url += "&updateMask.fieldPaths=pvp_points&updateMask.fieldPaths=gold_stolen"
    url += "&updateMask.fieldPaths=xp_total&updateMask.fieldPaths=craft_points&updateMask.fieldPaths=pvp_kills"
    url += "&updateMask.fieldPaths=last_online"
    url += "&updateMask.fieldPaths=arena_pos&updateMask.fieldPaths=arena_bounty&updateMask.fieldPaths=arena_is_top1&updateMask.fieldPaths=arena_league"
    url += "&updateMask.fieldPaths=player_clan_id&updateMask.fieldPaths=player_clan_name&updateMask.fieldPaths=player_clan_tag"
    url += "&updateMask.fieldPaths=pve_wins&updateMask.fieldPaths=boss_kills&updateMask.fieldPaths=crits_landed"
    url += "&updateMask.fieldPaths=double_hits&updateMask.fieldPaths=dodges_done&updateMask.fieldPaths=blocks_done"
    url += "&updateMask.fieldPaths=resist_done&updateMask.fieldPaths=items_dropped&updateMask.fieldPaths=messages_sent"
    url += "&updateMask.fieldPaths=achievements_unlocked"

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
        "pvp_points":   { "integerValue": str(GameData.pvp_points) },
        "gold_stolen":  { "integerValue": str(GameData.gold_stolen) },
        "xp_total":     { "integerValue": str(GameData.xp_total) },
        "craft_points": { "integerValue": str(GameData.craft_points) },
        "pvp_kills":    { "integerValue": str(GameData.pvp_kills) },
        # Timestamp Unix para calcular regen offline
        "last_online":  { "integerValue": str(int(Time.get_unix_time_from_system())) },
        "arena_pos":    { "integerValue": str(GameData.arena_pos) },
        "arena_bounty": { "integerValue": str(GameData.arena_bounty) },
        "arena_is_top1":{ "booleanValue": GameData.arena_is_top1 },
        "arena_league":   { "stringValue": GameData.get_arena_league_id() },
        "player_clan_id":   { "stringValue": GameData.player_clan_id },
        "player_clan_name": { "stringValue": GameData.player_clan_name },
        "player_clan_tag":  { "stringValue": GameData.player_clan_tag },
        "pve_wins":         { "integerValue": str(GameData.pve_wins) },
        "boss_kills":       { "integerValue": str(GameData.boss_kills) },
        "crits_landed":     { "integerValue": str(GameData.crits_landed) },
        "double_hits":      { "integerValue": str(GameData.double_hits) },
        "dodges_done":      { "integerValue": str(GameData.dodges_done) },
        "blocks_done":      { "integerValue": str(GameData.blocks_done) },
        "resist_done":      { "integerValue": str(GameData.resist_done) },
        "items_dropped":    { "integerValue": str(GameData.items_dropped) },
        "messages_sent":    { "integerValue": str(GameData.messages_sent) },
        "achievements_unlocked": { "arrayValue": { "values": _array_to_firestore(GameData.achievements_unlocked) } },
    }

    var headers = PackedStringArray([
        "Content-Type: application/json",
        "Authorization: Bearer " + GameData.id_token
    ])
    # Si hay una petición en curso la cancelamos y enviamos la nueva
    # (la más reciente siempre tiene los datos más actualizados)
    if _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
        _http.cancel_request()
    _http.request(url, headers, HTTPClient.METHOD_PATCH, JSON.stringify({"fields": fields}))

# ─────────────────────────────────────
# CARGAR DESDE FIRESTORE
# ─────────────────────────────────────
func cargar_desde_fields(fields: Dictionary) -> void:
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

    # Ranking
    GameData.pvp_points   = int(fields.get("pvp_points",   {}).get("integerValue", "0"))
    GameData.gold_stolen  = int(fields.get("gold_stolen",  {}).get("integerValue", "0"))
    GameData.xp_total     = int(fields.get("xp_total",     {}).get("integerValue", "0"))
    GameData.craft_points = int(fields.get("craft_points", {}).get("integerValue", "0"))
    GameData.pvp_kills    = int(fields.get("pvp_kills",    {}).get("integerValue", "0"))

    # Recalcular stats derivados (incluye hp_regen_per_min)
    GameData.recalcular_stats()

    # ── REGENERACIÓN OFFLINE ──────────────────────────────
    # Calcular cuántos minutos pasaron desde la última vez que estuvo online
    var last_online_unix = int(fields.get("last_online", {}).get("integerValue", "0"))
    if last_online_unix > 0:
        var ahora_unix    = int(Time.get_unix_time_from_system())
        var segundos_fuera = max(0, ahora_unix - last_online_unix)
        var minutos_fuera  = segundos_fuera / 60
        if minutos_fuera > 0 and GameData.hp < GameData.hp_max:
            var regen_total = minutos_fuera * GameData.hp_regen_per_min
            GameData.hp = min(GameData.hp + regen_total, GameData.hp_max)
            print("SaveManager: regen offline ", minutos_fuera, " min → +", regen_total, " HP")

    GameData.arena_pos     = int(fields.get("arena_pos",    {}).get("integerValue", "9999"))
    GameData.arena_bounty  = int(fields.get("arena_bounty", {}).get("integerValue", "0"))
    GameData.arena_is_top1 = fields.get("arena_is_top1", {}).get("booleanValue", false)
    GameData.player_clan_id   = fields.get("player_clan_id",   {}).get("stringValue", "")
    GameData.player_clan_name = fields.get("player_clan_name", {}).get("stringValue", "")
    GameData.player_clan_tag  = fields.get("player_clan_tag",  {}).get("stringValue", "")
    GameData.pve_wins       = int(fields.get("pve_wins",     {}).get("integerValue", "0"))
    GameData.boss_kills     = int(fields.get("boss_kills",   {}).get("integerValue", "0"))
    GameData.crits_landed   = int(fields.get("crits_landed", {}).get("integerValue", "0"))
    GameData.double_hits    = int(fields.get("double_hits",  {}).get("integerValue", "0"))
    GameData.dodges_done    = int(fields.get("dodges_done",  {}).get("integerValue", "0"))
    GameData.blocks_done    = int(fields.get("blocks_done",  {}).get("integerValue", "0"))
    GameData.resist_done    = int(fields.get("resist_done",  {}).get("integerValue", "0"))
    GameData.items_dropped  = int(fields.get("items_dropped",{}).get("integerValue", "0"))
    GameData.messages_sent  = int(fields.get("messages_sent",{}).get("integerValue", "0"))
    # Cargar logros desbloqueados
    var ach_raw = fields.get("achievements_unlocked", {}).get("arrayValue", {}).get("values", [])
    GameData.achievements_unlocked = []
    for v in ach_raw:
        GameData.achievements_unlocked.append(v.get("stringValue", ""))
    # arena_league se recalcula automáticamente desde el nivel, no hace falta cargarlo

    # Cargar equipo
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
    print("SaveManager: cargado. Nivel ", GameData.level, " HP ", GameData.hp, "/", GameData.hp_max)

func _restaurar_equipo_desde_ids(eq_ids: Dictionary) -> void:
    if not FileAccess.file_exists("res://data/items_database/items_database.json"):
        return
    var db = JSON.parse_string(FileAccess.get_file_as_string("res://data/items_database/items_database.json"))
    if db == null:
        return
    var indice: Dictionary = {}
    for categoria in ["armas", "escudos", "pecho", "cascos", "botas", "guantes", "collares", "anillos", "capas"]:
        if db.has(categoria):
            for item in db[categoria]:
                var item_c = item.duplicate()
                item_c["categoria"] = categoria
                indice[item_c.get("id", "")] = item_c

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
            _aplicar_stats_item(item)

func _aplicar_stats_item(item: Dictionary) -> void:
    var categoria = item.get("categoria", "")
    match categoria:
        "armas":
            GameData.damage_min += item.get("ataque_min", 0)
            GameData.damage_max += item.get("ataque_max", 0)
        "escudos":
            GameData.armor += item.get("defensa", 0)
        "pecho":
            GameData.armor += item.get("defensa", 0)

# ─────────────────────────────────────
# ACTUALIZAR PUNTOS DEL CLAN
# Se llama después de save_progress cuando hay clan
# Los puntos del clan son la suma de todos sus miembros
# Usamos un campo "delta" para no leer primero (operación atómica)
# ─────────────────────────────────────
func save_clan_stats(xp_ganada: int, pvp_pts: int, oro_robado: int, craft_pts: int) -> void:
    if GameData.player_clan_id == "" or GameData.id_token == "":
        return
    if xp_ganada == 0 and pvp_pts == 0 and oro_robado == 0 and craft_pts == 0:
        return

    # Leer el doc del clan primero para sumar
    var url = GameData.FIRESTORE_URL + "clanes/" + GameData.player_clan_id
    url += "?updateMask.fieldPaths=xp_total&updateMask.fieldPaths=pvp_points"
    url += "&updateMask.fieldPaths=gold_stolen&updateMask.fieldPaths=craft_points"

    # Guardamos los deltas en variables temporales y los mandamos al callback
    _pending_clan_delta = {
        "xp_total":     xp_ganada,
        "pvp_points":   pvp_pts,
        "gold_stolen":  oro_robado,
        "craft_points": craft_pts,
    }
    var headers = PackedStringArray([
        "Content-Type: application/json",
        "Authorization: Bearer " + GameData.id_token
    ])
    # Primero GET para leer valores actuales
    if _http_clan.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
        _http_clan.cancel_request()
    if not _http_clan.request_completed.is_connected(_on_clan_read):
        _http_clan.request_completed.connect(_on_clan_read, CONNECT_ONE_SHOT)
    _http_clan.request(url.split("?")[0], headers, HTTPClient.METHOD_GET)

var _pending_clan_delta: Dictionary = {}

func _on_clan_read(_result, response_code, _headers_r, body) -> void:
    if response_code != 200:
        return
    var data = JSON.parse_string(body.get_string_from_utf8())
    if data == null or not data.has("fields"):
        return
    var f = data["fields"]
    var new_xp     = int(f.get("xp_total",    {}).get("integerValue","0")) + _pending_clan_delta.get("xp_total",0)
    var new_pvp    = int(f.get("pvp_points",  {}).get("integerValue","0")) + _pending_clan_delta.get("pvp_points",0)
    var new_oro    = int(f.get("gold_stolen", {}).get("integerValue","0")) + _pending_clan_delta.get("gold_stolen",0)
    var new_craft  = int(f.get("craft_points",{}).get("integerValue","0")) + _pending_clan_delta.get("craft_points",0)

    var url = GameData.FIRESTORE_URL + "clanes/" + GameData.player_clan_id
    url += "?updateMask.fieldPaths=xp_total&updateMask.fieldPaths=pvp_points"
    url += "&updateMask.fieldPaths=gold_stolen&updateMask.fieldPaths=craft_points"

    var body_str = JSON.stringify({ "fields": {
        "xp_total":     { "integerValue": str(new_xp)    },
        "pvp_points":   { "integerValue": str(new_pvp)   },
        "gold_stolen":  { "integerValue": str(new_oro)   },
        "craft_points": { "integerValue": str(new_craft) },
    }})
    var headers = PackedStringArray([
        "Content-Type: application/json",
        "Authorization: Bearer " + GameData.id_token
    ])
    if _http_clan.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
        _http_clan.cancel_request()
    _http_clan.request(url, headers, HTTPClient.METHOD_PATCH, body_str)
    _pending_clan_delta = {}

static func _array_to_firestore(arr: Array) -> Array:
    var result = []
    for item in arr:
        result.append({ "stringValue": str(item) })
    return result
