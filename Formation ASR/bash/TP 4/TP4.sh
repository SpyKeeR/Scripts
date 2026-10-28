#!/bin/bash

if test -n "${1}"; then
        pids="$(pgrep -x -d ' ' -- "${1}")"
        if test -n "${pids}"; then
                echo "Le processus ${1} a comme pid(s) : ${pids}."
        else
                echo "Le processus ${1} n'est pas en cours d'exécution."
        fi
else
        echo "Vous n'avez pas spécifié d'argument au script ${0}."
fi