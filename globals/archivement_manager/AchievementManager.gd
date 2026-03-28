extends Node

# ─────────────────────────────────────────────────────────
# ACHIEVEMENT MANAGER — Autoload
# Gestiona los 100 logros del juego.
# Llamar check_all() después de cualquier acción relevante.
# ─────────────────────────────────────────────────────────

signal achievement_unlocked(achievement)

# Referencia al nodo de notificación (se crea en el MainHub)
var _notif_node: Control = null

# ─────────────────────────────────────
# DEFINICIÓN DE LOS 100 LOGROS
# ─────────────────────────────────────
const ACHIEVEMENTS = [
    # ── PvE ──────────────────────────────────────────────
    { "id": "pve_01", "nombre": "Primera Sangre",       "icono": "⚔",  "desc": "Ganá tu primer combate PvE.",               "campo": "pve_wins",     "meta": 1   },
    { "id": "pve_02", "nombre": "Cazador Novato",        "icono": "🗡",  "desc": "Ganá 10 combates PvE.",                    "campo": "pve_wins",     "meta": 10  },
    { "id": "pve_03", "nombre": "Guerrero del Páramo",   "icono": "🗡",  "desc": "Ganá 50 combates PvE.",                    "campo": "pve_wins",     "meta": 50  },
    { "id": "pve_04", "nombre": "Leyenda de la Jungla",  "icono": "🗡",  "desc": "Ganá 200 combates PvE.",                   "campo": "pve_wins",     "meta": 200 },
    { "id": "pve_05", "nombre": "Exterminador",          "icono": "💀",  "desc": "Ganá 500 combates PvE.",                   "campo": "pve_wins",     "meta": 500 },
    { "id": "pve_06", "nombre": "Asesino de Jefes",      "icono": "👑",  "desc": "Derrotá 1 jefe de zona.",                  "campo": "boss_kills",   "meta": 1   },
    { "id": "pve_07", "nombre": "Terror de los Jefes",   "icono": "👑",  "desc": "Derrotá 10 jefes de zona.",                "campo": "boss_kills",   "meta": 10  },
    { "id": "pve_08", "nombre": "Caza Mayor",             "icono": "👑",  "desc": "Derrotá 50 jefes de zona.",                "campo": "boss_kills",   "meta": 50  },
    { "id": "pve_09", "nombre": "Golpe Certero",          "icono": "⚡",  "desc": "Asestá 1 golpe crítico.",                  "campo": "crits_landed", "meta": 1   },
    { "id": "pve_10", "nombre": "Crítico Experto",        "icono": "⚡",  "desc": "Asestá 100 golpes críticos.",              "campo": "crits_landed", "meta": 100 },
    { "id": "pve_11", "nombre": "Doble Amenaza",          "icono": "⚡",  "desc": "Dá 1 doble golpe.",                        "campo": "double_hits",  "meta": 1   },
    { "id": "pve_12", "nombre": "Furia Doble",            "icono": "⚡",  "desc": "Dá 50 dobles golpes.",                     "campo": "double_hits",  "meta": 50  },
    { "id": "pve_13", "nombre": "Esquiva Perfecta",       "icono": "💨",  "desc": "Esquivá 10 ataques.",                      "campo": "dodges_done",  "meta": 10  },
    { "id": "pve_14", "nombre": "Bailarín de la Muerte",  "icono": "💨",  "desc": "Esquivá 100 ataques.",                     "campo": "dodges_done",  "meta": 100 },
    { "id": "pve_15", "nombre": "Bloqueador",              "icono": "🛡",  "desc": "Bloqueá 10 ataques.",                      "campo": "blocks_done",  "meta": 10  },
    { "id": "pve_16", "nombre": "Escudo Viviente",        "icono": "🛡",  "desc": "Bloqueá 100 ataques.",                     "campo": "blocks_done",  "meta": 100 },
    { "id": "pve_17", "nombre": "Resistente",              "icono": "❤",  "desc": "Resistí 1 golpe mortal con 1 HP.",         "campo": "resist_done",  "meta": 1   },
    { "id": "pve_18", "nombre": "Inmortal",                "icono": "❤",  "desc": "Resistí 10 golpes mortales con 1 HP.",     "campo": "resist_done",  "meta": 10  },
    { "id": "pve_19", "nombre": "Buscador de Botín",      "icono": "🎁",  "desc": "Obtené 1 ítem como drop en PvE.",          "campo": "items_dropped","meta": 1   },
    { "id": "pve_20", "nombre": "Coleccionista",           "icono": "🎁",  "desc": "Obtené 10 ítems como drop en PvE.",        "campo": "items_dropped","meta": 10  },
    { "id": "pve_21", "nombre": "El Dragón Cayó",         "icono": "🐉",  "desc": "Derrotá al Dragón de las Ruinas.",         "campo": "boss_kills",   "meta": 1   },
    { "id": "pve_22", "nombre": "Explorador Novato",      "icono": "🗺",  "desc": "Ganá 25 combates en la Jungla.",           "campo": "pve_wins",     "meta": 25  },
    { "id": "pve_23", "nombre": "Veterano de la Aldea",   "icono": "🗺",  "desc": "Ganá 25 combates en la Aldea Olvidada.",   "campo": "pve_wins",     "meta": 75  },
    { "id": "pve_24", "nombre": "Explorador Completo",    "icono": "🗺",  "desc": "Ganá 100 combates en el Cementerio.",      "campo": "pve_wins",     "meta": 150 },
    { "id": "pve_25", "nombre": "Maestro del PvE",        "icono": "🏆",  "desc": "Ganá 1.000 combates PvE.",                 "campo": "pve_wins",     "meta": 1000},

    # ── PvP ──────────────────────────────────────────────
    { "id": "pvp_01", "nombre": "Primer Duelo",           "icono": "⚔",  "desc": "Ganá tu primer combate PvP.",               "campo": "pvp_points",   "meta": 5   },
    { "id": "pvp_02", "nombre": "Gladiador",              "icono": "⚔",  "desc": "Acumulá 50 puntos de arena.",               "campo": "pvp_points",   "meta": 50  },
    { "id": "pvp_03", "nombre": "Campeón de Liga",        "icono": "🏆",  "desc": "Acumulá 250 puntos de arena.",              "campo": "pvp_points",   "meta": 250 },
    { "id": "pvp_04", "nombre": "Leyenda de la Arena",    "icono": "🏆",  "desc": "Acumulá 1.000 puntos de arena.",            "campo": "pvp_points",   "meta": 1000},
    { "id": "pvp_05", "nombre": "Asesino",                "icono": "💀",  "desc": "Matá a 1 jugador (HP a 0).",               "campo": "pvp_kills",    "meta": 1   },
    { "id": "pvp_06", "nombre": "Ejecutor",               "icono": "💀",  "desc": "Matá a 10 jugadores.",                     "campo": "pvp_kills",    "meta": 10  },
    { "id": "pvp_07", "nombre": "La Muerte Personificada","icono": "💀",  "desc": "Matá a 50 jugadores.",                     "campo": "pvp_kills",    "meta": 50  },
    { "id": "pvp_08", "nombre": "Primer Robo",            "icono": "🪙",  "desc": "Robá oro a otro jugador por primera vez.",  "campo": "gold_stolen",  "meta": 1   },
    { "id": "pvp_09", "nombre": "Ladrón",                 "icono": "🪙",  "desc": "Robá 1.000 de oro en total.",              "campo": "gold_stolen",  "meta": 1000 },
    { "id": "pvp_10", "nombre": "Gran Ladrón",            "icono": "🪙",  "desc": "Robá 10.000 de oro en total.",             "campo": "gold_stolen",  "meta": 10000},
    { "id": "pvp_11", "nombre": "Rey de los Ladrones",    "icono": "🪙",  "desc": "Robá 100.000 de oro en total.",            "campo": "gold_stolen",  "meta": 100000},
    { "id": "pvp_12", "nombre": "Número Uno",             "icono": "🥇",  "desc": "Llegá al puesto #1 de tu liga.",            "campo": "arena_pos",    "meta": -1  },
    { "id": "pvp_13", "nombre": "Botín Máximo",           "icono": "💰",  "desc": "Acumulá 10.000 de bronce como #1.",         "campo": "arena_bounty", "meta": 10000},
    { "id": "pvp_14", "nombre": "Implacable",             "icono": "⚔",  "desc": "Ganá 25 combates PvP.",                    "campo": "pvp_points",   "meta": 125 },
    { "id": "pvp_15", "nombre": "Sin Misericordia",       "icono": "💀",  "desc": "Matá a 100 jugadores.",                    "campo": "pvp_kills",    "meta": 100 },

    # ── Crafteo ───────────────────────────────────────────
    { "id": "cft_01", "nombre": "Primera Forja",          "icono": "⚒",  "desc": "Crafteá tu primer ítem.",                  "campo": "craft_points", "meta": 1   },
    { "id": "cft_02", "nombre": "Aprendiz Herrero",       "icono": "⚒",  "desc": "Acumulá 10 puntos de artesano.",            "campo": "craft_points", "meta": 10  },
    { "id": "cft_03", "nombre": "Herrero Experto",        "icono": "⚒",  "desc": "Acumulá 50 puntos de artesano.",            "campo": "craft_points", "meta": 50  },
    { "id": "cft_04", "nombre": "Maestro Artesano",       "icono": "⚒",  "desc": "Acumulá 200 puntos de artesano.",           "campo": "craft_points", "meta": 200 },
    { "id": "cft_05", "nombre": "Gran Maestro",           "icono": "🏆",  "desc": "Acumulá 500 puntos de artesano.",           "campo": "craft_points", "meta": 500 },
    { "id": "cft_06", "nombre": "Forja Legendaria",       "icono": "⭐",  "desc": "Crafteá 1 ítem de nivel 10.",               "campo": "craft_points", "meta": 100 },
    { "id": "cft_07", "nombre": "50 Puntos Artesano",     "icono": "⚒",  "desc": "Acumulá exactamente 50 puntos artesano.",   "campo": "craft_points", "meta": 50  },
    { "id": "cft_08", "nombre": "1000 Puntos Artesano",   "icono": "🏆",  "desc": "Acumulá 1.000 puntos de artesano.",         "campo": "craft_points", "meta": 1000},
    { "id": "cft_09", "nombre": "El Mejor Herrero",       "icono": "🥇",  "desc": "Llegá al TOP 1 de artesanos.",              "campo": "craft_points", "meta": 9999},
    { "id": "cft_10", "nombre": "5000 Puntos Artesano",   "icono": "🏆",  "desc": "Acumulá 5.000 puntos de artesano.",         "campo": "craft_points", "meta": 5000},

    # ── Progresión ────────────────────────────────────────
    { "id": "lvl_01", "nombre": "Primer Paso",            "icono": "⭐",  "desc": "Llegá al nivel 5.",                        "campo": "level",        "meta": 5   },
    { "id": "lvl_02", "nombre": "En Camino",              "icono": "⭐",  "desc": "Llegá al nivel 10.",                       "campo": "level",        "meta": 10  },
    { "id": "lvl_03", "nombre": "Veterano",               "icono": "⭐",  "desc": "Llegá al nivel 25.",                       "campo": "level",        "meta": 25  },
    { "id": "lvl_04", "nombre": "Élite",                  "icono": "⭐",  "desc": "Llegá al nivel 50.",                       "campo": "level",        "meta": 50  },
    { "id": "lvl_05", "nombre": "Leyenda",                "icono": "🌟",  "desc": "Llegá al nivel 100.",                      "campo": "level",        "meta": 100 },
    { "id": "lvl_06", "nombre": "Fuerza Bruta",           "icono": "💪",  "desc": "Subí Fuerza a nivel 50.",                  "campo": "attr_strength","meta": 50  },
    { "id": "lvl_07", "nombre": "Ágil como el Viento",    "icono": "💨",  "desc": "Subí Agilidad a nivel 50.",                "campo": "attr_agility", "meta": 50  },
    { "id": "lvl_08", "nombre": "Manos de Hierro",        "icono": "🎯",  "desc": "Subí Destreza a nivel 50.",                "campo": "attr_dexterity","meta": 50  },
    { "id": "lvl_09", "nombre": "Mente Brillante",        "icono": "📚",  "desc": "Subí Inteligencia a nivel 50.",            "campo": "attr_intelligence","meta": 50},
    { "id": "lvl_10", "nombre": "El Resistente",          "icono": "🛡",  "desc": "Subí Constitución a nivel 50.",            "campo": "attr_constitution","meta": 50},
    { "id": "lvl_11", "nombre": "El Carismático",         "icono": "👑",  "desc": "Subí Carisma a nivel 50.",                 "campo": "attr_charisma","meta": 50  },
    { "id": "lvl_12", "nombre": "Maestro del Cuerpo",     "icono": "💪",  "desc": "Llegá a nivel 100 en cualquier atributo.", "campo": "attr_strength","meta": 100 },
    { "id": "lvl_13", "nombre": "XP 10.000",              "icono": "⭐",  "desc": "Acumulá 10.000 XP total.",                 "campo": "xp_total",     "meta": 10000},
    { "id": "lvl_14", "nombre": "XP 100.000",             "icono": "🌟",  "desc": "Acumulá 100.000 XP total.",                "campo": "xp_total",     "meta": 100000},
    { "id": "lvl_15", "nombre": "XP 1.000.000",           "icono": "🌟",  "desc": "Acumulá 1.000.000 XP total.",              "campo": "xp_total",     "meta": 1000000},

    # ── Economía ──────────────────────────────────────────
    { "id": "eco_01", "nombre": "Primer Oro",             "icono": "💰",  "desc": "Acumulá 10 de oro.",                       "campo": "gold_hand",    "meta": 10  },
    { "id": "eco_02", "nombre": "Ahorrista",              "icono": "💰",  "desc": "Acumulá 50 de oro.",                       "campo": "gold_hand",    "meta": 50  },
    { "id": "eco_03", "nombre": "Rico",                   "icono": "💰",  "desc": "Acumulá 100 de oro.",                      "campo": "gold_hand",    "meta": 100 },
    { "id": "eco_04", "nombre": "Magnate",                "icono": "💰",  "desc": "Acumulá 1.000 de oro.",                    "campo": "gold_hand",    "meta": 1000},
    { "id": "eco_05", "nombre": "Primer Bronce",          "icono": "🪙",  "desc": "Acumulá 1.000 de bronce.",                 "campo": "bronze_hand",  "meta": 1000},
    { "id": "eco_06", "nombre": "Tesorero",               "icono": "🪙",  "desc": "Acumulá 10.000 de bronce.",                "campo": "bronze_hand",  "meta": 10000},
    { "id": "eco_07", "nombre": "Rey del Bronce",         "icono": "🪙",  "desc": "Acumulá 100.000 de bronce.",               "campo": "bronze_hand",  "meta": 100000},
    { "id": "eco_08", "nombre": "Sabiduría de Mercado",   "icono": "📚",  "desc": "Subí Inteligencia a nivel 30.",            "campo": "attr_intelligence","meta": 30},
    { "id": "eco_09", "nombre": "Fortuna Acumulada",      "icono": "💰",  "desc": "Acumulá 500 de oro.",                      "campo": "gold_hand",    "meta": 500 },
    { "id": "eco_10", "nombre": "Montaña de Bronce",      "icono": "🪙",  "desc": "Acumulá 50.000 de bronce.",                "campo": "bronze_hand",  "meta": 50000},

    # ── Social ────────────────────────────────────────────
    { "id": "soc_01", "nombre": "Fundador",               "icono": "⚑",  "desc": "Creá un clan.",                            "campo": "player_clan_id","meta": -2  },
    { "id": "soc_02", "nombre": "Parte del Equipo",       "icono": "🤝",  "desc": "Unite a un clan.",                         "campo": "player_clan_id","meta": -2  },
    { "id": "soc_03", "nombre": "Mensajero",              "icono": "💬",  "desc": "Enviá 10 mensajes en el chat del clan.",   "campo": "messages_sent","meta": 10  },
    { "id": "soc_04", "nombre": "Boca de Fuego",          "icono": "💬",  "desc": "Enviá 100 mensajes en el chat del clan.",  "campo": "messages_sent","meta": 100 },
    { "id": "soc_05", "nombre": "Perfil Completo",        "icono": "📝",  "desc": "Completá tu descripción pública.",         "campo": "level",        "meta": -3  },
    { "id": "soc_06", "nombre": "Medalla de Honor",       "icono": "🏅",  "desc": "Conseguí tu primera medalla semanal.",     "campo": "level",        "meta": -3  },
    { "id": "soc_07", "nombre": "30 Días",                "icono": "📅",  "desc": "Llevá 30 días jugando.",                   "campo": "days_played",  "meta": 30  },
    { "id": "soc_08", "nombre": "90 Días",                "icono": "📅",  "desc": "Llevá 90 días jugando.",                   "campo": "days_played",  "meta": 90  },
    { "id": "soc_09", "nombre": "180 Días",               "icono": "📅",  "desc": "Llevá 180 días jugando.",                  "campo": "days_played",  "meta": 180 },
    { "id": "soc_10", "nombre": "Coleccionista de Logros","icono": "🏆",  "desc": "Desbloqueá 25 logros.",                    "campo": "level",        "meta": -4  },

    # ── Especiales / Secretos ─────────────────────────────
    { "id": "esp_01", "nombre": "¡El Primero!",           "icono": "🌟",  "desc": "Ser el primer jugador del servidor.",      "campo": "level",        "meta": -3  },
    { "id": "esp_02", "nombre": "Noche de Cacería",       "icono": "🌙",  "desc": "Ganá 10 combates PvE en 10 minutos.",      "campo": "pve_wins",     "meta": 10  },
    { "id": "esp_03", "nombre": "La Gota que Colma",      "icono": "💀",  "desc": "????? Logro secreto.",                     "campo": "pvp_kills",    "meta": -3  },
    { "id": "esp_04", "nombre": "Sin Descanso",           "icono": "⚔",  "desc": "Ganá 50 combates en un día.",              "campo": "pve_wins",     "meta": 50  },
    { "id": "esp_05", "nombre": "Guardián de Atepaia",    "icono": "🌟",  "desc": "Desbloqueá 50 logros.",                    "campo": "level",        "meta": -4  },
    { "id": "esp_06", "nombre": "El Incomprendido",       "icono": "💀",  "desc": "Perdé 50 combates PvP.",                   "campo": "pvp_kills",    "meta": -3  },
    { "id": "esp_07", "nombre": "Renacido",               "icono": "❤",  "desc": "Resistí 5 golpes mortales en 1 combate.",  "campo": "resist_done",  "meta": 5   },
    { "id": "esp_08", "nombre": "Vengador",               "icono": "⚔",  "desc": "Derrotá al que te derrotó antes.",         "campo": "pvp_points",   "meta": -3  },
    { "id": "esp_09", "nombre": "Cazador de Clanes",      "icono": "⚔",  "desc": "Derrotá a 5 miembros del mismo clan.",     "campo": "pvp_kills",    "meta": 5   },
    { "id": "esp_10", "nombre": "Ath-Anori",              "icono": "🌑",  "desc": "??????? El Devorador observa.",            "campo": "level",        "meta": -3  },
]

func _ready() -> void:
    pass

# ─────────────────────────────────────
# VERIFICAR TODOS LOS LOGROS
# ─────────────────────────────────────
func check_all() -> void:
    for ach in ACHIEVEMENTS:
        _check_one(ach)

func _check_one(ach: Dictionary) -> void:
    var id  = ach["id"]
    if id in GameData.achievements_unlocked:
        return  # Ya desbloqueado

    var campo = ach["campo"]
    var meta  = ach["meta"]

    # Metas especiales (negativas = condiciones custom)
    if meta < 0:
        return  # Se desbloquean manualmente con unlock()

    var valor_actual = _get_valor(campo)
    if valor_actual >= meta:
        unlock(id)

func _get_valor(campo: String) -> int:
    match campo:
        "pve_wins":         return GameData.pve_wins
        "boss_kills":       return GameData.boss_kills
        "crits_landed":     return GameData.crits_landed
        "double_hits":      return GameData.double_hits
        "dodges_done":      return GameData.dodges_done
        "blocks_done":      return GameData.blocks_done
        "resist_done":      return GameData.resist_done
        "items_dropped":    return GameData.items_dropped
        "pvp_points":       return GameData.pvp_points
        "pvp_kills":        return GameData.pvp_kills
        "gold_stolen":      return GameData.gold_stolen
        "arena_bounty":     return GameData.arena_bounty
        "arena_pos":        return 1 if GameData.arena_pos == 1 else 0
        "craft_points":     return GameData.craft_points
        "level":            return GameData.level
        "xp_total":         return GameData.xp_total
        "gold_hand":        return GameData.gold_hand
        "bronze_hand":      return GameData.bronze_hand
        "messages_sent":    return GameData.messages_sent
        "days_played":      return GameData.days_played
        "attr_strength":    return GameData.attr_strength
        "attr_agility":     return GameData.attr_agility
        "attr_dexterity":   return GameData.attr_dexterity
        "attr_constitution":return GameData.attr_constitution
        "attr_intelligence":return GameData.attr_intelligence
        "attr_charisma":    return GameData.attr_charisma
        "player_clan_id":   return 1 if GameData.player_clan_id != "" else 0
    return 0

# ─────────────────────────────────────
# DESBLOQUEAR LOGRO
# ─────────────────────────────────────
func unlock(id: String) -> void:
    if id in GameData.achievements_unlocked:
        return
    GameData.achievements_unlocked.append(id)

    # Buscar datos del logro
    var ach_data: Dictionary = {}
    for ach in ACHIEVEMENTS:
        if ach["id"] == id:
            ach_data = ach
            break
    if ach_data.is_empty():
        return

    print("🏆 Logro desbloqueado: ", ach_data.get("nombre","?"))
    emit_signal("achievement_unlocked", ach_data)
    _mostrar_notificacion(ach_data)

# ─────────────────────────────────────
# NOTIFICACIÓN VISUAL — sube desde abajo
# ─────────────────────────────────────
func _mostrar_notificacion(ach: Dictionary) -> void:
    # Buscar el viewport raíz para anclar la notificación
    var viewport = get_tree().root
    if viewport == null:
        return

    var panel = PanelContainer.new()
    panel.z_index = 500

    # Estilo del panel
    var style = StyleBoxFlat.new()
    style.bg_color        = Color(0.08, 0.06, 0.04, 0.95)
    style.border_color    = Color(0.9, 0.75, 0.3, 1)
    style.border_width_left   = 2
    style.border_width_right  = 2
    style.border_width_top    = 2
    style.border_width_bottom = 2
    style.corner_radius_top_left     = 8
    style.corner_radius_top_right    = 8
    style.corner_radius_bottom_left  = 8
    style.corner_radius_bottom_right = 8
    panel.add_theme_stylebox_override("panel", style)

    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left",   16)
    margin.add_theme_constant_override("margin_right",  16)
    margin.add_theme_constant_override("margin_top",    10)
    margin.add_theme_constant_override("margin_bottom", 10)
    panel.add_child(margin)

    var hbox = HBoxContainer.new()
    hbox.add_theme_constant_override("separation", 10)
    margin.add_child(hbox)

    # Ícono del logro
    var lbl_icono = Label.new()
    lbl_icono.text = ach.get("icono", "🏆")
    lbl_icono.add_theme_font_size_override("font_size", 22)
    hbox.add_child(lbl_icono)

    var vbox = VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 2)
    hbox.add_child(vbox)

    var lbl_titulo = Label.new()
    lbl_titulo.text = "¡Logro desbloqueado!"
    lbl_titulo.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3, 1))
    lbl_titulo.add_theme_font_size_override("font_size", 10)
    vbox.add_child(lbl_titulo)

    var lbl_nombre = Label.new()
    lbl_nombre.text = ach.get("nombre", "?")
    lbl_nombre.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8, 1))
    lbl_nombre.add_theme_font_size_override("font_size", 14)
    vbox.add_child(lbl_nombre)

    viewport.add_child(panel)

    # Posición inicial: abajo de la pantalla, centrado
    await get_tree().process_frame
    var screen_size = get_tree().root.get_visible_rect().size
    panel.position = Vector2((screen_size.x - panel.size.x) / 2.0, screen_size.y + 10)

    # Animación: sube desde abajo
    var tween = get_tree().create_tween()
    var target_y = screen_size.y - panel.size.y - 30
    tween.tween_property(panel, "position:y", target_y, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

    # Esperar 3 segundos y bajar
    await get_tree().create_timer(3.0).timeout
    var tween2 = get_tree().create_tween()
    tween2.tween_property(panel, "position:y", screen_size.y + 10, 0.4).set_ease(Tween.EASE_IN)
    await tween2.finished
    panel.queue_free()

# ─────────────────────────────────────
# PROGRESO DE UN LOGRO (para mostrar en perfil)
# ─────────────────────────────────────
func get_progress(id: String) -> Dictionary:
    for ach in ACHIEVEMENTS:
        if ach["id"] == id:
            var meta  = ach["meta"]
            var valor = _get_valor(ach["campo"])
            var desbloqueado = id in GameData.achievements_unlocked
            return {
                "nombre":       ach["nombre"],
                "icono":        ach["icono"],
                "desc":         ach["desc"],
                "meta":         meta,
                "valor":        valor,
                "desbloqueado": desbloqueado,
                "pct":          min(100, int(float(valor) / float(max(1, meta)) * 100)) if meta > 0 else 0,
            }
    return {}
