#!/bin/bash
if [[ "$LOGNAME" == "root" ]] ; then
	read -p "Saisir l'identifiant utilisateur souhaité : " user
	echo "GESTION DES UTILISATEURS : $user"
	echo "---------------------------"
	echo "C - Créer le compte utilisateur"
	echo "M - Modifier le mot de passe de l'utilisateur"
	echo "S - Supprimer le compte utilisateur"
	echo "V - Vérifier si le compte utilisateur existe"
	echo "Q - Quitter"
	echo -e "\n"
	read -p "Votre choix : " choice
	echo -e "\n"
	case $choice in
		C)
			echo "Création du compte utilisateur : $user"
			useradd "$user" && echo "Utilisateur $user créé."
			;;
		M)
			echo "Modification du mot de passe de l'utilisateur : $user"
			passwd "$user" && echo "Mot de passe de l'utilisateur $user modifié"
			;;
		S)
			echo "Supression du compte utilisateur : $user"
			userdel "$user" && echo "Compte de l'utilisateur supprimé"
			;;
		V)
			echo "Vérification de l'existence de l'utilisateur"
			id "$user" &> /dev/null && echo "Compte utilisateur de $user existe"
			id "$user" &> /dev/null || echo "Compte utilisateur de $user inexistant"
			;;
		Q)
			echo "Sortie du script."
			exit 0
			;;
		*)
			echo "Vous avez renseigné un mauvais choix, veuillez exécuter de nouveau le script"
			;;
	esac
else
	echo "Vous devez être root pour utiliser ce script"
	exit 1
fi
