/**
 * ============================================
 * SYSTÈME DE DELOAD ÉQUILIBRÉ - CONFIGURATION
 * ============================================
 * 
 * Configuration pour une semaine de deload après 6 semaines (2 cycles de 3 semaines)
 * Format: 4 séances Mix A+B
 * Volume: 50-60% du volume habituel
 * Intensité: 60-70% des charges habituelles
 */

const deloadConfig = {
    // Paramètres généraux
    enabled: false, // Activé/désactivé par l'utilisateur
    currentWeek: 0, // 0 = pas en deload, 1-7 = semaine de deload
    volumeReduction: 0.55, // 55% du volume normal (moyenne 50-60%)
    intensityReduction: 0.65, // 65% de l'intensité normale (moyenne 60-70%)
    
    // Déclenchement automatique
    triggerAfterCycles: 2, // Suggérer deload après 2 cycles (6 semaines)
    autoSuggest: true, // Afficher automatiquement la suggestion
    
    // Workouts deload - 4 séances Mix A+B
    workouts: {
        deload_push: [
            { name: "Développé couché barre", sets: 2, reps: "8", source: "A", priority: "compound" },
            { name: "Développé incliné haltères", sets: 2, reps: "10", source: "A", priority: "compound" },
            { name: "Pec fly poulie", sets: 2, reps: "12", source: "B", priority: "isolation" },
            { name: "Élévations latérales machine", sets: 2, reps: "12", source: "B", priority: "isolation" },
            { name: "Extensions poulie", sets: 2, reps: "12", source: "B", priority: "isolation" }
        ],
        deload_pull: [
            { name: "Rowing barre", sets: 2, reps: "8", source: "A", priority: "compound" },
            { name: "Tirage vertical supination", sets: 2, reps: "10", source: "A", priority: "compound" },
            { name: "Face pull poulie", sets: 2, reps: "15", source: "B", priority: "isolation" },
            { name: "Tirage horizontal poulie", sets: 2, reps: "12", source: "B", priority: "isolation" },
            { name: "Machine curl", sets: 2, reps: "12", source: "B", priority: "isolation" }
        ],
        deload_legs: [
            { name: "Hack squat machine", sets: 2, reps: "10", source: "B", priority: "compound" },
            { name: "RDL", sets: 2, reps: "10", source: "A", priority: "compound" },
            { name: "Leg curl", sets: 2, reps: "12", source: "B", priority: "isolation" },
            { name: "Leg extension", sets: 2, reps: "12", source: "B", priority: "isolation" },
            { name: "Mollets à la presse", sets: 2, reps: "15", source: "A", priority: "isolation" }
        ],
        deload_fullbody: [
            { name: "Développé militaire haltères", sets: 2, reps: "10", source: "A", priority: "compound" },
            { name: "Rowing haltère unilatéral", sets: 2, reps: "10", source: "A", priority: "compound" },
            { name: "Fentes marchées", sets: 2, reps: "12", source: "A", priority: "compound" },
            { name: "Pec fly", sets: 2, reps: "12", source: "A", priority: "isolation" },
            { name: "Machine curl", sets: 2, reps: "12", source: "B", priority: "isolation" }
        ]
    },
    
    // Planning hebdomadaire suggéré
    weeklySchedule: [
        { day: "Lundi", workout: "deload_push", duration: "40 min" },
        { day: "Mardi", workout: "deload_pull", duration: "40 min" },
        { day: "Mercredi", rest: true },
        { day: "Jeudi", workout: "deload_legs", duration: "40 min" },
        { day: "Vendredi", rest: true },
        { day: "Samedi", workout: "deload_fullbody", duration: "30 min" },
        { day: "Dimanche", rest: true }
    ],
    
    // Recommandations techniques
    guidelines: {
        repsInReserve: "3-4", // RIR (Reps In Reserve)
        tempo: "3-1-2-1", // Tempo contrôlé (excentrique-pause-concentrique-pause)
        restBetweenSets: "90-120s", // Repos entre séries
        focusAreas: [
            "Technique et contrôle du mouvement",
            "Connexion esprit-muscle",
            "Mobilité et amplitude complète",
            "Récupération active"
        ],
        avoidances: [
            "Aller à l'échec musculaire",
            "Augmenter les charges",
            "Ajouter des exercices",
            "Prolonger les séances"
        ]
    },
    
    // Indicateurs de succès du deload
    successMetrics: {
        physical: [
            "Amélioration qualité sommeil",
            "Réduction douleurs articulaires",
            "Énergie retrouvée",
            "Moins de courbatures prolongées"
        ],
        performance: [
            "Augmentation force semaine 8",
            "Plus de reps avec mêmes charges",
            "Meilleure technique d'exécution",
            "Récupération inter-séries améliorée"
        ],
        mental: [
            "Motivation renouvelée",
            "Plaisir retrouvé à l'entraînement",
            "Moins de fatigue mentale",
            "Envie de retour salle"
        ]
    }
};

/**
 * Calcule les charges recommandées pour un exercice en deload
 * @param {string} exerciseName - Nom de l'exercice
 * @param {object} workoutData - Données historiques des entraînements
 * @returns {number} - Charge recommandée en kg
 */
function calculateDeloadWeight(exerciseName, workoutData) {
    // Chercher les dernières performances de cet exercice
    const recentWeights = [];
    
    Object.keys(workoutData).forEach(key => {
        const session = workoutData[key];
        session.forEach((exercise, idx) => {
            // Trouver l'exercice correspondant dans les workouts templates
            const template = findExerciseTemplate(key, idx);
            if (template && template.name === exerciseName && exercise.weight) {
                recentWeights.push(parseFloat(exercise.weight));
            }
        });
    });
    
    if (recentWeights.length === 0) return 0;
    
    // Prendre la moyenne des 3 dernières charges
    const recent = recentWeights.slice(-3);
    const avgWeight = recent.reduce((sum, w) => sum + w, 0) / recent.length;
    
    // Appliquer la réduction d'intensité (65%)
    return Math.round(avgWeight * deloadConfig.intensityReduction * 2) / 2; // Arrondi au 0.5 kg
}

/**
 * Fonction helper pour trouver le template d'exercice
 */
function findExerciseTemplate(workoutKey, exerciseIdx) {
    const parts = workoutKey.split('-');
    if (parts.length < 6) return null;
    
    const program = parts[4];
    const type = parts.slice(5).join('-');
    
    if (!workouts[program] || !workouts[program][type]) return null;
    
    return workouts[program][type][exerciseIdx];
}

/**
 * Vérifie si un deload doit être suggéré
 * @param {string} program - Programme (A ou B)
 * @returns {boolean} - True si deload recommandé
 */
function shouldSuggestDeload(program) {
    if (!deloadConfig.autoSuggest) return false;
    
    const cycles = detectCycles(program);
    if (cycles.length < deloadConfig.triggerAfterCycles) return false;
    
    // Vérifier si on vient de terminer le 2ème cycle
    const lastCycle = cycles[cycles.length - 1];
    const now = new Date();
    
    // Si le dernier cycle est complété et date de moins d'une semaine
    if (lastCycle.completed) {
        const daysSinceEnd = Math.floor((now - lastCycle.endDate) / (1000 * 60 * 60 * 24));
        return daysSinceEnd <= 7;
    }
    
    return false;
}

/**
 * Active le mode deload
 */
function enableDeloadMode() {
    deloadConfig.enabled = true;
    deloadConfig.currentWeek = 1;
    
    // Sauvegarder en localStorage ET synchroniser via API
    localStorage.setItem('deloadConfig', JSON.stringify(deloadConfig));
    
    // Synchroniser avec le serveur via l'API existante
    saveDeloadConfig();
    
    // Afficher la notification
    showToast('🔄 Mode DELOAD activé - Bon courage pour cette semaine de récupération active ! 💪');
    
    // Mettre à jour l'interface
    updateDeloadUI();
}

/**
 * Désactive le mode deload
 */
function disableDeloadMode() {
    deloadConfig.enabled = false;
    deloadConfig.currentWeek = 0;
    
    // Sauvegarder en localStorage ET synchroniser via API
    localStorage.setItem('deloadConfig', JSON.stringify(deloadConfig));
    
    // Synchroniser avec le serveur via l'API existante
    saveDeloadConfig();
    
    showToast('✅ Mode DELOAD terminé - Prêt à repartir fort ! 🚀');
    
    updateDeloadUI();
}

/**
 * Charge la configuration depuis localStorage et serveur
 */
function loadDeloadConfig() {
    // Charger depuis localStorage (fallback)
    const saved = localStorage.getItem('deloadConfig');
    if (saved) {
        const savedConfig = JSON.parse(saved);
        Object.assign(deloadConfig, savedConfig);
    }
    
    // Charger depuis le serveur via l'API existante (prioritaire)
    loadDeloadConfigFromServer();
}

/**
 * Sauvegarde la config deload via l'API existante
 */
async function saveDeloadConfig() {
    try {
        // Récupérer les données complètes existantes
        let fullData = JSON.parse(localStorage.getItem('workoutData') || '{}');
        
        // Ajouter la config deload
        fullData._deloadConfig = deloadConfig;
        
        // Utiliser la fonction de sync existante si disponible
        if (typeof syncToServer === 'function') {
            await syncToServer(fullData);
        } else {
            // Fallback : sauvegarder directement
            localStorage.setItem('workoutData', JSON.stringify(fullData));
        }
    } catch (error) {
        console.error('Erreur sauvegarde config deload:', error);
    }
}

/**
 * Charge la config deload depuis le serveur via l'API existante
 */
async function loadDeloadConfigFromServer() {
    try {
        // Utiliser la fonction de chargement existante si disponible
        if (typeof loadFromServer === 'function') {
            await loadFromServer();
        }
        
        // Récupérer les données chargées
        const fullData = JSON.parse(localStorage.getItem('workoutData') || '{}');
        
        // Extraire la config deload si elle existe
        if (fullData._deloadConfig) {
            Object.assign(deloadConfig, fullData._deloadConfig);
        }
    } catch (error) {
        console.error('Erreur chargement config deload:', error);
    }
}

/**
 * Met à jour l'interface utilisateur pour le deload
 */
function updateDeloadUI() {
    // Mise à jour des boutons de workout
    const workoutButtons = document.querySelectorAll('.workout-btn');
    
    if (deloadConfig.enabled) {
        // Masquer les boutons normaux, afficher les boutons deload
        workoutButtons.forEach(btn => {
            if (!btn.classList.contains('deload-workout-btn')) {
                btn.style.display = 'none';
            }
        });
        
        // Afficher la bannière deload
        showDeloadBanner();
    } else {
        // Restaurer l'affichage normal
        workoutButtons.forEach(btn => {
            if (!btn.classList.contains('deload-workout-btn')) {
                btn.style.display = '';
            }
        });
        
        hideDeloadBanner();
    }
}

// Charger la config au démarrage
document.addEventListener('DOMContentLoaded', function() {
    loadDeloadConfig();
    
    // Vérifier si deload doit être suggéré
    if (shouldSuggestDeload('A') || shouldSuggestDeload('B')) {
        showDeloadSuggestion();
    }
});

function showDeloadBanner() {
    var banner = document.getElementById('deloadBanner');
    if (banner) banner.style.display = 'block';
}

function hideDeloadBanner() {
    var banner = document.getElementById('deloadBanner');
    if (banner) banner.style.display = 'none';
}

function showDeloadSuggestion() {
    var popup = document.getElementById('deloadSuggestion');
    if (popup) popup.style.display = 'block';
}

function dismissDeloadSuggestion() {
    var popup = document.getElementById('deloadSuggestion');
    if (popup) popup.style.display = 'none';
    var d = new Date();
    d.setDate(d.getDate() + 7);
    localStorage.setItem('deloadDismissedUntil', d.toISOString());
}

/**
 * Affiche la bannière deload
 */
function showDeloadBanner() {
    var banner = document.getElementById('deloadBanner');
    if (banner) {
        banner.style.display = 'block';
    }
}

/**
 * Cache la bannière deload
 */
function hideDeloadBanner() {
    var banner = document.getElementById('deloadBanner');
    if (banner) {
        banner.style.display = 'none';
    }
}

/**
 * Affiche la popup de suggestion
 */
function showDeloadSuggestion() {
    var popup = document.getElementById('deloadSuggestion');
    if (popup) {
        popup.style.display = 'block';
    }
}

/**
 * Cache la popup de suggestion (bouton "Plus tard")
 */
function dismissDeloadSuggestion() {
    var popup = document.getElementById('deloadSuggestion');
    if (popup) {
        popup.style.display = 'none';
    }
    
    // Ne plus afficher pendant 7 jours
    var d = new Date();
    d.setDate(d.getDate() + 7);
    localStorage.setItem('deloadDismissedUntil', d.toISOString());
}
