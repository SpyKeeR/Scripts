#
#Creation arborescence AD avec OU, groupes.
#

#Création variable d'entreprise
$societe="_Entreprise"
New-ADOrganizationalUnit $societe -ProtectedFromAccidentalDeletion $false
#Création des OU
$base = Get-ADOrganizationalUnit -Filter { name -like "_Ent*" }
New-ADOrganizationalUnit Groupes -Path $base -ProtectedFromAccidentalDeletion $false
New-ADOrganizationalUnit Utilisateurs -Path $base -ProtectedFromAccidentalDeletion $false
New-ADOrganizationalUnit Ordinateurs -Path $base -ProtectedFromAccidentalDeletion $false
Get-ADOrganizationalUnit -filter * -SearchBase $base | ft name,DistinguishedName -AutoSize

# Création des modèles d'utilisateurs dans chaque OU
$ubase = Get-ADOrganizationalUnit -Filter { name -eq "Utilisateurs" }
$upn = "@ad30.societegb.fr"
# Modeles Direction - Informatique - Utilisateurs
New-ADUser -Name "_mod_dir" -SamAccountName "mod_dir" -Description "Modèle Direction" -City Nantes -PostalCode 44000 -Department Direction -Company "Société GB" -Path $ubase
New-ADUser -Name "_mod_info" -SamAccountName "mod_info" -Description "Modèle Informatique" -City Nantes -PostalCode 44000 -Department Informatique -Company "Société GB" -Path $ubase
New-ADUser -Name "_mod_util" -SamAccountName "mod_util" -Description "Modèle Utilisateurs" -Company "Société GB" -Path $ubase

# Création et Affectation d'un plage horaire d'accés possible pour le modèle des utilisateurs
[byte[]]$hours = @(0,0,0,192,255,15,192,255,15,192,255,15,192,255,15,192,255,15,192,255,15)
Set-ADUser -Identity "mod_util" -Replace @{logonhours = $hours}

# Création de l'utilisateur david selon le modèle de la direction
$mdir = get-aduser -Filter { samaccountname -eq "mod_dir" } -Properties city,postalcode,department,company
$uname = "david"
new-aduser -Instance $mdir -name $uname -givenname $uname -SamAccountName $uname -UserPrincipalName $uname$upn -Path $ubase -OfficePhone "504" -Title "Directeur Comptabilités Finances"

# Création des 2 utilisateurs informatique selon le modèle
$minf = get-aduser -Filter { samaccountname -eq "mod_info" } -Properties city,postalcode,department,company
$unames = @("isabelle","ivan")
foreach ($uname in $unames) {
    new-aduser -Instance $minf -name $uname -givenname $uname -SamAccountName $uname -UserPrincipalName $uname$upn -Path $ubase
}
## Ajout d'attributs (titre/phone) aux utilisateurs Informatique
Set-ADUser -Identity isabelle -Title "Administratrice SR" -OfficePhone "666"
Set-ADUser -Identity ivan -title "Support Technique"

# Création de 2 utilisateurs lambdas
$mutil = get-aduser -Filter { samaccountname -eq "mod_util" } -Properties logonhours,company
$unames = @("christelle","christophe")
foreach ($uname in $unames) {
    new-aduser -Instance $mutil -name $uname -givenname $uname -SamAccountName $uname -UserPrincipalName $uname$upn -Path $ubase
}
## Parametrage d'expiration de compte pour christophe
Set-ADAccountExpiration -Identity "christophe" -DateTime "01/01/2021"

# Affectation d'un mot de passe et activation des comptes d'utilisateurs
$unames = @("david","isabelle","christelle")
$mdp = 'Pa$$w0rd'
 foreach ($uname in $unames) {
   Set-ADAccountPassword $uname -NewPassword (ConvertTo-SecureString -AsPlainText $mdp -force)
   Enable-ADAccount $uname
 }

$unames = @("ivan","christophe")
$mdp = 'Pa$$w0rd'
 foreach ($uname in $unames) {
   Set-ADAccountPassword $uname -NewPassword (ConvertTo-SecureString -AsPlainText $mdp -force)
   Enable-ADAccount $uname
 }

# Création des groupes globaux
$gbase = Get-ADOrganizationalUnit -Filter { name -eq "Groupes" }
New-ADGroup G_Compta -Path $gbase -GroupScope Global -Description "Service Comptabilité"
New-ADGroup G_Direction -Path $gbase -GroupScope Global -Description "Service Direction" `
    -OtherAttributes @{'mail'='direction@societegb.fr'}
New-ADGroup G_Info -Path $gbase -GroupScope Global -Description "Service Informatique"
New-ADGroup G_Info_Tech -Path $gbase -GroupScope Global -Description "Techniciens - Service Informatique"
New-ADGroup G_Interim -Path $gbase -GroupScope Global -Description "Personnel intérimaire"
#Affichage des groupes globaux
Get-ADGroup -Filter { name -like "G_*" } | Format-Table name,DistinguishedName -AutoSize

# Affectation des utilisateurs aux groupes
Add-ADGroupMember G_Compta christelle,christophe
Add-ADGroupMember G_Direction david,mod_dir
Add-ADGroupMember G_Info isabelle,ivan,mod_info
Add-ADGroupMember G_Info_Tech ivan
Add-ADGroupMember G_Interim christophe

# Affichage des membres de tous les groupes globaux
$gg = Get-ADGroup -Filter { name -like "G_*" }
foreach ($group in $gg) {
    $group.Name
    Get-ADGroupMember $group | Format-Table name,DistinguishedName -AutoSize
    }

#OU des services
## Création des OU
$ubase = Get-ADOrganizationalUnit -Filter { name -eq "Utilisateurs" }
New-ADOrganizationalUnit S_Direction -Path $ubase -ProtectedFromAccidentalDeletion $false
New-ADOrganizationalUnit S_Compta -Path $ubase -ProtectedFromAccidentalDeletion $false
New-ADOrganizationalUnit S_Info -Path $ubase -ProtectedFromAccidentalDeletion $false
## Affichage des OU
$base = Get-ADOrganizationalUnit -Filter { name -like "_Ent*" }
Get-ADOrganizationalUnit -filter * -SearchBase $base | ft name,DistinguishedName -AutoSize
## Indiquer l'action
#Move-ADObject

# Log des Membres du groupe global Informatique dans un fichier et de david dans un autre
Get-ADGroupMember G_Info | select name,distinguishedname | Out-File -Encoding utf8 "c:\ctrl_membres_informatique.txt"
Get-ADUser david | out-file -Encoding utf8 "c:\detail_user_david.txt"


#
#Gestion des groupes de domaine local
#

# Création des groupes de domaine local
$gbase = Get-ADOrganizationalUnit -Filter { name -eq "Groupes" }
New-ADGroup DL_Racine_Data_CT -Path $gbase -GroupScope DomainLocal -Description "Racine DATA en CT"
New-ADGroup DL_Racine_Data_M -Path $gbase -GroupScope DomainLocal -Description "Racine DATA en M"
New-ADGroup DL_Racine_Data_L -Path $gbase -GroupScope DomainLocal -Description "Racine DATA en L"
New-ADGroup DL_Data_Doc_CT -Path $gbase -GroupScope DomainLocal -Description "DATA Docs en CT"
New-ADGroup DL_Data_Doc_M -Path $gbase -GroupScope DomainLocal -Description "DATA Docs en M"
New-ADGroup DL_Data_Doc_L -Path $gbase -GroupScope DomainLocal -Description "DATA Docs en L"
New-ADGroup DL_Data_Doc_Refus -Path $gbase -GroupScope DomainLocal -Description "DATA Docs en refus"
New-ADGroup DL_Data_Compta_CT -Path $gbase -GroupScope DomainLocal -Description "DATA Compta en CT"
New-ADGroup DL_Data_Compta_M -Path $gbase -GroupScope DomainLocal -Description "DATA Compta en M"
New-ADGroup DL_Data_Compta_L -Path $gbase -GroupScope DomainLocal -Description "DATA Compa en L"
#
Get-ADGroup -Filter { name -like "DL_*" } | ft name,DistinguishedName -AutoSize

# Création de nouveaux groupe globaux et imbrication de groupes et utilisateurs
New-ADGroup G_Entreprise -Path $gbase -GroupScope Global -Description "Personnel de l'entreprise"
Add-ADGroupMember G_Entreprise G_Compta,G_Direction,G_Info
New-ADGroup G_Info_Adm -Path $gbase -GroupScope Global -Description "Administrateurs - Service Informatique"
Add-ADGroupMember G_Info_Adm isabelle

# Imbrication des groupes globaux dans les groupes de domaine local
Add-ADGroupMember DL_Racine_Data_CT G_Info_Adm
Add-ADGroupMember DL_Data_Doc_L G_Entreprise
Add-ADGroupMember DL_Data_Doc_Refus G_Interim
Add-ADGroupMember DL_Data_Compta_M G_Compta
# Imbrication du Groupe global de Direction dans le groupe de domaine local autorisé a Lire le contenu de la ressource compta
Add-ADGroupMember DL_Data_Compta_L G_Direction

# Création de groupes de domaine local pour la gestion des comptes
New-ADGroup DL_Delegu_Gestion_Comptes_Compta -Path $gbase -GroupScope DomainLocal -Description "Délégation gestion des comptes Compta"
New-ADGroup DL_Delegu_Gestion_Comptes -Path $gbase -GroupScope DomainLocal -Description "Délégation gestion des comptes entreprise - sauf Service Info"
# Création d'un groupe Responsable de Service direction et affectation de l'utilisateur david
New-ADGroup G_Direction_Resp -Path $gbase -GroupScope Global -Description "Responsable - Service Direction"
Add-ADGroupMember G_Direction_Resp david

# Affectation des groupes globaux dans les groupes de domaine local de gestion des comptes
Add-ADGroupMember DL_Delegu_Gestion_Comptes_Compta G_Direction_Resp
Add-ADGroupMember DL_Delegu_Gestion_Comptes G_Info_Tech

