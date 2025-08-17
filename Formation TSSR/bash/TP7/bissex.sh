#!/bin/bash

#Déclaration des variables
debut=$1
fin=$2

[[ -z $1 || -z $2 || $# -eq 0 ]] && { echo -e "Syntaxe d'utilisation : $0 <AnneeDebut> <AnneeFin>"; exit 1; }

echo "#########################################"
echo "##  Période considérée de $debut à $fin  ##"
echo "#########################################"

while [[ $debut -le $fin ]]
	do
        	cal 2 $debut | grep 29 -q && { bissex=$(expr $bissex + 1); listbissex="$listbissex ${debut},"; }
		debut=$(expr $debut + 1)
	done
if [[ $bissex -eq 0 ]] ; then
	echo -e "Il n'y a pas d'année bissextile dans la plage donnée."
else 
	echo "Il y a $bissex année(s) bissextile(s) dans la plage donnée."
	echo "Année(s) :$listbissex"
fi
