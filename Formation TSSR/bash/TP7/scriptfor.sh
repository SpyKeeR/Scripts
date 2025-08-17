#!/bin/bash
folder=$1
extensions="./exts.txt"
if [[ -z $1 || $# -ne 1 ]] ; then
	echo "Syntaxe du script : $0 <Dossier>"; exit 1
else
	echo "Nombre total de fichiers dans $folder : $(ls -1A $folder | wc -l)"
	for ext in $(cat $extensions)
		do
		for file in ${folder}/*
			do
				echo "$file" | grep $ext -q && nbfilesext=$(expr $nbfilesext + 1)
			done
		if [[ nbfilesext -ne 0 ]] ; then
			echo "---------------"
			echo " $ext"
			echo "---------------"
			echo "-> $nbfilesext fichier(s) trouvé(s)."
			nbfilesext=0
		 	fi
		done
fi
