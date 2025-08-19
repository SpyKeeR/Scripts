on error resume next
set IPConfigSet = GetObject("winmgmts:{impersonationLevel=impersonate}!//" & Computer).ExecQuery _
("SELECT * FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled=TRUE")
Set WshShell=CreateObject("WScript.Shell")
dim version
version =  WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer\Version")
Set WshShellObj = WScript.CreateObject("WScript.Shell" )
Set WshProcessEnv = WshShellObj.Environment("PROCESS" )
WshUsername = WshProcessEnv("USERNAME" )
If Err.Number<>0 Then
wscript.echo " - non accessible -"
Else
for each IPConfig in IPConfigSet
wscript.echo " Configuration réseau de l'ordinateur " & computer & vbcrlf & vbcrlf & _
" DNSHostName " & vbtab & " : " & IPConfig.DNSHostName & vbcrlf & _
" Utilisateur " & vbtab & " : " & WshUsername & vbcrlf & _
" Adresse MAC " & vbtab & " : " & IPConfig.MACAddress & vbcrlf & _
" Adresse IP " & vbtab & " : " & IPConfig.IPAddress(0) & vbcrlf & _
" Version IE " & vbtab & " : " & version 
Next
End If