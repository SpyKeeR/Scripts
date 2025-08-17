#!/bin/bash
read -p "Renseigner le chemin absolu du répertoire : " rep
read -p "Renseigner l'extension du type de fichier : " extension
echo -e "\n"
echo "Liste des fichiers $extension disponibles dans le répertoire $rep : "
find $rep -maxdepth 1 -name "*.$extension" -printf "%f \n"
echo -e "\n"
read -p "Quel fichier voulez-vous traiter? " fic
nblign=$(wc -l $rep/$fic | cut -d " " -f 1)
debut=$(head $rep/$fic)
fin=$(tail $rep/$fic)
echo -e "\n"
echo "CARACTERISTIQUES de $fic : "
echo -e "\n"
echo "Nombre de lignes du fichier : $nblign"
echo -e "\n"
echo "Début du fichier :"
echo "$debut"
echo -e "\n"
echo "Fin du fichier :"
echo "$fin"
