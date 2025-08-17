#Gestion de la configuration réseau
#A faire le logging vers fichier a chaque boucle
#A faire le menu
#A faire les verif avant les Foreach si il n'y la recup du listing des interfaces et vide, on sort.
Function AffichMenu {
    Write-Host "----------------------------------------"
    Write-Host "Menu de l'outil de configuration réseau"
    Write-Host "----------------------------------------"
    write-Host "1) - Afficher la configuration IPv4 d'une interface réseau"
    Write-Host "2) - Modifier la configuration IPv4 d'une interface réseau"
    Write-Host "2) - Activer une interface réseau"
    Write-Host "3) - Désactiver une interface réseau"
    Write-Host "4) - Renommer une interface réseau"
    Write-Host "5) - Obtenir les informations matérielles d'une interface"
    Write-Host "q) - Quitter l'outil de configuration réseau"
    Write-Host ""
    $choix = Read-Host "Renseigner votre choix ? "
    return $choix
}
Function DisplayConfigIP {
    $AllIntD = Get-NetAdapter | Where-Object { $_.Status -ne "Disabled" }
    Write-Host "Liste des interfaces activées : "
    Foreach ($intD in $AllIntD) {
        Write-Host "N°$intD.IfIndex - $intD.Name - $intD.MacAddress"
    }
    do {
        $sortieD = $false
        $IntToDisplayIP = Read-Host "Renseigner le numéro de l'interface dont vous souhaitez voir la configuration IPv4? r pour revenir au menu précédent "
        if ( $IntToDisplayIP.GetType().Name -eq "int32" -or $IntToDisplayIP -gt 0 -or $(Get-NetAdapter -ifIndex $IntToConfig | Where-Object { $_.Status -ne "Disabled" })) {
                try {
                    Get-NetIPConfiguration -InterfaceIndex $IntToDisplayIP -ErrorAction Stop -ErrorVariable ErreurDisplayIP
                }
                catch {
                    Write-Host "Erreur lors de l'affichage des informations de configuration IP. Plus d'informations dans le log ./NetworkConfig.log"
                }
        }
        elseif  ( $IntToDisplayIP -eq "r") {
            $sortieD = $true
            Remove-Variable $IntToDisplayIP
        }
        else {
            Write-Host "Vous avez renseigné un numéro incorrect. Veuillez rééssayer."
            Remove-Variable $IntToDisplayIP
        }
    } while ($sortieD -eq $true)
}
Function EditConfigIP {
    $intconfig = Get-NetAdapter | Where-Object { $_.Status -ne "Disabled" }
    Write-Host "Liste des interfaces activées : "
    Foreach ($int in $intconfig) {
        Write-Host "N°$int.IfIndex - $int.Name - $int.MacAddress"
    }
    do {
        $sortieC = $false
        $IntToConfig = Read-Host "Renseigner le numéro de l'interface que vous souhaitez configurer? r pour revenir au menu précédent "
        if ( $IntToConfig.GetType().Name -eq "int32" -or $IntToConfig -gt 0 -or $(Get-NetAdapter -ifIndex $IntToConfig | Where-Object { $_.Status -ne "Disabled" })) {
                try {
                    $dhcp = Read-Host "Désirez-vous activer le DHCP? oui/non"
                    if ($dhcp -eq "oui") {
                        Set-NetIPInterface -InterfaceIndex $IntToConfig -Dhcp Enabled -ErrorAction Stop -ErrorVariable ErreurConfig -Confirm:$false
                        Set-DnsClientServerAddress –InterfaceIndex $IntToConfig -ResetServerAddresses -ErrorAction Stop -ErrorVariable ErreurConfig -Confirm:$false
                        Write-Host "DHCP activé sur l'interface N°$IntToConfig"
                    }
                    else {
                        Remove-NetIPAddress –InterfaceIndex $IntToConfig -AddressFamily IPv4 -Confirm:$false -ErrorAction Stop -ErrorVariable ErreurConfig
                        $IP = Read-Host "Renseigner l'adresse IP désirée "
                        $Prefix = Read-Host "Renseigner le préfixe CIDR désiré "
                        $gateway = Read-Host "Renseigner l'adresse IP de la passerelle "
                        $DNServer = Read-Host "Renseigner l'adresse du serveur DNS "
                        New-NetIPAddress –InterfaceIndex $IntToConfig –IPAddress $IP –PrefixLength $Prefix –DefaultGateway $gateway -Confirm:$false -ErrorAction Stop -ErrorVariable ErreurConfig
                        Set-DnsClientServerAddress -InterfaceIndex $IntToConfig -ServerAddresses $DNServer -Confirm:$false -ErrorAction Stop -ErrorVariable ErreurConfig
                        Write-Host "Configuration manuelle sur l'interface N°$IntToConfig terminée"
                    }
                }
                catch {
                    Write-Host "L'interface n'as pas pu être activée. Plus d'information dans le log ./NetworkConfig.log"
                }
            
        }
        elseif  ( $IntToActivate -eq "r") {
            $sortieC = $true
            Remove-Variable $IntToActivate
        }
        else {
            Write-Host "Vous avez renseigné un numéro incorrect. Veuillez rééssayer."
            Remove-Variable $IntToActivate
        }
    } while ($sortieC -eq $true)
}
Function ActivateInt {
    $intdisabled = Get-NetAdapter | Where-Object { $_.Status -eq "Disabled" }
    Write-Host "Liste des interfaces désactivées : "
    Foreach ($int in $intdisabled) {
        Write-Host "N°$int.IfIndex - $int.Name - $int.MacAddress"
    }
    do {
        $sortieA = $false
        $IntToActivate = Read-Host "Renseigner le numéro de l'interface que vous souhaitez activer? r pour revenir au menu précédent "
        if ( $IntToActivate.GetType().Name -eq "int32" -or $IntToActivate -gt 0 -or $(Get-NetAdapter -ifIndex $IntToActivate)) {
                try {
                    Enable-NetAdapter -Name $(Get-NetAdapter -ifIndex $IntToActivate).Name -Confirm:$false -ErrorAction Stop -ErrorVariable ErreurActivate
                    Write-Host "Interface N°$IntToActivate activée"
                }
                catch {
                    Write-Host "L'interface n'as pas pu être activée. Plus d'information dans le log ./NetworkConfig.log"
                }
        }
        elseif  ( $IntToActivate -eq "r") {
            $sortieA = $true
            Remove-Variable $IntToActivate
        }
        else {
            Write-Host "Vous avez renseigné un numéro incorrect. Veuillez rééssayer."
            Remove-Variable $IntToActivate
        }
    } while ($sortieA -eq $true)
}
Function DesactivateInt {
    $intEnabled = Get-NetAdapter | Where-Object { $_.Status -ne "Disabled" }
    Write-Host "Liste des interfaces activées : "
    Foreach ($intE in $intEnabled) {
        Write-Host "N°$intE.IfIndex - $intE.Name - $intE.MacAddress"
    }
    do {
        $sortieD = $false
        $IntToDesactivate = Read-Host "Renseigner le numéro de l'interface que vous souhaitez désactiver? r pour revenir au menu précédent "
        if ( $IntToDesactivate.GetType().Name -eq "int32" -or $IntToDesactivate -gt 0 -or $(Get-NetAdapter -ifIndex $IntToDesactivate)) {
                try {
                    Disable-NetAdapter -Name $(Get-NetAdapter -ifIndex $IntToDesactivate).Name -Confirm:$false -ErrorAction Stop -ErrorVariable ErreurDesactivate
                    Write-Host "Interface N°$IntToDesactivate desactivée"
                }
                catch {
                    Write-Host "L'interface n'as pas pu être desactivée. Plus d'information dans le log ./NetworkConfig.log"
                }
        }
        elseif  ( $IntToDesactivate -eq "r") {
            $sortieD = $true
            Remove-Variable $IntToDesactivate
        }
        else {
            Write-Host "Vous avez renseigné un numéro incorrect. Veuillez rééssayer."
            Remove-Variable $IntToDesactivate
        }
    } while ($sortieD -eq $true)
}
Function RenameInt {
    $AllInt = Get-NetAdapter
    Write-Host "Liste des interfaces : "
    Foreach ($intR in $AllInt) {
        Write-Host "N°$intR.IfIndex - $intR.Name - $intR.MacAddress"
    }
    do {
        $sortieR = $false
        $IntToRename = Read-Host "Renseigner le numéro de l'interface que vous souhaitez renommer? r pour revenir au menu précédent "
        if ( $IntToRename.GetType().Name -eq "int32" -or $IntToRename -gt 0 -or $(Get-NetAdapter -ifIndex $IntToRename)) {
                try {
                    [String]$IntNewName = Read-Host "Quel nom souhaitez-vous attribuer a cette interface ? "
                    Rename-NetAdapter -Name $(Get-NetAdapter -ifIndex $IntToRename).Name -NewName $IntNewName -Confirm:$false -ErrorAction Stop -ErrorVariable ErreurRename
                    Write-Host "Interface N°$IntToRename renommée"
                    $sortieR = $true
                }
                catch {
                    Write-Host "L'interface n'as pas pu être renommée Plus d'information dans le log ./NetworkConfig.log"
                    $sortieR = $true
                }
        }
        elseif  ( $IntToRename -eq "r") {
            $sortieR = $true
            Remove-Variable $IntToRename
        }
        else {
            Write-Host "Vous avez renseigné un numéro incorrect. Veuillez rééssayer."
            Remove-Variable $IntToRename
        }
    } while ($sortieR -eq $true)
}
function InfoMatInt {
    $AllIntM = Get-NetAdapter
    Write-Host "Liste des interfaces : "
    Foreach ($intM in $AllIntM) {
        Write-Host "N°$intM.IfIndex - $intM.Name - $intM.MacAddress"
    }
    do {
        $sortieM = $false
        $IntToInfoMat = Read-Host "Renseigner le numéro de l'interface dont vous souhaitez obtenir les informations matérielles? r pour revenir au menu précédent "
        if ( $IntToInfoMat.GetType().Name -eq "int32" -or $IntToInfoMat -gt 0 -or $(Get-NetAdapter -ifIndex $IntToInfoMat)) {
                try {
                    Get-NetAdapterHardwareInfo -Name $(Get-NetAdapter -ifIndex $IntToInfoMat).Name -ErrorAction Stop -ErrorVariable ErreurInfoMat
                }
                catch {
                    Write-Host "Erreur lors de l'affichage des informations matérielles. Plus d'informations dans le log ./NetworkConfig.log"
                }
        }
        elseif  ( $IntToInfoMat -eq "r") {
            $sortieM = $true
            Remove-Variable $IntToInfoMat
        }
        else {
            Write-Host "Vous avez renseigné un numéro incorrect. Veuillez rééssayer."
            Remove-Variable $IntToInfoMat
        }
    } while ($sortieM -eq $true)
}

do {
    
} while ($choix -eq "q")
#