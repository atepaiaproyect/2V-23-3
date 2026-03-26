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
var hp: int = 100
var hp_max: int = 100
var xp: int = 0
var xp_next: int = 100
var gold_hand: int = 100
var gold_vault: int = 0
var bronze_hand: int = 0

# --- Atributos ---
var attr_strength: int = 10
var attr_agility: int = 10
var attr_dexterity: int = 10
var attr_constitution: int = 10
var attr_intelligence: int = 10
var attr_charisma: int = 10

# --- Stats de combate (derivados de ítems — por ahora base) ---
var crit_chance: float = 0.0
var crit_damage: float = 1.5
var dodge_chance: float = 0.0
var block_chance: float = 0.0
var block_reduction: float = 0.0
var double_hit_chance: float = 0.0
const MAX_CHANCE: float = 0.5  # 50% cap para todas las probabilidades

# --- Bonos de clase ---
var bonus_exp: float = 0.0
var bonus_gold: float = 0.0

# --- Firebase ---
const FIREBASE_API_KEY = "AIzaSyAhAVBHtt71Emoa_4ohUa06Y_hQvEJWllM"
const FIREBASE_PROJECT_ID = "atepaia-2v"
const FIREBASE_AUTH_URL = "https://identitytoolkit.googleapis.com/v1/accounts:"
const FIRESTORE_URL = "https://firestore.googleapis.com/v1/projects/atepaia-2v/databases/(default)/documents/"

# --- Equipo actual (se actualizan al equipar/desequipar ítems) ---
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
var damage_min: int = 0   # bonus de arma al daño mínimo
var damage_max: int = 0   # bonus de arma al daño máximo
var armor:      int = 0   # armadura total del equipo

# --- Combate ---
var enemigo_actual: Dictionary = {}
var ultimo_drop:    Dictionary = {}
