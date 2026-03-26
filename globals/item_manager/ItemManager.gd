# ItemManager.gd
# Sistema de ítems de Atepaia
# Para agregar nueva categoría: solo agregar el bloque en items_database.json
# Para modificar valores: editar el JSON, no este script

extends Node

# ─────────────────────────────────────────────────────────
# BASE DE DATOS EN MEMORIA
# ─────────────────────────────────────────────────────────
var db: Dictionary = {}
var loaded: bool = false

const DB_PATH = "res://data/items_database/items_database.json"

# ─────────────────────────────────────────────────────────
func _ready():
    _load_database()

func _load_database():
    if not FileAccess.file_exists(DB_PATH):
        push_error("ItemManager: No se encontró " + DB_PATH)
        return
    var json_text = FileAccess.get_file_as_string(DB_PATH)
    var result = JSON.parse_string(json_text)
    if result == null:
        push_error("ItemManager: Error al parsear el JSON")
        return
    db = result
    loaded = true
    print("ItemManager: Base de datos cargada. Versión: ", db.get("version", "?"))

# ─────────────────────────────────────────────────────────
# OBTENER ÍTEM BASE
# ─────────────────────────────────────────────────────────
func get_item_base(categoria: String, item_id: String) -> Dictionary:
    if not loaded:
        return {}
    var cat = db["categorias"].get(categoria, {})
    for item in cat.get("items", []):
        if item["id"] == item_id:
            return item.duplicate()
    return {}

func get_items_by_categoria(categoria: String) -> Array:
    if not loaded:
        return []
    return db["categorias"].get(categoria, {}).get("items", [])

func get_items_by_nivel(categoria: String, nivel: int) -> Array:
    var result = []
    for item in get_items_by_categoria(categoria):
        if item["nivel"] == nivel:
            result.append(item)
    return result

# ─────────────────────────────────────────────────────────
# OBTENER ORIGEN Y ESENCIA
# ─────────────────────────────────────────────────────────
func get_origen(origen_id: String) -> Dictionary:
    if not loaded:
        return {}
    for origen in db["origenes"]["items"]:
        if origen["id"] == origen_id:
            return origen.duplicate()
    return {}

func get_esencia(esencia_id: String) -> Dictionary:
    if not loaded:
        return {}
    for esencia in db["esencias"]["items"]:
        if esencia["id"] == esencia_id:
            return esencia.duplicate()
    return {}

# ─────────────────────────────────────────────────────────
# GENERAR ÍTEM COMPLETO
# ─────────────────────────────────────────────────────────
func generate_item(categoria: String, item_id: String, rareza_id: String,
                   origen_id: String = "", esencia_id: String = "") -> Dictionary:

    var base = get_item_base(categoria, item_id)
    if base.is_empty():
        push_error("ItemManager: ítem base no encontrado: " + item_id)
        return {}

    var rareza = _get_rareza(rareza_id)
    var origen = get_origen(origen_id) if origen_id != "" else {}
    var esencia = get_esencia(esencia_id) if esencia_id != "" else {}

    var bonus_origen_pct = origen.get("bonus_pct", 0.0)
    var bonus_esencia_pct = esencia.get("bonus_pct", 0.0) if _esencia_afecta_stat_principal(esencia, categoria) else 0.0
    var multiplicador = 1.0 + bonus_origen_pct + bonus_esencia_pct

    var item_final = {
        "id_generado":  item_id + "_" + rareza_id + "_" + origen_id + "_" + esencia_id,
        "nombre":       _construir_nombre(base["nombre"], origen, esencia),
        "categoria":    categoria,
        "nivel":        base["nivel"],
        "rareza":       rareza_id,
        "color":        rareza.get("color", "#FFFFFF"),
        "durabilidad":  50 + base["nivel"] * 10,
        "dur_max":      50 + base["nivel"] * 10,
        "origen_id":    origen_id,
        "esencia_id":   esencia_id,
        "bonus_extra":  [],
    }

    match categoria:
        "armas":
            item_final["dano_min"] = roundi(base["dano_min"] * multiplicador)
            item_final["dano_max"] = roundi(base["dano_max"] * multiplicador)
        "escudos":
            item_final["armadura"]    = roundi(base["armadura"] * multiplicador)
            item_final["bloqueo_pct"] = base["bloqueo_pct"]
        "pecho":
            item_final["armadura"] = roundi(base["armadura"] * multiplicador)
        _:
            for key in base.keys():
                if key not in ["id", "nombre", "nivel"]:
                    item_final[key] = roundi(base[key] * multiplicador) if typeof(base[key]) == TYPE_INT else base[key]

    if not origen.is_empty() and origen.get("bonus_extra", "") != "":
        item_final["bonus_extra"].append(_parse_bonus_extra(origen["bonus_extra"]))
    if not esencia.is_empty() and esencia.get("bonus_extra", "") != "" and esencia.get("bonus_extra", "") != "efecto_especial":
        item_final["bonus_extra"].append(_parse_bonus_extra(esencia["bonus_extra"]))

    return item_final

# ─────────────────────────────────────────────────────────
# GENERAR ÍTEM ALEATORIO (para drops)
# ─────────────────────────────────────────────────────────
func generate_random_item(categoria: String, nivel_zona: int) -> Dictionary:
    var nivel_min = max(1, nivel_zona - 1)
    var nivel_max = min(10, nivel_zona + 1)
    var items_posibles = []
    for n in range(nivel_min, nivel_max + 1):
        items_posibles += get_items_by_nivel(categoria, n)
    if items_posibles.is_empty():
        return {}
    var base = items_posibles[randi() % items_posibles.size()]

    var rareza_id = _tirar_rareza()
    var rareza_data = _get_rareza(rareza_id)

    var origen_id = ""
    var esencia_id = ""
    var origenes_lista = db["origenes"]["items"]
    var esencias_lista = db["esencias"]["items"]

    if rareza_data.get("tiene_origen", false) and not origenes_lista.is_empty():
        origen_id = origenes_lista[randi() % origenes_lista.size()]["id"]
    if rareza_data.get("tiene_esencia", false) and not esencias_lista.is_empty():
        esencia_id = esencias_lista[randi() % esencias_lista.size()]["id"]

    return generate_item(categoria, base["id"], rareza_id, origen_id, esencia_id)

# ─────────────────────────────────────────────────────────
# HELPERS INTERNOS
# ─────────────────────────────────────────────────────────
func _get_rareza(rareza_id: String) -> Dictionary:
    for r in db["rareza"]["niveles"]:
        if r["id"] == rareza_id:
            return r.duplicate()
    return {}

func _tirar_rareza() -> String:
    var roll = randf()
    var acumulado = 0.0
    for r in db["rareza"]["niveles"]:
        acumulado += r["prob_drop"]
        if roll < acumulado:
            return r["id"]
    return "comun"

func _construir_nombre(nombre_base: String, origen: Dictionary, esencia: Dictionary) -> String:
    var nombre = nombre_base
    if not origen.is_empty():
        nombre = origen["nombre"] + " " + nombre
    if not esencia.is_empty():
        nombre = nombre + " " + esencia["nombre"]
    return nombre

func _esencia_afecta_stat_principal(esencia: Dictionary, categoria: String) -> bool:
    var atrib = esencia.get("atributo", "")
    match atrib:
        "dano":      return categoria == "armas"
        "armadura":  return categoria in ["pecho", "escudos", "casco", "manos", "pies", "capa"]
        "todo":      return true
        _:           return false

func _parse_bonus_extra(bonus_str: String) -> Dictionary:
    var partes = bonus_str.split(":")
    if partes.size() == 2:
        return { "stat": partes[0], "valor": float(partes[1]) }
    return {}

# ─────────────────────────────────────────────────────────
# UTILIDADES PÚBLICAS
# ─────────────────────────────────────────────────────────
func get_durabilidad_pct(item: Dictionary) -> float:
    if item.get("dur_max", 0) == 0:
        return 0.0
    return float(item.get("durabilidad", 0)) / float(item["dur_max"])

func reducir_durabilidad(item: Dictionary) -> Dictionary:
    item["durabilidad"] = max(0, item.get("durabilidad", 0) - 1)
    return item

func reparar_item(item: Dictionary) -> Dictionary:
    var nivel = item.get("nivel", 1)
    var costo = nivel * 5
    if GameData.bronze_hand >= costo:
        GameData.bronze_hand -= costo
        item["durabilidad"] = item["dur_max"]
    return item

func get_descripcion(item: Dictionary) -> String:
    var txt = item.get("nombre", "?") + "\n"
    txt += "Nivel requerido: " + str(item.get("nivel", 1)) + "\n"
    if item.has("dano_min"):
        txt += "Daño: " + str(item["dano_min"]) + " - " + str(item["dano_max"]) + "\n"
    if item.has("armadura"):
        txt += "Armadura: " + str(item["armadura"]) + "\n"
    if item.has("bloqueo_pct"):
        txt += "Bloqueo: " + str(item["bloqueo_pct"]) + "%\n"
    for bonus in item.get("bonus_extra", []):
        var valor = bonus.get("valor", 0)
        var signo = "+" if valor >= 0 else ""
        txt += bonus.get("stat", "?") + ": " + signo + str(valor * 100) + "%\n"
    txt += "Durabilidad: " + str(item.get("durabilidad", 0)) + "/" + str(item.get("dur_max", 0))
    return txt
