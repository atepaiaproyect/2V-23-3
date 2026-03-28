extends Control

# ─────────────────────────────────────────────────────────
# COMBAT — Informe estilo Gladiatus
# ─────────────────────────────────────────────────────────

@onready var lbl_ganador      = $ScrollMain/VBox/MarginContent/VBoxContent/PanelHeader/LblGanador
@onready var img_jugador      = $ScrollMain/VBox/MarginContent/VBoxContent/HBoxRetratos/PanelJugador/VBoxJugador/ImgJugador
@onready var img_enemigo      = $ScrollMain/VBox/MarginContent/VBoxContent/HBoxRetratos/PanelEnemigo/VBoxEnemigo/ImgEnemigo
@onready var lbl_nombre_j     = $ScrollMain/VBox/MarginContent/VBoxContent/HBoxRetratos/PanelJugador/VBoxJugador/LblNombre
@onready var lbl_nombre_e     = $ScrollMain/VBox/MarginContent/VBoxContent/HBoxRetratos/PanelEnemigo/VBoxEnemigo/LblNombre
@onready var lbl_hp_j         = $ScrollMain/VBox/MarginContent/VBoxContent/HBoxRetratos/PanelJugador/VBoxJugador/LblHP
@onready var lbl_hp_e         = $ScrollMain/VBox/MarginContent/VBoxContent/HBoxRetratos/PanelEnemigo/VBoxEnemigo/LblHP
@onready var panel_recompensa = $ScrollMain/VBox/MarginContent/VBoxContent/PanelRecompensa
@onready var lbl_recompensa   = $ScrollMain/VBox/MarginContent/VBoxContent/PanelRecompensa/LblRecompensa
@onready var lbl_log          = $ScrollMain/VBox/MarginContent/VBoxContent/ScrollLog/LblLog
@onready var btn_volver       = $ScrollMain/VBox/MarginContent/VBoxContent/BtnVolver

func _ready() -> void:
    btn_volver.pressed.connect(_on_volver)
    _resolver_y_mostrar()

func _resolver_y_mostrar() -> void:
    var enemigo = GameData.enemigo_actual
    if enemigo.is_empty():
        lbl_ganador.text = "ERROR: No hay enemigo definido"
        return
    var jugador   = CombatEngine.get_ficha_jugador()
    var resultado = CombatEngine.run_pve(jugador, enemigo)
    _aplicar_resultado(resultado)
    _mostrar_header(resultado)
    _mostrar_retratos(resultado, jugador, enemigo)
    _mostrar_recompensa(resultado)
    _mostrar_log(resultado, jugador, enemigo)

func _aplicar_resultado(resultado: Dictionary) -> void:
    GameData.hp = max(1, resultado.get("hp_final_a", GameData.hp))
    if resultado.get("jugador_gano", false):
        GameData.bronze_hand += resultado.get("oro_ganado", 0)  # PvE recompensa en bronce
        var xp_ganada = resultado.get("xp_ganada", 0)
        GameData.xp       += xp_ganada
        GameData.xp_total += xp_ganada  # ranking Eruditos
        _chequear_nivel()
        var item = resultado.get("item_dropeado", {})
        if not item.is_empty():
            GameData.ultimo_drop = item
    # Guardar progreso en Firebase
    SaveManager.save_progress()

func _chequear_nivel() -> void:
    while GameData.xp >= GameData.xp_next:
        GameData.xp      -= GameData.xp_next
        GameData.level   += 1
        GameData.xp_next  = int(GameData.xp_next * 1.4)
        GameData.hp_max   = 100 + GameData.attr_constitution * 10
        GameData.hp       = GameData.hp_max

func _mostrar_header(resultado: Dictionary) -> void:
    var ganador = resultado.get("ganador", "?")
    lbl_ganador.text = "⚔  Ganador: " + ganador
    lbl_ganador.add_theme_color_override("font_color",
        Color(0.2, 0.9, 0.2, 1) if resultado.get("jugador_gano", false) else Color(0.9, 0.2, 0.2, 1))

func _mostrar_retratos(resultado: Dictionary, jugador: Dictionary, enemigo: Dictionary) -> void:
    lbl_nombre_j.text = jugador.get("nombre", "?")
    lbl_hp_j.text = "❤ HP: " + str(resultado.get("hp_final_a", 0)) + " / " + str(resultado.get("hp_max_a", 100))
    var tex_j = load(jugador.get("icono", ""))
    if tex_j:
        img_jugador.texture = tex_j

    lbl_nombre_e.text = enemigo.get("nombre", "?")
    lbl_hp_e.text = "❤ HP: " + str(resultado.get("hp_final_d", 0)) + " / " + str(resultado.get("hp_max_d", 100))
    var tex_e = load(enemigo.get("icono", ""))
    if tex_e:
        img_enemigo.texture = tex_e

func _mostrar_recompensa(resultado: Dictionary) -> void:
    if not resultado.get("jugador_gano", false):
        panel_recompensa.visible = false
        return
    panel_recompensa.visible = true
    var txt  = "— RECOMPENSAS ——————————————\n"
    txt     += "🪙  Bronce: +" + str(resultado.get("oro_ganado", 0)) + "\n"
    txt     += "⭐  XP:  +" + str(resultado.get("xp_ganada",  0)) + "\n"
    var item = resultado.get("item_dropeado", {})
    if not item.is_empty():
        txt += "🎁  Objeto: " + item.get("nombre", "?") + "\n"
    lbl_recompensa.text = txt

# ─────────────────────────────────────
# LOG ESTILO GLADIATUS
# ─────────────────────────────────────
func _mostrar_log(resultado: Dictionary, jugador: Dictionary, enemigo: Dictionary) -> void:
    var combat_log : Array = resultado.get("log", [])
    var nombre_j : String = jugador.get("nombre", "Jugador")
    var nombre_e : String = enemigo.get("nombre", "Enemigo")
    var txt      : String = ""

    for ronda_data in combat_log:
        var r = ronda_data.get("ronda", 0)
        txt += "\nRonda " + str(r) + "\n"

        for ev in ronda_data.get("eventos", []):
            txt += _formatear_evento(ev) + "\n"

    # Línea final
    txt += "\n"
    if resultado.get("jugador_gano", false):
        txt += "⚔  " + nombre_j + " ganó tras " + str(resultado.get("rondas", 0)) + " rondas."
    else:
        txt += "💀  " + nombre_j + " fue derrotado tras " + str(resultado.get("rondas", 0)) + " rondas."

    lbl_log.text = txt

func _formatear_evento(ev: Dictionary) -> String:
    var tipo     = ev.get("tipo",     "golpe")
    var nombre_a = ev.get("atacante", "?")
    var nombre_d = ev.get("defensor", "?")
    var dano     = ev.get("dano",     0)
    var esquivo  = ev.get("esquivo",  false)
    var critico  = ev.get("critico",  false)

    match tipo:
        "muerte":
            return "*" + ev.get("nombre", "?") + " muere*"
        "doble":
            if dano <= 0:
                return nombre_a + " ataca a " + nombre_d + ".\nfallado"
            return nombre_a + " ataca a " + nombre_d + ".\n" + nombre_d + " recibe " + str(dano) + " de daño"
        _:
            var linea = nombre_a + " ataca a " + nombre_d + "."
            if esquivo or dano <= 0:
                linea += "\nfallado"
            elif critico:
                linea += "\n*" + nombre_d + " recibe " + str(dano) + " de daño (¡CRÍTICO!)*"
            else:
                linea += "\n" + nombre_d + " recibe " + str(dano) + " de daño"
            return linea

# ─────────────────────────────────────
# VOLVER — carga Exploration como subscena
# ─────────────────────────────────────
func _on_volver() -> void:
    # Buscar el ContentArea del main hub y cargar Exploration ahí
    var content_area = _buscar_content_area()
    if content_area:
        for child in content_area.get_children():
            child.queue_free()
        var scene = load("res://scenes/exploration/Exploration.tscn").instantiate()
        content_area.add_child(scene)
    else:
        # Fallback: cambiar escena completa
        get_tree().change_scene_to_file("res://scenes/exploration/Exploration.tscn")

func _buscar_content_area() -> Node:
    # Subir por el árbol hasta encontrar el ContentArea del main hub
    var node = get_parent()
    while node != null:
        var candidate = node.find_child("ContentArea", true, false)
        if candidate:
            return candidate
        node = node.get_parent()
    return null
