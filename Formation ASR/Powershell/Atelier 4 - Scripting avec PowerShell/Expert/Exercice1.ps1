[System.Collections.ArrayList]$Users_AD_List = @()

Write-Host "Liste des utilisateurs dans l'Active Directory :"
Get-ADUser -Filter * | Select-Object SamAccountName | Format-Wide -Column 5 | Out-Host

$ad_user_choice = Read-Host "Veuillez saisir deux sAMAccountName séparés par une virgule (ex: user1,user2)"
$ad_user_choice_array = $ad_user_choice.Split(",").Trim()

$user1 = Get-ADUser -Identity $ad_user_choice_array[0] | Select-Object SamAccountName,Enabled
$user2 = Get-ADUser -Identity $ad_user_choice_array[1] | Select-Object SamAccountName,Enabled

[void]$Users_AD_List.Add($user1)
[void]$Users_AD_List.Add($user2)

Write-host "Utilisateurs sélectionnés :"
$Users_AD_List | Format-Table -AutoSize | Out-Host

$actions = @{
    Activer  = "Enable-ADAccount"
    Desactiver = "Disable-ADAccount"
    Deverouiller  = "Unlock-ADAccount"
}

[int]$index = Read-Host "Choisir l'utilisateur (0 = $($Users_AD_List[0].SamAccountName) / 1 = $($Users_AD_List[1].SamAccountName))"
$user_cible = $Users_AD_List[$index]
$action = Read-Host "Choisir une action ($($actions.Keys -join ' / '))"
& $actions[$action] -Identity $user_cible.SamAccountName
Write-Host "Action $action exécutée sur l'utilisateur $($user_cible.SamAccountName)."
Get-ADUser -Identity $user_cible.SamAccountName -Properties LockedOut | Select-Object SamAccountName,Enabled,LockedOut