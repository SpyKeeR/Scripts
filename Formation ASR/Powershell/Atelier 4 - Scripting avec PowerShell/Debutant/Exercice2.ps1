$computer_name = $env:COMPUTERNAME
$username = $env:USERNAME
$version_os = (Get-CimInstance Win32_OperatingSystem).Version.ToString()
$date = (Get-Date -Format "dd/MM/yyyy").ToString()
$time = (Get-Date -Format "HH:mm:ss").ToString()

Write-Host "==== INFO SYSTEME ===="
Write-Host "Machine : $computer_name"
Write-Host "Utilisateur : $username"
Write-Host "Version OS : $version_os"
Write-Host "Date : $date"
Write-Host "Heure : $time"