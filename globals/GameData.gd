# GameData.gd
# Pizarra global que existe durante toda la sesión del juego.

extends Node

# --- Datos del jugador actual ---
var player_name: String = ""
var player_id: String = ""
var player_email: String = ""
var is_logged_in: bool = false

# --- Configuración de Firebase ---
const FIREBASE_API_KEY = "AIzaSyAhAVBHtt71Emoa_4ohUa06Y_hQvEJWllM"
const FIREBASE_PROJECT_ID = "atepaia-2v"
const FIREBASE_AUTH_URL = "https://identitytoolkit.googleapis.com/v1/accounts:"
const FIRESTORE_URL = "https://firestore.googleapis.com/v1/projects/atepaia-2v/databases/(default)/documents/"
