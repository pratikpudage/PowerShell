<#
 
.DESCRIPTION
Use this script to check if SMBv1 is enabled on multiple computers.

.NOTES
Author: Pratik Pudage (PratikPudage@hotmail.com)

.IMPORTANT
Tested on Windows Server 2012 Operating System

#>

$Results = @()
$Computers = Get-Content .\ServerList.txt

    ForEach ($Computer In $Computers){
$SMBv1 = Invoke-Command -ComputerName $Computer -ScriptBlock {Get-SmbServerConfiguration | Select EnableSMB1Protocol}
  
$Properties = @{
                MachineName = $SMBv1.PSComputerName
                SMBv1Enabled = $SMBv1.EnableSMB1Protocol
  }   

$Results += New-Object psobject -Property $properties
  
  }


$Results |Select-Object MachineName, SMBv1Enabled |ft