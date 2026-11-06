$proc_name = Read-Host "Entrez le nom du processus"
$proc_info = Get-Process -Name $proc_name
if ($proc_info) {
    Write-Host "Informations sur le processus $($proc_info.ProcessName) :"
    Write-Host "ID du processus : $($proc_info.Id)"
    Write-Host "Mémoire utilisée : $($proc_info.WorkingSet / 1MB) MB"
    Write-Host "Utilisation CPU : $($proc_info.CPU)"
    $response = Read-Host "Renseignez Oui/O pour arrêter le processus $($proc_info.ProcessName) ou tout autre pour ne pas l'arrêter"
    if ($response -eq "Oui" -or $response -eq "O") {
            Stop-Process -Id $proc_info.Id -ErrorAction SilentlyContinue
            if ($?) {
                Write-Host "Le processus $($proc_info.ProcessName) a été arrêté avec succès."
            } else {
                Write-Host "Le processus $($proc_info.ProcessName) n'a pas pu être arrêté. (Erreur : $($_.Exception.Message))"
            }
    } else {
        Write-Host "Le processus $($proc_info.ProcessName) n'a pas été arrêté."
    }
} else {
    Write-Host "Processus'$proc_name' introuvable."
}