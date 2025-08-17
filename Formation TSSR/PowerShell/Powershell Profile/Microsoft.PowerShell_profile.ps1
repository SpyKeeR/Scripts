function Get-Time {return $(Get-Date | ForEach {$_.ToLongTimeString()})}
function prompt {
    Write-Host "[" -noNewLine
    Write-Host $(Get-Time) -ForegroundColor DarkYellow -noNewLine
    Write-Host "] " -noNewLine
    Write-Host $($(Get-Location).Path.replace($home,"~")) -ForegroundColor DarkGreen -noNewLine
    Write-Host $(if ($nestedpromptlevel -ge 1) { '>>' }) -noNewLine
    return "> "
}
function IsAdmin  
{  
   $CurrentUser =   
      [System.Security.Principal.WindowsIdentity]::GetCurrent()  
   $principal =   
      New-Object System.Security.principal.windowsprincipal($CurrentUser)
   $principal.IsInRole( `  
      [System.Security.Principal.WindowsBuiltInRole]::Administrator)  
}  
$time = $(Get-Time)
$CurrentUser =   
   [System.Security.Principal.WindowsIdentity]::GetCurrent()  
  
Write-Host ’+---------------------------------------------------+’  
Write-Host ("+- Bonjour {0} " -f ($CurrentUser.Name).split(’\’)[1])"Il est  $time"
Write-Host ’+---------------------------------------------------+’  
Get-Help -Name Get-Help