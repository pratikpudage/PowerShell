# Install Azure Migrate PowerShell module.
Install-Module -Name Az.Migrate

# Sign in to your Microsoft Azure subscription.
Connect-AzAccount

# Get the list of Azure subscriptions you have access to.
Get-AzSubscription

# Select the Azure subscription that has your Azure Migrate project to work with.
Set-AzContext -SubscriptionId "Sub_Id"

# Retrive Azure Migrate Project.
Get-AzMigrateProject -Name Az-Migration -ResourceGroupName "RG_Name" |fl

# Get Azure Migrate Discovered VMs
$DiscoveredServers = Get-AzMigrateDiscoveredServer -ProjectName Az-Migration -ResourceGroupName "RG_Name" -ApplianceName "AzMigrate_ApplianceName" |Select DisplayName,Discovered*

# Retrieve the replicating VM details by using the discovered VM identifier
ForEach($DiscoveredServer in $DiscoveredServers){
$ReplicatingServer = Get-AzMigrateServerReplication -ProjectName Az-Migration -ResourceGroupName "RG_Name" -Filter {$_.MachineName -eq $DiscoveredServer.DisplayName}
}

# Retrieve replicating VM details using replicating VM identifier
$ReplicatingServer = Get-AzMigrateServerReplication -DiscoveredMachineId 'Machine_Id'

-TargetObjectID 205bc835-3b2a-11eb-a7ac-005056977a60


Get-AzMigrateDiscoveredServer -ProjectName Az-Migration -ResourceGroupName "RG_Name"
Get-AzMigrateJob -ProjectName Az-Migration -ResourceGroupName "RG_Name"
