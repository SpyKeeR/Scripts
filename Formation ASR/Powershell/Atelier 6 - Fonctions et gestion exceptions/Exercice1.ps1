$source = "C:\Partage\Exports"
$destination = "C:\Backup"
[System.Collections.ArrayList]$erreurs = @()

:menu While ($true)
    {
    Write-Host "Bienvenue dans l'outil de sauvegarde, faites votre choix parmi les menus suivants :"
    Write-Host "1) Sauvegarder les fichiers de $source dans $destination"
    Write-Host "2) Lister les fichiers de sauvegarde"
    Write-Host "3) Supprimer un fichier de sauvegarde"
    Write-Host "q) Quitter"
    Write-Host ""
    $choix = Read-Host "Entrez votre choix (1-3 ou q)"
    Switch ($choix)
        {
            '1' {
                $fichiers = @(Get-ChildItem -Path $source -File -ErrorAction SilentlyContinue -ErrorVariable erreur_action)
                if ($erreur_action) {
                    $erreurs.AddRange($erreur_action)
                    Write-Host "Échec : impossible de lire le dossier $source."
                    Write-Host "Détail : $($erreur_action[0].Exception.Message)"
                    break
                }
                if (!$fichiers) {
                    Write-Host "Aucun fichier à sauvegarder dans $source."
                    break
                }
                if (!(Test-Path -Path $destination -PathType Container)) {
                    New-Item -Path $destination -ItemType Directory -ErrorAction SilentlyContinue -ErrorVariable erreur_action | Out-Null
                    if ($erreur_action) {
                        $erreurs.AddRange($erreur_action)
                        Write-Host "Échec : impossible de créer le dossier $destination."
                        Write-Host "Détail : $($erreur_action[0].Exception.Message)"
                        break
                    }
                }
                $copies = 0
                foreach ($fichier in $fichiers) {
                    try {
                        Copy-Item -LiteralPath $fichier.FullName -Destination $destination -Force -ErrorAction Stop
                        $copies++
                    } catch {
                        $erreurs.Add($_) | Out-Null
                        Write-Host "Détail : le fichier '$($fichier.Name)' n'a pas été copié. $($_.Exception.Message)"
                    }
                }
                if ($copies -eq $fichiers.Count) {
                    Write-Host "Succès : $copies fichier(s) sauvegardé(s) dans $destination."
                } else {
                    Write-Host "Échec : seulement $copies fichier(s) sur $($fichiers.Count) sauvegardé(s) dans $destination."
                }
            }
            '2' {
                $sauvegardes = Get-ChildItem -Path $destination -File -ErrorAction SilentlyContinue -ErrorVariable erreur_action
                if ($erreur_action) {
                    $erreurs.AddRange($erreur_action)
                    Write-Host "Échec : impossible de lister les sauvegardes."
                    Write-Host "Détail : $($erreur_action[0].Exception.Message)"
                } elseif ($sauvegardes) {
                    Write-Host "Liste des fichiers de sauvegarde :"
                    $sauvegardes | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize -Wrap | Out-Host
                } else {
                    Write-Host "Aucun fichier de sauvegarde présent dans $destination."
                }
            }
            '3' {
                $sauvegardes = Get-ChildItem -Path $destination -File -ErrorAction SilentlyContinue -ErrorVariable erreur_action
                if ($erreur_action) {
                    $erreurs.AddRange($erreur_action)
                    Write-Host "Échec : impossible de lister les sauvegardes."
                    Write-Host "Détail : $($erreur_action[0].Exception.Message)"
                    break
                }
                if (!$sauvegardes) {
                    Write-Host "Aucun fichier de sauvegarde présent dans $destination."
                    break
                }
                Write-Host "Liste des fichiers de sauvegarde :"
                $sauvegardes | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize -Wrap | Out-Host
                $nom_fichier = Read-Host "Renseigner le nom du fichier de sauvegarde à supprimer"
                $fichier = $sauvegardes | Where-Object { $_.Name -eq $nom_fichier }
                if (!$fichier) {
                    Write-Host "Échec : le fichier '$nom_fichier' ne fait pas partie des sauvegardes."
                    break
                }
                $confirm = Read-Host "Confirmez-vous la suppression du fichier '$($fichier.Name)' ? (O/Oui)"
                if ($confirm -ne 'O' -and $confirm -ne 'Oui') { Write-Host "Suppression annulée." ; break }
                Remove-Item -LiteralPath $fichier.FullName -Force -ErrorAction SilentlyContinue -ErrorVariable erreur_action
                if ($erreur_action) {
                    $erreurs.AddRange($erreur_action)
                    Write-Host "Échec : le fichier '$($fichier.Name)' n'a pas été supprimé."
                    Write-Host "Détail : $($erreur_action[0].Exception.Message)"
                } else {
                    Write-Host "Succès : le fichier '$($fichier.Name)' a été supprimé."
                }
            }
            'q' {
                if ($erreurs) {
                    Write-Host "$($erreurs.Count) erreur(s) enregistrée(s) durant la session :"
                    $erreurs | ForEach-Object { Write-Host "- $($_.Exception.Message)" }
                }
                Write-Host "Vous quittez l'outil de sauvegarde"
                break menu
            }
            default { Write-Host "Vous avez renseigné un mauvais choix dans le menu, veuillez re-essayer" }
        }
    }
