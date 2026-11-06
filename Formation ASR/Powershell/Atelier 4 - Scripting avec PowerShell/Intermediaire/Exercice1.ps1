$nom_projet = Read-Host "Entrez le nom du projet"
$version_projet = Read-Host "Entrez la version du projet"
$description_projet = Read-Host "Entrez la description du projet"
$dossier_parent = "C:\Projets"
$dossier_projet = Join-Path -Path $dossier_parent -ChildPath $nom_projet
$dossier_version = Join-Path -Path $dossier_projet -ChildPath $version_projet

Write-Host "Création du projet '$nom_projet' version '$version_projet' dans le dossier '$dossier_parent'..."
New-Item -Path $dossier_projet -ItemType Directory -Force | Out-Null
New-Item -Path $dossier_version -ItemType Directory -Force | Out-Null
Write-Host "Création du fichier README.txt..."
$readme_path = Join-Path -Path $dossier_version -ChildPath "README.txt"
$readme_content = @"
Projet : $nom_projet
Version : $version_projet
Description : $description_projet
"@
Write-Host "Écriture du fichier README.txt..."
Set-Content -Path $readme_path -Value $readme_content
Write-Host "Projet '$nom_projet' version '$version_projet' créé avec succès dans le dossier '$dossier_version'."