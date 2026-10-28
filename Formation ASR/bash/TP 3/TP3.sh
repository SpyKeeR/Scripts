#!/bin/bash
read -p "Renseigner le chemin absolu du répertoire : " rep
read -p "Renseigner l'extension du type de fichier : " extension
echo -e "\n"
echo "Liste des fichiers ${extension} disponibles dans le répertoire ${rep} : "
find $rep -maxdepth 1 -name "*.$extension" -printf "%f \n"
echo -e "\n------------------------------\n"
read -p "Quel fichier voulez-vous traiter? : " fic
nblign=$(wc -l $rep/$fic | cut -d " " -f 1)
debut=$(head -n 2 $rep/$fic)
fin=$(tail -n 2 $rep/$fic)
echo -e "CARACTERISTIQUES de $fic : \nNombre de lignes du fichier : ${nblign}\nDébut du fichier :\n${debut}\nFin du fichier :\n${fin}"