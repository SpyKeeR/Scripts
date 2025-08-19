# Variables
# Changer l’adresse email de l’expéditeur
$MSender = "appsend@xxxxxxxxxxxxxx.com"
# Changer l’adresse IP du serveur de messagerie
$MServer = "xxx.xxx.xxx.233"
$port = "587"
#Identifiants Mail SMTP APPSEND
$emailSmtpUser = "EXCH-XXXXXXXXXXX\appsend"
$emailSmtpPass = "XXXXXXXXXXXXXXX"
# Indiquer le chemin LDAP de votre annuaire
$Ldappath = « OU=Utilisateurs,OU=GB-INFORMATIQUE,DC=XXXXXXXXXXX,DC=fr »

# Fonction pour générer le mail
function Send-SMTPmail($to, $from, $subject, $body, $attachment, $cc, $bcc, $port, $timeout, $smtpserver, [switch] $html, [switch] $alert)
{
    if ($smtpserver -eq $null) {$smtpserver = $MServer}
    $mailer = new-object Net.Mail.SMTPclient($smtpserver, $port)
    if ($port -ne $null) {$mailer.port = $port}
    if ($timeout -ne $null) {$mailer.timeout = $timeout}
    $msg = new-object Net.Mail.MailMessage($from,$to,$subject,$body)
    if ($html) {$msg.IsBodyHTML = $true}
    if ($cc -ne $null) {$msg.cc.add($cc)}
    if ($bcc -ne $null) {$msg.bcc.add($bcc)}
    if ($alert) {$msg.Headers.Add(« message-id », « <3bd50098e401463aa228377848493927-1> »)}
    if ($attachment -ne $null)
    {
        $attachment = new-object Net.Mail.Attachment($attachment)
        $msg.attachments.add($attachment) 
    }
	#Rajout de l'authentification SSL
		$mailer.EnableSsl = $true
		$mailer.Credentials = New-Object System.Net.NetworkCredential( $emailSmtpUser , $emailSmtpPass )
    $mailer.send($msg)
} 

# Programme principal
# Chargement du module PowerShell Quest
add-PSSnapin -Name Quest.ActiveRoles.ADManagement -ErrorAction SilentlyContinue
$Today = get-date -format d
$users = Get-QADUser -enable -SizeLimit 0 -Searchroot $Ldappath | where-object {$_.PasswordNeverExpires -eq $false} | Select-Object name,mail,passwordexpires,samaccountname
foreach ($user in $users)
{
     if ($user.’passwordexpires’)
     {
        $usrmail = $user.mail
        $usrname = $user.name
        $usrlogin = $User.sAMAccountName
        $ExpiredDate = ($user.’passwordexpires’).adddays(-14)
        $today = (get-date).date
        $difference = $ExpiredDate – $today
        if ($difference.Days -eq 14)
        {
               $MSubject = « Votre mot de passe va expirer dans 14 jours. »
               $Mbody = « Bonjour $usrname,<br><br>Votre <b>mot de passe de compte utilisateur ($usrlogin)</b> va expirer dans quatorze jours.<br><br>Merci de bien vouloir changer votre mot de passe en appuyant sur CTRL+ALT+SUPP. »
               Send-SMTPmail -to $($user.mail) -from $MSender -subject $MSubject -cc $MSender -smtpserver $MServer -body $Mbody -html
            }
            elseif ($difference.Days -eq 5)
            {
               $MSubject = « Votre mot de passe va expirer dans 5 jours. »
               $Mbody = « Bonjour $usrname,<br><br>Votre <b>mot de passe de compte utilisateur ($usrlogin)</b> va expirer dans cinq jours.<br><br>Merci de bien vouloir changer votre mot de passe en appuyant sur CTRL+ALT+SUPP. »
               Send-SMTPmail -to $($user.mail) -from $MSender -subject $MSubject -cc $MSender -smtpserver $MServer -body $Mbody -html
            }
            elseif ($difference.Days -eq 3)
            {
                $MSubject = « Votre mot de passe va expirer dans 3 jours. »
                $Mbody = « Bonjour $usrname,<br><br>Votre <b>mot de passe de compte utilisateur ($usrlogin)</b> va expirer dans trois jour.<br><br>Merci de bien vouloir changer votre mot de passe en appuyant sur CTRL+ALT+SUPP. »
                Send-SMTPmail -to $($user.mail) -from $MSender -subject $MSubject -cc $MSender -smtpserver $MServer -body $Mbody -html
            }
     }
}