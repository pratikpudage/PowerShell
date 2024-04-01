<#
.SYNOPSIS
This script facilitates movement of stale computer accounts to the confined OU.


.DESCRIPTION
This script can be used to automate the movement of unused computer objects to a confined disabled computer accounts OU. 
The filter criteria can be custome defined using the variable $DaysInactive.
Specific OUs can be exempted from the search by defining the OU in variable $Exclude.
Target OU to move the computer objects is defined by variable $TargetOU.
Email report in HTML format is sent to the defined recipients and this information can be used to move the computer objects back to the original OU, if required.


.NOTES
Author: Pratik Pudage (Pratik.Pudage@allieddigital.net)


.VERSION
2.0 
- Included HTML Email Reporting.
- Included exclusion criteria.

#>


# ::Importing AD Module::
import-module activedirectory

# ::Defining variables::
$Date = (get-date).ToString('dd/MM/yyyy hh:mm:ss')
$File = "C:\Temp\OLD_Computer.csv"

# Destination OU.
$TargetOU = 'OU=DisabledComputers,DC=DomainName,DC=com'

# Defining the Filter Criteria based on number of Days.
$DaysInactive = 90 
$Time = (Get-Date).Adddays(-($DaysInactive))

# Defining the search base.
$SearchBase = 'DC=DomainName,DC=Com'

# Defining Exceptions (Exclude specific OU from search criteria).
$Exclude = '*OU=Servers,DC=DomainName,DC=Com'
 
# Get all AD computers with lastLogonTimestamp less than the defined number of days.
$Data = Get-ADComputer -SearchBase $SearchBase -Properties LastLogonTimeStamp -Filter {LastLogonTimeStamp -lt $Time} | ? { ($_.distinguishedname -notlike $Exclude)} |
 
select-object Name,DistinguishedName,@{ComputerName="Stamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}}

# Output hostname and lastLogonTimestamp into CSV and HTML.
$Data | Export-Csv $File -notypeinformation
$Data | ConvertTo-Html |Out-file C:\Temp\Report.html

# Input File.
$Input=Import-Csv -Path "C:\Temp\OLD_Computer.csv"

# Module to move computer objects to Disabled Computers OU.

foreach ($line in $Input){
$Name=$line.Name    
        Get-ADComputer $Name | Move-ADObject -TargetPath $TargetOU
}


$Output = Get-Content .\Report.html |Out-String


# ::Module to send the email report::
Send-MailMessage `
-To Recipient@DomainName.com `
-From ADHealthChecks@DomainName.com `
-Subject "Moved Disabled Computers Report for $Date" `
-Body $Output -BodyAsHtml `
-SmtpServer SMTP.DomainName.com