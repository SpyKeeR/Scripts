#!/bin/bash

#Déclaration des variables
annee=$1
nummois=1
###annee=2011
rouge='\033[31m'
orange='\033[33m'
vert='\033[32m'
noir='\033[0m'

# A COMPLETER #
#Vérification de la présence d'un argument passé au script
# A COMPLETER #
[[ -z $1 ]] && { echo -e "Syntaxe d'utilisation : $0 $rouge <annee> $noir"; exit 13; }

echo "###################"
echo "##  ANNEE $annee   ##"
echo "###################"

# Recherche de vendredi 13 sur chaque mois
# On boucle pour tous les mois
until [[ $nummois -eq 13 ]]
        do
        ligne13=`cal $nummois $annee | grep 13`
	# format du retour de la commande precedente incorrect
	ligne13=$(echo $ligne13)
        if [[ $ligne13 = *13\ 14 ]]
                then
                nommois=`date --date "$nummois/01" +%B`
                listmois="$listmois $nommois,"
                nbremois=`expr $nbremois + 1`
        fi
        nummois=`expr $nummois + 1`
done

# A COMPLETER #
#Affichage des mois ayant un vendredi 13
echo -e "En $rouge $listmois $noir surveiller les paraskaviedekatriaphobes "
# A COMPLETER #
#Détermination du niveau de vigilence, du message, et de la couleur en fonction du nombre de mois ayant un vendredi 13
case $nbremois in
        1)
        niveau="calme"
        color="$vert"
        ;;
        2)
        niveau="moyenne"
        color="$orange"
        ;;
        *)
        niveau="a forte vigilance"
        color="$rouge"
        ;;
esac

# A COMPLETER #
#Affichage du message recap de l'année avec vigilence final
echo -e "$annee sera une annee ${color}$niveau $noir( $nbremois )"
