#!/bin/bash
if [[ $EUID -ne 0 ]]; then
    echo "Ce script doit être exécuté en tant que root."
    exit 2
fi
#Vérification de l'existence du fichier /tmp/listusersmaj.txt
if [[ ! -f /tmp/listusersmaj.txt || ! -s /tmp/listusersmaj.txt ]]; then
    echo -e "Le fichier /tmp/listusersmaj.txt n'existe pas ou est vide.\nVeuillez créer le fichier avec les informations des utilisateurs à ajouter.\nFormat: username home_directory shell"
    exit 1
else
    $userpassword = $(openssl passwd -6 "iop")
    while read -r username homeuser shelluser; do
        if id "$username" &>/dev/null; then
            echo "L'utilisateur $username existe déjà."
        else
            #Vérification de la variable homeuser qui doit être non null et contenir un chemin absolu
            if [[ -z "$homeuser" || "$homeuser" != '/*' ]]; then
                echo "Le chemin de l'utilisateur $username est invalide."
                exit 2
            else
                #Verification de la variable shelluser qui doit être non null, pointer vers un binaire, shell valide et contenir un chemin absolu, opérateur de test -x pour vérifier si le fichier est exécutable et que c'est bien un binaire
                if [[ -z "$shelluser" || ! -x "$shelluser" ]]; then
                    echo "Le shell de l'utilisateur $username est invalide, le shell par défaut sera /bin/bash."
                    shelluser="/bin/bash"
                fi
                    useradd -p "$userpassword" -md "$homeuser" -s "$shelluser" "$username"
                    echo "Utilisateur $username créé avec succès."
                    shelluser=""
            fi
        fi
    done < /tmp/listusersmaj.txt
fi