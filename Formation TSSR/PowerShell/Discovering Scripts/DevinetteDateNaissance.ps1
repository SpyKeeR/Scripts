$anniversaire = Read-Host "Veuillez renseigner l'année de naissance (yyyy) "
$essai = 0
Do {
    $sugg = Read-Host "Veuillez renseigner votre proposition d'année de naissance "
    $essai += 1
    If ( $sugg -eq $anniversaire )
        {
        Write-Host "Vous avez réussi à déterminer l'année de naissance en $essai essai(s). Félicitations !" 
        }
    ElseIf ($sugg -gt $anniversaire )
        {
        Write-Host "Vous avez renseigné une année trop élévée"
        Write-Host "Vous en êtes à la tentative n°$essai"
        }
    Else
        {
        Write-Host "Vous avez renseigné une année trop petite"
        Write-Host "Vous en êtes à la tentative n°$essai"
        }
} while ( $sugg -ne $anniversaire ) 