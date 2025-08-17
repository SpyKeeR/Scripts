echo "Bonjour, cette machine est fin prête pour scripter..."
echo "Scripts Shell présents ici :"
ls ./*.sh
echo -e "\n"
echo "Informations relatives à l'interpréteur Bash : "
echo "Version de bash : $(bash --version)"
echo "Binaire de bash : $(which bash)"
echo "Fichier .bashrc commun : $(ls /etc/bash.bashrc)"
echo "Fichier du manuel de bash : $(man -w bash)"
echo "Mise à jour disponible ?"
sudo apt upgrade bash
