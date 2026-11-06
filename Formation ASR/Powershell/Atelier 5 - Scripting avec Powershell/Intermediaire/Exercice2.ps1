:menu While ($true)
    {
    Write-Host "Bienvenue dans l'outil d'inventaire, faites votre choix parmi les menus suivants :"
    Write-Host "1) Rechercher un utilisateur AD"
    Write-Host "2) Lister les utilisateurs d'une OU"
    Write-Host "3) Désactiver un utilisateur AD"
    Write-Host "0) Quitter"
    Write-Host ""
    $choix = Read-Host "Entrez votre choix (0-3)"
    Switch ($choix)
        {
            '1' { 
            Read-Host "Renseigner le SamAccountName à rechercher dans l'AD" | Get-ADUser -Filter {sAMaccountName -like "*$($_)*"} -ErrorAction SilentlyContinue | Select-Object SamAccountName,Name, Surname, Enabled | Format-Table -AutoSize -Wrap
            if (!$?) { Write-Host "L'utilisateur n'a pas été trouvé dans l'AD. Veuillez renseigner un autre SamAccountName à rechercher." }
            }
            '2' { 
            Read-Host "Renseigner le chemin LDAP complet de l'OU à rechercher dans l'AD" | Get-ADUser -SearchBase "$($_)" -Filter * -ErrorAction SilentlyContinue | Select-Object SamAccountName,Name, Surname, Enabled | Format-Table -AutoSize -Wrap
            if (!$?) { Write-Host "L'OU n'a pas été trouvé dans l'AD. Veuillez renseigner un autre chemin LDAP complet de l'OU à rechercher." }
            }
            '3' {
            Read-Host "Renseigner le SamAccountName de l'utilisateur à désactiver dans l'AD" | Disable-ADAccount -ErrorAction SilentlyContinue
            if (!$?) { Write-Host "L'utilisateur n'a pas été trouvé dans l'AD. Veuillez renseigner un autre SamAccountName à désactiver." }
            else { Write-Host "L'utilisateur a été désactivé avec succès dans l'AD." }
            }
            '0' { Write-Host "Vous quittez l'outil d'inventaire" ; break menu }
            default { Write-Host "Vous avez renseigné un mauvais choix dans le menu, veuillez re-essayer" }
        }
}