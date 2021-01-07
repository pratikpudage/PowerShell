<#
.SYNOPSIS
This script audits the mailbox permissions set on all the mailboxes within the Exchange environment.

.DESCRIPTION
This script audits the mailbox permissions set on all the mailboxes within the Exchange environment.
A detailed report of "Send As" and "Full" mailbox rights is generated in the output file .\MailboxAuditResults.csv 


.NOTES
Author: Pratik Pudage (PratikPudage@hotmail.com)

#>

Import-Module ActiveDirectory
$OutFile = ".\MailboxAuditResults.csv"
"DisplayName" + "," + "Alias" + "," + "Email" + "," + "Department" + "," + "AD Account Enabled" + "," + "Full Access" + "," + "Send As" | Out-File $OutFile -Force
 
$Mailboxes = Get-Mailbox -resultsize unlimited | Select Identity, Alias, DisplayName, DistinguishedName, SAMAccountName
ForEach ($Mailbox in $Mailboxes) {
	$SendAs = Get-ADPermission $Mailbox.DistinguishedName | ? {$_.ExtendedRights -like "Send-As" -and $_.User -notlike "NT AUTHORITY\SELF" -and !$_.IsInherited} | % {$_.User}
	$FullAccess = Get-MailboxPermission $Mailbox.Identity | ? {$_.AccessRights -eq "FullAccess" -and !$_.IsInherited} | % {$_.User}
    $ADDetails = Get-ADUser $Mailbox.SAMAccountName -Properties *
 
	$Mailbox.DisplayName + "," + $Mailbox.Alias + "," + $ADDetails.Mail + "," + $ADDetails.Department + "," + $ADDetails.Enabled + "," + $FullAccess + "," + $SendAs | Out-File $OutFile -Append
}