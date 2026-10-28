[cmdletbinding(DefaultParameterSetName="ByPath")]
param(
    [parameter(Mandatory=$true, ParameterSetName="ByPath")][ValidateNotNullOrEmpty()][string] $Path
    , [parameter(Mandatory=$true, ParameterSetName="ByPipe", ValueFromPipeline=$true, Position=0)][ValidateNotNullOrEmpty()][string[]] $RawText
)

#region Configuration - Variables à modifier selon vos besoins
# Nom du fichier CSV de sortie
$OutputFile = ".\test.csv"

# Encodage des fichiers (entrée et sortie)
$FileEncoding = "UTF8"

# Délimiteur CSV (point-virgule pour compatibilité Excel France)
$CsvDelimiter = ";"

# Filtrer uniquement les services avec une adresse email
$FilterByEmail = $true
#endregion

#region Traitement

# Structure JSON attendue :
# - "service" : tableau d'objets représentant les services/organismes
#   Chaque service contient :
#   - "nom" : nom du service (chaîne de caractères)
#   - "adresse_courriel" : tableau d'emails (peut être vide)
#   - "adresse" : tableau d'objets adresse
#     Chaque adresse contient :
#     - "code_postal" : code postal (chaîne)
#     - "numero_voie", "nom_commune", etc.

# If ByPath is the entry point, check that the specified file actually exists.
if ($Path)
{
    if (Test-Path -Path $Path)
    {
        # Lecture du fichier JSON avec l'encodage approprié pour gérer les accents
        $services = (Get-Content -Path $Path -Raw -Encoding $FileEncoding | ConvertFrom-Json).service
        
        # Filtrage optionnel : ne garder que les services ayant au moins une adresse email
        if ($FilterByEmail) {
            $services = $services | Where-Object { $_.adresse_courriel -and $_.adresse_courriel.Count -gt 0 }
        }
        
        # Transformation des données en objets CSV
        $services | ForEach-Object {
            [PSCustomObject]@{
                # Accès au code postal de la première adresse (objet enfant dans le tableau "adresse")
                # Utilisation de [0] car "adresse" est un tableau qui peut contenir plusieurs adresses
                code_postal = $_.adresse[0].code_postal
                nom = $_.nom
                # Join des emails avec virgule car "adresse_courriel" est un tableau
                adresse_courriel = $_.adresse_courriel -join ', '
            }
        } | ConvertTo-Csv -NoTypeInformation -Delimiter $CsvDelimiter | Out-File -FilePath $OutputFile -Encoding $FileEncoding
    }
    else
    {
        throw [System.IO.FileNotFoundException]::new();
    }

}
else
{
    # Même traitement pour les données provenant du pipeline (paramètre -RawText)
    $services = ($RawText | ConvertFrom-Json).service
    
    if ($FilterByEmail) {
        $services = $services | Where-Object { $_.adresse_courriel -and $_.adresse_courriel.Count -gt 0 }
    }
    
    $services | ForEach-Object {
        [PSCustomObject]@{
            code_postal = $_.adresse[0].code_postal
            nom = $_.nom
            adresse_courriel = $_.adresse_courriel -join ', '
        }
    } | ConvertTo-Csv -NoTypeInformation -Delimiter $CsvDelimiter | Out-File -FilePath $OutputFile -Encoding $FileEncoding
}
#endregion