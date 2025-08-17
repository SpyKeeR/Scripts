$ADUsers = Get-ADUser -Filter { Name -ne "Administrator" -and Name -ne "Guest" -and Name -ne "krbtgt" }
$pw = Read-Host "Entrez le mot de passe à affecter pour tous les utilisateurs "
foreach ($user in $ADUsers)
    {
    Set-ADAccountPassword -Identity $user.SamAccountName -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "$pw" -Force)
    if ( $user.Enabled -eq $false )
        {
        Set-AdUser $user.SamAccountName -Enabled $true
        }
    }