#!/bin/bash
min_free_capacity=10
services=("syslogd" "rsyslog" "kjournald" "systemd-journald")

if [[ $EUID -ne 0 ]]; then
    echo "Ce script doit être exécuté en tant que root."
    exit 2
fi

echo "Script de vérification MCO"
echo "$sep"
echo "Vérification de l'espace disque disponible"
disk_check=$(df / | tail -1 | tr -s ' ' | cut -d ' ' -f 5 | tr -d '%')

if [[ $disk_check -lt $min_free_capacity ]]; then
    echo "L'espace disque disponible est inférieur au seuil défini de ${min_free_capacity}%."
    exit 1
else
    echo "L'espace disque disponible est suffisant."
fi

echo "$sep"
echo "Vérification des services suivants : syslogd/rsyslog, kjournald/systemd-journald"
read -p "Souhaitez-vous vérifier d'autres services ? (o/n) : " check_more
if [[ $check_more == "o" || $check_more == "O" ]]; then
    read -p "Entrez les noms des services à vérifier, séparés par des espaces : " additional_services
    services+=($additional_services)
fi
for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service"; then
        echo "Le service $service est actif."
    else
        echo "Le service $service n'est pas actif."
    fi
done

echo "$sep"
echo "Affichage des messages significatifs du jour"
if [[ -f /var/log/messages ]]; then
    grep "$(date '+%b %d')" /var/log/messages
elif [[ -f /var/log/syslog ]]; then
    grep "$(date '+%b %d')" /var/log/syslog
else
    echo "Aucun fichier de log approprié trouvé."
fi

echo "$sep"
echo "Vérification MCO terminée."