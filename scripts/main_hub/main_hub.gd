extends Control

# --- Referencias barra superior ---
@onready var btn_quick = [
    $VBoxMain/TopBar/BtnQuick1,
    $VBoxMain/TopBar/BtnQuick2,
    $VBoxMain/TopBar/BtnQuick3,
    $VBoxMain/TopBar/BtnQuick4,
    $VBoxMain/TopBar/BtnQuick5,
]
@onready var label_player = $VBoxMain/TopBar/LabelPlayer

# --- Referencias contenido ---
@onready var label_content = $VBoxMain/HBoxContent/ContentArea/LabelContent

# --- Popup de edición ---
@onready var edit_popup = $EditPopup
@onready var label_slot_info = $EditPopup/VBoxPopup/LabelSlotInfo

# --- Estado ---
var editing_slot: int = -1  # cuál botón rápido estamos editando

# Configuración por defecto de los 5 botones rápidos
var quick_slots = [
    "👤  Perfil",
    "⚔  Arena",
    "🏪  Mercado",
    "🛡  Clan",
	"🏆  Ranking"
]

# ─────────────────────────────────────
func _ready():
    label_player.text = "  " + GameData.player_name
    _update_quick_buttons()
    edit_popup.visible = false

# Actualiza los textos de los 5 botones rápidos
func _update_quick_buttons():
    for i in range(5):
        btn_quick[i].text = quick_slots[i]

# ─────────────────────────────────────
# BOTONES RÁPIDOS (barra superior)
# ─────────────────────────────────────
func _on_quick_btn_pressed(slot_index: int):
    var section = quick_slots[slot_index]
    _navigate_to(section)

# ─────────────────────────────────────
# MENÚ LATERAL
# ─────────────────────────────────────
func _on_menu_pressed(section: String):
    _navigate_to(section)

# ─────────────────────────────────────
# NAVEGACIÓN CENTRAL
# ─────────────────────────────────────
func _navigate_to(section: String):
    # Por ahora muestra el nombre de la sección
    # Más adelante cada sección carga su propia sub-escena
    var clean = section.replace("👤  ", "").replace("🗺  ", "")\
        .replace("⚔  ", "").replace("🏪  ", "").replace("🛡  ", "")\
        .replace("⚒  ", "").replace("🏆  ", "").replace("🎒  ", "")\
        .replace("💪  ", "").replace("🍺  ", "")
    
    label_content.text = "[ " + clean + " ]\n\nEsta sección está en construcción.\nProximamente disponible."

# ─────────────────────────────────────
# BOTÓN EDITAR ACCESOS RÁPIDOS
# ─────────────────────────────────────
func _on_btn_edit_pressed():
    # Preguntamos qué slot quiere editar
    # Por ahora editamos el slot 1, después hacemos selector visual
    editing_slot = 0
    _open_edit_popup(0)

func _open_edit_popup(slot: int):
    editing_slot = slot
    label_slot_info.text = "Editando: Botón " + str(slot + 1) + " (actualmente: " + quick_slots[slot] + ")"
    edit_popup.visible = true

# ─────────────────────────────────────
# SELECCIÓN EN EL POPUP
# ─────────────────────────────────────
func _on_option_selected(option: String):
    if editing_slot >= 0 and editing_slot < 5:
        quick_slots[editing_slot] = option
        _update_quick_buttons()
        # Avanzamos al siguiente slot automáticamente
        editing_slot += 1
        if editing_slot < 5:
            _open_edit_popup(editing_slot)
        else:
            edit_popup.visible = false
            editing_slot = -1

func _on_popup_cerrar():
    edit_popup.visible = false
    editing_slot = -1
