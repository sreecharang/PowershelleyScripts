
function New-FabricAccessTokenSP {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            Position = 0,
            HelpMessage = "Client ID of service principal"
        )]
        [string]$ClientID = $ClientID,

        [Parameter(
            Mandatory = $false,
            Position = 1,
            HelpMessage = "TenantName"
        )]
        [string]$TenantName = $TenantName,

        [Parameter(
            Mandatory = $false,
            Position = 2,
            HelpMessage = "ClientSecret of Service principal"
        )]
        [string]$ClientSecret = $ClientSecret
    )

    begin {
        Write-Verbose "Retrieving JWT Token from Service principal"
        Write-Verbose "Valid for 30 mins"
    }

    process{
        try {
            $Url = "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token"
            $Body = @{
                Grant_Type = "client_credentials"
                Scope = "https://graph.microsoft.com/.default"
                Client_Id = $ClientID
                Client_secret = $ClientSecret
            }

            $TokenResponse = Invoke-RestMethod -Uri $Url -Method POST -Body $Body
            Write-Verbose $Url
            $TokenVar = $TokenResponse.access_token
            Write-Verbose 'Retrive JWT Token successfully'
            $script:TokenVar = $TokenVar
        }
        
        catch {
           Write-Error $_.Exception.Message 
        }
    }
    end {
        # return $TokenVar
        Write-Verbose "All Done."
    }
}



function Get-FabricGroupsAll {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $Connect
    )

    $restUri = "https://graph.microsoft.com/v1.0/groups?`$count=true&`$select=displayName,id&`$search=`"displayName:SubOwner`""

    if($Connect) {
        try {
            Write-Verbose $restUri
            
            $script:Headers = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri = $restUri
                Method = "GET"
                ContentType = "application/json"
                Headers = @{
                Authorization = "Bearer $($Headers)"
                ConsistencyLevel = "eventual"
                }
                ErrorAction = "Stop"
               
            }
            $response = Invoke-RestMethod @invokeRestAPIRequestSplat 
            $responseValue = $response.value
            $array = @()
            for($i = 0; $i -lt $responseValue.Count; $i++) {
                $object = New-Object PSCustomObject -Property @{
                    Id = $responseValue[$i].id
                    DisplayName = $responseValue[$i].displayName
                }
                $array += $object
            }

            return $array
            
        }
        catch {
            $_.Exception.Message 
        }
    }
}


function GetFabricGroupMemberList {
    [CmdletBinding()]
    param (

        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'Users List',
            ValueFromPipeline = $true
        )]
        [string]$GroupName,

        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'Switch statement for Users ID'
        )]
        [switch]$Connect
    )
   

    $restUri = "https://graph.microsoft.com/v1.0/groups/$GroupName/members?`$count=true&`$select=displayName,id"
    

    
    if($Connect){
        try {
            
            Write-Verbose $restUri
            
            $script:Headers = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri = $restUri
                Method = "GET"
                ContentType = "application/json"
                Headers = @{
                Authorization = "Bearer $($Headers)"
                ConsistencyLevel = "eventual"
                }
                ErrorAction = "Stop"
               
            }
            $response = Invoke-RestMethod @invokeRestAPIRequestSplat 
            $responseValue = $response.value
            $responseValueDisplay = $responseValue.displayName
            $Final = [string]::Join("; ", $responseValueDisplay)
            
            return $Final
            
        }
        catch {
            $Final = "No Members"
            return $Final
            Write-Error $_
        }
    }
}



function GetFabricGroupOwnerList {
    [CmdletBinding()]
    param (

        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'Users List',
            ValueFromPipeline = $true
        )]
        [string]$GroupID,

        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'Switch statement for Users ID'
        )]
        [switch]$Connect
    )
   

    $restUri = "https://graph.microsoft.com/v1.0/groups/$GroupID/members?`$count=true&`$select=displayName,id"
    

    
    if($Connect){
        try {
            
            Write-Verbose $restUri
            
            $script:Headers = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri = $restUri
                Method = "GET"
                ContentType = "application/json"
                Headers = @{
                Authorization = "Bearer $($Headers)"
                ConsistencyLevel = "eventual"
                }
                ErrorAction = "Stop"
               
            }
            $response = Invoke-RestMethod @invokeRestAPIRequestSplat 
            $responseValue = $response.value
            $responseValueDisplay = $responseValue.displayName
            $Final = [string]::Join("; ", $responseValueDisplay)
            
            return $Final
            
        }
        catch {
            $Final = "No Members"
            return $Final
            Write-Error $_
        }
    }
}



$GroupIDs = Get-FabricGroupsAll -Connect -Verbose

$data = @() 
for ($j = 0; $j -lt $GroupIDs.Count; $j++) {
    $groupId = $GroupIDs.Id[$j]
    $groupName = $GroupIDs.displayName[$j]
    $Members = GetFabricGroupMemberList -GroupName $groupId -Connect -Verbose
    $Owners = GetFabricGroupOwnerList -GroupID $groupId -Connect -Verbose
    Write-Host $Members
    Write-Host $Owners

    

    $data += [pscustomobject]@{
        GroupId = $groupId
        GroupName = $groupName
        GroupOwners = $Owners
        GroupMembers = $Members
    }
}

$data | ForEach-Object {[pscustomobject]@{GroupId = $_.GroupId; GroupName = $_.GroupName; GroupOwners = $_.GroupOwners; GroupMembers = $_.GroupMembers}} | Export-Excel -Path ".\Fabric.xlsx" -AutoSize -TableName "SubOwner" -WorksheetName "SubOwner"
