extends Control

# --- Referencias barra superior ---
@onready var btn_quick = [
    $HBoxMain/VBoxRight/TopBar/TopBarContent/BtnQuick1,
    $HBoxMain/VBoxRight/TopBar/TopBarContent/BtnQuick2,
    $HBoxMain/VBoxRight/TopBar/TopBarContent/BtnQuick3,
    $HBoxMain/VBoxRight/TopBar/TopBarContent/BtnQuick4,
    $HBoxMain/VBoxRight/TopBar/TopBarContent/BtnQuick5,
]
@onready var label_player = $HBoxMain/VBoxRight/TopBar/TopBarContent/LabelPlayer
@onready var label_content = $HBoxMain/VBoxRight/ContentContainer/ContentArea/LabelContent
@onready var edit_popup = $EditPopup
@onready var label_slot_info = $EditPopup/VBoxPopup/LabelSlotInfo

@onready var menu_buttons = [
    $HBoxMain/SideMenuContainer/SideMenu/BtnPerfil,
    $HBoxMain/SideMenuContainer/SideMenu/BtnExploracion,
    $HBoxMain/SideMenuContainer/SideMenu/BtnArena,
    $HBoxMain/SideMenuContainer/SideMenu/BtnClasificacion,
    $HBoxMain/SideMenuContainer/SideMenu/BtnMercado,
    $HBoxMain/SideMenuContainer/SideMenu/BtnClan,
    $HBoxMain/SideMenuContainer/SideMenu/BtnCrafteo,
    $HBoxMain/SideMenuContainer/SideMenu/BtnRanking,
    $HBoxMain/SideMenuContainer/SideMenu/BtnInventario,
    $HBoxMain/SideMenuContainer/SideMenu/BtnEntrenamiento,
    $HBoxMain/SideMenuContainer/SideMenu/BtnTaberna,
    $HBoxMain/SideMenuContainer/SideMenu/BtnSalir,
]

var btn_section_map = {}
var editing_slot: int = -1
var active_button: Button = null
var _btn_correo: Button = null
var _lbl_badge:  Label  = null
var quick_slots = [
    "👤  Perfil",
    "⚔  Arena",
    "🏪  Mercado",
    "🛡  Clan",
	"🏆  Ranking"
]

# ─────────────────────────────────────
func _ready():
    var nombre = GameData.player_name if GameData.player_name != "" else "Aventurero"
    label_player.text = "  " + nombre + "  "
    _update_quick_buttons()
    edit_popup.visible = false
    call_deferred("_setup_effects")
    # Cargar Perfil por defecto
    call_deferred("_navigate_to", "Perfil")
    # Iniciar timer de regeneración de HP en tiempo real
    _iniciar_regen_timer()
    # Agregar botón de correo/mensajes
    call_deferred("_agregar_boton_correo")

# ─────────────────────────────────────
# REGENERACIÓN DE HP EN TIEMPO REAL
# 1 tick cada 60 segundos = 1 minuto
# ─────────────────────────────────────
var _regen_timer: Timer

func _iniciar_regen_timer() -> void:
    _regen_timer = Timer.new()
    _regen_timer.wait_time = 60.0
    _regen_timer.autostart = true
    _regen_timer.timeout.connect(_on_regen_tick)
    add_child(_regen_timer)

func _on_regen_tick() -> void:
    if GameData.hp < GameData.hp_max:
        GameData.hp = min(GameData.hp + GameData.hp_regen_per_min, GameData.hp_max)
        # Guardar HP actualizado en Firebase
        SaveManager.save_progress()
        # Notificar al perfil si está abierto para refrescar los labels
        EquipmentManager.emit_signal("stats_changed")

func _setup_effects():
    var sections = [
        "Perfil", "Exploración", "Arena", "Clasificación", "Mercado", "Clan",
        "Crafteo", "Ranking", "Inventario", "Entrenamiento", "Taberna", "Salir"
    ]
    for i in range(menu_buttons.size()):
        var btn = menu_buttons[i]
        btn_section_map[btn] = sections[i]
        btn.mouse_entered.connect(_on_side_btn_enter.bind(btn))
        btn.mouse_exited.connect(_on_side_btn_exit.bind(btn))
        btn.pressed.connect(_on_side_btn_clicked.bind(btn))
    for btn in btn_quick:
        btn.mouse_entered.connect(_on_top_btn_enter.bind(btn))
        btn.mouse_exited.connect(_on_top_btn_exit.bind(btn))

# ─────────────────────────────────────
func _on_side_btn_clicked(btn: Button):
    _set_active_button(btn)
    _navigate_to(btn_section_map[btn])

func _on_side_btn_enter(btn: Button):
    if btn == active_button:
        return
    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_method(func(c): btn.add_theme_color_override("font_color", c),
        Color(0.85, 0.72, 0.45, 1.0), Color(1.0, 0.95, 0.5, 1.0), 0.12)
    tween.tween_property(btn, "position:x", 6.0, 0.12).set_ease(Tween.EASE_OUT)

func _on_side_btn_exit(btn: Button):
    if btn == active_button:
        return
    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_method(func(c): btn.add_theme_color_override("font_color", c),
        Color(1.0, 0.95, 0.5, 1.0), Color(0.85, 0.72, 0.45, 1.0), 0.15)
    tween.tween_property(btn, "position:x", 0.0, 0.15).set_ease(Tween.EASE_OUT)

func _on_top_btn_enter(btn: Button):
    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_method(func(c): btn.add_theme_color_override("font_color", c),
        Color(0.15, 0.08, 0.02, 1.0), Color(0.5, 0.25, 0.02, 1.0), 0.1)
    tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1).set_ease(Tween.EASE_OUT)

func _on_top_btn_exit(btn: Button):
    var tween = create_tween()
    tween.set_parallel(true)
    tween.tween_method(func(c): btn.add_theme_color_override("font_color", c),
        Color(0.5, 0.25, 0.02, 1.0), Color(0.15, 0.08, 0.02, 1.0), 0.12)
    tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12).set_ease(Tween.EASE_OUT)

func _set_active_button(btn: Button):
    if active_button != null and active_button != btn:
        active_button.add_theme_color_override("font_color", Color(0.85, 0.72, 0.45, 1.0))
        active_button.position.x = 0.0
    active_button = btn
    btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3, 1.0))
    btn.position.x = 8.0

func _update_quick_buttons():
    for i in range(5):
        btn_quick[i].text = quick_slots[i]

func _on_quick_btn_pressed(slot_index: int):
    var clean = quick_slots[slot_index]
    for emoji in ["👤  ", "🗺  ", "⚔  ", "🏪  ", "🛡  ", "⚒  ", "🏆  ", "🎒  ", "💪  ", "🍺  "]:
        clean = clean.replace(emoji, "")
    _navigate_to(clean)

func _navigate_to(section: String):
    match section:
        "Perfil":
            _load_sub_scene("res://scenes/profile/Profile.tscn")
        "Exploración":
            _load_sub_scene("res://scenes/exploration/Exploration.tscn")
        "Entrenamiento":
            _load_sub_scene("res://scenes/training/Training.tscn")
        "Arena":
            _load_sub_scene("res://scenes/arena/Arena.tscn")
        "Clasificación":
            _load_sub_scene("res://scenes/classification/Classification.tscn")
        "Clan":
            _load_sub_scene("res://scenes/clan/Clan.tscn")
        "Ranking":
            _load_sub_scene("res://scenes/ranking/Ranking.tscn")
        "Salir":
            SaveManager.save_and_quit()
        "Herreria":
            _load_sub_scene("res://scenes/crafting/Crafting.tscn")
        "Inventario", "Mercado", "Taberna":
            _show_label_bloqueado(section)
        _:
            _show_label("[ " + section + " ]\n\nEsta sección está en construcción.\nProximamente disponible.")

func _load_sub_scene(path: String):
    for child in $HBoxMain/VBoxRight/ContentContainer/ContentArea.get_children():
        child.queue_free()
    var scene = load(path).instantiate()
    $HBoxMain/VBoxRight/ContentContainer/ContentArea.add_child(scene)

func _show_label(text: String):
    for child in $HBoxMain/VBoxRight/ContentContainer/ContentArea.get_children():
        child.queue_free()
    label_content.text = text
    $HBoxMain/VBoxRight/ContentContainer/ContentArea.add_child(label_content)

func _show_label_bloqueado(section: String):
    var iconos = {"Herreria": "⚒", "Inventario": "🎒", "Mercado": "🏪", "Taberna": "🍺"}
    var fechas = {"Herreria": "Próximamente", "Inventario": "Próximamente", "Mercado": "Próximamente", "Taberna": "Próximamente"}
    var icono = iconos.get(section, "🔒")
    var txt = icono + "  " + section.to_upper() + "\n\n"
    txt += "Esta sección está en desarrollo.\n"
    txt += "Estará disponible en una próxima actualización.\n\n"
    txt += "⚠  No disponible aún."
    for child in $HBoxMain/VBoxRight/ContentContainer/ContentArea.get_children():
        child.queue_free()
    label_content.text = txt
    $HBoxMain/VBoxRight/ContentContainer/ContentArea.add_child(label_content)

func _on_btn_edit_pressed():
    editing_slot = 0
    _open_edit_popup(0)

func _open_edit_popup(slot: int):
    editing_slot = slot
    label_slot_info.text = "Editando botón " + str(slot + 1) + " de 5"
    edit_popup.visible = true

func _on_option_selected(option: String):
    if editing_slot >= 0 and editing_slot < 5:
        quick_slots[editing_slot] = option
        _update_quick_buttons()
        editing_slot += 1
        if editing_slot < 5:
            _open_edit_popup(editing_slot)
        else:
            edit_popup.visible = false
            editing_slot = -1

func _on_popup_cerrar():
    edit_popup.visible = false
    editing_slot = -1

# ─────────────────────────────────────
# BOTÓN DE CORREO CON BADGE
# ─────────────────────────────────────
func _agregar_boton_correo() -> void:
    var topbar_content = get_node_or_null("HBoxMain/VBoxRight/TopBar/TopBarContent")
    if topbar_content == null:
        return

    # Contenedor del botón con badge encima
    var stack = Control.new()
    stack.custom_minimum_size = Vector2(48, 36)
    topbar_content.add_child(stack)

    _btn_correo = Button.new()
    _btn_correo.text = "✉"
    _btn_correo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _btn_correo.add_theme_font_size_override("font_size", 18)
    _btn_correo.pressed.connect(_abrir_buzon)
    stack.add_child(_btn_correo)

    # Badge rojo con contador
    _lbl_badge = Label.new()
    _lbl_badge.text = ""
    _lbl_badge.add_theme_font_size_override("font_size", 10)
    _lbl_badge.add_theme_color_override("font_color", Color(1, 1, 1, 1))
    _lbl_badge.position = Vector2(26, -4)
    _lbl_badge.visible = false

    var badge_panel = PanelContainer.new()
    badge_panel.position = Vector2(26, -4)
    badge_panel.custom_minimum_size = Vector2(18, 18)
    var badge_style = StyleBoxFlat.new()
    badge_style.bg_color = Color(0.95, 0.2, 0.2, 1)
    badge_style.corner_radius_top_left     = 9
    badge_style.corner_radius_top_right    = 9
    badge_style.corner_radius_bottom_left  = 9
    badge_style.corner_radius_bottom_right = 9
    badge_panel.add_theme_stylebox_override("panel", badge_style)
    badge_panel.add_child(_lbl_badge)
    badge_panel.name = "BadgePanel"
    badge_panel.visible = false
    stack.add_child(badge_panel)

    # Conectar señal del MessageManager
    if MessageManager.unread_changed.is_connected(_on_unread_changed):
        pass
    else:
        MessageManager.unread_changed.connect(_on_unread_changed)

    # Cargar no leídos al abrir
    MessageManager.cargar_no_leidos()


func _on_unread_changed(count: int) -> void:
    if _lbl_badge == null:
        return
    var badge = get_node_or_null("HBoxMain/VBoxRight/TopBar/TopBarContent/*/BadgePanel")
    if count > 0:
        _lbl_badge.text = str(count) if count < 100 else "99+"
        _lbl_badge.visible = true
        if badge: badge.visible = true
        # Pulso animado para llamar la atención
        if _btn_correo:
            var tween = create_tween()
            tween.tween_property(_btn_correo, "scale", Vector2(1.2, 1.2), 0.15)
            tween.tween_property(_btn_correo, "scale", Vector2(1.0, 1.0), 0.15)
    else:
        _lbl_badge.visible = false
        if badge: badge.visible = false


func _abrir_buzon() -> void:
    # Evitar abrir dos veces
    if get_node_or_null("Mailbox"):
        return
    var script = load("res://scripts/mailbox/mailbox.gd")
    if script == null:
        return
    var buzon = Control.new()
    buzon.name = "Mailbox"
    buzon.set_script(script)
    add_child(buzon)
    buzon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    buzon.z_index = 150
