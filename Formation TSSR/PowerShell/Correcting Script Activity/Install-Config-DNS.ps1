# Installation et configuration DNS - Cours Services réseau Windows et GNU/Linux
#
# Installation composant
Install-WindowsFeature dns -IncludeManagementTools
# Machine client de son service DNS
Set-DnsClientServerAddress  -InterfaceIndex 4 -ServerAddresses 172.20.0.2 -PassThru

# Configuration Suffixe DNS Principal
Set-ItemProperty “HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\” –Name Domain –Value "gilles.eni"
# Restart-Computer

## Redirecteurs
# Redirecteur conditionnel
Add-DnsServerConditionalForwarderZone -ZoneName "gilles.eni" -MasterServers 172.20.0.1
# Redirecteur vers S1-GL et ENI
Set-DnsServerForwarder -IPAddress 10.0.0.3,10.100.0.3 -PassThru

## Zones

# Zone enfant ad.gilles.eni
Add-DnsServerPrimaryZone -Name "ad.gilles.eni" -ZoneFile "ad.gilles.eni.dns"
# Glue DNS pour le NS de la zone
Add-DnsServerResourceRecordA -Name "s2-w-cd" -IPv4Address 172.20.0.1 -ZoneName "ad"
# Enregistrement dans la zone
Add-DnsServerResourceRecordA -Name "dns1" -IPv4Address 172.20.0.2 -ZoneName "ad.gilles.eni"

#Add-DnsServerResourceRecord -CName -Name "dns2" -HostNameAlias "s3-gl.gilles.eni" -ZoneName "ad.gilles.eni" 
# Lister le contenu de la zone
Get-DnsServerResourceRecord -ZoneName "ad.gilles.eni" | ft -AutoSize
# Activation de la mise à jour dynamique
Set-DnsServerPrimaryZone -Name "ad.gilles.eni" -DynamicUpdate "Secure" -PassThru

# Configuration des serveurs secondaires + glue DNS
Add-DnsServerResourceRecord -NS -Name "ad.gilles.eni" -NameServer "s3-gl.gilles.eni" -ZoneName "ad.gilles.eni"
Add-DnsServerResourceRecord -A -Name "s3-gl.gilles.eni." -IPv4Address 172.20.8.3 -ZoneName "ad"
## Ou
Add-DnsServerResourceRecord -NS -Name "ad.gilles.eni" -NameServer "s4-w-sm" -ZoneName "ad.gilles.eni"
Add-DnsServerResourceRecord -A -Name "s4-w-sm" -IPv4Address 172.20.8.4 -ZoneName "ad.gilles.eni"

# Zone inverse réseau 172.20.0.0/16
#Add-DnsServerPrimaryZone -NetworkId 172.20.0.0/16 -ZoneName 20.172.dns -DynamicUpdate NonsecureAndSecure
#Ou
Add-DnsServerPrimaryZone -Name "20.172.in-addr.arpa" -ZoneFile "20.172.dns" -DynamicUpdate NonsecureAndSecure
Add-DnsServerResourceRecordPtr -Name "1.0" -ZoneName "20.172.in-addr.arpa" -AllowUpdateAny -PtrDomainName "s1-gl.gilles.eni"
Add-DnsServerResourceRecordPtr -Name "2.0" -ZoneName "20.172.in-addr.arpa" -AllowUpdateAny -PtrDomainName "s2-w-cd.gilles.eni"
Add-DnsServerResourceRecordPtr -Name "3.8" -ZoneName "20.172.in-addr.arpa" -AllowUpdateAny -PtrDomainName "s3-gl.gilles.eni"
Add-DnsServerResourceRecordPtr -Name "4.8" -ZoneName "20.172.in-addr.arpa" -AllowUpdateAny -PtrDomainName "s4-w-sm.gilles.eni"
Add-DnsServerResourceRecordPtr -Name "254.7" -ZoneName "20.172.in-addr.arpa" -AllowUpdateAny -PtrDomainName "routeur.gilles.eni"
Add-DnsServerResourceRecordPtr -Name "254.15" -ZoneName "20.172.in-addr.arpa" -AllowUpdateAny -PtrDomainName "routeur.gilles.eni"
# Lister le contenu de la zone
Get-DnsServerResourceRecord -ZoneName "20.172.in-addr.arpa" | ft -AutoSize

