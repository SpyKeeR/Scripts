try{
    #Encodage UTF-8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    
    #Lecture des variables demandées à l'user
    
    $SMBname = Read-Host "Nom du partage SMB"
    $SMBpath = Read-Host "Chemin du dossier à partager"
    
    #Generation Variable Date Heure
    $date = Get-Date -Format "dd-MM-yyyy"
    $heure = Get-Date -Format "HH:mm:ss"

    #Création du Partage en mode caché selon les valeurs resneignées avec FullAccess aux utilisateurs authentifiés
    New-SmbShare -Name $SMBname"$" -Path $SMBpath -FullAccess "AUTORITE NT\Utilisateurs authentifiés"
}
catch {
    #Message d'erreur execution du script dans console
    Write-Output "---- Une erreur est apparue durant la création du partage caché $SMBname le ${date} à ${heure} ----"
}