#Requires -Modules ActiveDirectory
if (!(Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "Le module ActiveDirectory est introuvable sur ce poste. Installez les outils RSAT (AD DS) puis relancez le script."
    return
}
Import-Module ActiveDirectory

[System.Collections.ArrayList]$erreurs = @()

function Write-Failure {
    param (
        [Parameter(Mandatory = $true)]
        [string]$message,
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$error_record
    )
    $erreurs.Add($error_record) | Out-Null
    Write-Host "Échec : $message"
    Write-Host "Détail : $($error_record.Exception.Message)"
}

function Test-SamAccountName {
    param (
        [string]$sam
    )
    if (!$sam) {
        Write-Host "Erreur : la saisie du nom d'utilisateur est obligatoire."
        return $false
    }
    if ($sam.Length -gt 20) {
        Write-Host "Erreur : le nom d'utilisateur '$sam' dépasse 20 caractères."
        return $false
    }
    if ($sam -notmatch '^[a-zA-Z0-9._-]+$' -or $sam.EndsWith('.')) {
        Write-Host "Erreur : le nom d'utilisateur '$sam' contient des caractères non autorisés (lettres sans accent, chiffres, point, tiret et underscore uniquement, sans point final)."
        return $false
    }
    return $true
}

function Get-ExistingUser {
    param (
        [Parameter(Mandatory = $true)]
        [string]$sam
    )
    try {
        return Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction Stop
    } catch {
        Write-Failure -message "impossible d'interroger l'AD pour le compte '$sam'." -error_record $_
        return $null
    }
}

function Read-ExistingUser {
    $sam = (Read-Host "Renseigner le SamAccountName de l'utilisateur").Trim()
    if (!(Test-SamAccountName -sam $sam)) { return $null }
    $nb_erreurs = $erreurs.Count
    $user = Get-ExistingUser -sam $sam
    if (!$user -and $erreurs.Count -eq $nb_erreurs) { Write-Host "Erreur : le compte '$sam' n'existe pas dans l'AD." }
    return $user
}

function Read-NewPassword {
    $password = Read-Host "Renseigner le mot de passe" -AsSecureString
    if ($password.Length -eq 0) {
        Write-Host "Erreur : la saisie du mot de passe est obligatoire."
        return $null
    }
    return $password
}

function Test-OUPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ou
    )
    try {
        $found_ou = Get-ADOrganizationalUnit -Filter * -ErrorAction Stop | Where-Object { $_.DistinguishedName -eq $ou }
    } catch {
        Write-Failure -message "impossible de vérifier l'OU '$ou'." -error_record $_
        return $false
    }
    if (!$found_ou) {
        Write-Host "Erreur : l'OU '$ou' n'existe pas dans l'AD."
        return $false
    }
    return $true
}

function Test-NewUser {
    param (
        [string]$sam,
        [string]$prenom,
        [string]$nom,
        [string]$ou
    )
    if (!(Test-SamAccountName -sam $sam)) { return $false }
    $nb_erreurs = $erreurs.Count
    if (Get-ExistingUser -sam $sam) {
        Write-Host "Erreur : le compte '$sam' existe déjà dans l'AD."
        return $false
    }
    if ($erreurs.Count -ne $nb_erreurs) { return $false }
    if (!$prenom -or !$nom) {
        Write-Host "Erreur : le prénom et le nom sont obligatoires pour le compte '$sam'."
        return $false
    }
    if ($ou -and !(Test-OUPath -ou $ou)) { return $false }
    return $true
}

function New-UserAccount {
    param (
        [Parameter(Mandatory = $true)]
        [string]$sam,
        [Parameter(Mandatory = $true)]
        [string]$prenom,
        [Parameter(Mandatory = $true)]
        [string]$nom,
        [Parameter(Mandatory = $true)]
        [securestring]$password,
        [string]$ou
    )
    $user_params = @{
        Name            = "$prenom $nom"
        GivenName       = $prenom
        Surname         = $nom
        DisplayName     = "$prenom $nom"
        SamAccountName  = $sam
        AccountPassword = $password
        Enabled         = $true
        ErrorAction     = 'Stop'
    }
    if ($ou) { $user_params.Path = $ou }
    try {
        $user_params.UserPrincipalName = "$sam@$((Get-ADDomain -ErrorAction Stop).DNSRoot)"
        New-ADUser @user_params
        Write-Host "Succès : le compte '$sam' a été créé."
        return $true
    } catch {
        Write-Failure -message "le compte '$sam' n'a pas été créé correctement." -error_record $_
        if (Get-ExistingUser -sam $sam) {
            Write-Host "Attention : le compte '$sam' existe tout de même dans l'AD, probablement désactivé. Vérifiez-le ou supprimez-le."
        }
        return $false
    }
}

function New-UserFromPrompt {
    $sam = (Read-Host "Renseigner le SamAccountName du nouvel utilisateur").Trim()
    if (!(Test-SamAccountName -sam $sam)) { return }
    $prenom = (Read-Host "Renseigner le prénom").Trim()
    $nom = (Read-Host "Renseigner le nom").Trim()
    $ou = (Read-Host "Renseigner le DistinguishedName de l'OU (laisser vide pour le conteneur par défaut)").Trim()
    if (!(Test-NewUser -sam $sam -prenom $prenom -nom $nom -ou $ou)) { return }
    $password = Read-NewPassword
    if (!$password) { return }
    New-UserAccount -sam $sam -prenom $prenom -nom $nom -password $password -ou $ou | Out-Null
}

function New-UserFromCsv {
    Write-Host "Colonnes attendues, séparées par des points-virgules : Prenom;Nom;SamAccountName;MotDePasse;OU (OU facultative)"
    $csv_path = (Read-Host "Renseigner le chemin complet du fichier CSV").Trim().Trim('"')
    if (!$csv_path -or !(Test-Path -Path $csv_path -PathType Leaf)) {
        Write-Host "Erreur : le fichier '$csv_path' n'existe pas."
        return
    }
    try {
        $lignes = @(Import-Csv -Path $csv_path -Delimiter ';' -ErrorAction Stop)
    } catch {
        Write-Failure -message "impossible de lire le fichier '$csv_path'." -error_record $_
        return
    }
    if ($lignes.Count -eq 0) {
        Write-Host "Erreur : le fichier '$csv_path' ne contient aucun utilisateur."
        return
    }
    $colonnes = $lignes[0].PSObject.Properties.Name
    foreach ($colonne in 'Prenom', 'Nom', 'SamAccountName', 'MotDePasse') {
        if ($colonne -notin $colonnes) {
            Write-Host "Erreur : la colonne '$colonne' est absente du fichier CSV."
            return
        }
    }
    $crees = 0
    foreach ($ligne in $lignes) {
        $sam = "$($ligne.SamAccountName)".Trim()
        $prenom = "$($ligne.Prenom)".Trim()
        $nom = "$($ligne.Nom)".Trim()
        $ou = "$($ligne.OU)".Trim()
        if (!(Test-NewUser -sam $sam -prenom $prenom -nom $nom -ou $ou)) { continue }
        if (!$ligne.MotDePasse) {
            Write-Host "Erreur : le mot de passe du compte '$sam' est absent du fichier CSV."
            continue
        }
        $password = ConvertTo-SecureString -String $ligne.MotDePasse -AsPlainText -Force
        if (New-UserAccount -sam $sam -prenom $prenom -nom $nom -password $password -ou $ou) { $crees++ }
    }
    if ($crees -eq $lignes.Count) {
        Write-Host "Succès : $crees compte(s) créé(s) sur $($lignes.Count)."
    } else {
        Write-Host "Échec partiel : $crees compte(s) créé(s) sur $($lignes.Count)."
    }
}

function New-UserMenu {
    Write-Host "1) Créer le compte par saisie"
    Write-Host "2) Créer les comptes par import d'un fichier CSV"
    Write-Host "0) Retour au menu principal"
    $choix_creation = Read-Host "Entrez votre choix (0-2)"
    Switch ($choix_creation)
        {
            '1' { New-UserFromPrompt }
            '2' { New-UserFromCsv }
            '0' { Write-Host "Création annulée." }
            default { Write-Host "Vous avez renseigné un mauvais choix, retour au menu principal." }
        }
}

function Test-UserAccount {
    $user = Read-ExistingUser
    if (!$user) { return }
    Write-Host "Succès : le compte '$($user.SamAccountName)' existe dans l'AD."
    $user | Select-Object SamAccountName, Name, Enabled, DistinguishedName | Format-Table -AutoSize -Wrap | Out-Host
}

function Set-UserPassword {
    $user = Read-ExistingUser
    if (!$user) { return }
    $password = Read-NewPassword
    if (!$password) { return }
    try {
        Set-ADAccountPassword -Identity $user.DistinguishedName -Reset -NewPassword $password -ErrorAction Stop
        Write-Host "Succès : le mot de passe du compte '$($user.SamAccountName)' a été modifié."
    } catch {
        Write-Failure -message "le mot de passe du compte '$($user.SamAccountName)' n'a pas été modifié." -error_record $_
    }
}

function Remove-UserAccount {
    $user = Read-ExistingUser
    if (!$user) { return }
    $confirm = Read-Host "Confirmez-vous la suppression définitive du compte '$($user.SamAccountName)' ? (O/Oui)"
    if ($confirm -ne 'O' -and $confirm -ne 'Oui') {
        Write-Host "Suppression annulée."
        return
    }
    try {
        Remove-ADUser -Identity $user.DistinguishedName -Confirm:$false -ErrorAction Stop
        Write-Host "Succès : le compte '$($user.SamAccountName)' a été supprimé."
    } catch {
        Write-Failure -message "le compte '$($user.SamAccountName)' n'a pas été supprimé." -error_record $_
    }
}

function Show-UserGroups {
    $user = Read-ExistingUser
    if (!$user) { return }
    try {
        $groupes = @(Get-ADPrincipalGroupMembership -Identity $user.DistinguishedName -ErrorAction Stop)
    } catch {
        Write-Failure -message "impossible d'afficher les groupes du compte '$($user.SamAccountName)'." -error_record $_
        return
    }
    if ($groupes.Count -eq 0) {
        Write-Host "Le compte '$($user.SamAccountName)' n'appartient à aucun groupe."
        return
    }
    Write-Host "Groupes du compte '$($user.SamAccountName)' :"
    $groupes | Select-Object Name, GroupCategory, GroupScope | Format-Table -AutoSize -Wrap | Out-Host
}

function Export-UserAccounts {
    $export_path = (Read-Host "Renseigner le chemin complet du répertoire d'export (ex: C:\Temp\)").Trim().Trim('"')
    if (!$export_path -or !(Test-Path -Path $export_path -PathType Container)) {
        Write-Host "Erreur : le répertoire '$export_path' n'existe pas."
        return
    }
    $export_file = Join-Path -Path $export_path -ChildPath "Utilisateurs_AD_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    try {
        $users = @(Get-ADUser -Filter * -ErrorAction Stop)
        $users | Select-Object SamAccountName, Name, GivenName, Surname, Enabled, DistinguishedName | Export-Csv -Path $export_file -Delimiter ';' -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
        Write-Host "Succès : $($users.Count) compte(s) exporté(s) dans $export_file."
    } catch {
        Write-Failure -message "l'export des comptes utilisateurs n'a pas abouti." -error_record $_
    }
}

function Show-SessionErrors {
    if ($erreurs) {
        Write-Host "$($erreurs.Count) erreur(s) enregistrée(s) durant la session :"
        $erreurs | ForEach-Object { Write-Host "- $($_.Exception.Message)" }
    }
}

:menu While ($true)
    {
    Write-Host "Bienvenue dans l'outil d'administration des utilisateurs AD, faites votre choix parmi les menus suivants :"
    Write-Host "1) Créer un compte utilisateur (saisie ou import CSV)"
    Write-Host "2) Vérifier l'existence d'un compte utilisateur"
    Write-Host "3) Changer le mot de passe d'un utilisateur"
    Write-Host "4) Supprimer un compte utilisateur"
    Write-Host "5) Afficher les appartenances d'un utilisateur à des groupes"
    Write-Host "6) Exporter les comptes utilisateurs dans un fichier CSV"
    Write-Host "0) Quitter"
    Write-Host ""
    $choix = Read-Host "Entrez votre choix (0-6)"
    Switch ($choix)
        {
            '1' { New-UserMenu }
            '2' { Test-UserAccount }
            '3' { Set-UserPassword }
            '4' { Remove-UserAccount }
            '5' { Show-UserGroups }
            '6' { Export-UserAccounts }
            '0' { Show-SessionErrors ; Write-Host "Vous quittez l'outil d'administration des utilisateurs AD" ; break menu }
            default { Write-Host "Vous avez renseigné un mauvais choix dans le menu, veuillez re-essayer" }
        }
    }
