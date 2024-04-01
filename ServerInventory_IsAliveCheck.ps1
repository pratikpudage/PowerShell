# Function to check if server is alive by pinging
Function Test-ServerAlive {
    Param (
        [string]$IPAddress
    )
    $PingResult = Test-Connection -ComputerName $IPAddress -Count 1 -Quiet
    if ($PingResult) {
        return "Yes"
    }
    else {
        return "No"
    }
}

# Get all Windows servers from Active Directory
$Servers = Get-ADComputer -Filter { OperatingSystem -like "*Windows*Server*" } -Property DNSHostName, OperatingSystem, OperatingSystemServicePack

# Create an array to store the results
$ServerList = @()

# Loop through each server
foreach ($Server in $Servers) {
    $ServerFQDN = $Server.DNSHostName
    $ServerIPAddress = $null
    $IsAvailable = $null
    
    try {
        # Resolve FQDN to IP address
        $ServerIPAddress = [System.Net.Dns]::GetHostAddresses($ServerFQDN) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1 -ExpandProperty IPAddressToString
    }
    catch {
        # If IP address not found, mark server as unavailable
        $IsAvailable = "No"
    }
    
    if ($ServerIPAddress) {
        $IsServerAlive = Test-ServerAlive -IPAddress $ServerIPAddress
        $IsAvailable = $IsServerAlive
    }
    
    # Create a custom object for each server and add it to the list
    $ServerObject = New-Object PSObject -Property @{
        "Server FQDN"       = $ServerFQDN
        "Server IP Address" = $ServerIPAddress
        "Is Available"      = $IsAvailable
        "Operating System"  = $Server.OperatingSystem
        "Service Pack"      = $Server.OperatingSystemServicePack
        
    }
    $ServerList += $ServerObject
}

# Output the results
$ServerList | Export-Csv .\ServerInventory.csv -NoTypeInformation