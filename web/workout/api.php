<?php
/**
 * API de synchronisation pour Workout Tracker
 * Permet de sauvegarder et récupérer les données d'entraînement
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Gestion des preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Configuration
define('DATA_DIR', __DIR__ . '/data');
define('DATA_FILE', DATA_DIR . '/workout-data.json');
define('API_KEY', 'freddebian79claudius'); // CHANGE CE MOT DE PASSE !

// Vérification de l'authentification
function checkAuth() {
    $headers = getallheaders();
    
    // Debug: afficher tous les headers reçus
    error_log("Headers reçus: " . print_r($headers, true));
    
    // Essayer plusieurs variantes de casse
    $authHeader = $headers['Authorization'] ?? 
                  $headers['authorization'] ?? 
                  $_SERVER['HTTP_AUTHORIZATION'] ?? 
                  '';
    
    error_log("Auth header trouvé: " . $authHeader);
    error_log("API_KEY attendue: Bearer " . API_KEY);
    
    if ($authHeader !== 'Bearer ' . API_KEY) {
        http_response_code(401);
        error_log("ÉCHEC AUTH - Reçu: '$authHeader' vs Attendu: 'Bearer " . API_KEY . "'");
        echo json_encode(['error' => 'Non autorisé']);
        exit();
    }
}

// Initialisation du dossier data
if (!file_exists(DATA_DIR)) {
    mkdir(DATA_DIR, 0755, true);
}

if (!file_exists(DATA_FILE)) {
    file_put_contents(DATA_FILE, json_encode([]));
}

// Router simple
$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

checkAuth();

switch ($method) {
    case 'GET':
        // Récupérer les données
        if ($action === 'load') {
            $data = file_get_contents(DATA_FILE);
            echo $data;
        } else {
            http_response_code(400);
            echo json_encode(['error' => 'Action non reconnue']);
        }
        break;
        
    case 'POST':
        // Sauvegarder les données
        if ($action === 'save') {
            $input = file_get_contents('php://input');
            $data = json_decode($input, true);
            
            if (json_last_error() === JSON_ERROR_NONE) {
                // Backup de la version précédente
                if (file_exists(DATA_FILE)) {
                    $backup = DATA_FILE . '.backup.' . date('Y-m-d-H-i-s');
                    copy(DATA_FILE, $backup);
                    
                    // Garder seulement les 5 derniers backups
                    $backups = glob(DATA_DIR . '/workout-data.json.backup.*');
                    if (count($backups) > 5) {
                        arsort($backups);
                        $toDelete = array_slice($backups, 5);
                        foreach ($toDelete as $file) {
                            unlink($file);
                        }
                    }
                }
                
                // Sauvegarder les nouvelles données
                file_put_contents(DATA_FILE, json_encode($data, JSON_PRETTY_PRINT));
                echo json_encode([
                    'success' => true,
                    'timestamp' => time()
                ]);
            } else {
                http_response_code(400);
                echo json_encode(['error' => 'JSON invalide']);
            }
        } else {
            http_response_code(400);
            echo json_encode(['error' => 'Action non reconnue']);
        }
        break;
        
    default:
        http_response_code(405);
        echo json_encode(['error' => 'Méthode non autorisée']);
        break;
}

