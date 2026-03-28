extends Control

# --- Referencias ---
@onready var name_input = $VBoxContainer/LineEdit
@onready var error_label = $VBoxContainer/LabelError
@onready var desc_label = $VBoxContainer/LabelDesc
@onready var btn_noble = $VBoxContainer/HBoxContainer2/BtnNoble
@onready var btn_mercenary = $VBoxContainer/HBoxContainer2/BtnMercenario
@onready var portrait_male = $VBoxContainer/HBoxContainer/VBoxMale/HBoxCarouselMale/TextureButtonMale
@onready var portrait_female = $VBoxContainer/HBoxContainer/VBoxFemale/HBoxCarouselFemale/TextureButtonFemale

# HTTPRequest para guardar en Firestore
@onready var http_save = $HTTPRequest

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
    male_max = _count_portraits("male")
    female_max = _count_portraits("female")
    _update_portrait("male")
    _update_portrait("female")
    http_save.request_completed.connect(_on_save_completed)

func _count_portraits(gender: String) -> int:
    var count = 0
    for i in range(1, 50):
        var path = "res://assets/portraits/players/portrait_" + gender + "_" + str(i) + ".png"
        if ResourceLoader.exists(path):
            count += 1
        else:
            break
    return count

func _update_portrait(gender: String):
    var index = male_index if gender == "male" else female_index
    var path = "res://assets/portraits/players/portrait_" + gender + "_" + str(index) + ".png"
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
# SELECCIÓN DE GÉNERO
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
# BOTÓN COMENZAR → guarda en Firestore
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

    # Guardamos en GameData
    GameData.player_name    = player_name
    GameData.player_gender  = selected_gender
    GameData.player_class   = selected_class
    GameData.player_portrait = selected_portrait

    if selected_class == "noble":
        GameData.bonus_exp  = 0.05
        GameData.bonus_gold = -0.05
    else:
        GameData.bonus_exp  = -0.05
        GameData.bonus_gold = 0.05

    error_label.text = "Guardando personaje..."
    _save_to_firestore(player_name)

# ─────────────────────────────────────
# GUARDAR EN FIRESTORE
# ─────────────────────────────────────
func _save_to_firestore(player_name: String):
    var url = GameData.FIRESTORE_URL + "players/" + GameData.player_id

    var body = JSON.stringify({
        "fields": {
            "username":         {"stringValue": player_name},
            "gender":           {"stringValue": selected_gender},
            "class":            {"stringValue": selected_class},
            "portrait":         {"stringValue": selected_portrait},
            "level":            {"integerValue": "1"},
            "xp":               {"integerValue": "0"},
            "xp_next":          {"integerValue": "80"},
            "hp":               {"integerValue": "120"},
            "hp_max":           {"integerValue": "120"},
            "gold_hand":        {"integerValue": "100"},
            "gold_vault":       {"integerValue": "0"},
            "bronze_hand":      {"integerValue": "500"},
            "attr_strength":    {"integerValue": "2"},
            "attr_agility":     {"integerValue": "2"},
            "attr_dexterity":   {"integerValue": "2"},
            "attr_constitution":{"integerValue": "2"},
            "attr_intelligence":{"integerValue": "2"},
            "attr_charisma":    {"integerValue": "2"},
            "bonus_exp":        {"doubleValue": GameData.bonus_exp},
            "bonus_gold":       {"doubleValue": GameData.bonus_gold},
            "created_at":       {"stringValue": Time.get_datetime_string_from_system()},
            # Sin equipo inicial — los ítems arrancan en el inventario
            "eq_weapon":        {"stringValue": ""},
            "eq_shield":        {"stringValue": ""},
            "eq_chest":         {"stringValue": ""},
            "eq_helmet":        {"stringValue": ""},
            "eq_boots":         {"stringValue": ""},
            "eq_gloves":        {"stringValue": ""},
            "eq_neck":          {"stringValue": ""},
            "eq_ring_l":        {"stringValue": ""},
            "eq_ring_r":        {"stringValue": ""},
            "eq_cape":          {"stringValue": ""},
            # Ranking — todos empiezan en 0
            "pvp_points":       {"integerValue": "0"},
            "gold_stolen":      {"integerValue": "0"},
            "xp_total":         {"integerValue": "0"},
            "craft_points":     {"integerValue": "0"},
            "pvp_kills":        {"integerValue": "0"},
        }
    })

    # Usamos el idToken guardado en GameData
    var headers = [
        "Content-Type: application/json",
        "Authorization: Bearer " + GameData.id_token
    ]

    # PATCH crea o sobreescribe el documento
    http_save.request(url, headers, HTTPClient.METHOD_PATCH, body)

func _on_save_completed(_result, response_code, _headers, _body):
    if response_code == 200:
        # Guardado exitoso → ir a la intro
        get_tree().change_scene_to_file("res://scenes/intro/Intro.tscn")
    else:
        error_label.text = "Error al guardar. Intentá de nuevo."
