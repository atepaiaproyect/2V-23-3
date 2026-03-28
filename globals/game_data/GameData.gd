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

# --- Stats de combate (se recalculan con recalcular_stats) ---
var crit_chance: float = 0.05       # base 5%
var crit_damage: float = 1.5        # base +50% daño
var dodge_chance: float = 0.05      # base 5%
var block_chance: float = 0.05      # base 5%
var block_reduction: float = 1.0    # bloqueo = 0 daño
var double_hit_chance: float = 0.05 # base 5%
var resist_mortal: float = 0.0      # % de sobrevivir con 1 HP (fuerza/11)
var hp_regen_per_min: int = 1       # regeneracion base 1/min
const MAX_CHANCE: float = 0.75      # cap 75%

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

# --- Ranking ---
var pvp_points:   int = 0
var gold_stolen:  int = 0
var xp_total:     int = 0
var craft_points: int = 0
var pvp_kills:    int = 0


# FÓRMULAS

func xp_para_nivel(nivel: int) -> int:
    return int(floor(80.0 * pow(float(nivel), 2.6)))

func costo_entrenamiento(valor_actual: int) -> int:
    return max(2, int(floor(pow(float(valor_actual), 2.8) * 0.16)))

# Recalcula TODOS los stats derivados de atributos + equipo
func recalcular_stats() -> void:
    
    # HP max: 100 + CON*10 + (CONdiv11)*5
    var hp_bonus_con = (float(attr_constitution) / 11) * 5
    hp_max = 100 + attr_constitution * 10 + hp_bonus_con
    hp = min(hp, hp_max)
    # Regen: base 1 + 1 por cada 10 CON
    hp_regen_per_min = 1 + int(attr_constitution) / 10

    
    # Daño bonus del arma + bonus por cada 10 puntos de fuerza
    var fuerza_bonus = int(attr_strength) / 10
    damage_min = equipped_weapon.get("ataque_min", 0) + fuerza_bonus
    damage_max = equipped_weapon.get("ataque_max", 0) + fuerza_bonus
    # Resistir mortal: +1% por cada 11 puntos de fuerza
    resist_mortal = min((float(attr_strength) / 11) / 100.0, MAX_CHANCE)

    
    # Esquiva: base 5% + 1% por cada 10 puntos
    dodge_chance = min(0.05 + (float(attr_agility) / 10) / 100.0, MAX_CHANCE)
    # Daño crítico: base 1.5 (+50%) + 1% por cada 11 puntos
    crit_damage = 1.5 + (float(attr_agility) / 11) / 100.0

    
    # Doble golpe: base 5% + 1% por cada 15 puntos
    double_hit_chance = min(0.05 + (float(attr_dexterity) / 15) / 100.0, MAX_CHANCE)
    # Golpe crítico: base 5% + 1% por cada 15 puntos
    crit_chance = min(0.05 + (float(attr_dexterity) / 15) / 100.0, MAX_CHANCE)

    
    # Bloqueo: base 5% + 1% por cada 10 puntos (bloqueo = 0 daño)
    block_chance = min(0.05 + (float(attr_charisma) / 10) / 100.0, MAX_CHANCE)
    block_reduction = 1.0  # siempre 0 daño al bloquear

    
    armor = equipped_chest.get("defensa", 0) + equipped_shield.get("defensa", 0)

# Alias para compatibilidad
func recalcular_hp_max() -> void:
    recalcular_stats()

# Reducción de precio por inteligencia: -2% por cada 10 puntos, máx 80%
func reduccion_precio() -> float:
    return min((float(attr_intelligence) / 10) * 0.02, 0.80)

func precio_con_descuento(precio_base: int) -> int:
    return max(1, int(precio_base * (1.0 - reduccion_precio())))
