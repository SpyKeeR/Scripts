#!/bin/bash
if [[ $EUID -ne 0 ]]; then
    echo "Ce script doit être exécuté en tant que root."
    exit 2
fi
base_name=""
num_users=""
start_num=""
if [[ $# -ne 0 ]]; then
    if [[ $# -eq 1 && -n $1 ]]; then
        base_name=$1
    elif [[ $# -eq 2 && -n $1 && -n $2 ]]; then
        base_name=$1
        num_users=$2
    elif [[ $# -eq 3 && -n $1 && -n $2 && -n $3 ]]; then
        base_name=$1
        num_users=$2
        start_num=$3
    else
        echo "Usage: $0 [base_name [num_users [start_num]]]"
        exit 1
    fi
fi
while true; do
    if [[ -f /tmp/listusers.txt && -s /tmp/listusers.txt ]]; then
        echo "Le fichier /tmp/listusers.txt existe."
        echo "Confirmez-vous que vous souhaitez créer le(s) $(wc -l < /tmp/listusers.txt) utilisateur(s) suivants ?  (o/n)"
        tr '\n' ' ' < /tmp/listusers.txt | xargs -n 7
        read -p "Votre choix : " confirm
        if [[ $confirm != "o" && $confirm != "O" ]]; then
            echo "Annulation de la création des utilisateurs par bloc."
            echo "----------------------------------------------"
            echo -e "Veuillez supprimer le fichier /tmp/listusers.txt si vous souhaitez utiliser\n le mode de création d'utilisateurs incremental avec un nom de base et un nombre d'utilisateurs."
            exit 2
        fi
        echo "----------------------------------------------"
        success_count=0
        fail_count=0
        fail_log="/var/log/createusers_fails.log"
        echo "Log des échecs de création : $fail_log"
        echo "----------------------------------------------"
        for username in $(cat /tmp/listusers.txt); do
            echo -n "Creation du compte : $username - "
            if useradd "$username" &> /dev/null; then
                sleep 0.5
                echo -e "\033[32mOK\033[0m"
                sed -i "/^${username}$/d" /tmp/listusers.txt
                ((success_count++))
            else
                sleep 0.5
                echo -e "\033[31mECHEC\033[0m"
                echo -n "$(date '+%Y-%m-%d %H:%M:%S') - " >> "$fail_log"
                echo "ECHEC de creation de l'utilisateur : $username" >> "$fail_log"
                ((fail_count++))
            fi
        done
        echo "----------------------------------------------"
        if [[ $success_count -gt 0 ]]; then
            echo "$success_count utilisateur(s) ont été créés avec succès."
        fi
        if [[ $fail_count -gt 0 ]]; then
            echo "----------------------------------------------" >> "$fail_log"
            echo "$fail_count utilisateur(s) n'ont pas été créés."
            echo "Les échecs de création ont été reportés dans : $fail_log"
        fi
        echo "----------------------------------------------"
        exit 0
    fi
    if [[ -z $base_name ]]; then
        read -p "Base de nom des comptes a créer : " base_name
    fi
    if [[ -z $num_users ]]; then
        read -p "Nombre d'utilisateurs a créer : " num_users
    fi
    if [[ -z $start_num ]]; then
        read -p "Numero du premier utilisateur (défaut: 1) : " start_num
    fi
    start_num=${start_num:-1}
    if [[ -n "$base_name" && -n "$num_users" ]]; then
        if [[ "$base_name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
            if [[ "$num_users" =~ ^[1-9][0-9]*$ ]] && [[ "$start_num" =~ ^[0-9]+$ ]]; then
                for ((i=0; i<num_users; i++)); do
                    user_num=$((start_num + i))
                    username="${base_name}${user_num}"
                    if id "$username" &>/dev/null; then
                        echo "L'utilisateur '$username' existe déjà. Veuillez choisir un autre nom de base ou un autre numéro de départ."
                        base_name=""
                        num_users=""
                        start_num=""
                        continue 2
                    fi
                done
                echo "----------------------------------------------"
                echo "Création de $num_users utilisateurs avec le nom de base '$base_name'"
                echo "Numéro de départ : $start_num"
                echo "----------------------------------------------"
                echo "Début de la création des utilisateurs..."
                echo "----------------------------------------------"
                success_count=0
                fail_count=0
                fail_log="/var/log/createusers_fails.log"
                echo "Log des échecs de création : $fail_log"
                echo "----------------------------------------------"
                for ((i=0; i<num_users; i++)); do
                    user_num=$((start_num + i))
                    username="${base_name}${user_num}"
                    echo -n "Creation du compte : $username - "
                    if useradd "$username" &> /dev/null; then
                        sleep 0.5
                        echo -e "\033[32mOK\033[0m"
                        ((success_count++))
                    else
                        sleep 0.5
                        echo -e "\033[31mECHEC\033[0m"
                        echo -n "$(date '+%Y-%m-%d %H:%M:%S') - " >> "$fail_log"
                        echo "ECHEC de creation de l'utilisateur : $username" >> "$fail_log"
                        ((fail_count++))
                    fi
                done
                echo "----------------------------------------------"
                if [[ $success_count -gt 0 ]]; then
                    echo "$success_count utilisateur(s) ont été créés avec succès."
                fi
                if [[ $fail_count -gt 0 ]]; then
                    echo "----------------------------------------------" >> "$fail_log"
                    echo "$fail_count utilisateur(s) n'ont pas été créés."
                    echo "Les échecs de création ont été reportés dans : $fail_log"
                fi
                echo "----------------------------------------------"
                break
            else
                num_users=""
                start_num=""
                echo "Le nombre d'utilisateurs et le numéro de départ doivent être des nombres entiers. Veuillez réessayer."
            fi
        else
            echo "Le nom de base '$base_name' n'est pas valide. Il doit commencer par une lettre et ne peut contenir que des lettres, des chiffres, des tirets et des underscores."
            base_name=""
        fi
    else
        echo "Les champs ne peuvent pas être vides. Veuillez réessayer."
    fi
done
if [[ $fail_count -gt 0 ]]; then
    exit 1
fi