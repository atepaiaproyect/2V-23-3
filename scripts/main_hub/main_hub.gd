extends Control

# --- Referencias barra superior ---
@onready var btn_quick = [
    $VBoxMain/TopBar/TopBarContent/BtnQuick1,
    $VBoxMain/TopBar/TopBarContent/BtnQuick2,
    $VBoxMain/TopBar/TopBarContent/BtnQuick3,
    $VBoxMain/TopBar/TopBarContent/BtnQuick4,
    $VBoxMain/TopBar/TopBarContent/BtnQuick5,
]
@onready var label_player = $VBoxMain/TopBar/TopBarContent/LabelPlayer
@onready var label_content = $VBoxMain/HBoxContent/ContentContainer/ContentArea/LabelContent
@onready var edit_popup = $EditPopup
@onready var label_slot_info = $EditPopup/VBoxPopup/LabelSlotInfo

# --- Estado ---
var editing_slot: int = -1
var quick_slots = [
    "👤  Perfil",
    "⚔  Arena",
    "🏪  Mercado",
    "🛡  Clan",
	"🏆  Ranking"
]

# ─────────────────────────────────────
func _ready():
    # Si no hay nombre guardado usamos "Aventurero" como placeholder
    var nombre = GameData.player_name if GameData.player_name != "" else "Aventurero"
    label_player.text = "  " + nombre + "  "
    _update_quick_buttons()
    edit_popup.visible = false

func _update_quick_buttons():
    for i in range(5):
        btn_quick[i].text = quick_slots[i]

# ─────────────────────────────────────
func _on_quick_btn_pressed(slot_index: int):
    _navigate_to(quick_slots[slot_index])

func _on_menu_pressed(section: String):
    _navigate_to(section)

func _navigate_to(section: String):
    var clean = section
    for emoji in ["👤  ", "🗺  ", "⚔  ", "🏪  ", "🛡  ", "⚒  ", "🏆  ", "🎒  ", "💪  ", "🍺  "]:
        clean = clean.replace(emoji, "")
    label_content.text = "[ " + clean + " ]\n\nEsta sección está en construcción.\nProximamente disponible."

# ─────────────────────────────────────
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
