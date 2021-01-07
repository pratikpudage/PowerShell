<# 
.SYNOPSIS 
Get-HomeFolderAudit.ps1 - Audits if Home Folder profile still exists for the disabled user. 
 
.DESCRIPTION  
This script targets a specific Active Directory OU where Ex-Employee AD accounts are located and scans their Home folder profile path set on the account.
If a valid path is found, the folder size is recorded in the report. The report is then sent via email to required recipients.

Modify the $TargetOU viriable as required to change the scope of the audit.

 
.OUTPUTS 
Results are sent as email notification and the script can be scheduled using Task Scheduler. 
 
.NOTES 
Written by: Pratik Pudage
 

Find me on: 
* Github:  https://github.com/pratikpudage/PowerShell
* TechNet: https://social.technet.microsoft.com/profile/pratik%20pudage/
* Email:   pratikpudage80@gmail.com
 
Change Log 
V1.00, 01/06/2021 - Initial version 

#> 


# AD Module
Import-Module ActiveDirectory


# Pre cleanup
Remove-Item .\HomeFoldersAuditOutput.csv, .\HomeFoldersAuditOutputHeader.csv, .\HomeFoldersAuditForDisabledAccounts.html


# Variables
$Month = (Get-Date).AddMonths(-1).ToString('MMMM')
$Date = (Get-Date).AddMonths(-1).ToString('MMMM yyyy')
$Year = Get-Date -Format "yyyy"
$TargetOU = "OU=$Month,OU=Ex-Employees,DC=Domain,DC=local"
$TermedUsers = Get-ADUser -SearchBase $TargetOU -Properties * -Filter {Enabled -eq $False}

ForEach($TermedUser in $TermedUsers) {

If($TermedUser.HomeDirectory -eq $null) {
Add-Content -Path .\HomeFoldersAuditOutput.csv -Value "NotSet,$($TermedUser.SamAccountName),$($TermedUser.Description),$($TermedUser.Enabled),NA,NA"


}Else {
$TestDirectory = Test-Path $TermedUser.HomeDirectory

If($TestDirectory -eq 'True'){

$HomeFolderSize = "{0:N2} MB" -f ((Get-ChildItem '$($TermedUser.HomeDirectory)' -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum / 1MB)
Add-Content -Path .\HomeFoldersAuditOutput.csv -Value "Present,$($TermedUser.SamAccountName),$($TermedUser.Description),$($TermedUser.Enabled),$($TermedUser.HomeDirectory),$($HomeFolderSize)"



}Else{
Add-Content -Path .\HomeFoldersAuditOutput.csv -Value "NotPresent,$($TermedUser.SamAccountName),$($TermedUser.Description),$($TermedUser.Enabled),NA,NA"
}
}
}
Import-Csv .\HomeFoldersAuditOutput.csv -Header HomeFolderStatus,SamAccountName,Description,ADAccountEnabled,HomeFolderPath,HomeFolderSize'(MB)' |Export-Csv .\HomeFoldersAuditOutputHeader.csv -NoTypeInformation


# HTML Formatting for Email
$style = $Style + "<style>BODY{font-family: Calibri; font-size: 10pt;}"
$style = $style + "TABLE{border-collapse: collapse; Width: 75%; }"
$style = $style + "TH{text-align: center; background: #1bc8e2; padding: 8px; }"
$style = $style + "TD{text-align: center; background: #f2f2f2; padding: 8px; }"
$style = $style + "</style>"

Import-Csv .\HomeFoldersAuditOutputHeader.csv | ConvertTo-Html -Head $Style | Out-File .\HomeFoldersAuditForDisabledAccounts.html

$Body = Get-content .\HomeFoldersAuditForDisabledAccounts.html |Out-String




#Email
Send-MailMessage `
        -To "emailaddress@domain.com"`
        -From "Notification@domain.com" `
        -Subject "Home Folder Audit for Disabled Accounts $($Date)" `
        -SmtpServer "smtp.domain.com" `
        -Body "Monthly Home Folder Disabled AD Accounts Audit for the month of $($Date).This is an automated script which runs on every 5th day of the month from $($env:computername). $Body" -BodyAsHtml -Encoding ([System.Text.Encoding]::UTF8)