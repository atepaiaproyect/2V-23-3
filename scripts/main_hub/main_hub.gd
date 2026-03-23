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
    $HBoxMain/SideMenuContainer/SideMenu/BtnMercado,
    $HBoxMain/SideMenuContainer/SideMenu/BtnClan,
    $HBoxMain/SideMenuContainer/SideMenu/BtnCrafteo,
    $HBoxMain/SideMenuContainer/SideMenu/BtnRanking,
    $HBoxMain/SideMenuContainer/SideMenu/BtnInventario,
    $HBoxMain/SideMenuContainer/SideMenu/BtnEntrenamiento,
    $HBoxMain/SideMenuContainer/SideMenu/BtnTaberna,
]

var btn_section_map = {}
var editing_slot: int = -1
var active_button: Button = null
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

func _setup_effects():
    var sections = [
        "Perfil", "Exploración", "Arena", "Mercado", "Clan",
        "Crafteo", "Ranking", "Inventario", "Entrenamiento", "Taberna"
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
    label_content.text = "[ " + section + " ]\n\nEsta sección está en construcción.\nProximamente disponible."

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
