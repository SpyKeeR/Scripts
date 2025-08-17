 function Search-Service {
    param ($service)
    try {
    Get-Service -Name $service -ErrorAction Stop -ErrorVariable Erreur | Out-Null
    Write-Host "Le Service est présent"
    }
    catch {
    [array]$listErreurs += "$Erreur"
    }
 }