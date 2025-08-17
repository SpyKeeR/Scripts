While ($true)
    {
    Write-Host "Bienvenue dans l'outil d'inventaire, faites votre choix parmi les menus suivants :"
    Write-Host "1) Affichage des ordinateurs du domaine."
    Write-Host "2) Affichage des groupes de domaines locaux"
    Write-Host "3) Importation des utilisateurs « AD » à partir d’un fichier « CSV »"
    Write-Host "4) Quitter"
    Write-Host ""
    $choix = Read-Host "Entrez votre choix"
    Switch ($choix)
        {
            '1' { 
            Get-AdComputer -Filter *
             }
            '2' { 
            Get-ADGroup -Filter 'GroupScope -eq "Domainlocal"'
            }
            '3' {
            $CSVPath = Read-Host "Renseigner le chemin d'accès au fichier CSV " 
            Import-CSV -delimiter ";" -Path $CSVPath | New-ADUser
            }
            '4' {
            Write-Host "Vous quitter l'outil d'inventaire" 
            return
            }
            default { Write-Host "Vous avez renseigné un mauvais choix dans le menu, veuillez re-essayer" }
        }
}