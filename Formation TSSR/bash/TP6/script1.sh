#!/bin/bash
if [[ $# -eq 0 || -z $1 ]] ; then
	echo "Veuillez fournir un nom en argument au lancement du script."
elif [[ $# -gt 1 ]] ; then 
	echo "Erreur : Vous avez renseigné plusieurs noms"
	exit 1
elif [[ "$1" = "root" ]] ; then
	echo -e "\033[1;31mLe compte root est interdit\033[0m"
	exit 2
else 
	echo "Bonjour ${1}, bienvenue sur la machine $(uname -n)"
fi
echo "--- Fin du script --"	
