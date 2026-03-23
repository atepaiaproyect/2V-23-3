extends Control

# --- Referencias ---
@onready var name_input = $VBoxContainer/LineEdit
@onready var error_label = $VBoxContainer/LabelError
@onready var desc_label = $VBoxContainer/LabelDesc
@onready var btn_noble = $VBoxContainer/HBoxContainer2/BtnNoble
@onready var btn_mercenary = $VBoxContainer/HBoxContainer2/BtnMercenario
@onready var portrait_male = $VBoxContainer/HBoxContainer/VBoxMale/HBoxCarouselMale/TextureButtonMale
@onready var portrait_female = $VBoxContainer/HBoxContainer/VBoxFemale/HBoxCarouselFemale/TextureButtonFemale

# --- Estado del carrusel ---
var male_index: int = 1
var female_index: int = 1
var male_max: int = 0
var female_max: int = 0

# --- Estado de selección ---
var selected_gender: String = ""
var selected_class: String = ""
var selected_portrait: String = ""

const DESC_NOBLE = "NOBLE: +5% experiencia, -5% oro.\nPara quienes prefieren crecer en poder."
const DESC_MERCENARIO = "MERCENARIO: +5% oro, -5% experiencia.\nPara quienes viven de la batalla."

# ─────────────────────────────────────
func _ready():
    # Contamos cuántas imágenes hay de cada género
    male_max = _count_portraits("male")
    female_max = _count_portraits("female")
    
    # Cargamos la primera imagen de cada carrusel
    _update_portrait("male")
    _update_portrait("female")

# Cuenta cuántos retratos existen para un género
func _count_portraits(gender: String) -> int:
    var count = 0
    for i in range(1, 50):  # máximo 50 por seguridad
        var path = "res://assets/portraits/portrait_" + gender + "_" + str(i) + ".png"
        if ResourceLoader.exists(path):
            count += 1
        else:
            break
    return count

# Actualiza la imagen mostrada en el carrusel
func _update_portrait(gender: String):
    var index = male_index if gender == "male" else female_index
    var path = "res://assets/portraits/portrait_" + gender + "_" + str(index) + ".png"
    var texture = load(path)
    if gender == "male":
        portrait_male.texture = texture
    else:
        portrait_female.texture = texture

# ─────────────────────────────────────
# CARRUSEL HOMBRE
# ─────────────────────────────────────
func _on_btn_prev_male_pressed():
    male_index -= 1
    if male_index < 1:
        male_index = male_max
    _update_portrait("male")

func _on_btn_next_male_pressed():
    male_index += 1
    if male_index > male_max:
        male_index = 1
    _update_portrait("male")

# ─────────────────────────────────────
# CARRUSEL MUJER
# ─────────────────────────────────────
func _on_btn_prev_female_pressed():
    female_index -= 1
    if female_index < 1:
        female_index = female_max
    _update_portrait("female")

func _on_btn_next_female_pressed():
    female_index += 1
    if female_index > female_max:
        female_index = 1
    _update_portrait("female")

# ─────────────────────────────────────
# SELECCIÓN DE GÉNERO (click en retrato)
# ─────────────────────────────────────
func _on_btn_select_male_pressed():
    selected_gender = "male"
    selected_portrait = "portrait_male_" + str(male_index)
    portrait_male.modulate = Color(1.4, 1.2, 0.6, 1)
    portrait_female.modulate = Color(0.3, 0.3, 0.3, 1)

func _on_btn_select_female_pressed():
    selected_gender = "female"
    selected_portrait = "portrait_female_" + str(female_index)
    portrait_male.modulate = Color(0.3, 0.3, 0.3, 1)
    portrait_female.modulate = Color(1.4, 1.2, 0.6, 1)

# ─────────────────────────────────────
# SELECCIÓN DE CLASE
# ─────────────────────────────────────
func _on_btn_noble_pressed():
    selected_class = "noble"
    desc_label.text = DESC_NOBLE
    btn_noble.modulate = Color(1, 0.85, 0, 1)
    btn_mercenary.modulate = Color(1, 1, 1, 1)

func _on_btn_mercenario_pressed():
    selected_class = "mercenario"
    desc_label.text = DESC_MERCENARIO
    btn_mercenary.modulate = Color(1, 0.4, 0.1, 1)
    btn_noble.modulate = Color(1, 1, 1, 1)

# ─────────────────────────────────────
# BOTÓN COMENZAR
# ─────────────────────────────────────
func _on_btn_comenzar_pressed():
    var player_name = name_input.text.strip_edges()

    if player_name == "":
        error_label.text = "Escribí un nombre para tu personaje."
        return
    if player_name.length() < 3:
        error_label.text = "El nombre debe tener al menos 3 letras."
        return
    if selected_gender == "":
        error_label.text = "Hacé click en un retrato para elegir tu género."
        return
    if selected_class == "":
        error_label.text = "Elegí entre Noble o Mercenario."
        return

    GameData.player_name = player_name
    GameData.player_gender = selected_gender
    GameData.player_class = selected_class
    GameData.player_portrait = selected_portrait

    if selected_class == "noble":
        GameData.bonus_exp = 0.05
        GameData.bonus_gold = -0.05
    else:
        GameData.bonus_exp = -0.05
        GameData.bonus_gold = 0.05

    get_tree().change_scene_to_file("res://scenes/intro/Intro.tscn")
