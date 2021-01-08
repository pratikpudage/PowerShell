<#
.SYNOPSIS
This script will list the unused/obsolete/inactive AD user accounts.


.DESCRIPTION
This script can be used to automate the reporting of unused/obsolete/inactive AD user account which have not logged in since specific number of days. 
Several OUs like Service Accounts, Disabled Users, etc. can be filtered out from the search. The exceptions can be defined under # Defining Exceptions section in the script.
Email report in HTML format is sent to the predefined recipients and this information can be used to move the AD user accounts to the Disabled Users OU, if required.


.NOTES
Author: Pratik Pudage (PratikPudage80@Gmail.com)


.VERSION
2.0 
- Included HTML Email Reporting.
- Included exclusion criteria.

#>


# ::Importing AD Module::
import-module activedirectory

# ::Defining variables::
$Date = (get-date).ToString('dd/MM/yyyy')
$File = ".\UsersNotLoggedin90Days.csv"


# Defining the Filter criteria based on number of Days.
$DaysInactive = 90 
$Time = (Get-Date).Adddays(-($DaysInactive))

# Defining the search base.
$SearchBase = 'DC=Domain,DC=Com'

# Defining Exceptions (Exclude specific OU from search criteria).
$Exclude1 = '*OU=IT Maintenance,DC=Domain,DC=Com'
$Exclude2 = '*OU=Service Accounts,DC=Domain,DC=Com'
$Exclude3 = '*OU=Disabled Users,DC=Domain,DC=COM'

 
# Get all AD User Accounts with lastLogonTimestamp less than the defined number of days.
$Data = Get-ADUser -SearchBase $SearchBase -Properties LastLogonTimeStamp,DistinguishedName,Enabled -Filter {LastLogonTimeStamp -lt $Time} | Where {($_.Enabled -eq 'True') -and ($_.DistinguishedName -notlike $Exclude1) -and ($_.DistinguishedName -notlike $Exclude2) -and ($_.DistinguishedName -notlike $Exclude3)} |
 
select-object Name,Enabled,DistinguishedName,@{Name="LogonTimeStamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}}


# HTML Formatting for Email
$style = $Style + "<style>BODY{font-family: Calibri; font-size: 10pt;}"
$style = $style + "TABLE{border-collapse: collapse; Width: 100%; }"
$style = $style + "TH{text-align: center; background: #1bc8e2; padding: 8px; }"
$style = $style + "TD{text-align: center; background: #f2f2f2; padding: 8px; }"
$style = $style + "</style>"


# Output User name and lastLogonTimestamp into CSV and HTML.
$Data | Export-Csv $File -notypeinformation
$Data | ConvertTo-Html -Head $Style |Out-file .\Report.html


$Body = Get-Content .\Report.html |Out-String


# ::Module to send the email report::
Send-MailMessage `
-SmtpServer SMTP.DomainName.com `
-To Recipient@DomainName.com `
-From ADHealthChecks@DomainName.com `
-Subject "Obsolete AD User Account Report for $Date" `
-Body $Body -BodyAsHtml -Encoding ([System.Text.Encoding]::UTF8)
