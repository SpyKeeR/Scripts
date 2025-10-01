<#
.SYNOPSIS
    Outil d'import / création / mise à jour d'utilisateurs Active Directory à partir d'un CSV.
    - Dry-run (tir à blanc)
    - Vérifications : module AD, droits, OU, attributs schema, CSV lisible
    - Journalisation et reporting (créés / mis à jour / erreurs)
    - Menu interactif pour paramétrer tout ça

.USAGE
    Exécuter dans une session PowerShell élevée (Run as Administrator).
    Tester d'abord en mode "Tir à blanc" (DryRun = $true).
#>

# ===================== Config initiale =====================
# Emplacement des logs (modifiable)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LogDir = Join-Path $ScriptDir "Logs"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }

$LogFile = Join-Path $LogDir ("run_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date))
$ReportCreated = Join-Path $LogDir "created_{0:yyyyMMdd_HHmmss}.csv" -f (Get-Date)
$ReportUpdated = Join-Path $LogDir "updated_{0:yyyyMMdd_HHmmss}.csv" -f (Get-Date)
$ReportErrors  = Join-Path $LogDir "errors_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date)

# Structure des paramètres modifiables via le menu
$Settings = @{
    CSVPath           = ""
    CSVDelimiter      = ";"
    OU                = ""         # DN de l'OU cible, ex: "OU=Users,DC=ad01,DC=lcl"
    DomainController  = ""         # ex: "ad01.ad01.lcl" ou domaine "ad01.lcl"
    Domain            = ""         # ex: "ad01.lcl"
    GroupsDefault     = @()        # groupes à ajouter par défaut (samAccountName)
    CustomAttr1       = ""         # nom ldapDisplayName de l'attribut 1 (ex: myAppId)
    CustomAttr2       = ""         # nom ldapDisplayName de l'attribut 2 (ex: myAppNumber)
    UPNSuffix         = ""         # suffixe UPN ex: "@entreprise.local"
    ForcePwdChange    = $true
    DefaultPassword   = "P@ssw0rd123!"  # changer en prod
    DryRun            = $true
    MailboxScriptPath = ""         # chemin vers le script qui créera la BAL
}

# Collections de reporting
$CreatedList = @()
$UpdatedList = @()
$ErrorList = @()

# ===================== Fonctions utilitaires =====================
function Write-Log {
    param($Message, $Level = "INFO")
    $line = ("[{0:yyyy-MM-dd HH:mm:ss}] [{1}] {2}" -f (Get-Date), $Level, $Message)
    $line | Tee-Object -FilePath $LogFile -Append | Out-Null
}

function Write-ErrorLog {
    param($Message)
    $Message | Tee-Object -FilePath $ReportErrors -Append | Out-Null
    $global:ErrorList += $Message
    Write-Log $Message "ERROR"
}

function Pause-Confirm {
    param($Message="Appuyez sur Entrée pour continuer...")
    Read-Host $Message | Out-Null
}

# ===================== Vérifications initiales =====================
function Ensure-ADModule {
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        Write-Log "Module ActiveDirectory chargé."
        return $true
    } catch {
        Write-ErrorLog "Module ActiveDirectory introuvable. Installer RSAT/AD-PowerShell."
        return $false
    }
}

function Is-CurrentUser-Privileged {
    # Vérifie si l'utilisateur courant est membre d'un groupe administratif fréquent
    try {
        $me = "$($env:USERDOMAIN)\$($env:USERNAME)"
        $groups = Get-ADPrincipalGroupMembership -Identity $me -ErrorAction Stop
        $names = $groups.Name
        if ($names -contains "Domain Admins" -or $names -contains "Enterprise Admins" -or $names -contains "Administrators" -or $names -contains "Account Operators") {
            Write-Log "Utilisateur courant ($me) appartient à un groupe privilégié: $($names -join ', ')"
            return $true
        } else {
            Write-Log "Utilisateur courant ($me) ne semble pas être membre explicite d'un groupe privilégié."
            return $false
        }
    } catch {
        Write-ErrorLog "Impossible de vérifier l'appartenance aux groupes pour l'utilisateur courant. $_"
        return $false
    }
}

function Test-OUExists {
    param($OUdn, $Server = $null)
    try {
        if ([string]::IsNullOrWhiteSpace($OUdn)) { return $false }
        $params = @{Identity = $OUdn; ErrorAction = 'Stop'}
        if ($Server) { $params.Server = $Server }
        $ou = Get-ADOrganizationalUnit @params
        return $true
    } catch {
        return $false
    }
}

function Test-CustomAttributeExists {
    param($AttrName, $Server = $null)
    # Cherche l'attribut dans la partition schema
    try {
        $root = Get-ADRootDSE -ErrorAction Stop
        $schemaBase = $root.schemaNamingContext
        $params = @{SearchBase = $schemaBase; LDAPFilter = "(ldapDisplayName=$AttrName)"; ErrorAction = 'Stop'}
        if ($Server) { $params.Server = $Server }
        $res = Get-ADObject @params
        if ($res) {
            Write-Log "Attribut schema '$AttrName' trouvé."
            return $true
        } else { return $false }
    } catch {
        Write-Log "Erreur pendant la vérification du schema pour l'attribut '$AttrName' : $_"
        return $false
    }
}

function Ensure-AttributeOnUser {
    param(
        [Parameter(Mandatory)][string]$UserDNorSam,
        [Parameter(Mandatory)][string]$AttrName,
        [Parameter(Mandatory)]$Value,
        [bool]$IsReplace = $true,
        [switch]$WhatIf
    )
    try {
        # Build the replace/clear hashtable
        $hash = @{}
        $hash[$AttrName] = $Value

        $params = @{Identity = $UserDNorSam; Replace = $hash; ErrorAction = 'Stop'}
        if ($WhatIf) { $params.Add('WhatIf',$true) }
        Set-ADUser @params
        Write-Log "Attrib '$AttrName' défini sur $UserDNorSam => $Value"
        return $true
    } catch {
        Write-ErrorLog "Erreur ajout attribut '$AttrName' sur '$UserDNorSam' : $_"
        return $false
    }
}

# ===================== Chargement et parsing CSV =====================
function Prompt-Settings {
    Write-Host "=== Configuration initiale ===" -ForegroundColor Cyan
    $Settings.CSVPath = Read-Host "Chemin vers le CSV (ex: \\CD01\Partage\Exports\CSV\users.csv)"
    $Settings.CSVDelimiter = Read-Host "Délimiteur CSV (par défaut ';')" ; if (-not $Settings.CSVDelimiter) { $Settings.CSVDelimiter = ";" }
    $Settings.OU = Read-Host "DN de l'OU de destination (ex: OU=Users,DC=ad01,DC=lcl)"
    $Settings.DomainController = Read-Host "Contrôleur de domaine / server (laisser vide pour défaut)"
    $Settings.Domain = Read-Host "FQDN du domaine (ex: ad01.lcl)"
    $groups = Read-Host "Groupes par défaut (séparés par une virgule, samAccountName)"
    if ($groups) { $Settings.GroupsDefault = $groups.Split(',') | ForEach-Object { $_.Trim() } }
    $Settings.CustomAttr1 = Read-Host "Nom LDAP (ldapDisplayName) attribut personnalisé 1 (ex: myAppId)"
    $Settings.CustomAttr2 = Read-Host "Nom LDAP attribut personnalisé 2 (ex: myAppNumber)"
    $Settings.UPNSuffix = Read-Host "Suffixe UPN (ex: @entreprise.local)"
    $Settings.ForcePwdChange = Read-Host "Demander changement mot de passe à la 1ere connexion ? (y/n)" 
    $Settings.ForcePwdChange = $Settings.ForcePwdChange -match '^(y|Y)'
    $pwd = Read-Host "Mot de passe par défaut (utiliser un mot de passe fort)"; if ($pwd) { $Settings.DefaultPassword = $pwd }
    $Settings.DryRun = Read-Host "Mode tir à blanc (Doit être true pour tests) (y/n)"; $Settings.DryRun = $Settings.DryRun -match '^(y|Y)'
    $Settings.MailboxScriptPath = Read-Host "Chemin script création BAL (laisser vide si pas utilisé)"
}

function Validate-Settings {
    Write-Host "Validation des paramètres..." -ForegroundColor Cyan
    $ok = $true
    if (-not (Test-Path $Settings.CSVPath)) {
        Write-ErrorLog "CSV introuvable : $($Settings.CSVPath)"
        $ok = $false
    } else {
        try { Import-Csv -Path $Settings.CSVPath -Delimiter $Settings.CSVDelimiter -ErrorAction Stop | Out-Null; Write-Log "CSV lisible"; } catch { Write-ErrorLog "CSV non lisible : $_"; $ok = $false }
    }

    if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }

    if (-not (Test-ADModule)) { $ok = $false }

    if (-not (Is-CurrentUser-Privileged)) {
        Write-Host "ATTENTION: l'utilisateur courant ne semble pas disposer de droits admin. Le script peut échouer." -ForegroundColor Yellow
        Write-Log "Attention : pas de droits admin détectés."
    }

    # Test OU
    if (-not (Test-OUExists -OUdn $Settings.OU -Server $Settings.DomainController)) {
        Write-ErrorLog "OU introuvable : $($Settings.OU)"
        $ok = $false
    }

    # Test custom attrs existing in schema (si fournis)
    foreach ($attr in @($Settings.CustomAttr1, $Settings.CustomAttr2) | Where-Object {$_ -and $_.Trim() -ne ""}) {
        if (-not (Test-CustomAttributeExists -AttrName $attr -Server $Settings.DomainController)) {
            Write-Log "ATENTION : L'attribut schema '$attr' semble absent. Il faudra le créer via ADSIEdit si nécessaire."
            # On ne bloque pas automatiquement, mais on avertit
        }
    }

    return $ok
}

function Load-CSVData {
    try {
        $csv = Import-Csv -Path $Settings.CSVPath -Delimiter $Settings.CSVDelimiter -ErrorAction Stop
        Write-Log "Import CSV : $($csv.Count) lignes."
        return $csv
    } catch {
        Write-ErrorLog "Erreur import CSV : $_"
        return $null
    }
}

# ===================== Prévisualisation / Planification =====================
function Preview-Plan {
    param($csvData)
    $plan = @()
    foreach ($row in $csvData) {
        # Attendu : CSV doit contenir au minimum SamAccountName, GivenName, Surname
        $sam = $row.SamAccountName
        if (-not $sam) { $sam = ($row.GivenName + '.' + $row.Surname).ToLower().Replace(' ','') }
        try {
            $existing = Get-ADUser -Filter "SamAccountName -eq '$sam'" -Server $Settings.DomainController -ErrorAction SilentlyContinue
        } catch { $existing = $null }
        $action = if ($existing) { "Update" } else { "Create" }
        $plan += [PSCustomObject]@{SamAccountName=$sam; Action=$action; GivenName=$row.GivenName; Surname=$row.Surname; Source=$row}
    }

    # Affiche résumé
    $plan | Group-Object Action | ForEach-Object { Write-Host ("{0}: {1}" -f $_.Name, $_.Count) }
    Write-Host ""
    $plan | Format-Table SamAccountName, Action, GivenName, Surname -AutoSize
    return $plan
}

# ===================== Création / Mise à jour d'un user =====================
function CreateOrUpdate-User {
    param(
        [Parameter(Mandatory)][psobject]$Row,
        [switch]$WhatIf
    )
    $sam = $Row.SamAccountName
    if (-not $sam) { $sam = (($Row.GivenName) + '.' + ($Row.Surname)).ToLower().Replace(' ','') }
    $displayName = if ($Row.DisplayName) { $Row.DisplayName } else { "$($Row.GivenName) $($Row.Surname)" }
    $upn = if ($Row.UserPrincipalName) { $Row.UserPrincipalName } elseif ($Settings.UPNSuffix) { $sam + $Settings.UPNSuffix } else { $null }

    try {
        $existing = Get-ADUser -Filter "SamAccountName -eq '$sam'" -Server $Settings.DomainController -ErrorAction SilentlyContinue
    } catch {
        $existing = $null
    }

    if ($existing) {
        # Update path
        Write-Log "Mise à jour de l'utilisateur existant : $sam"
        try {
            $setParams = @{
                Identity = $existing.DistinguishedName
                ErrorAction = 'Stop'
            }
            if ($Row.GivenName) { $setParams['GivenName'] = $Row.GivenName }
            if ($Row.Surname)   { $setParams['Surname'] = $Row.Surname }
            if ($displayName)   { $setParams['DisplayName'] = $displayName }
            if ($upn)           { $setParams['UserPrincipalName'] = $upn }
            if ($Row.Title)     { $setParams['Title'] = $Row.Title }
            if ($Row.Department) { $setParams['Department'] = $Row.Department }
            if ($Row.Office)    { $setParams['Office'] = $Row.Office }
            # Add -WhatIf if asked
            if ($WhatIf) { $setParams['WhatIf'] = $true }
            Set-ADUser @setParams
            # Custom attributes
            if ($Settings.CustomAttr1 -and $Row.CustomAttr1) { Ensure-AttributeOnUser -UserDNorSam $existing.DistinguishedName -AttrName $Settings.CustomAttr1 -Value $Row.CustomAttr1 -WhatIf:$WhatIf }
            if ($Settings.CustomAttr2 -and $Row.CustomAttr2) { Ensure-AttributeOnUser -UserDNorSam $existing.DistinguishedName -AttrName $Settings.CustomAttr2 -Value $Row.CustomAttr2 -WhatIf:$WhatIf }
            # Groups
            foreach ($g in $Settings.GroupsDefault) {
                try {
                    if ($WhatIf) {
                        Write-Host "(WhatIf) Add-ADGroupMember -Identity $g -Members $existing.SamAccountName"
                    } else {
                        Add-ADGroupMember -Identity $g -Members $existing.SamAccountName -ErrorAction Stop -Confirm:$false
                        Write-Log "Ajouté $($existing.SamAccountName) au groupe $g"
                    }
                } catch {
                    Write-ErrorLog "Erreur ajout $($existing.SamAccountName) au groupe $g : $_"
                }
            }
            $global:UpdatedList += $existing.SamAccountName
            return "Updated"
        } catch {
            Write-ErrorLog "Erreur update user $sam : $_"
            return "Error"
        }
    } else {
        # Create path
        Write-Log "Création utilisateur : $sam"
        try {
            # Build params for New-ADUser
            $securePwd = ConvertTo-SecureString -String $Settings.DefaultPassword -AsPlainText -Force
            $createParams = @{
                Name = $displayName
                SamAccountName = $sam
                GivenName = $Row.GivenName
                Surname = $Row.Surname
                DisplayName = $displayName
                Path = $Settings.OU
                AccountPassword = $securePwd
                Enabled = $true
                ChangePasswordAtLogon = $Settings.ForcePwdChange
                ErrorAction = 'Stop'
            }
            if ($upn) { $createParams['UserPrincipalName'] = $upn }
            if ($Row.Title) { $createParams['Title'] = $Row.Title }
            if ($Row.Department) { $createParams['Department'] = $Row.Department }
            if ($Row.Office) { $createParams['Office'] = $Row.Office }
            if ($WhatIf) { $createParams['WhatIf'] = $true }

            New-ADUser @createParams
            # After creation set custom attributes and group membership
            if (-not $WhatIf) {
                # Re-fetch user
                $newUser = Get-ADUser -Filter "SamAccountName -eq '$sam'" -Properties * -ErrorAction Stop
            } else {
                $newUser = [PSCustomObject]@{ SamAccountName = $sam; DistinguishedName = "CN=$displayName,$($Settings.OU)" }
            }

            if ($Settings.CustomAttr1 -and $Row.CustomAttr1) { Ensure-AttributeOnUser -UserDNorSam $newUser.DistinguishedName -AttrName $Settings.CustomAttr1 -Value $Row.CustomAttr1 -WhatIf:$WhatIf }
            if ($Settings.CustomAttr2 -and $Row.CustomAttr2) { Ensure-AttributeOnUser -UserDNorSam $newUser.DistinguishedName -AttrName $Settings.CustomAttr2 -Value $Row.CustomAttr2 -WhatIf:$WhatIf }

            foreach ($g in $Settings.GroupsDefault) {
                try {
                    if ($WhatIf) {
                        Write-Host "(WhatIf) Add-ADGroupMember -Identity $g -Members $sam"
                    } else {
                        Add-ADGroupMember -Identity $g -Members $sam -ErrorAction Stop -Confirm:$false
                        Write-Log "Ajouté $sam au groupe $g"
                    }
                } catch {
                    Write-ErrorLog "Erreur ajout $sam au groupe $g : $_"
                }
            }

            # Mailbox creation hook (call external script if specified)
            if ($Settings.MailboxScriptPath) {
                if ($WhatIf) {
                    Write-Host "(WhatIf) Appel script création mailbox: $($Settings.MailboxScriptPath) pour $sam"
                } else {
                    try {
                        & $Settings.MailboxScriptPath -SamAccountName $sam -Email $Row.Email -WhatIf:$false
                        Write-Log "Appel script BAL pour $sam"
                    } catch {
                        Write-ErrorLog "Erreur appel script BAL pour $sam : $_"
                    }
                }
            }

            $global:CreatedList += $sam
            return "Created"
        } catch {
            Write-ErrorLog "Erreur création user $sam : $_"
            return "Error"
        }
    }
}

# ===================== Exécution (boucle principale) =====================
function Execute-Import {
    param(
        [switch]$WhatIf
    )
    Write-Log "Début d'exécution. Mode WhatIf=$WhatIf"
    $csv = Load-CSVData
    if (-not $csv) { Write-ErrorLog "CSV vide ou non lisible. Arrêt."; return }

    $plan = Preview-Plan -csvData $csv

    Write-Host "`nRésumé :"
    Write-Host "Créations prévues: $($plan | Where-Object {$_.Action -eq 'Create'} | Measure-Object).Count"
    Write-Host "Mises à jour prévues: $($plan | Where-Object {$_.Action -eq 'Update'} | Measure-Object).Count"

    $confirm = Read-Host "Confirmez-vous l'exécution ? (oui/non)"
    if ($confirm -notmatch '^(o|O|y|Y|oui|yes)$') {
        Write-Log "Exécution annulée par l'utilisateur."
        return
    }

    # Optionnel : sauvegarde AD (on avertit, ne force pas)
    $doBackup = Read-Host "Souhaitez-vous déclencher une sauvegarde système (wbadmin) avant exécution ? (y/n)"
    if ($doBackup -match '^(y|Y)') {
        Write-Host "Lancement sauvegarde système... (Attention: demande des droits et configuration WB)"
        Write-Log "Utilisateur a demandé une sauvegarde système. (Non implémentée automatiquement par sécurité dans ce script)"
        # Ici on ne lance pas automatiquement la sauvegarde, on avertit
    }

    foreach ($row in $csv) {
        # pour robustesse, on catch au niveau boucle
        try {
            CreateOrUpdate-User -Row $row -WhatIf:($WhatIf)
        } catch {
            Write-ErrorLog "Erreur générale sur la ligne SamAccountName=$($row.SamAccountName) : $_"
        }
    }

    # Reporting final
    Write-Log "Execution terminée. Créés : $($CreatedList.Count). Mis à jour : $($UpdatedList.Count). Erreurs : $($ErrorList.Count)"
    if ($CreatedList.Count -gt 0) {
        $CreatedList | Export-Csv -Path $ReportCreated -NoTypeInformation -Force
        Write-Log "Liste des créés exportée: $ReportCreated"
    }
    if ($UpdatedList.Count -gt 0) {
        $UpdatedList | Export-Csv -Path $ReportUpdated -NoTypeInformation -Force
        Write-Log "Liste des mis à jour exportée: $ReportUpdated"
    }
    if ($ErrorList.Count -gt 0) {
        Write-Log "Erreurs enregistrées: $ReportErrors"
    }

    Write-Host "Terminé. Voir logs: $LogFile"
}

# ===================== Menu =====================
function Show-Menu {
    Clear-Host
    Write-Host "=== Outil import AD (CSV) ===" -ForegroundColor Cyan
    Write-Host "1) Configurer les paramètres"
    Write-Host "2) Valider les paramètres et pré-tests"
    Write-Host "3) Charger et pré-visualiser le plan (sans exécution)"
    Write-Host "4) Exécuter (mode tir à blanc / WhatIf)"
    Write-Host "5) Exécuter (mode réel) - ATTENTION: Actions irréversibles"
    Write-Host "6) Quitter"
    $choice = Read-Host "Choisissez une option (1-6)"
    return $choice
}

# ===================== Boot menu loop =====================
if (-not (Ensure-ADModule)) {
    Write-Host "Module ActiveDirectory requis. Installez RSAT. Sortie." -ForegroundColor Red
    exit 1
}

do {
    $choice = Show-Menu
    switch ($choice) {
        '1' {
            Prompt-Settings
            Write-Log "Paramètres mis à jour via menu."
            Pause-Confirm
        }
        '2' {
            if (Validate-Settings) { Write-Host "Validation OK" -ForegroundColor Green } else { Write-Host "Validation échouée. Voir logs." -ForegroundColor Red }
            Pause-Confirm
        }
        '3' {
            if (-not (Validate-Settings)) { Write-Host "Validation échouée, corrigez les paramètres." -ForegroundColor Red; Pause-Confirm; continue }
            $csv = Load-CSVData
            if ($csv) {
                $plan = Preview-Plan -csvData $csv
            }
            Pause-Confirm
        }
        '4' {
            if (-not (Validate-Settings)) { Write-Host "Validation échouée, corrigez les paramètres." -ForegroundColor Red; Pause-Confirm; continue }
            $Settings.DryRun = $true
            Execute-Import -WhatIf
            Pause-Confirm
        }
        '5' {
            if (-not (Validate-Settings)) { Write-Host "Validation échouée, corrigez les paramètres." -ForegroundColor Red; Pause-Confirm; continue }
            Write-Host "!!! MODE REEL !!! Ne lancez ceci qu'après tests et sauvegardes." -ForegroundColor Red
            $ok = Read-Host "Confirmez exécution réelle (tapez OUI pour continuer)"
            if ($ok -ne "OUI") { Write-Host "Abandon."; Pause-Confirm; continue }
            $Settings.DryRun = $false
            Execute-Import -WhatIf:$false
            Pause-Confirm
        }
        '6' {
            Write-Host "Sortie..."
        }
        default {
            Write-Host "Choix invalide."
            Pause-Confirm
        }
    }
} while ($choice -ne '6')

Write-Log "Script terminé par l'utilisateur."
Write-Host "Logs: $LogFile"
