#############################################################################
#       Author- Ajaz Ahmed
#       Reviewer-    
#       Version- 1.0 
#	Date- 29/5/2018
#	Description- Script to automate Monthly Reporting of Account Expiry
#############################################################################
#############################################################################

import-module ActiveDirectory;

###############################HTMl Report Content############################

$a = "<style>"
$a = $a + "BODY{background-color:White;}"
$a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
$a = $a + "TH{border-width: 1px;padding: 10px;border-style: solid;border-color: black;background-color:#FFC200}"
$a = $a + "TD{border-width: 1px;padding: 10px;border-style: solid;border-color: black;background-color:White}"
$a = $a + "</style>" 


$period = "15"
$Cdate = get-date -Format "MM/dd/yyyy"
$Fdate=(date).Adddays(15)

Search-ADAccount -AccountExpiring -TimeSpan $period | where-object {$_.Enabled -eq $true} | get-aduser -properties Name,samAccountname, AccountExpirationDate, EmailAddress| `
select Name, @{Label="User Logon name"; Expression={$_.samAccountName}},`
 AccountExpirationDate, EmailAddress | Sort-Object AccountExpirationDate `
| ConvertTo-HTML -head $a | Out-File "C:\scripts\AccountExpiry\UserReport.htm"
$report = get-content "C:\scripts\AccountExpiry\UserReport.htm"


$header = "
<p style='font-family:calibri'>Hi Team,</p>
<p style='font-family:calibri'>Please find below the list of User accounts which will be Expiring in next 15 days.</p><br>
"
$sign = "
<p style='font-family:calibri'>Regards, <br>
JML Team<br>
Accenture' 
</p>
 
"


$subject = "IMPORTANT: Fortnight User Expiry Report - $Cdate to $Fdate"

$email = "Email1@Ahmedajaz.com,Email2@Ahmedajaz.com"
$emailCC = "Email3@Ahmedajaz.com,Email4@accenture.com"

$smtphost = "s-tpl-exc01.AhmedajazSMTP.local"
$from = "AccountExpiry@Ahmedajaz.com" 
 
$message ="$header  $report $sign "
$smtp= New-Object System.Net.Mail.SmtpClient $smtphost
$msg = New-Object System.Net.Mail.MailMessage

$msg.To.Add($email)
$msg.cc.Add($emailCC)


$msg.from = $from
$msg.subject = $subject
$msg.body = "<font face = calibri size = 3>$message</font>"
$msg.isBodyhtml = $true 
$smtp.send($msg)
