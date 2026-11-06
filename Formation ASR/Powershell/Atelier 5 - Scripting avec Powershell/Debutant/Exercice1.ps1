$spooler_status = Get-Service -Name "Spooler" | Select-Object -ExpandProperty Status
Write-Host "Le statut du service Spooler est : $spooler_status"
if ($spooler_status -eq "Running") {
    Write-Host "Le service Spooler est en cours d'exécution."
} else {
    Write-Host "Le service Spooler n'est pas en cours d'exécution."
    Start-Service -Name "Spooler"
    Write-Host "Le service Spooler est en cours de démarrage."
    Start-Sleep -Seconds 5
    $spooler_status = Get-Service -Name "Spooler" | Select-Object -ExpandProperty Status
    if ($spooler_status -eq "Running") {
        Write-Output "Le service Spooler a été démarré avec succès le $(Get-Date -Format 'dd-MM-yyyy HH:mm:ss')." | Tee-Output -FilePath ".\spooler_status.txt" -Append
    } else {
        Write-Host "Le service Spooler n'a pas pu être démarré."
    }
}