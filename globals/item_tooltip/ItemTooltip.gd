extends CanvasLayer

# Sistema de 5 calidades
const RARITY_COLORS := {
    "normal":     Color(0.90, 0.90, 0.90, 1.0),
    "bueno":      Color(0.30, 0.90, 0.30, 1.0),
    "epico":      Color(0.80, 0.40, 1.00, 1.0),
    "inmortal":   Color(1.00, 0.30, 0.30, 1.0),
    "legendario": Color(1.00, 0.85, 0.20, 1.0),
    # Compatibilidad sistema viejo
    "comun":      Color(0.85, 0.85, 0.85, 1.0),
    "inusual":    Color(0.30, 0.85, 0.30, 1.0),
    "magico":     Color(0.40, 0.60, 1.00, 1.0),
    "raro":       Color(1.00, 0.85, 0.10, 1.0),
}

const RARITY_LABELS := {
    "normal":     "Normal",
    "bueno":      "✦ Bueno",
    "epico":      "✦✦ Épico",
    "inmortal":   "✦✦✦ Inmortal",
    "legendario": "✦✦✦✦ Legendario",
    "comun":      "Común",
    "inusual":    "Inusual",
    "magico":     "Mágico",
    "raro":       "Raro",
}

var panel       : PanelContainer
var lbl_nombre  : Label
var lbl_rareza  : Label
var sep1        : HSeparator
var lbl_nivel   : Label
var lbl_stats   : Label
var sep2        : HSeparator
var lbl_valor   : Label
var lbl_crafteo : Label
var lbl_desc    : Label

func _ready() -> void:
    layer = 128
    _build_ui()
    panel.visible = false
    set_process_input(true)

func _build_ui() -> void:
    panel = PanelContainer.new()
    panel.custom_minimum_size = Vector2(240, 0)
    panel.z_index = 200
    add_child(panel)

    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left",   10)
    margin.add_theme_constant_override("margin_right",  10)
    margin.add_theme_constant_override("margin_top",    10)
    margin.add_theme_constant_override("margin_bottom", 10)
    panel.add_child(margin)

    var inner = VBoxContainer.new()
    inner.add_theme_constant_override("separation", 5)
    margin.add_child(inner)

    lbl_nombre  = _lbl("", 15, Color.WHITE, true)
    inner.add_child(lbl_nombre)

    lbl_rareza  = _lbl("", 12, Color.WHITE, true)
    inner.add_child(lbl_rareza)

    inner.add_child(HSeparator.new())

    lbl_nivel   = _lbl("", 11, Color(0.8, 0.75, 0.6, 1), false)
    inner.add_child(lbl_nivel)

    lbl_stats   = _lbl("", 11, Color(0.9, 0.85, 0.7, 1), false)
    lbl_stats.autowrap_mode = TextServer.AUTOWRAP_WORD
    inner.add_child(lbl_stats)

    inner.add_child(HSeparator.new())

    lbl_valor   = _lbl("", 11, Color(1.0, 0.85, 0.3, 1), false)
    inner.add_child(lbl_valor)

    lbl_crafteo = _lbl("", 10, Color(0.6, 0.8, 1.0, 1), false)
    lbl_crafteo.autowrap_mode = TextServer.AUTOWRAP_WORD
    lbl_crafteo.visible = false
    inner.add_child(lbl_crafteo)

    lbl_desc    = _lbl("", 10, Color(0.55, 0.55, 0.55, 1), false)
    lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
    lbl_desc.visible = false
    inner.add_child(lbl_desc)

func _lbl(txt: String, size: int, color: Color, _bold: bool) -> Label:
    var l = Label.new()
    l.text = txt
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    return l

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if panel.visible:
            if not panel.get_global_rect().has_point(event.position):
                hide_tooltip()

func show_tooltip(item: Dictionary, origin_pos: Vector2) -> void:
    var rareza    = item.get("rareza", item.get("calidad", "normal"))
    var nivel     = item.get("nivel", 1)
    var herrero   = item.get("crafteo_por", "")
    var categoria = item.get("categoria", "")
    var color     = RARITY_COLORS.get(rareza, Color.WHITE)

    # Borde del panel con color de calidad
    var style = StyleBoxFlat.new()
    style.bg_color        = Color(0.08, 0.06, 0.04, 0.97)
    style.border_color    = color
    style.border_width_left   = 2
    style.border_width_right  = 2
    style.border_width_top    = 2
    style.border_width_bottom = 2
    style.corner_radius_top_left     = 5
    style.corner_radius_top_right    = 5
    style.corner_radius_bottom_left  = 5
    style.corner_radius_bottom_right = 5
    panel.add_theme_stylebox_override("panel", style)

    # Nombre con color de calidad
    lbl_nombre.text = item.get("nombre", "?")
    lbl_nombre.add_theme_color_override("font_color", color)

    # Calidad — texto con color
    lbl_rareza.text = RARITY_LABELS.get(rareza, "Normal")
    lbl_rareza.add_theme_color_override("font_color", color)

    # Nivel
    lbl_nivel.text = "Nivel: " + str(nivel) + "   Slot: " + item.get("slot", "?").capitalize()

    # Stats — soporta todas las categorías
    var s = ""
    var dur = str(item.get("durabilidad", 0)) + " / " + str(item.get("durabilidad_max", 0))
    match categoria:
        "armas":
            s  = "⚔ Daño: " + str(item.get("ataque_min", 0)) + " — " + str(item.get("ataque_max", 0))
            s += "\n🔧 Durabilidad: " + dur
        "escudos":
            s  = "🛡 Defensa: " + str(item.get("defensa", 0))
            var blq = item.get("bloqueo_bonus", 0.0)
            if blq > 0:
                s += "\n⛨ Bloqueo: +" + str(int(blq * 100)) + "%"
            s += "\n🔧 Durabilidad: " + dur
        "pecho":
            s  = "🛡 Defensa: " + str(item.get("defensa", 0))
            var con_b = item.get("constitucion_bonus", 0)
            if con_b > 0:
                s += "\n💪 Constitución: +" + str(con_b)
            s += "\n🔧 Durabilidad: " + dur
        "cascos":
            s  = "🛡 Defensa: " + str(item.get("defensa", 0))
            s += "\n🔧 Durabilidad: " + dur
        "guantes":
            s  = "🛡 Defensa: " + str(item.get("defensa", 0))
            s += "\n🔧 Durabilidad: " + dur
        "botas":
            s  = "🛡 Defensa: " + str(item.get("defensa", 0))
            s += "\n🔧 Durabilidad: " + dur
        "anillos", "collares":
            var bonus_tipo = item.get("bonus_tipo", "")
            match bonus_tipo:
                "armadura":
                    s = "🛡 Armadura: +" + str(item.get("defensa", 0))
                "ataque":
                    s = "⚔ Ataque: +" + str(item.get("ataque_min", 0)) + " / +" + str(item.get("ataque_max", 0))
                "all_stats":
                    var pct = int(item.get("all_stats_bonus", 0.03) * 100)
                    s = "✦ Todos los stats: +" + str(pct) + "%"
                _:
                    if item.has("defensa"):
                        s = "🛡 Armadura: +" + str(item.get("defensa", 0))
                    elif item.has("ataque_min"):
                        s = "⚔ Ataque: +" + str(item.get("ataque_min", 0)) + " — +" + str(item.get("ataque_max", 0))
    lbl_stats.text = s

    # Valor
    var valor = item.get("valor_mercado", nivel * 10)
    lbl_valor.text = "Valor estimado: " + str(valor) + " oro"

    # Crafteo
    if herrero != "":
        lbl_crafteo.text    = "⚒ Crafteado por: " + herrero
        lbl_crafteo.visible = true
    else:
        lbl_crafteo.visible = false

    # Descripción
    var desc = item.get("descripcion", "")
    if desc != "":
        lbl_desc.text    = "\"" + desc + "\""
        lbl_desc.visible = true
    else:
        lbl_desc.visible = false

    # Posición junto al ítem
    panel.visible = true
    await get_tree().process_frame
    var screen = get_viewport().get_visible_rect().size
    var pos    = origin_pos + Vector2(65, 0)
    if pos.x + panel.size.x > screen.x:
        pos.x = origin_pos.x - panel.size.x - 4
    if pos.y + panel.size.y > screen.y:
        pos.y = screen.y - panel.size.y - 4
    panel.global_position = pos

# ─────────────────────────────────────────────────────────
# TOOLTIP DOBLE — Enemigo vs Jugador
# panel_jugador se posiciona al lado del panel enemigo
# ─────────────────────────────────────────────────────────
var panel_jugador : PanelContainer
var lbl_j_nivel   : Label
var lbl_j_hp      : Label
var lbl_j_stats   : Label

func _asegurar_panel_jugador() -> void:
    if panel_jugador != null:
        return

    panel_jugador = PanelContainer.new()
    panel_jugador.custom_minimum_size = Vector2(220, 0)
    panel_jugador.z_index = 200
    panel_jugador.visible = false
    add_child(panel_jugador)

    var margin_j = MarginContainer.new()
    margin_j.add_theme_constant_override("margin_left",   10)
    margin_j.add_theme_constant_override("margin_right",  10)
    margin_j.add_theme_constant_override("margin_top",    10)
    margin_j.add_theme_constant_override("margin_bottom", 10)
    panel_jugador.add_child(margin_j)

    var inner_j = VBoxContainer.new()
    inner_j.add_theme_constant_override("separation", 5)
    margin_j.add_child(inner_j)

    var lbl_titulo = _lbl("— Tu personaje —", 11, Color(0.7, 0.7, 0.7, 1), false)
    lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    inner_j.add_child(lbl_titulo)
    inner_j.add_child(HSeparator.new())

    lbl_j_nivel = _lbl("", 11, Color(0.4, 0.8, 1.0, 1), false)
    inner_j.add_child(lbl_j_nivel)

    lbl_j_hp = _lbl("", 11, Color(0.9, 0.3, 0.3, 1), false)
    inner_j.add_child(lbl_j_hp)

    lbl_j_stats = _lbl("", 11, Color(0.9, 0.85, 0.7, 1), false)
    lbl_j_stats.autowrap_mode = TextServer.AUTOWRAP_WORD
    inner_j.add_child(lbl_j_stats)

func show_tooltip_mob(mob: Dictionary, origin_pos: Vector2) -> void:
    _asegurar_panel_jugador()

    var nivel   = mob.get("nivel", 1)
    var es_jefe = mob.get("es_jefe", false)
    var color   = Color(1.0, 0.75, 0.1, 1) if es_jefe else Color(0.9, 0.85, 0.7, 1)

    # Panel enemigo
    lbl_nombre.text = mob.get("nombre", "?")
    lbl_nombre.add_theme_color_override("font_color", color)
    lbl_rareza.text = "JEFE DE ZONA" if es_jefe else "Enemigo · Nivel " + str(nivel)
    lbl_rareza.add_theme_color_override("font_color", color)
    lbl_nivel.text  = "HP: " + str(mob.get("hp_max", 0))
    var s  = "Fuerza: "     + str(mob.get("attr_strength", 0))
    s += "\nAgilidad: "    + str(mob.get("attr_agility", 0))
    s += "\nConstitución: "+ str(mob.get("attr_constitution", 0))
    s += "\nDaño: "        + str(mob.get("ataque_min", 0)) + " — " + str(mob.get("ataque_max", 0))
    s += "\nArmadura: "    + str(mob.get("armadura", 0))
    lbl_stats.text = s
    lbl_valor.text = mob.get("descripcion", "")
    lbl_crafteo.visible = false
    lbl_desc.visible    = false

    # Panel jugador
    lbl_j_nivel.text = "Nivel " + str(GameData.level)
    lbl_j_hp.text    = "HP: " + str(GameData.hp) + " / " + str(GameData.hp_max)
    var dmg_min = 5  + GameData.attr_strength + GameData.damage_min
    var dmg_max = 10 + GameData.attr_strength * 2 + GameData.damage_max
    var js  = "Fuerza: "     + str(GameData.attr_strength)
    js += "\nAgilidad: "    + str(GameData.attr_agility)
    js += "\nConstitución: "+ str(GameData.attr_constitution)
    js += "\nDaño: "        + str(dmg_min) + " — " + str(dmg_max)
    js += "\nArmadura: "    + str(GameData.attr_constitution * 5 + GameData.armor)
    lbl_j_stats.text = js

    panel.visible         = true
    panel_jugador.visible = true

    await get_tree().process_frame

    # Posicionar enemigo, luego jugador justo al lado
    var screen = get_viewport().get_visible_rect().size
    var ancho_total = panel.size.x + 8 + panel_jugador.size.x
    var pos = origin_pos + Vector2(155, 0)
    if pos.x + ancho_total > screen.x:
        pos.x = origin_pos.x - ancho_total - 4
    if pos.y + panel.size.y > screen.y:
        pos.y = screen.y - panel.size.y - 4
    panel.global_position         = pos
    panel_jugador.global_position = Vector2(pos.x + panel.size.x + 8, pos.y)

func hide_tooltip() -> void:
    panel.visible = false
    if panel_jugador != null:
        panel_jugador.visible = false
