#!/bin/bash
while read username x uid tampon 
	do
	echo "-------------------"
	echo "Identifiant : $username"
	echo "- - - - - -"
	echo "UID : $uid"
done < <(tr -s ":" " " < /etc/passwd)
