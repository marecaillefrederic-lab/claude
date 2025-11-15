#!/usr/bin/env python3
"""
Fail2ban Statistics Generator
Génère des statistiques HTML à partir des logs fail2ban
"""

import subprocess
import json
import geoip2.database
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
from collections import defaultdict, Counter
import re
import os

# Configuration
GEOIP_DB = '/usr/share/GeoIP/GeoLite2-Country.mmdb'
OUTPUT_DIR = '/var/www/fail2ban-stats'
DATA_FILE = f'{OUTPUT_DIR}/data/stats.json'

def get_fail2ban_status():
    """Récupère le statut de tous les jails fail2ban"""
    try:
        result = subprocess.run(
            ['sudo', 'fail2ban-client', 'status'],
            capture_output=True,
            text=True,
            check=True
        )
        
        # Extraire la liste des jails
        jails = []
        for line in result.stdout.split('\n'):
            if 'Jail list:' in line:
                jails_str = line.split('Jail list:')[1].strip()
                jails = [j.strip() for j in jails_str.split(',')]
        
        return jails
    except Exception as e:
        print(f"Erreur récupération jails: {e}")
        return []

def get_jail_stats(jail_name):
    """Récupère les stats d'une jail spécifique"""
    try:
        result = subprocess.run(
            ['sudo', 'fail2ban-client', 'status', jail_name],
            capture_output=True,
            text=True,
            check=True
        )
        
        stats = {
            'currently_failed': 0,
            'total_failed': 0,
            'currently_banned': 0,
            'total_banned': 0,
            'banned_ips': []
        }
        
        for line in result.stdout.split('\n'):
            if 'Currently failed:' in line:
                stats['currently_failed'] = int(line.split(':')[1].strip())
            elif 'Total failed:' in line:
                stats['total_failed'] = int(line.split(':')[1].strip())
            elif 'Currently banned:' in line:
                stats['currently_banned'] = int(line.split(':')[1].strip())
            elif 'Total banned:' in line:
                stats['total_banned'] = int(line.split(':')[1].strip())
            elif 'Banned IP list:' in line:
                ips_str = line.split('Banned IP list:')[1].strip()
                if ips_str:
                    stats['banned_ips'] = ips_str.split()
        
        return stats
    except Exception as e:
        print(f"Erreur récupération stats {jail_name}: {e}")
        return None

def get_country_from_ip(ip, reader):
    """Récupère le code pays d'une IP"""
    try:
        response = reader.country(ip)
        return {
            'code': response.country.iso_code,
            'name': response.country.name
        }
    except:
        return {'code': 'XX', 'name': 'Unknown'}

def parse_fail2ban_logs():
    """Parse les logs fail2ban pour extraire l'historique"""
    bans_by_date = defaultdict(int)
    bans_by_hour = defaultdict(int)
    
    try:
        # Lire les logs fail2ban des 7 derniers jours
        result = subprocess.run(
            ['sudo', 'grep', 'Ban', '/var/log/fail2ban.log'],
            capture_output=True,
            text=True,
            check=False
        )
        
        if result.returncode != 0 or not result.stdout.strip():
            print("⚠️  Aucun ban trouvé dans les logs")
            return {}, {}
        
        # Pattern pour le format exact des logs fail2ban
        # Format: 2025-10-24 06:36:59,758 fail2ban.actions [135807]: NOTICE [sshd] Ban 186.13.24.118
        ban_pattern = re.compile(r'(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}),\d+.*NOTICE\s+\[.*\]\s+Ban\s+(\d+\.\d+\.\d+\.\d+)')
        
        ban_count = 0
        seven_days_ago = datetime.now() - timedelta(days=7)
        
        for line in result.stdout.split('\n'):
            match = ban_pattern.search(line)
            if match:
                date_str = match.group(1)
                ip = match.group(2)
                
                try:
                    # Parser la date
                    dt = datetime.strptime(date_str, "%Y-%m-%d %H:%M:%S")
                    
                    # Ne garder que les 7 derniers jours
                    if dt >= seven_days_ago:
                        # Stats par jour
                        date_key = dt.strftime('%Y-%m-%d')
                        bans_by_date[date_key] += 1
                        
                        # Stats par heure
                        hour_key = dt.strftime('%H:00')
                        bans_by_hour[hour_key] += 1
                        
                        ban_count += 1
                    
                except Exception as e:
                    continue
        
        print(f"📊 {len(bans_by_date)} jours avec des bans, {ban_count} bans totaux sur 7 jours")
        return dict(bans_by_date), dict(bans_by_hour)
    
    except Exception as e:
        print(f"❌ Erreur parsing logs: {e}")
        import traceback
        traceback.print_exc()
        return {}, {}

def generate_stats():
    """Génère les statistiques complètes"""
    print("🔍 Génération des statistiques fail2ban...")
    
    # Récupérer tous les jails
    jails = get_fail2ban_status()
    print(f"📊 Jails détectés: {', '.join(jails)}")
    
    # Stats globales
    all_banned_ips = []
    stats_by_jail = {}
    
    # Récupérer les stats de chaque jail
    for jail in jails:
        jail_stats = get_jail_stats(jail)
        if jail_stats:
            stats_by_jail[jail] = jail_stats
            all_banned_ips.extend(jail_stats['banned_ips'])
    
    # Géolocalisation
    print("🌍 Géolocalisation des IPs...")
    country_counter = Counter()
    ip_details = []
    
    try:
        with geoip2.database.Reader(GEOIP_DB) as reader:
            for ip in set(all_banned_ips):  # Unique IPs
                country = get_country_from_ip(ip, reader)
                country_counter[country['code']] += all_banned_ips.count(ip)
                ip_details.append({
                    'ip': ip,
                    'country_code': country['code'],
                    'country_name': country['name'],
                    'count': all_banned_ips.count(ip)
                })
    except Exception as e:
        print(f"❌ Erreur géolocalisation: {e}")
    
    # Parser les logs historiques
    print("📜 Analyse des logs...")
    bans_by_date, bans_by_hour = parse_fail2ban_logs()
    
    # Préparer les données pour Chart.js
    data = {
        'generated_at': datetime.now(ZoneInfo('Europe/Paris')).isoformat(),
        'summary': {
            'total_jails': len(jails),
            'total_banned': len(set(all_banned_ips)),
            'total_attempts': sum(s['total_failed'] for s in stats_by_jail.values()),
            'total_bans': sum(s['total_banned'] for s in stats_by_jail.values())
        },
        'jails': stats_by_jail,
        'countries': [
            {'code': code, 'count': count} 
            for code, count in country_counter.most_common(15)
        ],
        'recent_ips': sorted(ip_details, key=lambda x: x['count'], reverse=True)[:20],
        'bans_by_date': bans_by_date,
        'bans_by_hour': bans_by_hour
    }
    
    # Sauvegarder les données
    os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)
    with open(DATA_FILE, 'w') as f:
        json.dump(data, f, indent=2)
    
    print(f"✅ Statistiques sauvegardées dans {DATA_FILE}")
    return data

def generate_html(data):
    """Génère le fichier HTML avec les stats"""
    
    html = f"""<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fail2ban Statistics - leblais.net</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chartjs-plugin-datalabels@2.2.0/dist/chartjs-plugin-datalabels.min.js"></script>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
            color: #333;
        }}
        
        .container {{
            max-width: 1400px;
            margin: 0 auto;
        }}
        
        header {{
            background: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            margin-bottom: 30px;
            text-align: center;
        }}
        
        header h1 {{
            color: #667eea;
            font-size: 2.5em;
            margin-bottom: 10px;
        }}
        
        header .subtitle {{
            color: #666;
            font-size: 1.1em;
        }}
        
        header .updated {{
            color: #999;
            font-size: 0.9em;
            margin-top: 10px;
        }}
        
        .stats-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }}
        
        .stat-card {{
            background: white;
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            text-align: center;
            transition: transform 0.3s;
        }}
        
        .stat-card:hover {{
            transform: translateY(-5px);
        }}
        
        .stat-value {{
            font-size: 3em;
            font-weight: bold;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }}
        
        .stat-label {{
            color: #666;
            font-size: 1.1em;
            margin-top: 10px;
        }}
        
        .charts-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(500px, 1fr));
            gap: 30px;
            margin-bottom: 30px;
        }}
        
        .chart-card {{
            background: white;
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }}
        
        .chart-card h2 {{
            color: #667eea;
            margin-bottom: 20px;
            font-size: 1.5em;
        }}
        
        .chart-container {{
            position: relative;
            height: 300px;
        }}
        
        .table-card {{
            background: white;
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }}
        
        .table-card h2 {{
            color: #667eea;
            margin-bottom: 20px;
            font-size: 1.5em;
        }}
        
        table {{
            width: 100%;
            border-collapse: collapse;
        }}
        
        th, td {{
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #eee;
        }}
        
        th {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            font-weight: 600;
        }}
        
        tr:hover {{
            background: #f5f5f5;
        }}
        
        .flag {{
            font-size: 1.5em;
            margin-right: 10px;
        }}
        
        @media (max-width: 768px) {{
            .charts-grid {{
                grid-template-columns: 1fr;
            }}
            
            header h1 {{
                font-size: 1.8em;
            }}
        }}
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🛡️ Fail2ban Statistics</h1>
            <div class="subtitle">leblais.net Security Dashboard</div>
            <div class="updated">Dernière mise à jour : {datetime.now(ZoneInfo('Europe/Paris')).strftime('%d/%m/%Y %H:%M:%S')} (heure de Paris)</div>
        </header>
        
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-value">{data['summary']['total_jails']}</div>
                <div class="stat-label">Jails actifs</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">{data['summary']['total_banned']}</div>
                <div class="stat-label">IPs bannies</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">{data['summary']['total_attempts']}</div>
                <div class="stat-label">Tentatives totales</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">{data['summary']['total_bans']}</div>
                <div class="stat-label">Bans totaux</div>
            </div>
        </div>
        
        <div class="charts-grid">
            <div class="chart-card">
                <h2>📍 Top 15 pays</h2>
                <div class="chart-container">
                    <canvas id="countryChart"></canvas>
                </div>
            </div>
            
            <div class="chart-card">
                <h2>📅 Bans des 7 derniers jours</h2>
                <div class="chart-container">
                    <canvas id="dateChart"></canvas>
                </div>
            </div>
            
            <div class="chart-card">
                <h2>🕐 Bans par heure des 7 derniers jours</h2>
                <div class="chart-container">
                    <canvas id="hourChart"></canvas>
                </div>
            </div>
            
            <div class="chart-card">
                <h2>🎯 Statistiques par Jail</h2>
                <div class="chart-container">
                    <canvas id="jailChart"></canvas>
                </div>
            </div>
        </div>
        
        <div class="table-card">
            <h2>🌍 Top 20 IPs bannies</h2>
            <table>
                <thead>
                    <tr>
                        <th>Rang</th>
                        <th>IP</th>
                        <th>Pays</th>
                        <th>Occurrences</th>
                    </tr>
                </thead>
                <tbody>
"""
    
    # Table des IPs
    country_flags = {
        'CN': '🇨🇳', 'US': '🇺🇸', 'RU': '🇷🇺', 'DE': '🇩🇪', 'FR': '🇫🇷',
        'GB': '🇬🇧', 'IN': '🇮🇳', 'BR': '🇧🇷', 'KR': '🇰🇷', 'JP': '🇯🇵',
        'NL': '🇳🇱', 'SG': '🇸🇬', 'VN': '🇻🇳', 'ID': '🇮🇩', 'UA': '🇺🇦',
        'XX': '🏴‍☠️'
    }
    
    for idx, ip_info in enumerate(data['recent_ips'], 1):
        flag = country_flags.get(ip_info['country_code'], '🏴')
        html += f"""
                    <tr>
                        <td>{idx}</td>
                        <td><code>{ip_info['ip']}</code></td>
                        <td><span class="flag">{flag}</span>{ip_info['country_name']}</td>
                        <td><strong>{ip_info['count']}</strong></td>
                    </tr>
"""
    
    html += """
                </tbody>
            </table>
        </div>
        
        <div class="table-card">
            <h2>🎯 Détails par Jail</h2>
            
            <style>
            .jails-grid {
                display: grid;
                grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
                gap: 20px;
                margin-top: 20px;
            }
            
            .jail-card {
                background: white;
                border-radius: 12px;
                padding: 20px;
                box-shadow: 0 2px 8px rgba(0,0,0,0.08);
                transition: all 0.3s ease;
                border-left: 4px solid #cbd5e0;
                position: relative;
                overflow: hidden;
            }
            
            .jail-card::before {
                content: '';
                position: absolute;
                top: 0;
                right: 0;
                width: 100px;
                height: 100px;
                background: linear-gradient(135deg, rgba(102,126,234,0.05) 0%, transparent 100%);
                border-radius: 0 0 0 100%;
            }
            
            .jail-card:hover {
                transform: translateY(-3px);
                box-shadow: 0 4px 16px rgba(0,0,0,0.12);
            }
            
            .jail-card.has-bans {
                border-left-color: #f56565;
            }
            
            .jail-card.has-attempts {
                border-left-color: #ed8936;
            }
            
            .jail-card.meta {
                border-left-color: gold;
                background: linear-gradient(135deg, #fffbeb 0%, #fef3c7 100%);
            }
            
            .jail-header {
                display: flex;
                align-items: center;
                justify-content: space-between;
                margin-bottom: 16px;
                position: relative;
                z-index: 1;
            }
            
            .jail-title {
                display: flex;
                align-items: center;
                gap: 10px;
            }
            
            .jail-icon {
                font-size: 1.6em;
            }
            
            .jail-name {
                font-size: 1em;
                font-weight: 600;
                color: #2d3748;
                font-family: 'Courier New', monospace;
            }
            
            .meta-badge {
                background: gold;
                color: #000;
                padding: 3px 10px;
                border-radius: 12px;
                font-size: 0.7em;
                font-weight: bold;
                white-space: nowrap;
            }
            
            .jail-stats {
                display: grid;
                grid-template-columns: repeat(3, 1fr);
                gap: 10px;
                position: relative;
                z-index: 1;
            }
            
            .stat-box {
                text-align: center;
                padding: 12px 8px;
                background: #f7fafc;
                border-radius: 8px;
                border: 1px solid #e2e8f0;
                transition: all 0.2s;
            }
            
            .stat-box:hover {
                background: #edf2f7;
            }
            
            .stat-box.active-bans {
                background: #fed7d7;
                border-color: #fc8181;
            }
            
            .stat-box.has-data {
                background: #fef5e7;
                border-color: #f6e05e;
            }
            
            .stat-number {
                font-size: 1.5em;
                font-weight: bold;
                color: #2d3748;
                line-height: 1;
            }
            
            .stat-box.active-bans .stat-number {
                color: #c53030;
            }
            
            .stat-box.has-data .stat-number {
                color: #d69e2e;
            }
            
            .stat-label {
                font-size: 0.7em;
                color: #718096;
                margin-top: 6px;
                text-transform: uppercase;
                letter-spacing: 0.3px;
                font-weight: 500;
            }
            
            @media (max-width: 768px) {
                .jails-grid {
                    grid-template-columns: 1fr;
                }
            }
            </style>
            
            <div class="jails-grid">
"""
    
    # Mapper les icônes par type de jail
    jail_icons = {
        'sshd': '🔑',
        'caddy-cockpit': '⚙️',
        'caddy-freshrss': '📰',
        'caddy-freebox': '📦',
        'caddy-terminal': '💻',
        'caddy-torrent': '🌊',
        'caddy-vaultwarden': '🔐',
        'caddy-adguard': '🛡️',
        'caddy-files': '🗂️',
        'fail2ban-stats': '📊'
    }
    
    # Générer une carte pour chaque jail
    for jail_name, jail_stats in data['jails'].items():
        icon = jail_icons.get(jail_name, '🔒')
        is_meta = (jail_name == "fail2ban-stats")
        has_bans = jail_stats['currently_banned'] > 0
        has_attempts = jail_stats['total_failed'] > 0
        
        card_class = "jail-card"
        if is_meta:
            card_class += " meta"
        elif has_bans:
            card_class += " has-bans"
        elif has_attempts:
            card_class += " has-attempts"
        
        html += f"""
                <div class="{card_class}">
                    <div class="jail-header">
                        <div class="jail-title">
                            <span class="jail-icon">{icon}</span>
                            <span class="jail-name">{jail_name}</span>
                        </div>
"""
        
        if is_meta:
            html += """
                        <span class="meta-badge">🛡️ META</span>
"""
        
        html += """
                    </div>
                    <div class="jail-stats">
"""
        
        # Stat 1: Currently banned
        stat_class_1 = "stat-box"
        if jail_stats['currently_banned'] > 0:
            stat_class_1 += " active-bans"
        
        html += f"""
                        <div class="{stat_class_1}">
                            <div class="stat-number">{jail_stats['currently_banned']}</div>
                            <div class="stat-label">Bannies</div>
                        </div>
"""
        
        # Stat 2: Total banned
        stat_class_2 = "stat-box"
        if jail_stats['total_banned'] > 0:
            stat_class_2 += " has-data"
        
        html += f"""
                        <div class="{stat_class_2}">
                            <div class="stat-number">{jail_stats['total_banned']}</div>
                            <div class="stat-label">Total bans</div>
                        </div>
"""
        
        # Stat 3: Total failed
        stat_class_3 = "stat-box"
        if jail_stats['total_failed'] > 0:
            stat_class_3 += " has-data"
        
        html += f"""
                        <div class="{stat_class_3}">
                            <div class="stat-number">{jail_stats['total_failed']:,}</div>
                            <div class="stat-label">Tentatives</div>
                        </div>
"""
        
        html += """
                    </div>
                </div>
"""
    
    html += """
            </div>
        </div>
    </div>
    
    <script>
        Chart.register(ChartDataLabels);
        Chart.defaults.plugins.datalabels.display = false;
        
        const chartColors = {
            primary: '#667eea',
            secondary: '#764ba2',
            success: '#48bb78',
            warning: '#ed8936',
            danger: '#f56565'
        };
        
        // Graphique des pays
        const countryData = """ + json.dumps(data['countries']) + """;
        new Chart(document.getElementById('countryChart'), {
            type: 'bar',
            data: {
                labels: countryData.map(c => c.code),
                datasets: [{
                    label: 'Nombre de bans',
                    data: countryData.map(c => c.count),
                    backgroundColor: chartColors.primary,
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false },
                    datalabels: {
                        display: true,
                        color: 'white',
                        font: { weight: 'bold' }
                    }
                },
                scales: {
                    y: { beginAtZero: true }
                }
            }
        });
        
        // Graphique des dates
        const dateData = """ + json.dumps(data['bans_by_date']) + """;
        const sortedDates = Object.keys(dateData).sort();
        new Chart(document.getElementById('dateChart'), {
            type: 'line',
            data: {
                labels: sortedDates,
                datasets: [{
                    label: 'Bans par jour',
                    data: sortedDates.map(d => dateData[d]),
                    borderColor: chartColors.secondary,
                    backgroundColor: chartColors.secondary + '33',
                    fill: true,
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false }
                },
                scales: {
                    y: { beginAtZero: true }
                }
            }
        });
        
        // Graphique des heures
        const hourData = """ + json.dumps(data['bans_by_hour']) + """;
        const hours = Array.from({length: 24}, (_, i) => `${String(i).padStart(2, '0')}:00`);
        new Chart(document.getElementById('hourChart'), {
            type: 'bar',
            data: {
                labels: hours,
                datasets: [{
                    label: 'Bans par heure',
                    data: hours.map(h => hourData[h] || 0),
                    backgroundColor: chartColors.success,
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false }
                },
                scales: {
                    y: { beginAtZero: true }
                }
            }
        });
        
        // Graphique des jails
        const jailData = """ + json.dumps(data['jails']) + """;
        const jailNames = Object.keys(jailData);
        new Chart(document.getElementById('jailChart'), {
            type: 'doughnut',
            data: {
                labels: jailNames,
                datasets: [{
                    data: jailNames.map(j => jailData[j].total_banned),
                    backgroundColor: [
                        chartColors.primary,
                        chartColors.secondary,
                        chartColors.success,
                        chartColors.warning
                    ]
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom'
                    },
                    datalabels: {
                        display: true,
                        color: 'white',
                        font: { weight: 'bold', size: 16 }
                    }
                }
            }
        });
    </script>
</body>
</html>
"""
    
    # Sauvegarder le HTML
    output_file = f'{OUTPUT_DIR}/index.html'
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html)
    
    print(f"✅ HTML généré : {output_file}")

if __name__ == '__main__':
    try:
        data = generate_stats()
        generate_html(data)
        print("🎉 Génération terminée avec succès !")
    except Exception as e:
        print(f"❌ Erreur : {e}")
        import traceback
        traceback.print_exc()
