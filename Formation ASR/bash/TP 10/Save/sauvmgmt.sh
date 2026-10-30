#!/bin/bash
source fonctions.fct
while true 
	do
	f_affichmenu
	read -p "Choisissez une action [S/D/L ou Q] : " choix
	echo -e "\n"
	case $choix in
		S|s)
			f_createsave
			;;
		D|d)
			f_cleansave
			;;
		L|l)
			f_listfiles
			;;
		Q|q)
			exit 0
			;;
		*)
			echo "Vous avez renseigné un mauvais choix de menu."
			;;
	esac
done
