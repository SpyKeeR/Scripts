#!/bin/bash
if [[ "$LOGNAME" == "root" ]] ; then
  sep="---------------------------"
  read -p "Saisir l'identifiant utilisateur souhaité : " user
  echo "GESTION DES UTILISATEURS : $user"
  echo "---------------------------"
  echo "C - Créer le compte utilisateur"
  echo "M - Modifier le mot de passe de l'utilisateur"
  echo "S - Supprimer le compte utilisateur"
  echo "V - Afficher l'UID et GIDs des groupes de l'utilisateur"
  echo "Q - Quitter"
  echo -e "\n"
  read -p "Votre choix : " choice
  echo -e "\n"
  case $choice in
    C|c)
      if id "$user" &> /dev/null ; then
        echo "Utilisateur ${user} déjà existant"
        exit 2
      else
        secret=$(openssl passwd -6 'iop')
        echo -e "Création du compte utilisateur : ${user}\n${sep}"
        { useradd -ms /bin/bash -p "$secret" "${user}" && passwd -e "${user}" ; } &> /dev/null && echo "Utilisateur $user créé avec MDP par défaut & expire auto"
      fi
      ;;
    M|m)
      if id "$user" &> /dev/null ; then
        echo -e "Modification du mot de passe de l'utilisateur : ${user}\n${sep}"
        passwd "${user}" && echo "Mot de passe de l'utilisateur ${user} modifié"
      else
        echo "Aucun utilisateur nommé ${user} n'existe sur le système"
        exit 3
      fi
      ;;
    S|s)
      if id "$user" &> /dev/null ; then
        read -p "Confirmez-vous la suppression de l'utilisateur ${user} [O/o/OUI/oui] : " confirm_del
        regex_yes="^(O|o|OUI|oui)$"
        if [[ "${confirm_del}" =~ ${regex_yes} ]] ; then
          echo -e "Supression du compte utilisateur : ${user}\n${sep}"
          userdel "$user" && echo "Compte de l'utilisateur supprimé"
        else
          echo "Abandon de la suppression"
          exit 4
        fi
      else
        echo "Aucun utilisateur nommé ${user} n'existe sur le système"
        exit 3
      fi
      ;;
    V|v)
      echo -e "Vérification de l'existence et des UID/GIDs de l'utilisateur ${user}\n${sep}"
      id "$user" &> /dev/null && echo -e "Compte de l'utilisateur ${user} existe.\nInformations (id) :\n$(id "${user}")"
      id "$user" &> /dev/null || echo "Compte de l'utilisateur ${user} inexistant" ; exit 3
      ;;
    Q|q)
      echo "Sortie du script."
      exit 0
      ;;
    *)
      echo "Vous avez renseigné un mauvais choix, veuillez exécuter de nouveau le script"
      exit 5
      ;;
  esac
else
  echo "Vous devez être root pour utiliser ce script"
  exit 1
fi