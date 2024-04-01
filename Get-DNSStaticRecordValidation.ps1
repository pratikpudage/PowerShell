<#
.SYNOPSIS 
Get-DNSStaticRecordValidation.ps1 - Audits static A records in a DNS zone to verify if the systems are live or not. A report in the form of CSV and HTML is generated via email notification.
 
.DESCRIPTION  
This script targets a specific DNS Zone defined under the vairable $DNSTargetZoneName. Specify the target DNS server name under $DNSServerName variable.
 
.OUTPUTS 
Results are sent as email notification which included a CSV and HTML file and the script can be scheduled using Task Scheduler. 
 
.NOTES 
Written by: Pratik Pudage
 

Find me on: 
* Github:  https://github.com/pratikpudage/PowerShell
* TechNet: https://social.technet.microsoft.com/profile/pratik%20pudage/
* Email:   pratikpudage80@gmail.com
 
Change Log 
V1.00, 01/20/2021 - Initial version 

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



    .IsOnline {

        background: #67f58d;
    }
    
  
    .IsOffline {

        background: #f59667;
    }

    
    
</style>
"@

#Import PS DNS Module
Import-Module DNSServer

# Pre cleanup
Remove-Item .\DNSStaticRecordsAuditOutput.csv, .\DNSStaticRecordsAudit.html -ErrorAction SilentlyContinue

# Define Variables
$Month = (Get-Date).ToString('MMMM')
$Date = (Get-Date).ToString('MMMM yyyy')
$Year = Get-Date -Format "yyyy"
$TargetDNSZoneName = 'DNSZoneName'
$DNSServer = 'DNSServerFQDN'

$OutputCSVFile = Set-Content .\DNSStaticRecordsAuditOutput.csv 'HostName,IPAddress,RecordType,SystemStatus'


$StaticRecords = Get-DnsServerResourceRecord -ZoneName $TargetDNSZoneName -ComputerName $DNSServer -RRType A | Where Timestamp -eq $Null | Select -Property HostName,RecordType -ExpandProperty RecordData
$NumberOfRecords = $StaticRecords | Measure-Object HostName | Select-Object -Property Count

ForEach($StaticRecord in $StaticRecords){ 

$ICMPTest = Test-NetConnection -ComputerName $StaticRecord.HostName 
    If($ICMPTest.PingSucceeded -eq 'True'){
    Add-Content -Path .\DNSStaticRecordsAuditOutput.csv -Value "$($StaticRecord.HostName),$($StaticRecord.IPv4Address.IPAddressToString),$($StaticRecord.RecordType),Online"

    }Else{
         $TCPTest1 = Test-NetConnection -ComputerName $StaticRecord.HostName -Port 80
                If($TCPTest1.TcpTestSucceeded -eq 'True') {
                    Add-Content -Path .\DNSStaticRecordsAuditOutput.csv -Value "$($StaticRecord.HostName),$($StaticRecord.IPv4Address.IPAddressToString),$($StaticRecord.RecordType),Online"
        }
    
                Else{
                    $TCPTest2 = Test-NetConnection -ComputerName $StaticRecord.HostName -Port 443
                        If($TCPTest2.TcpTestSucceeded -eq 'True') {
                            Add-Content -Path .\DNSStaticRecordsAuditOutput.csv -Value "$($StaticRecord.HostName),$($StaticRecord.IPv4Address.IPAddressToString),$($StaticRecord.RecordType),Online"
                }
                
                        Else{
                            Add-Content -Path .\DNSStaticRecordsAuditOutput.csv -Value "$($StaticRecord.HostName),$($StaticRecord.IPv4Address.IPAddressToString),$($StaticRecord.RecordType),Offline"
                     }
                     }
                
          }
          }
          


$Report = Import-Csv .\DNSStaticRecordsAuditOutput.csv | Sort-Object -Property SystemStatus | ConvertTo-Html -Property HostName,IPAddress,RecordType,SystemStatus -PreContent "<h2>DomainName: DNS Static Records Validation for DNS Zone $($TargetDNSZoneName) $($Date)</h2>"
$Report = $Report -replace '<td>Online</td>','<td class="IsOnline">Online</td>'
$Report = $Report -replace '<td>Offline</td>','<td class="IsOffline">Offline</td>'


$Report = ConvertTo-Html -Body "$Report" -Head $Header -Title "DomainName: DNS Static Records Audit for $($TargetDNSZoneName) $($Date)"`
-PostContent "<p id='Footer'>Monthly DNS Static Records Audit for the month of $($Date).This is an automated script which runs every 5th day of the month from $($env:computername).<br>This script enumerates all static A records from DNS Zone $($TargetDNSZoneName) and then validates each record first using ICMP, followed by TCP test on port 80 and 443.</p>"

$Report | Out-File .\DNSStaticRecordsAudit.html


#Email
Send-MailMessage `
        -To "Admin@Domain.com" `
        -From "Notification@Domain.com" `
        -Subject "DomainName: Monthly DNS Static Records Audit for $($TargetDNSZoneName) $($Date)" `
        -SmtpServer "smtp.domain.com" `
        -BodyAsHTML ($Report |Out-String) -Encoding ([System.Text.Encoding]::UTF8) `
        -Attachments .\DNSStaticRecordsAuditOutput.csv, .\DNSStaticRecordsAudit.html