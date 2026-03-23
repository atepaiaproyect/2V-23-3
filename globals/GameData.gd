extends Node

# --- Datos del jugador ---
var player_name: String = ""
var player_id: String = ""
var player_email: String = ""
var is_logged_in: bool = false

# --- Firebase ---
const FIREBASE_API_KEY = "AIzaSyAhAVBHtt71Emoa_4ohUa06Y_hQvEJWllM"
const FIREBASE_PROJECT_ID = "atepaia-2v"
const FIREBASE_AUTH_URL = "https://identitytoolkit.googleapis.com/v1/accounts:"
const FIRESTORE_URL = "https://firestore.googleapis.com/v1/projects/atepaia-2v/databases/(default)/documents/"

# --- Datos del personaje ---
var player_gender: String = ""
var player_class: String = ""
var bonus_exp: float = 0.0
var bonus_gold: float = 0.0
var player_portrait: String = ""
