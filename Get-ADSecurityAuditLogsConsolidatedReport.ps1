<#
.SYNOPSIS 
Get-ADSecurityAuditLogs.ps1 - Reports AD object changes based on AD Serice Changes Auditing events. 
The script can be scheduled to run every hour to capture events generated in past 1 day and send email notification.
 
.DESCRIPTION  
This script targets all domain controllers to read the Security events 5136,5137,5139 and 5141.
 
.OUTPUTS 
Results are sent over email notification which includes a HTML report and the script can be scheduled using Task Scheduler. 
 
.NOTES 
Written by: Pratik Pudage
 

Find me on: 
* Github:  https://github.com/pratikpudage/PowerShell
* TechNet: https://social.technet.microsoft.com/profile/pratik%20pudage/
* Email:   pratikpudage80@gmail.com
 
Change Log 
V1.00, 02/02/2021 - Initial version 

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



    .IsDSAttributeAdd {

        background: #67f58d;
    }
    
  
    .IsDSAttributeDelete {

        background: #f59667;
    }

    .IsADObjectMoved {

        background: #6cacf0;
    }

    .IsADObjectDeleted {

        background: #fc83ba;
    }
    
    
</style>
"@

# Pre cleanup
Remove-Item .\ConSolidatedSecEvents.csv, .\ConsolidatedSecEvents.html, .\ConsolidatedADSecReport.xlsx -ErrorAction SilentlyContinue

# Time
$PastTime = (Get-Date).AddDays(-1).ToString('MM/dd/yyy HH:mm tt')
$CurrentTime = (Get-Date).ToString('MM/dd/yyy HH:mm tt')

# Define servers to check for Security event logs
$DomainControllers = 'DC1' , 'DC2'

# Filter Hashtable for Get-WinEvent cmdlet
$Filter=@{
StartTime = (Get-Date).AddDays(-1)
EndTime = (Get-Date)
LogName = 'Security'
ID = 5136,5137,5139,5141
}

# Event Lookup Logic
ForEach($DomainController in $DomainControllers){

$Events = Get-WinEvent -ComputerName $DomainController -FilterHashtable $Filter |Select |?{$_.Message -notlike '*$*'} -ErrorAction SilentlyContinue

$KnownValues = @{
    '%%14674' = 'ValueAdded';
    '%%14675' = 'ValueDeleted';
    '%%14676' = 'ADObjectMoved';
    '%%14679' = 'ADObjectDeleted';
          }

ForEach ($Event in $Events)
{
    $eventXML = [xml]$event.ToXml()
    if($event.id -eq '5141') {$Action = $EventXML.Event.EventData.Data[11].'#text'.ToString()}
    else { $Action = $EventXML.Event.EventData.Data[14].'#text'.ToString()}

    if($event.id -eq '5141') {$Attribute = $EventXML.Event.EventData.Data[10].'#text'.ToString()}
    else { $Attribute = $EventXML.Event.EventData.Data[11].'#text'.ToString()}

    $Target = $eventXML.Event.EventData.Data[8].'#text'.Substring(3)
    $Target = $Target.Substring(0,$Target.IndexOf(','))
    
    foreach ($i in $KnownValues.Keys) 
    {
    $Action = $Action -replace $i, $KnownValues[$i]
    }
        
    $EventArray = New-Object -TypeName PSObject -Property @{

    EventID = $event.id
    TimeCreated = $event.timecreated
       
    #Parsing Requestor attribute.
    Requestor = $eventXML.Event.EventData.Data[3].'#text'
    #Parsing Target attribute.
    Target = $Target
    #Parsing AD attribute in scope of change
    Attribute = $Attribute
    #Parsing attribute value in scope of change.
    AttributeValue = $eventXML.Event.EventData.Data[13].'#text'
    #Parsing Location attribute.
    Location = $eventXML.Event.EventData.Data[8].'#text'
    #Parsing DomainController name.
    DomainController = $eventXML.Event.System.Computer
    #Parsing action taken on attribute.
    Action = $Action
    }


    $eventArray | select TimeCreated,Requestor,Action,EventID,Target,Attribute,AttributeValue,Location,DomainController | Export-Csv .\ConsolidatedSecEvents.csv -NoTypeInformation -Append
}

}


# HTML Formatting
$Report = Import-Csv .\ConsolidatedSecEvents.csv |Sort-Object -Property TimeCreated `
|ConvertTo-Html -Property TimeCreated,Requestor,Action,EventID,Target,Attribute,AttributeValue,Location,DomainController `
-PreContent "<h2>Consolidated AD Security Audit Logs from $PastTime to $CurrentTime for ADSL US DCs.<br/> Please check attached Excel file for more details.</h2>"

$Report = $Report -replace '<td>ValueAdded</td>','<td class="IsDSAttributeAdd">ValueAdded</td>'
$Report = $Report -replace '<td>ValueDeleted</td>','<td class="IsDSAttributeDelete">ValueDeleted</td>'
$Report = $Report -replace '<td>ADObjectMoved</td>','<td class="IsADObjectMoved">ADObjectMoved</td>'
$Report = $Report -replace '<td>ADObjectDeleted</td>','<td class="IsADObjectDeleted">ADObjectDeleted</td>'

$Report = ConvertTo-Html -Body "$Report" -Head $Header -Title "ADSL: Consolidated AD Security Audit Logs from $PastTime to $CurrentTime for ADSL US DCs."`
-PostContent "<p id='Footer'>Consolidated AD Audit Logs Report.This is an automated script which runs daily at 00:00 HRS from $($env:computername).</p>"

$Report | Out-File .\ConsolidatedSecEvents.html


#Excel Formatting
Import-Csv .\ConsolidatedSecEvents.csv |Export-Excel .\ConsolidatedADSecReport.xlsx `
-IncludePivotTable -PivotRows Requestor -PivotData @{TimeCreated="Count"} -PivotTableName PivotData `
-IncludePivotChart -ChartType PieExploded3D -ShowPercent


#Email Report
Send-MailMessage `
        -To "ppudage@allieddigital.net" `
        -From "AlertNotification@allieddigital.net" `
        -Subject "Consolidated AD Objects Modification Report for ADSL US DCs $PastTime to $CurrentTime" `
        -SmtpServer "ADSLUSLVEXCH01.allieddigital.net" `
        -BodyAsHTML ($Report |Out-String) -Encoding ([System.Text.Encoding]::UTF8) `
        -Attachments .\ConsolidatedADSecReport.xlsx, .\ConsolidatedSecEvents.html
