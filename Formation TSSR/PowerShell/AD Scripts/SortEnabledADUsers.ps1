$ADUsers = Get-ADUser -filter *
$UserActifs = New-Object System.Collections.ArrayList
$UserInactifs = New-Object System.Collections.ArrayList
Foreach ($user in $ADUsers)
    {
    if ($user.Enabled -eq $true)
        {
        $UserActifs.Add($user) | Out-Null
        } 
    else
        {
        $UserInactifs.Add($user)| Out-Null
        }
    }
Write-Host "Nombre d'utilisateurs Actifs : $($UserActifs.Count) "
Write-Host "Nombre d'utilisateurs Inactifs : $($UserInactifs.Count) "