[int] $i=-1
$random_list_services = Get-Service | Select-Object Name,Status | Get-Random -Count 6
Write-Host "==== SERVICES ===="
Write-Host "Liste aléatoire de 6 services est :"
$random_list_services | Format-Table @{N="N°";E={ $script:i++ ; $i }},Name,Status -AutoSize
$selected_service = Read-Host "Pour quel N° de service souhaitez-vous exporter ses informations ? (1-6)"
Export-CSV -Path ".\services.csv" -NoTypeInformation -Append -InputObject $random_list_services[$selected_service - 1]
Write-Host "Le fichier services.csv a été créé avec succès et se trouve ici : $(Get-Location)\services.csv"