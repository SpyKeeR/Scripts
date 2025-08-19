#!/bin/bash

if [ -z $1 ] || [ -z $2 ]
        then
        echo 'Le domaine ou le Blog ID est vide, veuillez réessayez'
        echo -e 'Usage : newblog.sh Domaine Idblog'
        exit;
fi
echo "Verification variables : OK <br />"

#Copie parametres vers variables
domain=$1
idblog=$2
echo "Enregistrement variable OK <br />"
echo "############################### Début du travail pour $domain ##################################" >> /var/log/newblog.log

#Verification Enregistrement SQL
mysql -udotclearuser -pcleardotstage -e "SELECT blog_id FROM dotclear.dc_blog WHERE blog_id='$idblog';"  > /tmp/SQLtest.log 
if [[ `cat /tmp/SQLtest.log` = "" ]];then
	echo 'Aucun enregistrement dans la base de donnée trouvé pour $idblog <br />'
	echo -e 'Veuillez re-exécuter le Script.PHP <br />'
	exit;
else
	echo 'Enregistrement trouvé dans la base de donnée : Début du travail <br />'

	#Creation du repertoire pour le blog en reprenant id blog
	cd /var/www
	if [ ! -d "$idblog" ]
        	then
		mkdir "$idblog"
		echo 'Dossier blog crée avec succés <br />'
		echo 'Dossier blog crée avec succés' >> /var/log/newblog.log

        	#Création du fichier index.php
        	cd "$idblog"
        	#touch index.php
        	#echo 'creation du index.php OK <br />'

        	#Personnalisation de l'index.php avec le paramètre domain
        	#echo -n "<?php define('DC_BLOG_ID','" > index.php
        	#echo -n "$idblog" >> index.php
        	#echo "');
        #require dirname(__FILE__).'/../inc/public/prepend.php';?>" >> index.php
        	#echo 'Remplissage du index.php OK <br />'


        	#Creation d'un dossier public
        	mkdir public
        	echo 'creation du dossier public du blog : OK <br />'
        	echo 'creation du dossier public du blog : OK' >> /var/log/newblog.log

        	#Chown et Chmod du tout
        	cd /var/www
        	#chmod 770 "$idblog"/index.php
        	chmod -R 774 "$idblog"/public
		echo 'Chmod et chown effectués <br />'
		echo 'Chmod et chown effectués'  >> /var/log/newblog.log
	else
		echo "Le dossier receptacle du Blog existes déjà <br />"
		echo "Le dossier receptacle du Blog existes déjà"  >> /var/log/newblog.log
		exit;
	fi

		#Generation Vhost nginx par le rajout de dot-exemple dans conf.dotclear
	#cd /etc/nginx/conf.dotclear/
	#if [ ! -e dot-$idblog ]
        #then
		#touch "dot-""$idblog"
		#echo "Vhost crée <br />"

		#Personnalisation du dot-exemple
		#echo "#Server dotclear de $idblog" > "dot-""$idblog"
		#echo -e "server {" >> dot-$idblog
		#echo -e "      listen   80;

       		#root /var/www/;" >> dot-"$idblog"
		#echo -n "      index index.php index.html index.htm;

       		#	server_name $domain " >> dot-"$idblog"
		#echo -n "*.$domain" >> dot-"$idblog"
		#echo ";" >> dot-$idblog
		#echo -e "      include conf.dotclear/confglobale;" >> dot-$idblog
		#echo -e "}" >> dot-"$idblog"
		#echo "Remplissage du Vhost effectué <br />"


		#Test et graceful de nginx
		#nginx -t
		#kill -HUP $( cat /run/nginx.pid )
		#echo "Nginx testé gracefullé <br />"
	#else
		#echo "Le fichier de configuration Nginx existe déjà <br />"
	#fi
		cd /var/www
		domaingrep="$domain=$idblog"
		grepdomain=`grep $domaingrep /var/www/domains.ini`
		if [[ $grepdomain = $domaingrep ]]
		then
			echo "Deja dans la fichier ini de domains"
			echo "Deja dans la fichier ini de domains"  >> /var/log/newblog.log
		else
			echo "$domain=$idblog" >> domains.ini
			echo "Rajouté dans le domains.ini"
			echo "Rajouté dans le domains.ini"  >> /var/log/newblog.log
		fi
fi
