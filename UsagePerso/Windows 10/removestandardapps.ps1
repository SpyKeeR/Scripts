<#     
    ************************************************************************************************************ 
    Purpose:    Remove built in apps specified in list 
    Pre-Reqs:    Windows 10
    ************************************************************************************************************ 
#>

#List of Packages that will be removed
$PackageList = @(

# Default 'useful' apps

#"Microsoft.Windows.Photos", # Microsoft Photos (Photo Viewer)
"Microsoft.ZuneMusic", # Groove Music (Music Player)
"Microsoft.ZuneVideo", # Movies & TV (Video Player)
"Microsoft.MSPaint", # Paint 3D
"Microsoft.People", # Microsoft People (Contacts)
"Microsoft.Messaging", # Microsoft Messaging (Messaging App)
"microsoft.windowscommunicationsapps", # Microsoft Mail and Calendar
"Microsoft.WindowsCamera", # Microsoft Camera
"Microsoft.MicrosoftStickyNotes", # Sticky Notes
#"Microsoft.WindowsAlarms", # Windows Alarms & Clock
"Microsoft.WindowsSoundRecorder", # Windows Voice Recorder

# Xbox Related
"Microsoft.Xbox.TCUI", # Xbox Live in-game Experiece
"Microsoft.XboxGamingOverlay", # Xbox Game Bar
"Microsoft.XboxIdentityProvider", # Xbox Identity Provider
"Microsoft.XboxApp", # Xbox Console Companion
"Microsoft.XboxGameOverlay", # Xbox Game Bar Plugin
"Microsoft.XboxSpeechToTextOverlay", # Xbox ???

# Bing
"Microsoft.BingNews", # Bing News
"Microsoft.BingSports", # Bing Sport
"Microsoft.BingWeather", # Bing Weather
"Microsoft.BingFinance", # Bing Finance
"Microsoft.WindowsMaps", # Bing Maps

# Advertising, help, tips, feedback
"Microsoft.Advertising.Xaml", # Microsoft Advertising
"Microsoft.GetHelp", # Get Help
"Microsoft.Getstarted", # Microsoft Tips
"Microsoft.WindowsFeedbackHub", # Feedback Hub

# 3D Related
"Microsoft.3DBuilder", # 3D Builder
"Microsoft.MixedReality.Portal", # Mixed Reality Portal
"Microsoft.Microsoft3DViewer", # Mixed Reaility Viewer

# Mobile related
"Microsoft.OneConnect", # Mobile Plans
"Microsoft.Wallet", # Microsoft Pay
"Microsoft.YourPhone", # Your Phone

# Bit of Office related
"Microsoft.Office.Sway", # Microsoft Sway
"Microsoft.Office.OneNote", # Microsoft OneNote
"Microsoft.MicrosoftOfficeHub", # Microsoft Office Hub

# Pre-installed normal programs/websites
"Microsoft.SkypeApp", # Skype
"9E2F88E3.Twitter", # Twitter
"46928bounde.EclipseManager", # Eclipse Manager
"Microsoft.RemoteDesktop", # Remote Desktop
"ActiproSoftwareLLC.562882FEEB491", # Code Writer
"AdobeSystemsIncorporated.AdobePhotoshopExpress", # Photoshop Express
"king.com.CandyCrushSodaSaga", # Candy Crush
"PandoraMediaInc.29680B314EFC2", # Pandora
"Microsoft.NetworkSpeedTest", # Network Speed Test
"D5EA27B7.Duolingo-LearnLanguagesforFree", # Duolingo
"Microsoft.MicrosoftSolitaireCollection", # Microsoft Solitaire

# Unknown / depricated
"Microsoft.ConnectivityStore",
"Microsoft.CommsPhone",
"Microsoft.WindowsPhone",
"Microsoft.Appconnector"

)
foreach ($Package in $PackageList){
    Write-Host "Removing Appx Package: $Package"
    Get-AppxPackage -AllUsers -Name $Package | Remove-AppxPackage
    Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq $Package} | Remove-AppxProvisionedPackage -Online
}

pause
