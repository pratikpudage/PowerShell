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

# CSS codes for HTML Formatting
$Header = @"
<style>

    h1 {

        font-family: Arial, Helvetica, sans-serif;
        color: #e68a00;
        font-size: 28px;

    }

    
    h2 {

        font-family: Arial, Helvetica, sans-serif;
        color: #000099;
        font-size: 16px;

    }

    
    
   table {
		font-size: 12px;
		border: 0px; 
		font-family: Arial, Helvetica, sans-serif;
	} 
	
    td {
		padding: 4px;
		margin: 0px;
		border: 0;
	}
	
    th {
        background: #20756e;
        background: linear-gradient(#49708f, #293f50);
        color: #fff;
        font-size: 11px;
        padding: 10px 15px;
        vertical-align: middle;
	}

    tbody tr:nth-child(even) {
        background: #f0f0f2;
    }
    


    #Footer {

        font-family: Arial, Helvetica, sans-serif;
        color: #ff3300;
        font-size: 12px;

    }



    .PresentStatus {

        background: #f59667;
    }
    
  
    .NotPresentStatus {

        background: #67f58d;
    }

    .NotSetStatus {

        background: #f567d9;
    }




</style>
"@

# ::Importing AD Module::
import-module activedirectory

# ::Pre Clean-up::
Remove-Item .\UsersNotLoggedin30Days.csv, .\UsersNotLoggedin30Days_HTMLReport.html -ErrorAction SilentlyContinue

# ::Defining variables::
$Date = (get-date).ToString('MM/dd/yyyy')
$File = ".\UsersNotLoggedin30Days.csv"
$HTMLReport = ".\UsersNotLoggedin30Days_HTMLReport.html"


# Defining the Filter criteria based on number of Days.
$DaysInactive = 30
$Time = (Get-Date).Adddays(-($DaysInactive))

# Defining the search base.
$SearchBase = 'DC=Domain,DC=com'

# Defining Exceptions (Exclude specific OU from search criteria).
$Exclude1 = '*OU=Employee Retention Accounts,DC=Domain,DC=com'
$Exclude2 = '*OU=Ex-Employees,DC=Domain,DC=com'
$Exclude3 = '*OU=ImageNOW,DC=Domain,DC=com'
$Exclude4 = '*OU=Service Accounts,DC=Domain,DC=com'
$Exclude5 = '*CN=Monitoring Mailboxes,CN=Microsoft Exchange System Objects,DC=Domain,DC=com'

 
# Get all AD User Accounts with lastLogonTimestamp less than the defined number of days.
$Data = Get-ADUser -SearchBase $SearchBase -Properties LastLogonTimeStamp,DistinguishedName,Enabled -Filter {LastLogonTimeStamp -lt $Time} | 
Where {($_.Enabled -eq 'True') -and ($_.DistinguishedName -notlike $Exclude1) -and ($_.DistinguishedName -notlike $Exclude2) -and ($_.DistinguishedName -notlike $Exclude3) -and ($_.DistinguishedName -notlike $Exclude4) -and ($_.DistinguishedName -notlike $Exclude5)} |
 
select-object Name,SAMAccountName,@{Name="LastLogonTimeStamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}},Enabled,DistinguishedName |Sort-Object -Property LastLogonTimeStamp


# Output User name and lastLogonTimestamp into CSV and HTML.
$Data | Export-Csv $File -notypeinformation

$HTMLData = Import-CSV .\UsersNotLoggedin30Days.csv | Sort-Object -Property Name |ConvertTo-Html -Property Name,SAMAccountName,LastLogonTimeStamp,Enabled,DistinguishedName `
-PreContent "<h2>Domain: Obsolete AD Account Audit Report for Users not logged in since past 30 days.</h2><br/><p id='Footer'>Report generation date: $($Date)</p>"

$HTMLData = ConvertTo-HTML -Body "$HTMLData" -Head $Header -Title "Domain: List Obsolete AD Account not logged in since past 30 days."`
-PostContent "<p id='Footer'>Obsolete AD Accounts not logged in since past 30 days.This is an automated script which runs every 5th day of the month from $($env:computername).<br/><br/> The scope of this script doesn't include OUs mentioned below.<br/> $($Exclude1)<br/>$($Exclude2)<br/>$($Exclude3)<br/>$($Exclude4)<br/>$($Exclude5)<br/></p>"

$HTMLData |Out-file $HTMLReport


# ::Module to send the email report::
Send-MailMessage `
    -SmtpServer SMTP.Domain.com `
    -To admin@Domain.net `
    -From Notification@Domain.com `
    -Subject "Domain: Obsolete AD User Account Audit Report $($Date)." `
    -BodyAsHTML ($HTMLData |Out-String) -Encoding ([System.Text.Encoding]::UTF8) `
    -Attachments $File, $HTMLReport