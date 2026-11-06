$user = $env:USERNAME
$date = (Get-Date -Format "dd/MM/yyyy").ToString()
$time = (Get-Date -Format "HH:mm:ss").ToString()
Write-Host "Bienvenue $user, nous sommes le $date à $time."