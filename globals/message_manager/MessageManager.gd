extends Node

# ============================================================
# MessageManager — Autoload
# Maneja mensajes privados, reportes PvE y PvP
# Colección Firestore: "messages"
#
# Campos de cada documento:
#   to_player_id   : string   — destinatario
#   from_name      : string   — remitente
#   type           : string   — "pve" | "pvp_ataque" | "pvp_defensa" | "sistema"
#   title          : string   — asunto
#   body           : string   — cuerpo completo del reporte
#   leido          : bool
#   timestamp      : int      — unix timestamp
#   expires_at     : int      — timestamp + 60 días
# ============================================================

signal unread_changed(count: int)

const FIRESTORE_URL = "https://firestore.googleapis.com/v1/projects/atepaia-2v/databases/(default)/documents"
const DIAS_EXPIRACION = 60

var unread_count: int = 0


# ── Guardar un reporte / mensaje ──────────────────────────────
func guardar_reporte(to_player_id: String, from_name: String,
                     tipo: String, title: String, body: String) -> void:
    if to_player_id == "" or GameData.id_token == "":
        return

    var ahora      = int(Time.get_unix_time_from_system())
    var expira_en  = ahora + DIAS_EXPIRACION * 86400
    var msg_id     = str(ahora) + "_" + to_player_id.substr(0, 6) + "_" + tipo

    var doc = {
        "fields": {
            "to_player_id": { "stringValue": to_player_id },
            "from_name":    { "stringValue": from_name },
            "type":         { "stringValue": tipo },
            "title":        { "stringValue": title },
            "body":         { "stringValue": body },
            "leido":        { "booleanValue": false },
            "timestamp":    { "integerValue": str(ahora) },
            "expires_at":   { "integerValue": str(expira_en) },
        }
    }

    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(func(_r, _c, _h, _b): http.queue_free())

    var url = FIRESTORE_URL + "/messages/" + msg_id
    var headers = _headers()
    http.request(url, headers, HTTPClient.METHOD_PATCH, JSON.stringify(doc))


# ── Contar mensajes no leídos del jugador actual ──────────────
func cargar_no_leidos() -> void:
    if GameData.player_id == "" or GameData.id_token == "":
        return

    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(func(_r, code, _h, body):
        http.queue_free()
        _on_no_leidos(code, body)
    )

    var query = {
        "structuredQuery": {
            "from": [{"collectionId": "messages"}],
            "where": {
                "compositeFilter": {
                    "op": "AND",
                    "filters": [
                        {
                            "fieldFilter": {
                                "field": {"fieldPath": "to_player_id"},
                                "op": "EQUAL",
                                "value": {"stringValue": GameData.player_id}
                            }
                        },
                        {
                            "fieldFilter": {
                                "field": {"fieldPath": "leido"},
                                "op": "EQUAL",
                                "value": {"booleanValue": false}
                            }
                        }
                    ]
                }
            },
            "limit": 100
        }
    }

    var url = "https://firestore.googleapis.com/v1/projects/atepaia-2v/databases/(default)/documents:runQuery"
    http.request(url, _headers(), HTTPClient.METHOD_POST, JSON.stringify(query))


func _on_no_leidos(code: int, body: PackedByteArray) -> void:
    if code != 200:
        return
    var data = JSON.parse_string(body.get_string_from_utf8())
    var count = 0
    if data is Array:
        for entry in data:
            if entry.has("document"):
                count += 1
    unread_count = count
    emit_signal("unread_changed", unread_count)


# ── Marcar un mensaje como leído ─────────────────────────────
func marcar_leido(msg_id: String) -> void:
    if GameData.id_token == "": return
    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(func(_r, _c, _h, _b): http.queue_free())
    var url = FIRESTORE_URL + "/messages/" + msg_id + "?updateMask.fieldPaths=leido"
    http.request(url, _headers(), HTTPClient.METHOD_PATCH,
        JSON.stringify({"fields": {"leido": {"booleanValue": true}}}))


# ── Borrar un mensaje ─────────────────────────────────────────
func borrar_mensaje(msg_id: String) -> void:
    if GameData.id_token == "": return
    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(func(_r, _c, _h, _b): http.queue_free())
    http.request(FIRESTORE_URL + "/messages/" + msg_id, _headers(), HTTPClient.METHOD_DELETE)


# ── Helper: construir log de combate como texto ───────────────
func construir_log_pve(resultado: Dictionary, nombre_jugador: String, nombre_enemigo: String) -> String:
    var gano     = resultado.get("jugador_gano", false)
    var rondas   = resultado.get("rondas", 0)
    var bronce   = resultado.get("oro_ganado", 0)
    var xp       = resultado.get("xp_ganada", 0)
    var hp_final = resultado.get("hp_final_a", 0)
    var hp_max   = resultado.get("hp_max_a", 0)
    var item     = resultado.get("item_dropeado", {})
    var txt = ""

    if gano:
        txt += "══════════════════════════════════\n"
        txt += "         VICTORIA\n"
        txt += "   Ganador: " + nombre_jugador + "\n"
        txt += "══════════════════════════════════\n\n"
        txt += "— RECOMPENSAS ————————————————\n"
        txt += "🪙 Bronce ganado: +" + str(bronce) + "\n"
        txt += "⭐ XP ganada: +" + str(xp) + "\n"
        if not item.is_empty():
            txt += "🎁 Objeto: " + item.get("nombre", "?") + "\n"
        txt += "\n"
    else:
        txt += "══════════════════════════════════\n"
        txt += "         DERROTA\n"
        txt += "   Ganador: " + nombre_enemigo + "\n"
        txt += "══════════════════════════════════\n\n"

    txt += "— ESTADO FINAL ——————————————————\n"
    txt += nombre_jugador + ":  HP " + str(hp_final) + " / " + str(hp_max) + "\n"
    txt += nombre_enemigo + ":  " + ("HP 0 (derrotado)" if gano else "sobrevivio") + "\n\n"

    txt += "— INFORME DE BATALLA (" + str(rondas) + " rondas) ————\n"
    for ronda_data in resultado.get("log", []):
        txt += "\n  Ronda " + str(ronda_data.get("ronda", 0)) + "\n"
        txt += "  " + "-".repeat(26) + "\n"
        for ev in ronda_data.get("eventos", []):
            txt += _fmt_ev(ev) + "\n"

    txt += "\n══════════════════════════════════\n"
    txt += (nombre_jugador + " triunfo en batalla.\n") if gano else (nombre_jugador + " fue derrotado.\n")
    return txt


func construir_log_pvp(resultado: Dictionary, nombre_atacante: String, nombre_defensor: String) -> String:
    var gano     = resultado.get("jugador_gano", false)
    var rondas   = resultado.get("rondas", 0)
    var hp_j     = resultado.get("hp_final_a", 0)
    var hp_max_j = resultado.get("hp_max_a", 0)
    var hp_r     = resultado.get("hp_final_d", 0)
    var hp_max_r = resultado.get("hp_max_d", 0)
    var txt = ""

    if gano:
        txt += "══════════════════════════════════\n"
        txt += "         VICTORIA\n"
        txt += "   " + nombre_atacante + " derroto a " + nombre_defensor + "\n"
        txt += "══════════════════════════════════\n\n"
    else:
        txt += "══════════════════════════════════\n"
        txt += "         DERROTA\n"
        txt += "   " + nombre_defensor + " resistio el ataque\n"
        txt += "══════════════════════════════════\n\n"

    txt += "— ESTADO FINAL ——————————————————\n"
    txt += "Atacante " + nombre_atacante + ":  HP " + str(hp_j) + " / " + str(hp_max_j) + "\n"
    txt += "Defensor " + nombre_defensor + ":  HP " + str(hp_r) + " / " + str(hp_max_r) + "\n\n"

    txt += "— INFORME DE BATALLA (" + str(rondas) + " rondas) ————\n"
    for ronda_data in resultado.get("log", []):
        txt += "\n  Ronda " + str(ronda_data.get("ronda", 0)) + "\n"
        txt += "  " + "-".repeat(26) + "\n"
        for ev in ronda_data.get("eventos", []):
            txt += _fmt_ev(ev) + "\n"

    txt += "\n══════════════════════════════════\n"
    txt += (nombre_atacante + " prevaleció en la arena.\n") if gano else (nombre_atacante + " fue expulsado.\n")
    return txt


func _fmt_ev(ev: Dictionary) -> String:
    var tipo    = ev.get("tipo",     "golpe")
    var atac    = ev.get("atacante", "?")
    var defen   = ev.get("defensor", "?")
    var dano    = ev.get("dano",     0)
    var esquivo = ev.get("esquivo",  false)
    var critico = ev.get("critico",  false)
    match tipo:
        "muerte":
            return "  [X] " + ev.get("nombre", "?") + " cae derrotado."
        "resistencia":
            return "  [!] " + ev.get("nombre", "?") + " resistio el golpe mortal. Sobrevive con 1 HP."
        "doble":
            if dano <= 0: return "  " + atac + " golpea a " + defen + " — esquivado."
            return "  " + atac + " DOBLE GOLPE a " + defen + " — " + str(dano) + " de dano."
        _:
            if esquivo or dano <= 0:
                return "  " + atac + " golpea a " + defen + " — esquivado."
            elif critico:
                return "  [*] " + atac + " GOLPE CRITICO a " + defen + " — " + str(dano) + " de dano. [*]"
            else:
                return "  " + atac + " golpea a " + defen + " — " + str(dano) + " de dano."


# mantener _formatear_evento para compatibilidad
func _formatear_evento(ev: Dictionary) -> String:
    return _fmt_ev(ev)


func _headers() -> PackedStringArray:
    return PackedStringArray([
        "Content-Type: application/json",
        "Authorization: Bearer " + GameData.id_token
    ])
