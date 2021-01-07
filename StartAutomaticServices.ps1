<# 
.SYNOPSIS
Use this script to start automatic services which have failed to start.

.DESCRIPTION
This script attempts to start those services which are set to start automatically, but are not running. 
If the services fail to start, the list of such services is generated to output file .\ServicesStatus.txt.
Provide Server names in .\ServerList.txt

.IMPORTANT
This script must be run with elevated privileges.
Input file - ServerList.txt
Output file - FailedServices.txt
Failed Services Output - ServicesStatus.txt


.NOTES
Author: Pratik Pudage (PratikPudage80@Gmail.com)

#>

$Date = Get-Date -Format G
$Computers = Get-Content .\ServerList.txt
Foreach ($Computer in $Computers) {

$Services = Get-Service -ComputerName $Computer | Where-Object {($_.StartType -eq "Automatic") -and ($_.Status -eq "Stopped")}

Foreach ($Service in $Services) {

Write "$Date,$Computer,$($Service.DisplayName)" |Out-file .\FailedServices.txt -Append

Try {
Start-Service -Name $Service.Name -ErrorAction Stop
}

Catch {
Write "$Date Automatic Service $($Service.DisplayName) failed to start on $Computer" |Out-file .\ServicesStatus.txt -Append
}
}
}