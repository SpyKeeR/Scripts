#!/bin/bash

sep="----------------------------------------"

if [[ $EUID -ne 0 ]]; then
    echo "Ce script doit être exécuté en tant que root."
    exit 2
fi

# Menu principal
while true; do
    echo "$sep"
    echo "Espace occupé par :"
    echo "$sep"
    echo "1- Les 5 dossiers depuis racine les plus volumineux"
    echo "2- Les 5 répertoires d'accueil utilisateurs les plus volumineux"
    echo
    echo "Q- Quitter le script"
    echo
    read -p "Votre choix ? " choice
    echo
    echo "$sep"
    case $choice in
        1)
            echo "Les 5 dossiers depuis racine les plus volumineux :"
            du -h  / --max-depth=1 2> /dev/null | sort -hr | head -n 5 | awk '{print $2 "\t" $1}' | column -t -N "Dossier","Taille" | tee /tmp/5doss_volumineux
            echo "Résultat sauvegardé dans /tmp/5doss_volumineux"
            ;;
        2)
            echo "Les 5 répertoires d'accueil utilisateurs les plus volumineux :"
            du -h --max-depth=1 /home | sort -hr | head -n 5 | awk '{print $2 "\t" $1}' | column -t -N "Répertoire Accueil","Taille" | tee /tmp/5homedir_volumineux
            echo "Résultat sauvegardé dans /tmp/5homedir_volumineux"
            ;;
        Q|q)
            echo "Sortie du script."
            exit 0
            ;;
        *)
            echo "Choix invalide. Veuillez réessayer."
            ;;
    esac
done