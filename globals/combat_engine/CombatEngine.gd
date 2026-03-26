extends Node

const MAX_ROUNDS_PVE := 50
const MAX_ROUNDS_PVP := 15

func run_pve(jugador: Dictionary, enemigo: Dictionary) -> Dictionary:
    return _resolver_combate(jugador, enemigo, MAX_ROUNDS_PVE, false)

func run_pvp(jugador_a: Dictionary, jugador_b: Dictionary) -> Dictionary:
    return _resolver_combate(jugador_a, jugador_b, MAX_ROUNDS_PVP, true)

func _resolver_combate(atacante: Dictionary, defensor: Dictionary, max_rondas: int, es_pvp: bool) -> Dictionary:
    var a = atacante.duplicate(true)
    var d = defensor.duplicate(true)

    var hp_a_inicial = float(a.get("hp", 100))
    var hp_d_inicial = float(d.get("hp", 100))

    var log_rondas: Array = []
    var ronda_final := 0
    var ganador := ""

    for ronda in range(1, max_rondas + 1):
        ronda_final = ronda
        var eventos: Array = []

        # Turno del atacante
        var res_a = _resolver_turno(a, d)
        d["hp"] = max(0, d.get("hp", 0) - res_a["dano_total"])
        eventos.append_array(res_a["eventos"])

        if d["hp"] <= 0:
            eventos.append({ "tipo": "muerte", "nombre": d.get("nombre", "?") })
            ganador = a.get("nombre", "Atacante")
            log_rondas.append({ "ronda": ronda, "hp_a": a["hp"], "hp_d": 0, "eventos": eventos })
            break

        # Turno del defensor
        var res_d = _resolver_turno(d, a)
        a["hp"] = max(0, a.get("hp", 0) - res_d["dano_total"])
        eventos.append_array(res_d["eventos"])

        if a["hp"] <= 0:
            eventos.append({ "tipo": "muerte", "nombre": a.get("nombre", "?") })
            ganador = d.get("nombre", "Defensor")
            log_rondas.append({ "ronda": ronda, "hp_a": 0, "hp_d": d["hp"], "eventos": eventos })
            break

        log_rondas.append({ "ronda": ronda, "hp_a": a["hp"], "hp_d": d["hp"], "eventos": eventos })

    if ganador == "":
        var pct_a = float(a.get("hp", 0)) / hp_a_inicial
        var pct_d = float(d.get("hp", 0)) / hp_d_inicial
        ganador = a.get("nombre", "Atacante") if pct_a >= pct_d else d.get("nombre", "Defensor")

    var jugador_gano: bool = ganador == atacante.get("nombre", "")
    var oro_ganado    := 0
    var xp_ganada     := 0
    var item_dropeado := {}

    if not es_pvp and jugador_gano:
        oro_ganado = randi_range(defensor.get("oro_min", 5), defensor.get("oro_max", 15))
        xp_ganada  = defensor.get("xp", 10)
        if randf() < defensor.get("drop_chance", 0.15):
            item_dropeado = _generar_drop(defensor.get("nivel", 1))

    return {
        "ganador":       ganador,
        "jugador_gano":  jugador_gano,
        "rondas":        ronda_final,
        "log":           log_rondas,
        "hp_final_a":    a.get("hp", 0),
        "hp_final_d":    d.get("hp", 0),
        "hp_max_a":      atacante.get("hp_max", atacante.get("hp", 100)),
        "hp_max_d":      defensor.get("hp_max", defensor.get("hp", 100)),
        "oro_ganado":    oro_ganado,
        "xp_ganada":     xp_ganada,
        "item_dropeado": item_dropeado,
        "es_pvp":        es_pvp,
    }

func _resolver_turno(atacante: Dictionary, defensor: Dictionary) -> Dictionary:
    var nombre_a = atacante.get("nombre", "?")
    var nombre_d = defensor.get("nombre", "?")
    var eventos: Array = []
    var dano_total := 0

    # Daño base
    var dano_min = atacante.get("ataque_min", 3) + atacante.get("attr_strength", 5)
    var dano_max = atacante.get("ataque_max", 8) + atacante.get("attr_strength", 5) * 2
    var dano_base = randi_range(dano_min, max(dano_min, dano_max))

    # ¿Crítico?
    var es_critico: bool = randf() < atacante.get("crit_chance", 0.0)
    if es_critico:
        dano_base = int(dano_base * atacante.get("crit_damage", 1.5))

    # ¿Doble golpe?
    var es_doble: bool = randf() < atacante.get("double_hit_chance", 0.0)

    # Reducción armadura
    var armadura   = defensor.get("armadura", 0)
    var reduccion  = int(armadura * 0.5)
    dano_base      = max(0, dano_base - reduccion)

    # ¿Esquiva?
    var esquivo: bool = randf() < defensor.get("dodge_chance", 0.0)

    # ¿Bloqueo?
    var bloqueo := false
    if not esquivo and randf() < defensor.get("block_chance", 0.0):
        bloqueo   = true
        var red_b = int(dano_base * defensor.get("block_reduction", 0.3))
        dano_base = max(0, dano_base - red_b)

    # Golpe principal
    eventos.append({
        "tipo":      "golpe_critico" if es_critico else "golpe",
        "atacante":  nombre_a,
        "defensor":  nombre_d,
        "dano":      dano_base,
        "esquivo":   esquivo,
        "bloqueo":   bloqueo,
        "critico":   es_critico,
    })

    if not esquivo:
        dano_total += dano_base

    # Doble golpe
    if es_doble:
        var dano2 = max(0, randi_range(dano_min, max(dano_min, dano_max)) - reduccion)
        dano_total += dano2
        eventos.append({
            "tipo":     "doble",
            "atacante": nombre_a,
            "defensor": nombre_d,
            "dano":     dano2,
            "esquivo":  false,
            "bloqueo":  false,
            "critico":  false,
        })

    return { "dano_total": dano_total, "eventos": eventos }

func _generar_drop(nivel_enemigo: int) -> Dictionary:
    return {
        "nombre":      "Objeto desconocido",
        "nivel":       nivel_enemigo,
        "rareza":      "comun",
        "categoria":   "armas",
        "descripcion": "Un objeto encontrado en el campo de batalla."
    }

func get_ficha_jugador() -> Dictionary:
    return {
        "nombre":            GameData.player_name,
        "nivel":             GameData.level,
        "hp":                GameData.hp,
        "hp_max":            GameData.hp_max,
        "attr_strength":     GameData.attr_strength,
        "attr_agility":      GameData.attr_agility,
        "attr_dexterity":    GameData.attr_dexterity,
        "attr_constitution": GameData.attr_constitution,
        "attr_intelligence": GameData.attr_intelligence,
        "attr_charisma":     GameData.attr_charisma,
        "ataque_min":        5  + GameData.attr_strength + GameData.damage_min,
        "ataque_max":        10 + GameData.attr_strength * 2 + GameData.damage_max,
        "armadura":          GameData.attr_constitution * 5 + GameData.armor,
        "crit_chance":       GameData.crit_chance,
        "crit_damage":       GameData.crit_damage,
        "dodge_chance":      GameData.dodge_chance,
        "block_chance":      GameData.block_chance,
        "block_reduction":   GameData.block_reduction,
        "double_hit_chance": GameData.double_hit_chance,
        "icono":             "res://assets/portraits/players/" + GameData.player_portrait + ".png",
    }
