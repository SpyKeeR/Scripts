#!/bin/bash
fic=fic.txt
read -p "Veuillez saisir un nom de dossier à créer : " dossier
echo -e "\n"
echo "Création du dossier : $dossier"
echo "----------------------"
mkdir "$dossier" && echo -e "\033[0;32mRépertoire $dossier créé.\033[0m"
echo -e "\n"
echo "Création du fichier : $fic"
echo "----------------------"
touch "$dossier/$fic" && echo "Introduction du fichier $fic" > $dossier/$fic && echo -e "\033[0;34mFichier $fic créé dans ${dossier}.\033[0m"
echo -e "\n"
echo "Contenu du fichier : $fic"
echo "----------------------"
cat $dossier/$fic
