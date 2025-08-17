 do {
    $service = Read-Host "Entrez un nom de service à tester (Ou q pour quitter la vérification) " 
    if ( $service -ne "q" ) {
        try {
        Get-Service -Name $service -ErrorAction Stop -ErrorVariable Erreur | Out-Null
        Write-Host "Le Service est présent"
        }
        catch 
        {
        [array]$listErreurs += "$Erreur"
        }
    }
} while ( $service -ne "q" )
Write-Host "Tous les services ont été testés"
if ( $listErreurs ) {
Write-Host "Liste des erreurs rencontrées : $listErreurs" ; $listErreurs = $null
}