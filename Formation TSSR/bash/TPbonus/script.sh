#!/bin/bash
source ./fonctions.fct
if [[ ! -f "/tmp/listusersmaj.txt" ]] ; then
	echo "Le fichier /tmp/listusersmaj.txt n'est pas présent sur le système"
	exit 2
elif [[ $# -gt 0 && "$1" == "create" ]] ; then
	f_createaccounts
	exit 0
else
	while true 
		do
		f_affichmenu
		case $choix in
			C|c)
				f_createaccounts
				;;
			D|d)
				f_suppaccount
				;;
			L|l)
				f_showlist
				;;
			A|a)
				f_addaccount2list
				;;
			Q|q)
				exit 0
				;;
			*)
				echo "Vous avez renseigné un mauvais choix de menu."
				;;
		esac
	done
fi
