#!/bin/bash

sep="-------------------------------------------------"

if [ "${#}" -gt 1 ] ; then
    echo "Utilisation : <${0})> [nom_process]"
    echo "Un seul argument est attendu"
    exit 3
elif [ "${#}" -eq 1 ] ; then
    crit="${1}"
else
    read -r -p "Saisir le critère de recherche : " crit
fi

if [ -z "${crit}" ] ; then
    crit="$(id -un)"
fi

echo "${sep}"
echo "Liste des processus contenant ${crit}"
echo "${sep}"
ps aux | head -n 1
ps aux | grep -iw -F -- "${crit}"
echo "${sep}"

echo "$(date +%H:%M:%S) – Fin de traitement"