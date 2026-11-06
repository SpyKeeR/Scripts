#Requires -Modules ActiveDirectory
if (!(Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "Le module ActiveDirectory est introuvable sur ce poste. Installez les outils RSAT (AD DS) puis relancez le script."
    return
}
Import-Module ActiveDirectory

[System.Collections.ArrayList]$computers = @()
[System.Collections.ArrayList]$logObject = @()
function Write-Log {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$log_message,
        [Parameter(Mandatory = $true)]
        [string]$computer_name,
        [Parameter(Mandatory = $true)]
        [string]$action,
        [Parameter(Mandatory = $true)]
        [string]$result
    )
    process {
        if ($result -eq "0") {
            $result = "Succès"
        } elseif ($result -eq "1") {
            $result = "Échec"
        }
        $log_entry = "$(Get-Date -Format 'dd-MM-yyyy HH:mm:ss') - Ordinateur : $computer_name | Action : $action | Résultat : $result | Message : $log_message"
        $logObject.Add($log_entry) | Out-Null
        Write-Host $log_message
    }
}

function Get-OUName {
    param (
        [Parameter(Mandatory = $true)]
        [string]$distinguished_name
    )
    $parent = ($distinguished_name -split ',', 2)[1]
    return (($parent -split ',')[0] -replace '^(OU|CN|DC)=', '')
}

:menu While ($true)
    {
    Write-Host "Bienvenue dans l'outil de gestion des ordinateurs du domaine, faites votre choix parmi les menus suivants :"
    Write-Host "1) Afficher le nom, l'OU et l'état des ordinateurs sélectionnés"
    Write-Host "2) Appliquer une action (activer/désactiver ou modifier l'OU) sur un ordinateur du domaine"
    Write-Host "3) Exporter le journal des actions réalisées durant la session dans un fichier texte"
    Write-Host "0) Quitter"
    Write-Host ""
    $choix = Read-Host "Entrez votre choix (0-3)"
    Switch ($choix)
        {
            '1' {
                Write-Host "Affichage des ordinateurs du domaine :"
                Get-ADComputer -Filter * -Properties Name, DistinguishedName, Enabled | Select-Object Name, @{"Name"="OU";"Expression"={Get-OUName -distinguished_name $_."DistinguishedName"}}, Enabled | Format-Table -AutoSize -Wrap
                Write-Host "Fin de l'affichage des ordinateurs du domaine."
                if ($computers) {
                    Write-Host "Liste des ordinateurs sélectionnés :"
                    $computers | Format-Table -AutoSize -Wrap
                } else {
                    Write-Host "Aucun ordinateur n'a été sélectionné."
                }
                do {
                    $add_computers = Read-Host "Voulez-vous ajouter un ou plusieurs ordinateurs à la liste des ordinateurs sélectionnés ? (O/Oui pour ajouter, N/Non pour ne pas ajouter)"
                    if ($add_computers -eq 'O' -or $add_computers -eq 'Oui') {
                        $add_computer_name = Read-Host "Veuillez entrer le ou les nom(s) de l'ordinateur à ajouter, séparés par des virgules"
                        if ($add_computer_name) {
                            $computers_name = $add_computer_name -split ','
                            foreach ($comp_name in $computers_name) {
                                $comp_name = $comp_name.Trim()
                                if ($comp_name) {
                                    $comp_filter = $comp_name -replace "'", "''"
                                    $found_computers = Get-ADComputer -Filter "Name -like '*$($comp_filter)*'" -Properties Name, DistinguishedName, Enabled | Select-Object Name, @{"Name"="OU";"Expression"={Get-OUName -distinguished_name $_."DistinguishedName"}}, DistinguishedName, Enabled
                                    if ($found_computers) {
                                        foreach ($computer in $found_computers) {
                                            if ($computers.Name -contains $computer.Name) {
                                                Write-Host "Ordinateur '$($computer.Name)' déjà présent dans la liste des ordinateurs sélectionnés."
                                            } else {
                                                $computers.Add($computer) | Out-Null
                                                Write-Host "Ordinateur '$($computer.Name)' ajouté à la liste des ordinateurs sélectionnés."
                                            }
                                        }
                                    } else {
                                        Write-Host "Aucun ordinateur trouvé avec le nom '$comp_name'."
                                    }
                                }
                            }
                        }
                    }
                    elseif ($add_computers -ne 'N' -and $add_computers -ne 'Non') {
                        Write-Host "Réponse non reconnue. Veuillez répondre par O/Oui ou N/Non."
                    }
                } until ($add_computers -eq 'N' -or $add_computers -eq 'Non')
            }
            '2' {
                if (!$computers) {
                    Write-Host "Aucun ordinateur n'a été sélectionné. Veuillez d'abord sélectionner un (ou plusieurs) ordinateur(s) dans le menu 1."
                    break
                }
                Write-Host "Liste des ordinateurs sélectionnés :"
                $computers | Format-Table -AutoSize -Wrap
                $confirm = Read-Host "Confirmez-vous la liste d'ordinateur(s) sélectionné(s) pour les actions en masse ? (O/Oui)"
                if ($confirm -ne 'O' -and $confirm -ne 'Oui') { Write-Host "Action annulée." ; break }

                do {
                    $action_choice = Read-Host "Choisir une action (1 = Activer / 2 = Desactiver / 3 = Modifier l'OU / 0 = Annuler)"
                    switch ($action_choice) {
                        '1' {
                            Write-Host "Vous avez choisi d'activer un ou plusieurs ordinateurs."
                            Write-Host "Lancement de la simulation de l'activation des ordinateurs sélectionnés..."
                            foreach ($comp in $computers) {
                                Enable-ADAccount -Identity $comp.DistinguishedName -WhatIf
                            }
                            Write-Host "Simulation terminée. Aucune modification n'a été effectuée."
                            $confirm = Read-Host "Confirmez vous l'activation des ordinateurs sélectionnés ? (O/Oui)"
                            if ($confirm -ne 'O' -and $confirm -ne 'Oui') { Write-Host "Action annulée." ; break }
                            foreach ($comp in $computers) {
                                if ($comp.Enabled -eq $false) {
                                    Enable-ADAccount -Identity $comp.DistinguishedName
                                    if ($?) {
                                        $comp.Enabled = $true
                                        Write-Output "Ordinateur '$($comp.Name)' activé avec succès." | Write-Log -computer_name $comp.Name -action "Activation" -result 0
                                    } else {
                                        Write-Output "Erreur lors de l'activation de l'ordinateur '$($comp.Name)'." | Write-Log -computer_name $comp.Name -action "Activation" -result 1
                                    }
                                } else {
                                    Write-Output "Ordinateur '$($comp.Name)' est déjà activé." | Write-Log -computer_name $comp.Name -action "Activation" -result 1
                                }
                            }
                            break
                        }
                        '2' {
                            Write-Host "Vous avez choisi de désactiver un ou plusieurs ordinateurs."
                            Write-Host "Lancement de la simulation de la désactivation des ordinateurs sélectionnés..."
                            foreach ($comp in $computers) {
                                Disable-ADAccount -Identity $comp.DistinguishedName -WhatIf
                            }
                            Write-Host "Simulation terminée. Aucune modification n'a été effectuée."
                            $confirm = Read-Host "Confirmez vous la désactivation des ordinateurs sélectionnés ? (O/Oui)"
                            if ($confirm -ne 'O' -and $confirm -ne 'Oui') { Write-Host "Action annulée." ; break }
                            foreach ($comp in $computers) {
                                if ($comp.Enabled -eq $true) {
                                    Disable-ADAccount -Identity $comp.DistinguishedName
                                    if ($?) {
                                        $comp.Enabled = $false
                                        Write-Output "Ordinateur '$($comp.Name)' désactivé avec succès." | Write-Log -computer_name $comp.Name -action "Désactivation" -result 0
                                    } else {
                                        Write-Output "Erreur lors de la désactivation de l'ordinateur '$($comp.Name)'." | Write-Log -computer_name $comp.Name -action "Désactivation" -result 1
                                    }
                                } else {
                                    Write-Output "Ordinateur '$($comp.Name)' est déjà désactivé." | Write-Log -computer_name $comp.Name -action "Désactivation" -result 1
                                }
                            }
                            break
                        }
                        '3' {
                            Write-Host "Vous avez choisi de modifier l'OU d'un ou plusieurs ordinateurs."
                            Write-Host "Affichage des différents OUs disponibles dans l'Active Directory :"
                            $all_ous = Get-ADOrganizationalUnit -Filter *
                            $all_ous | Select-Object Name, DistinguishedName | Format-Table -AutoSize -Wrap
                            $ou_choice = Read-Host "Renseigner le nom exact ou le DistinguishedName de l'OU de destination pour les ordinateurs sélectionnés"
                            $found_ous = @($all_ous | Where-Object { $_.Name -eq $ou_choice -or $_.DistinguishedName -eq $ou_choice })
                            if ($found_ous.Count -eq 1) {
                                $new_ou = $found_ous[0]
                                Write-Host "L'OU de destination est : $($new_ou.Name) ($($new_ou.DistinguishedName))"
                                Write-Host "Lancement de la simulation de la modification de l'OU des ordinateurs sélectionnés..."
                                foreach ($comp in $computers) {
                                    Move-ADObject -Identity $comp.DistinguishedName -TargetPath $new_ou.DistinguishedName -ErrorAction SilentlyContinue -WhatIf
                                }
                                Write-Host "Simulation terminée. Aucune modification n'a été effectuée."
                                $confirm = Read-Host "Confirmez-vous la modification de l'OU des ordinateurs sélectionnés vers cette OU ? (O/Oui)"
                                if ($confirm -ne 'O' -and $confirm -ne 'Oui') { Write-Host "Action annulée." ; break }
                                foreach ($comp in $computers) {
                                    $new_dn = "CN=$($comp.Name),$($new_ou.DistinguishedName)"
                                    if ($comp.DistinguishedName -ne $new_dn) {
                                        Move-ADObject -Identity $comp.DistinguishedName -TargetPath $new_ou.DistinguishedName -ErrorAction SilentlyContinue
                                        if ($?) {
                                            $comp.DistinguishedName = $new_dn
                                            $comp.OU = $new_ou.Name
                                            Write-Output "Ordinateur '$($comp.Name)' déplacé avec succès vers l'OU '$($new_ou.Name)'." | Write-Log -computer_name $comp.Name -action "Déplacement OU" -result 0
                                        } else {
                                            Write-Output "Erreur lors du déplacement de l'ordinateur '$($comp.Name)' vers l'OU '$($new_ou.Name)'." | Write-Log -computer_name $comp.Name -action "Déplacement OU" -result 1
                                        }
                                    } else {
                                        Write-Output "Ordinateur '$($comp.Name)' est déjà dans l'OU '$($new_ou.Name)'. Aucune action n'a été effectuée." | Write-Log -computer_name $comp.Name -action "Déplacement OU" -result 1
                                    }
                                }
                            } elseif ($found_ous.Count -gt 1) {
                                Write-Output "Plusieurs OU portent le nom '$ou_choice'. Veuillez réessayer avec son DistinguishedName." | Write-Log -computer_name "N/A" -action "Déplacement OU" -result 1
                            } else {
                                Write-Output "Aucune OU trouvée avec le nom '$ou_choice'. Veuillez réessayer." | Write-Log -computer_name "N/A" -action "Déplacement OU" -result 1
                            }
                        }
                        '0' { Write-Host "Action annulée." ; break }
                        default { Write-Host "Action non reconnue. Veuillez réessayer." }
                    }
                } while ($action_choice -notin '1','2','3','0')
            }
            '3' {
                $confirm = Read-Host "Voulez-vous exporter le journal des actions réalisées durant la session dans un fichier texte ? (O/Oui pour exporter, N/Non pour ne pas exporter)"
                if ($confirm -ne 'O' -and $confirm -ne 'Oui') { Write-Host "Exportation annulée." ; break }
                if (!$logObject) {
                    Write-Host "Aucune action n'a été réalisée durant la session. Le journal est vide."
                    break
                }
                $log_path = Read-Host "Veuillez renseigner le chemin complet du répertoire dans lequel vous souhaitez exporter le journal (ex: C:\Temp\)"
                if (!$log_path -or !(Test-Path -Path $log_path -PathType Container)) {
                    Write-Host "Le répertoire '$log_path' n'existe pas. Veuillez créer le répertoire avant d'exporter le journal."
                    break
                }
                $log_file = Join-Path -Path $log_path -ChildPath "AD_Computer_mgmt_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
                Write-Host "Exportation du journal des actions réalisées durant la session dans le fichier : $log_file"
                $logObject | ForEach-Object {
                    Add-Content -Path $log_file -Value $_
                }
                Write-Host "Exportation terminée. Fichier journal créé : $log_file"
            }
            '0' {
                Write-Host "Vous quittez l'outil d'inventaire"
                break menu
            }
            default { Write-Host "Vous avez renseigné un mauvais choix dans le menu, veuillez re-essayer" }
        }
    }