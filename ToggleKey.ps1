Clear-Host
Echo "Toggling Scroll Lock Key..."  
$WShell = New-Object -com "Wscript.Shell" 
while ($true) { 
$WShell.sendkeys("{SCROLLLOCK}") 
Start-Sleep -Milliseconds 200   
$WShell.sendkeys("{SCROLLLOCK}") 
Start-Sleep -Seconds 250
}
