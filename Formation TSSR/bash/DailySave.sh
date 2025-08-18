#!/bin/bash
echo "---" >> /root/saves/savejourna.log
echo "Sauvegarde journalière lancé le $(date +"%A, %d %B %Y à %H:%M")" >> /root/saves/savejourna.log
echo "---" >> /root/saves/savejourna.log
cd /
tar cf /root/saves/UsersHome.tar home/* &>> /root/saves/savejourna.log 
tar cf /root/saves/ServicesData.tar services/* &>> /root/saves/savejourna.log 
scp -i /root/.ssh/id_ed25519 /root/saves/UsersHome.tar /root/saves/ServicesData.tar upresta@DEB12-Presta.local:/home/upresta/saves/DEB12-CM/ &>> /root/saves/savejourna.log