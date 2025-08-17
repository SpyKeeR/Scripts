#Gestion de la configuration réseau
Function AffichMenu {
    Write-Host "----------------------------------------"
    Write-Host "Menu de l'outil de configuration réseau"
    Write-Host "----------------------------------------"
    write-Host "1) - Afficher la configuration IPv4 d'une interface réseau"
    Write-Host "2) - Modifier la configuration IPv4 d'une interface réseau"
    Write-Host "3) - Activer une interface réseau"
    Write-Host "4) - Désactiver une interface réseau"
    Write-Host "5) - Renommer une interface réseau"
    Write-Host "6) - Obtenir les informations matérielles d'une interface"
    Write-Host "q) - Quitter l'outil de configuration réseau"
    Write-Host ""
    $choix = Read-Host "Renseigner votre choix ? "
    return $choix
}
Function WriteLog {
    param ($ContentErrorVar,$Type)
    if ($(Get-ChildItem -Path "./NetworkConfig.log" -ErrorAction Ignore)) {
        $LogTime = Get-Date -Format "dd-MM-yyyy HH:mm:ss"
        Add-Content -Path "./NetworkConfig.log" -Value "$LogTime - $type : $ContentErrorVar"
        Write-Host "${Type}. Plus d'informations dans le log ./NetworkConfig.log"
    }
    else {
        "Fichier de journalisation des erreurs provenant de l'outil de configuration réseau" | Out-File -FilePath "./NetworkConfig.log"
        "---------------------------------------------------------" | Out-File -FilePath "./NetworkConfig.log" -Append
        $LogTime = Get-Date -Format "dd-MM-yyyy HH:mm:ss"
        Add-Content -Path "./NetworkConfig.log" -Value "$LogTime - $type : $ContentErrorVar"
        Write-Host "${Type}. Plus d'informations dans le log ./NetworkConfig.log"
    }
}
Function DisplayConfigIP {
    $AllIntD = Get-NetAdapter | Where-Object { $_.Status -ne "Disabled" }
    if ($AllIntD) {
        Write-Host "Liste des interfaces activées : "   
        Foreach ($intD in $AllIntD) {
            Write-Host "N°$($intD.IfIndex) - $($intD.Name) - $($intD.MacAddress)"
        }
        do {
            $sortieD = $false
            [int]$IntToDisplayIP = 0
            do {
                $reponseD = Read-Host "Renseigner le numéro de l'interface dont vous souhaitez voir la configuration IPv4? 0 pour revenir au menu précédent "
                $reponseDisInt = [int]::TryParse($reponseD, [ref]$IntToDisplayIP)
                if (-not $reponseDisInt) {
                    Write-Host "Veuillez renseigner un numéro entier sans autres caractères"
                }
            } until ($reponseDisInt)
            Remove-Variable reponseD
            if ( $IntToDisplayIP -gt 0 -and $(Get-NetAdapter -ifIndex $IntToDisplayIP -ErrorAction Ignore | Where-Object { $_.Status -ne "Disabled" })) {
                try {
                    Get-NetIPConfiguration -InterfaceIndex $IntToDisplayIP -ErrorAction Stop -ErrorVariable ErreurDisplayIP
                }
                catch {
                        WriteLog "$ErreurDisplayIP" "Erreur affichage Config. IP de l'interface N°$IntToDisplayIP"
                }
            }
            elseif  ( $IntToDisplayIP -eq 0) {
                $sortieD = $true
                Remove-Variable IntToDisplayIP
            }
            else {
                $ErreurNumero = "Vous avez renseigné un numéro incorrect. Veuillez rééssayer."
                Write-Host $ErreurNumero
                WriteLog "$ErreurNumero" "Erreur affichage Config. IP de l'interface N°$IntToDisplayIP"
                Remove-Variable IntToDisplayIP
            }
        } while ($sortieD -eq $false)
    }
    else {
        Write-Host "Aucune interface activée disponible"
    }
}
Function EditConfigIP {
    $intconfig = Get-NetAdapter | Where-Object { $_.Status -ne "Disabled" }
    if ($intconfig)
        {
        Write-Host "Liste des interfaces activées : "   
        Foreach ($int in $intconfig) {
            Write-Host "N°$($int.IfIndex) - $($int.Name) - $($int.MacAddress)"
        }
        do {
            $sortieC = $false
            [int]$IntToConfig = 0
            do {
                $reponseC = Read-Host "Renseigner le numéro de l'interface dont vous souhaitez éditer la configuration IPv4? 0 pour revenir au menu précédent "
                $reponseCisInt = [int]::TryParse($reponseC, [ref]$IntToConfig)
                if (-not $reponseCisInt) {
                    Write-Host "Veuillez renseigner un numéro entier sans autres caractères"
                }
            } until ($reponseCisInt)
            Remove-Variable reponseC
            if ( $IntToConfig -gt 0 -and $(Get-NetAdapter -ifIndex $IntToConfig -ErrorAction Ignore | Where-Object { $_.Status -ne "Disabled" })) {
                    try {
                        $dhcp = Read-Host "Désirez-vous activer le DHCP? oui/non"
                        if ($dhcp -eq "oui") {
                            Set-NetIPInterface -InterfaceIndex $IntToConfig -Dhcp Enabled -ErrorAction Stop -ErrorVariable ErreurConfig -Confirm:$false
                            Set-DnsClientServerAddress –InterfaceIndex $IntToConfig -ResetServerAddresses -ErrorAction Stop -ErrorVariable ErreurConfig -Confirm:$false
                            Write-Host "DHCP activé sur l'interface N°$IntToConfig"
                        }
                        else {
                            Write-Host "Configuration IP manuelle"
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
                        WriteLog $ErreurConfig "Erreur de Config. IP de l'interface N°$IntToConfig"
                    }
                
            }
            elseif  ( $IntToConfig -eq 0) {
                $sortieC = $true
                Remove-Variable IntToConfig
            }
            else {
                $ErreurNumero = "Vous avez renseigné un numéro incorrect. Veuillez rééssayer."
                Write-Host $ErreurNumero
                WriteLog "$ErreurNumero" "Erreur Config. IP de l'interface N°$IntToConfig"
                Remove-Variable IntToConfig
            }
        } while ($sortieC -eq $false)
    }
    else {
        Write-Host "Aucune interface activée disponible"
    }
}
Function ActivateInt {
    $intdisabled = Get-NetAdapter | Where-Object { $_.Status -eq "Disabled" }
    if ($intdisabled) {
    Write-Host "Liste des interfaces désactivées : "
    Foreach ($int in $intdisabled) {
        Write-Host "N°$($int.IfIndex) - $($int.Name) - $($int.MacAddress)"
    }
    do {
        $sortieA = $false
        [int]$IntToActivate = 0
        do {
            $reponseA = Read-Host "Renseigner le numéro de l'interface que vous souhaitez activer? 0 pour revenir au menu précédent "
            $reponseAisInt = [int]::TryParse($reponseA, [ref]$IntToActivate)
            if (-not $reponseAisInt) {
                Write-Host "Veuillez renseigner un numéro entier sans autres caractères"
            }
        } until ($reponseAisInt)
        Remove-Variable reponseA
        if ( $IntToActivate -gt 0 -and $(Get-NetAdapter -ifIndex $IntToActivate -ErrorAction Ignore)) {
                try {
                    Enable-NetAdapter -Name $(Get-NetAdapter -ifIndex $IntToActivate).Name -Confirm:$false -ErrorAction Stop -ErrorVariable ErreurActivate
                    Write-Host "Interface N°$IntToActivate activée"
                }
                catch {
                    WriteLog $ErreurConfig "Erreur d'activation de l'interface N°$IntToActivate"
                }
        }
        elseif  ( $IntToActivate -eq 0) {
            $sortieA = $true
            Remove-Variable IntToActivate
        }
        else {
            $ErreurNumero = "Vous avez renseigné un numéro incorrect. Veuillez rééssayer."
            Write-Host $ErreurNumero
            WriteLog "$ErreurNumero" "Erreur d'activation de l'interface N°$IntToActivate"
            Remove-Variable IntToActivate
        }
    } while ($sortieA -eq $false)
    }
    else {
        Write-Host "Aucune interface desactivée disponible"
    }
}
Function DesactivateInt {
    $intEnabled = Get-NetAdapter | Where-Object { $_.Status -ne "Disabled" }
    if ($intEnabled) {
    Write-Host "Liste des interfaces activées : "
    Foreach ($intE in $intEnabled) {
        Write-Host "N°$($intE.IfIndex) - $($intE.Name) - $($intE.MacAddress)"
    }
    do {
        $sortieD = $false
        [int]$IntToDesactivate = 0
        do {
            $reponseD = Read-Host "Renseigner le numéro de l'interface que vous souhaitez désactiver? 0 pour revenir au menu précédent "
            $reponseDisInt = [int]::TryParse($reponseD, [ref]$IntToDesactivate)
            if (-not $reponseDisInt) {
                Write-Host "Veuillez renseigner un numéro entier sans autres caractères"
            }
        } until ($reponseDisInt)
        Remove-Variable reponseD
        if ( $IntToDesactivate -gt 0 -and $(Get-NetAdapter -ifIndex $IntToDesactivate -ErrorAction Ignore)) {
                try {
                    Disable-NetAdapter -Name $(Get-NetAdapter -ifIndex $IntToDesactivate).Name -Confirm:$false -ErrorAction Stop -ErrorVariable ErreurDesactivate
                    Write-Host "Interface N°$IntToDesactivate desactivée"
                }
                catch {
                    WriteLog $ErreurConfig "Erreur de désactivation de l'interface N°$IntToDesactivate"
                }
        }
        elseif  ( $IntToDesactivate -eq 0) {
            $sortieD = $true
            Remove-Variable IntToDesactivate
        }
        else {
            $ErreurNumero = "Vous avez renseigné un numéro incorrect. Veuillez rééssayer."
            Write-Host $ErreurNumero
            WriteLog "$ErreurNumero" "Erreur de désactivation de l'interface N°$IntToDesactivate"
            Remove-Variable IntToDesactivate
        }
    } while ($sortieD -eq $false)
    }
    else {
        Write-Host "Aucune interface activée disponible"
    }
}
Function RenameInt {
    $AllInt = Get-NetAdapter
    if ($AllInt) {
    Write-Host "Liste des interfaces : "
    Foreach ($intR in $AllInt) {
        Write-Host "N°$($intR.IfIndex) - $($intR.Name) - $($intR.MacAddress)"
    }
    do {
        $sortieR = $false
        [int]$IntToRename = 0
        do {
            $reponseR = Read-Host "Renseigner le numéro de l'interface que vous souhaitez renommer? 0 pour revenir au menu précédent "
            $reponseRisInt = [int]::TryParse($reponseR, [ref]$IntToRename)
            if (-not $reponseRisInt) {
                Write-Host "Veuillez renseigner un numéro entier sans autres caractères"
            }
        } until ($reponseRisInt)
        Remove-Variable reponseR
        if ( $IntToRename -gt 0 -and $(Get-NetAdapter -ifIndex $IntToRename -ErrorAction Ignore)) {
                try {
                    [String]$IntNewName = Read-Host "Quel nom souhaitez-vous attribuer a cette interface ? "
                    Rename-NetAdapter -Name $(Get-NetAdapter -ifIndex $IntToRename).Name -NewName $IntNewName -Confirm:$false -ErrorAction Stop -ErrorVariable ErreurRename
                    Write-Host "Interface N°$IntToRename renommée"
                }
                catch {
                    WriteLog "$ErreurRename" "Erreur de renommage de l'interface N°$IntToRename"
                }
        }
        elseif  ( $IntToRename -eq 0) {
            $sortieR = $true
            Remove-Variable IntToRename
        }
        else {
            $ErreurNumero = "Vous avez renseigné un numéro incorrect. Veuillez rééssayer."
            Write-Host $ErreurNumero
            WriteLog "$ErreurNumero" "Erreur de renommage de l'interface N°$IntToRename"
            Remove-Variable IntToRename
        }
    } while ($sortieR -eq $false)
    }
    else {
        Write-Host "Aucune interface disponible."
    }
}
function InfoMatInt {
    $AllIntM = Get-NetAdapter
    if ($AllIntM) {
    Write-Host "Liste des interfaces : "
    Foreach ($intM in $AllIntM) {
        Write-Host "N°$($intM.IfIndex) - $($intM.Name) - $($intM.MacAddress)"
    }
    do {
        $sortieM = $false
        [int]$IntToInfoMat = 0
        do {
            $reponseM = Read-Host "Renseigner le numéro de l'interface dont vous souhaitez obtenir les informations matérielles? 0 pour revenir au menu précédent "
            $reponseMisInt = [int]::TryParse($reponseM, [ref]$IntToInfoMat)
            if (-not $reponseMisInt) {
                Write-Host "Veuillez renseigner un numéro entier sans autres caractères"
            }
        } until ($reponseMisInt)
        Remove-Variable reponseM
        if ( $IntToInfoMat -gt 0 -and $(Get-NetAdapter -ifIndex $IntToInfoMat -ErrorAction Ignore)) {
                try {
                    Get-NetAdapterHardwareInfo -Name $(Get-NetAdapter -ifIndex $IntToInfoMat).Name -ErrorAction Stop -ErrorVariable ErreurInfoMat | Format-List *
                }
                catch {
                    WriteLog $ErreurConfig "Erreur d'affichage d'informations matérielles de l'interface N°$IntToInfoMat"
                }
        }
        elseif  ( $IntToInfoMat -eq 0) {
            $sortieM = $true
            Remove-Variable IntToInfoMat
        }
        else {
            $ErreurNumero = "Vous avez renseigné un numéro incorrect. Veuillez rééssayer."
            Write-Host $ErreurNumero
            WriteLog "$ErreurNumero" "Erreur d'obtention d'information de l'interface N°$IntToInfoMat"
            Remove-Variable IntToInfoMat
        }
    } while ($sortieM -eq $false)
    }
    else {
        Write-Host "Aucune interface disponible."
    }
}
do {
    $choix = AffichMenu
    Switch ($choix) {
        '1' { DisplayConfigIP }
        '2' { EditConfigIP }
        '3' { ActivateInt }
        '4' { DesactivateInt }
        '5' { RenameInt }
        '6' { InfoMatInt }
        'q' { Write-Host "Vous quittez le script." }  
        Default { Write-Host "Vous avez renseigné un choix incorrect. Veuillez re-essayer."} 
    }    
} while ($choix -ne "q")