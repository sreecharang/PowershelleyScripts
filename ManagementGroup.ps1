# Variables 

$ProductFullName = "Fabric-PRODUCTEAM"
$ProductShortName = $ProductFullName.Substring(7,10) # Retrieving Information on ProductTeam 

$ProductFabricManagementGroupName = "MG-"+ $ProductFullName
$ParentFabricManagementGuid = New-Guid

# recurring Product team 

ProductFabricManagementGroupName1 = "MG-" + $ProductFullName + "-01"
$ProductManagementGroupGuid1 = New-Guid


# Subscription Information 

$subNameFabricProduct1 = Get-AzSubscription | Where-Object {$_.Name -like "Fabric-PRODUCTTEAM-001*"}
$subNameFabricProduct2 = Get-AzSubscription | Where-Object {$_.Name -like "Fabric-PRODUCTTEAM-002*"}



$global:currenttime = Set-PSBreakpoint -Variable currenttime -Mode Read -Action {$global:currenttime= Get-Date -UFormat "%A %m/%d/%Y %R"}
$foregroundColor1 = "Red"
$foregroundColor2 = "Yellow"
$writeEmptyLine = "`n"
$writeSeperatorSpaces = " - "




## Check if PowerShell runs as Administrator (when not running from Cloud Shell), otherwise exit the script
 
if ($PSVersionTable.Platform -eq "Unix") {
    Write-Host ($writeEmptyLine + "# Running in Cloud Shell" + $writeSeperatorSpaces + $currentTime)` -foregroundcolor $foregroundColor1 $writeEmptyLine
     
    ## Start script execution    
    Write-Host ($writeEmptyLine + "# Script started. Without any errors, it will need around 5 minute to complete" + $writeSeperatorSpaces + $currentTime)`
    -foregroundcolor $foregroundColor1 $writeEmptyLine
} else {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdministrator = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
 
        ## Check if running as Administrator, otherwise exit the script
        if ($isAdministrator -eq $false) {
        Write-Host ($writeEmptyLine + "# Please run PowerShell as Administrator" + $writeSeperatorSpaces + $currentTime)`
        -foregroundcolor $foregroundColor1 $writeEmptyLine
        Start-Sleep -s 3
        exit
        }
        else {
 
        ## If running as Administrator, start script execution    
        Write-Host ($writeEmptyLine + "# Script started. Without any errors, it will need around 5 minutes to complete" + $writeSeperatorSpaces + $currentTime)`
        -foregroundcolor $foregroundColor1 $writeEmptyLine
        }
}



## ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
## Suppress breaking change warning messages
 
Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
 
## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



$FabricParentGroup = Get-AzManagementGroup -GroupName 






# Create a Fabric Product Management Group 

New-AzManagementGroup -GroupName $ProductManagementGroupGuid -DisplayName $ProductFabricManagementGroupName | Out-Null
 
# Store Company management group in a variable
$FabricParentGroup = Get-AzManagementGroup -GroupName $ParentFabricManagementGuid
 
Write-Host ($writeEmptyLine + "# Creating management group under $FabricParentGroup" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine





## Create Top management Product groups 

# Create FAbric management group 01
New-AzManagementGroup -GroupName $ProductManagementGroupGuid1 -DisplayName $ProductFabricManagementGroupName1 -ParentObject $FabricParentGroup | Out-Null
 
# Create FAbric management group 02
New-AzManagementGroup -GroupName $ProductManagementGroupGuid2 -DisplayName $ProductFabricManagementGroupName2 -ParentObject $FabricParentGroup | Out-Null
 
# # Create Sandbox management group
# New-AzManagementGroup -GroupName $ProductManagementGroupGuid3 -DisplayName $ProductFabricManagementGroupName3 -ParentObject $FabricParentGroup | Out-Null
 
# # Create Decomission management group
# New-AzManagementGroup -GroupName $ProductManagementGroupGuid4 -DisplayName $ProductFabricManagementGroupName4 -ParentObject $FabricParentGroup | Out-Null
 

# Store specific Top management groups in variables
$ProductManagementGroup1 = Get-AzManagementGroup -GroupName $ProductManagementGroupGuid1
$ProductManagementGroup2 = Get-AzManagementGroup -GroupName $ProductManagementGroupGuid2
 
Write-Host ($writeEmptyLine + "# Top management groups $ProductManagementGroup1, $ProductManagementGroup2 `
created" + $writeSeperatorSpaces + $currentTime) -foregroundcolor $foregroundColor2 $writeEmptyLine
 

 
## Move subscriptions under the tenant root group to the correct management groups, if they exist

# Move Fabric Product subscription, if it exists
If(!! $subNameFabricProduct1)
{
    New-AzManagementGroupSubscription -GroupId $ProductFabricManagementGroupName1 -SubscriptionId $subNameFabricProduct1.SubscriptionId
}
 
# Move Fabric Product subscription, if it exists
If(!! $subNameFabricProduct2)
{
    New-AzManagementGroupSubscription -GroupId $ProductFabricManagementGroupName2 -SubscriptionId $subNameFabricProduct2.SubscriptionId
}
 
Write-Host ($writeEmptyLine + "# Subscriptions moved to management groups" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor2 $writeEmptyLine



## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
## Write script completed
 
Write-Host ($writeEmptyLine + "# Script completed" + $writeSeperatorSpaces + $currentTime)`
-foregroundcolor $foregroundColor1 $writeEmptyLine
 
## ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




