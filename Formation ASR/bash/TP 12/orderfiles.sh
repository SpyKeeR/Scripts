#!/bin/bash

if [[ ! -f "$HOME/.orderfiles.conf" ]]; then
    read -p "Veuillez choisir les formats de fichiers d'image à traiter, séparés par des espaces : " formats
    echo "$formats" > "$HOME/.orderfiles.conf"
    echo "Le fichier de configuration $HOME/.orderfiles.conf a été créé."
    echo "Vous pouvez modifier ce fichier à tout moment pour ajuster les formats de fichiers."
fi
formats=$(cat "$HOME/.orderfiles.conf")
while true; do
    echo "Formats de fichiers actuels : $formats"
    read -p "Souhaitez-vous modifier les formats de fichiers à traiter ? (O/o pour Oui, N/n pour Non, Q/q pour Quitter) : " modify_choice
    case $modify_choice in
        O|o )
            read -p "Veuillez entrer les nouveaux formats de fichiers d'image à traiter, séparés par des espaces (ex : jpg png gif) : " new_formats
            echo "$new_formats" > "$HOME/.orderfiles.conf"
            echo "Le fichier de configuration $HOME/.orderfiles.conf a été mis à jour."
            formats="$new_formats"
            break
            ;;
        N|n )
            echo "Les formats de fichiers actuels seront utilisés : $formats"
            break
            ;;
        Q|q )
            echo "Sortie du script."
            exit 0
            ;;
        * )
            echo "Veuillez répondre par O/o pour Oui ou N/n pour Non."
            ;;
    esac
done
while read -r -d '' file; do
    if [[ -f "$file" ]]; then
        creation_date=$(stat -c %y "$file" | cut -d ' ' -f 1)
        year=$(echo "$creation_date" | cut -d '-' -f 1)
        month=$(echo "$creation_date" | cut -d '-' -f 2)
        day=$(echo "$creation_date" | cut -d '-' -f 3)
        target_dir="$year-$month-$day"
        mkdir -p "$target_dir"
        new_file_name=$(echo "$(basename "$file")" | tr -s ' ' '_')
        mv "$file" "$target_dir/$(stat -c %y "$file" | cut -d ' ' -f 2 | tr ':' '-')-${new_file_name}"
    fi
done < <(find . -type f \( $(printf -- '-iname "*.%s" ' ${formats}) \) -print0 2> /dev/null)
echo "Les fichiers ont été classés par date de création dans les répertoires correspondants."
