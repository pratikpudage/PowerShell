<# 
.SYNOPSIS 
Get-HomeFolderAudit.ps1 - Audits if Home Folder profile still exists for the disabled user. 
 
.DESCRIPTION  
This script targets a specific OU to 
 
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


# AD Module
Import-Module ActiveDirectory


# Pre cleanup
Remove-Item .\HomeFoldersAuditOutput.csv, .\HomeFoldersAuditOutputHeader.csv, .\HomeFoldersAuditForDisabledAccounts.html -ErrorAction SilentlyContinue


# Variables
$Month = (Get-Date).AddMonths(-1).ToString('MMMM')
$Date = (Get-Date).AddMonths(-1).ToString('MMMM yyyy')
$Year = Get-Date -Format "yyyy"
$TargetOU = "OU=Ex-Employees,DC=Domain,DC=local"
$TermedUsers = Get-ADUser -SearchBase $TargetOU -Properties * -Filter {Enabled -eq $False}
$OutputCSVFile = Set-Content .\HomeFoldersAuditOutput.csv 'HomeFolderStatus,SamAccountName,Description,ADAccountEnabled,HomeFolderPath,HomeFolderSize(MB),FolderCreationTime,FolderLastWriteTime,FolderLastAccessTime'

ForEach($TermedUser in $TermedUsers) {

If($TermedUser.HomeDirectory -eq $null) {
Add-Content -Path .\HomeFoldersAuditOutput.csv -Value "NotSet,$($TermedUser.SamAccountName),$($TermedUser.Description),$($TermedUser.Enabled),NA,NA,NA,NA,NA"

}Else {
$TestDirectory = Test-Path $TermedUser.HomeDirectory

If($TestDirectory -eq 'True'){

$HomeFolderProp = Get-Item $TermedUser.HomeDirectory |Select CreationTime,LastWriteTime,LastAccessTime
$HomeFolderSize = "{0:N2} MB" -f ((Get-ChildItem '$($TermedUser.HomeDirectory)' -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum / 1MB)
Add-Content -Path .\HomeFoldersAuditOutput.csv -Value "Present,$($TermedUser.SamAccountName),$($TermedUser.Description),$($TermedUser.Enabled),$($TermedUser.HomeDirectory),$($HomeFolderSize),$($HomeFolderProp.CreationTime),$($HomeFolderProp.LastWriteTime),$($HomeFolderProp.LastAccessTime)"

}Else{
Add-Content -Path .\HomeFoldersAuditOutput.csv -Value "NotPresent,$($TermedUser.SamAccountName),$($TermedUser.Description),$($TermedUser.Enabled),NA,NA,NA,NA,NA"
}
}
}


$Report = Import-Csv .\HomeFoldersAuditOutput.csv | Sort-Object -Property HomeFolderStatus | ConvertTo-Html -Property HomeFolderStatus,SamAccountName,Description,ADAccountEnabled,HomeFolderPath,HomeFolderSize'(MB)',FolderCreationTime,FolderLastWriteTime,FolderLastAccessTime -PreContent "<h2>ClientName: Home Folder Audit for Disabled Accounts $($Date)</h2>"
$Report = $Report -replace '<td>Present</td>','<td class="PresentStatus">Present</td>'
$Report = $Report -replace '<td>NotPresent</td>','<td class="NotPresentStatus">NotPresent</td>'
$Report = $Report -replace '<td>NotSet</td>','<td class="NotSetStatus">NotSet</td>'


$Report = ConvertTo-Html -Body "$Report" -Head $Header -Title "ClientName: Home Folder Audit for Disabled Accounts"`
-PostContent "<p id='Footer'>Monthly Home Folder Disabled AD Accounts Audit for the month of $($Date).This is an automated script which runs every 5th day of the month from $($env:computername).</p>"

$Report | Out-File .\HomeFoldersAuditForDisabledAccounts.html



#Email
Send-MailMessage `
        -To "Admin@Domain.com"`
        -From "Notification@Domain.com" `
        -Subject "ClientName: Home Folder Audit for Disabled Accounts $($Date)" `
        -SmtpServer "smtp.Domain.com" `
        -BodyAsHTML ($Report |Out-String) -Encoding ([System.Text.Encoding]::UTF8) `
        -Attachments .\HomeFoldersAuditOutput.csv, .\HomeFoldersAuditForDisabledAccounts.html