#Script de sauvegarde.
#Version 1.1
#Date 22/01/2025

try{
    #Encodage UTF-8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    CHCP 65001

    #Generation Variable User Date Heure
    $utilisateur = $env:USERNAME
    $date = Get-Date -Format "dd-MM-yyyy"
    $heure = Get-Date -Format "HH:mm:ss"

    #Sauvegarde Robocopy verbeux avec log
    robocopy C:\Users\$utilisateur\Documents E:\Sauvegarde\$utilisateur\ /S /E /B /XJ /TEE /LOG+:E:\Sauvegarde\$utilisateur\JournalScriptSauvegarde.log
    
    #Message de confirmation execution robocopy dans console et log fichier
    Write-Output "---- Exécution de la sauvegarde réussie le ${date} à ${heure} ----" | Out-String | Add-Content E:\Sauvegarde\$utilisateur\JournalScriptSauvegarde.log -PassThru
}
catch {
    #Message d'erreur execution robocopy dans console et log fichier
    Write-Output "---- Une erreur est apparue durant le lancement de la sauvegarde le ${date} à ${heure} ----" | Out-String | Add-Content E:\Sauvegarde\$utilisateur\JournalScriptSauvegarde.log -PassThru
}