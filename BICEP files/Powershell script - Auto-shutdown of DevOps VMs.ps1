<#
.SYNOPSIS
    Sets auto-shutdown for all VMs with a specific tag in a specific resource group.
.DESCRIPTION
    This runbook iterates through all VMs with a specific tag in a specified resource group 
    and sets them to auto-shutdown a set number of hours after being turned on.
    It distinguishes between development and testing VMs and shuts them down
    after an appropriate amount of time (7 hours for development and 2 for testing VMs, 
    one hour more than their declared time of use, to allow for flexibility).
.PARAMETER ResourceGroupName
    The name of the resource group containing the VMs.
.PARAMETER TagName
    The name of the tag to filter the VMs.
.PARAMETER TagValue
    The value of the tag to filter the VMs.
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$TagName,

    [Parameter(Mandatory = $true)]
    [string]$TagValue

)

# Try to connect to Azure using the managed identity of the Automation Account
try {
    "Logging in to Azure with managed identity..."
    Connect-AzAccount -Identity
    "Logged in to Azure with managed identity"

    # Get the current subscription context
    $context = Get-AzContext
    if (-not $context) {
        Write-Error "Failed to retrieve the subscription context."
        exit
    }

    Write-Output "Using subscription: $($context.Subscription.Id)"
}
# Catch the exception in case the operation is not successful.
catch {
    $ErrorMessage = "Could not authenticate to Azure using managed identity. Error: $_"
    throw $ErrorMessage
}

# Check if the resource group exists
$resourceGroups = Get-AzResourceGroup
if (-not ($resourceGroups.ResourceGroupName -contains $ResourceGroupName)) {
    Write-Error "Resource group '$ResourceGroupName' does not exist."
    exit
}

# Get all VMs with the specific tag in the specified resource group
try {
    $vms = Get-AzVM -ResourceGroupName $ResourceGroupName | Where-Object { $_.Tags[$TagName] -eq $TagValue }
    if ($vms.Count -eq 0) {
        Write-Output "No VMs found with tag '$TagName' and value '$TagValue' in resource group '$ResourceGroupName'."
    }
} catch {
    Write-Error "Failed to retrieve VMs. Error: $_"
    exit
}

# Iterating through the VMs
foreach ($vm in $vms) {
    # Calculate the shutdown time depending on the VM environment
    $timeZoneId = "E. Europe Standard Time" 
    $shutdownTime = (Get-Date)
    switch ($TagValue) {
    "development" { 
        $shutdownTime.AddHours(7).ToString("HH:mm")
     }
    "test" { 
        $shutdownTime.AddHours(2).ToString("HH:mm")
    }
    default { $shutdownTime.AddHours(9).ToString("HH:mm") } # Optional: Define a default value
    }
    
    # Define the resource URI for auto-shutdown with a supported API version
    $resourceUri = "/subscriptions/$($context.Subscription.Id)/resourceGroups/$ResourceGroupName/providers/Microsoft.Compute/virtualMachines/$($vm.Name)/providers/Microsoft.Insights/autoShutdownSettings"

    # Try to create or update the auto-shutdown schedule
    try {
        # The script should run only on weekdays
        $days = @("Monday", "Tuesday", "Wednesday", "Thursday", "Friday")
        
        # Setting the properties in a separate clause for readability
        $properties = @{
            Status = "Enabled"
            TaskType = "ComputeVmShutdownTask"
            WeeklyRecurrence = @{
                Time = $shutdownTime
                Days = $days
            }
            TimeZoneId = $timeZoneId
            NotificationSettings = @{
                Status = "Enabled"
                WebhookUrl = ""
                Email = "" 
            }
        }
        
        # Setting the schedule on the VM
        # This part of the script runs with an error, there is a problem with the API version - we get an error of bad request for the resource uri 
        # Generally, there was also a problem with the command recognizing our parameter of WeeklyRecurrence.
        New-AzResource -ResourceId $resourceUri -Properties $properties -Location 'northeurope' -Force -ApiVersion '2024-07-01'
        
        Write-Output "Auto-shutdown schedule created/updated for VM: $($vm.Name)"
    }
    catch {
        Write-Error "Failed to create/update auto-shutdown schedule for VM: $($vm.Name). Error: $_"
    }
}


Write-Output "Auto-shutdown schedule set for all VMs with tag '$TagName' in resource group '$ResourceGroupName'."
