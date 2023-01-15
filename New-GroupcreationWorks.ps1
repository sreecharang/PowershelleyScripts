using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)


# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."


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




function Get-FabricUsersId {
    [CmdletBinding()]
    param (

        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'Users List',
            ValueFromPipeline = $true
        )]
        [string]$UserEmailAddress,

        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'Switch statement for Users ID'
        )]
        [switch]$Connect
    )
   
    Begin{

        $restUri = "https://graph.microsoft.com/v1.0/users?`$select=displayName,id&`$filter=mail eq "
        $restUri += "`'$UserEmailAddress`'"
        
    }
    
    Process {
        
        if($Connect){
            try {
                
                Write-Verbose $UserEmailAddress
                Write-Verbose $restUri
                
                $script:Headers = $TokenVar
                $invokeRestAPIRequestSplat = @{
                    Uri = $restUri
                    Method = "GET"
                    ContentType = "application/json"
                    Headers = @{Authorization = "Bearer $($Headers)"}
                    ErrorAction = "Stop"
                }

                $response = Invoke-RestMethod @invokeRestAPIRequestSplat

                $responseVar        = $response.value[0]            
                $UserID             = $responseVar.id
                $UserDisplayName    = $responseVar.displayName
                
                Write-Verbose "UserID: $UserID"
                Write-Verbose "UserDisplayName: $UserDisplayName"
                return $response
            }
            catch {
                Write-Error $_
            }
        }
    }
    End{
        return $UserID
    }
}



function Get-FabricGroups {
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
   

    $restUri = "https://graph.microsoft.com/v1.0/groups?`$select=displayName,id&`$filter=displayName eq "
    $restUri += "`'$GroupName`'"
    

    
    if($Connect){
        try {
            
            Write-Verbose $GroupName
            Write-Verbose $restUri
            
            $script:Headers = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri = $restUri
                Method = "GET"
                ContentType = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"}
                ErrorAction = "Stop"
            }

            $response = Invoke-RestMethod @invokeRestAPIRequestSplat
            $value = $response.value
            return $response

            # $responseVar        = $response.value[0]            
            # $UserID             = $responseVar.id
            # $UserDisplayName    = $responseVar.displayName
            # Write-Verbose "UserID: $UserID"
            # Write-Verbose "UserDisplayName: $UserDisplayName"
            
        }
        catch {
            Write-Error $_
        }
    }
}



function Set-FabricSPNID {
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
   

    $restUri = "https://graph.microsoft.com/v1.0/groups//members/`$ref"
    
    $Body = @{

        "@odata.id"= "https://graph.microsoft.com/v1.0/directoryObjects/"
    } | ConvertTo-Json

    
    if($Connect){
        try {
            
            Write-Verbose $GroupName
            Write-Verbose $restUri
            
            $script:Headers = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri = $restUri
                Method = "POST"
                ContentType = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"}
                ErrorAction = "Stop"
                Body = $Body
            }

            $response = Invoke-RestMethod @invokeRestAPIRequestSplat
            $value = $response.value
            return $response

            # $responseVar        = $response.value[0]            
            # $UserID             = $responseVar.id
            # $UserDisplayName    = $responseVar.displayName
            # Write-Verbose "UserID: $UserID"
            # Write-Verbose "UserDisplayName: $UserDisplayName"
            
        }
        catch {
            Write-Error $_
        }
    }
}


function Get-FabricSPN {
    [CmdletBinding()]
    param (

        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'Users List',
            ValueFromPipeline = $true
        )]
        [string]$SPNName,

        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'Switch statement for Users ID'
        )]
        [switch]$Connect
    )
   

    $restUri = "https://graph.microsoft.com/v1.0/servicePrincipals?`$select=displayName,id&`$filter=id eq "
    $restUri += "`'$SPNName`'"
    

    
    if($Connect){
        try {
            
            Write-Verbose $SPNName
            Write-Verbose $restUri
            
            $script:Headers = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri = $restUri
                Method = "GET"
                ContentType = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"}
                ErrorAction = "Stop"
            }

            $response = Invoke-RestMethod @invokeRestAPIRequestSplat
            $value = $response.value
            return $value

            # $responseVar        = $response.value[0]            
            # $UserID             = $responseVar.id
            # $UserDisplayName    = $responseVar.displayName
            # Write-Verbose "UserID: $UserID"
            # Write-Verbose "UserDisplayName: $UserDisplayName"
            
        }
        catch {
            Write-Error $_
        }
    }
}                                                                               

function New-FabricDisplayName {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $DisplayName,
        [Parameter()]
        [string]
        $Sequence,
        [Parameter()]
        [switch]
        $Connect
    )

    $NewDisplayName = "Fabric-{0}-Role" -f $DisplayName
    return $NewDisplayName
}

function New-FabricGroup{
    [CmdletBinding()]    
    param(
        [Parameter(Mandatory = $false)][string]$DisplayName,
        [Parameter(Mandatory = $false)][string]$Description,
        [Parameter(Mandatory = $false)][string[]]$GroupOwners,
        [Parameter(Mandatory = $false)][switch]$Connect
        )

        
        


        $NewDisplayName = New-FabricDisplayName -DisplayName $DisplayName -Connect

        #Owners
        $restUri =  "https://graph.microsoft.com/v1.0/groups"
        
        $OwnerMembers = @()
        
        if($Connect) {
            
            try {
                
                New-FabricAccessTokenSP -ClientID $ClientID -TenantName $TenantName -ClientSecret $ClientSecret
                $script:Headers = $TokenVar

                Write-Verbose "Creating a New RBAC group"

                $script:Headers = $TokenVar
                foreach ($s in $GroupOwners) {

                    $OwnerID = Get-FabricUsersId -UserEmailAddress $s -Connect
                    
                    $OwnerMembers += "https://graph.microsoft.com/v1.0/users/$OwnerID"
                    
                }
                Write-Verbose $restUri
                $Body = @{
                    description = $NewDisplayName
                    displayName = $NewDisplayName
                    groupTypes = @()
                    mailEnabled = 'false'
                    mailNickName = $NewDisplayName
                    securityEnabled = 'true'
                    "owners@odata.bind" =  @(
                        $OwnerMembers
                    )
                } | ConvertTo-Json

                $invokeRestAPIRequestSplat = @{
                    Uri                 = $restUri
                    Method              = "POST"
                    ContentType         = "application/json"
                    Headers = @{Authorization = "Bearer $($Headers)"}
                    ErrorAction = "Stop"
                    Body = $Body
                    
                }

                $response       = Invoke-RestMethod @invokeRestAPIRequestSplat
                Write-Verbose "Group Creation "
                return $response
            }
            catch {
                Write-Error $_
            }
    }
        return $response
}

$Content = New-FabricGroup -DisplayName $DisplayName -GroupOwners $GroupOwners -Connect -Verbose
Write-Verbose $Content

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})
