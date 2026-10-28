#!/bin/bash
############################
## Maxime C. - PASR_2605
## TP 2 - Scripting Bash
## 26-10-2026
############################

echo "Bonjour, cette machine est fin prête pour scripter ..."
echo "Scripts shells présents ici :"

## Affiche la liste détaillée des scripts Shell présents dans le répertoire courant
ls -l *.{,ba}sh

echo
echo "Informations relatives à l’interpréteur Bash : "

## Affiche la version de Bash installée
bash --version

## Affiche binaire bash, bashrc commun à tous les utilisateurs, fichier contenant les sources pages du man de Bash
whereis bash

echo "Mise à jour disponible ?"

## Affiche si une version mise à jour de Bash est disponible
apt list --upgradable "bash*"
