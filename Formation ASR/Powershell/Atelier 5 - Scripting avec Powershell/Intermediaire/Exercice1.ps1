:menu While ($true)
    {
    Write-Host "Bienvenue dans l'outil de diagnostic réseau, faites votre choix parmi les menus suivants :"
    Write-Host "1) Test de connectivité réseau vers une adresse IP au choix"
    Write-Host "2) Test de connectivité vers la passerelle par défaut"
    Write-Host "3) Test de résolution DNS pour un nom de domaine au choix"
    Write-Host "4) Test de la relation d'approbation avec le contrôleur de domaine"
    Write-Host "5) Affichage de la configuration IP de l'interface principale de l'ordinateur"
    Write-Host "0) Quitter"
    Write-Host ""
    $choix = Read-Host "Entrez votre choix (0-5)"
    Switch ($choix)
        {
            '1' { 
            Read-Host "Renseigner l'adresse IP à tester" | Test-Connection -Count 4 -ErrorAction SilentlyContinue
            if (!$?) { Write-Host "L'adresse IP renseignée n'a pas répondu au test de connectivité." }
            }
            '2' { 
            $default_gateway = (Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null }).IPv4DefaultGateway.NextHop
            Test-Connection -ComputerName $default_gateway -Count 4 -ErrorAction SilentlyContinue
            if (!$?) { Write-Host "La passerelle par défaut n'a pas répondu au test de connectivité." }
            }
            '3' {
            Read-Host "Renseigner le nom de domaine à résoudre" | Resolve-DnsName -ErrorAction SilentlyContinue
            if (!$?) { Write-Host "Le nom de domaine renseigné n'a pas pu être résolu." }
            }
            '4' {
            Test-ComputerSecureChannel -ErrorAction SilentlyContinue
            if (!$?) { Write-Host "La relation d'approbation avec le contrôleur de domaine a échoué." }
            else { Write-Host "La relation d'approbation avec le contrôleur de domaine est valide." }
            }
            '5' {
            Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null } | Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer | Format-Table -AutoSize
            }
            '0' { Write-Host "Vous quittez l'outil d'inventaire" ; break menu }
            default { Write-Host "Vous avez renseigné un mauvais choix dans le menu, veuillez re-essayer" }
        }
}