extends Node

# --- Datos del jugador ---
var player_name: String = ""
var player_id: String = ""
var player_email: String = ""
var player_gender: String = ""
var player_class: String = ""
var player_portrait: String = ""
var is_logged_in: bool = false
var id_token: String = ""

# --- Stats base ---
var level: int = 1
var hp: int = 120
var hp_max: int = 120
var xp: int = 0
var xp_next: int = 80
var gold_hand: int = 100
var gold_vault: int = 0
var bronze_hand: int = 500

# --- Atributos (arrancan en 2) ---
var attr_strength: int = 2
var attr_agility: int = 2
var attr_dexterity: int = 2
var attr_constitution: int = 2
var attr_intelligence: int = 2
var attr_charisma: int = 2

# --- Stats de combate ---
var crit_chance: float = 0.0
var crit_damage: float = 1.5
var dodge_chance: float = 0.0
var block_chance: float = 0.0
var block_reduction: float = 0.0
var double_hit_chance: float = 0.0
const MAX_CHANCE: float = 0.5

# --- Bonos de clase ---
var bonus_exp: float = 0.0
var bonus_gold: float = 0.0

# --- Firebase ---
const FIREBASE_API_KEY = "AIzaSyAhAVBHtt71Emoa_4ohUa06Y_hQvEJWllM"
const FIREBASE_PROJECT_ID = "atepaia-2v"
const FIREBASE_AUTH_URL = "https://identitytoolkit.googleapis.com/v1/accounts:"
const FIRESTORE_URL = "https://firestore.googleapis.com/v1/projects/atepaia-2v/databases/(default)/documents/"

# --- Equipo actual ---
var equipped_weapon:  Dictionary = {}
var equipped_shield:  Dictionary = {}
var equipped_chest:   Dictionary = {}
var equipped_helmet:  Dictionary = {}
var equipped_boots:   Dictionary = {}
var equipped_gloves:  Dictionary = {}
var equipped_neck:    Dictionary = {}
var equipped_ring_l:  Dictionary = {}
var equipped_ring_r:  Dictionary = {}
var equipped_cape:    Dictionary = {}

# --- Stats derivados del equipo ---
var damage_min: int = 0
var damage_max: int = 0
var armor:      int = 0

# --- Combate ---
var enemigo_actual: Dictionary = {}
var ultimo_drop:    Dictionary = {}

# ─────────────────────────────────────
# FÓRMULAS
# ─────────────────────────────────────

# XP para subir al siguiente nivel: floor(80 * nivel^2.6)
func xp_para_nivel(nivel: int) -> int:
    return int(floor(80.0 * pow(float(nivel), 2.6)))

# Costo entrenamiento: max(2, floor(valor^2.8 * 0.16))
# Nivel 2: 2  | Nivel 10: 100  | Nivel 100: 63.697  | Nivel 500: 5.7M
func costo_entrenamiento(valor_actual: int) -> int:
    return max(2, int(floor(pow(float(valor_actual), 2.8) * 0.16)))

func recalcular_hp_max() -> void:
    hp_max = 100 + attr_constitution * 10
    hp = min(hp, hp_max)
