
$ClientID 
$ClientSecret  
$TenantName  

# App Reg Secrets 


function New-NewCoAccessTokenSP {
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
            $TokenVar = $TokenResponse.access_token
            Write-Verbose 'Retrive JWT Token successfully'
            $script:TokenVar = $TokenVar
        }
        
        catch {
           Write-Error $_.Exception.Message 
        }
    }
    end {
        Write-Verbose "All Done."
    }
}


function Get-ListNewCoAPP {
    [CmdletBinding()]
    param (
        

        [Parameter()]
        [switch]
        $Connect
    )


    $restUri =  "https://graph.microsoft.com/v1.0/applications?`$search=`"displayName:`""
    if($Connect) {

        try {

            Write-Verbose "Retrieving Existing SPN Values"

            $script:Headers = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri                 = $restUri
                Method              = "GET"
                ContentType         = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"
                            ConsistencyLevel = "eventual"}
                ErrorAction = "Stop"
                
                
            }

            $response       = Invoke-RestMethod @invokeRestAPIRequestSplat
            $responseValue         = $response.value

            return $response
        }

        catch {
            Write-Error $_
        }
    }
}




function List-UsersAppReg {
    [CmdletBinding()]
    param (
        

        [Parameter()]
        [switch]
        $Connect
    )


    $restUri =  "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=appId eq "
    if($Connect) {

        try {

            Write-Verbose "Retrieving Existing SPN Values"

            $script:Headers = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri                 = $restUri
                Method              = "GET"
                ContentType         = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"
                            ConsistencyLevel = "eventual"}
                ErrorAction = "Stop"
                
                
            }

            $response       = Invoke-RestMethod @invokeRestAPIRequestSplat
            $responseValue         = $response.value

            return $responseValue
        }

        catch {
            Write-Error $_
        }
    }
}


# Get SPN ID using APP ID 

function List-SPNAppReg {
    [CmdletBinding()]
    param (
        

        [Parameter()]
        [switch]
        $Connect
    )


    $restUri =  "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=appId eq "
    if($Connect) {

        try {

            Write-Verbose "Retrieving Existing SPN Values"

            $script:Headers = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri                 = $restUri
                Method              = "GET"
                ContentType         = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"
                            ConsistencyLevel = "eventual"}
                ErrorAction = "Stop"
                
                
            }

            $response       = Invoke-RestMethod @invokeRestAPIRequestSplat
            $responseValue         = $response.value

            return $responseValue
        }

        catch {
            Write-Error $_
        }
    }
}


function Get-SPNAppReg {
    [CmdletBinding()]
    param (
    
        [Parameter()]
        [switch]
        $Connect
    )


    $restUri =  "https://graph.microsoft.com/v1.0/servicePrincipals/SPN-ID/members?`$filter=memberType eq 'User'"
    if($Connect) {

        try {

            Write-Verbose "Retrieving Existing SPN Values"

            $script:Headers = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri                 = $restUri
                Method              = "GET"
                ContentType         = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"
                            ConsistencyLevel = "eventual"}
                ErrorAction = "Stop"
                
                
            }

            $response       = Invoke-RestMethod @invokeRestAPIRequestSplat
            $responseValue         = $response.value

            return $response
        }

        catch {
            Write-Error $_
        }
    }
}

function Set-OwnersForSPN {
    [CmdletBinding()]
    param (
    

        [Parameter()]
        [switch]
        $Connect
    )

    $Body = @{
        id = 
    } | ConvertTo-Json

    $restUri =  "https://graph.microsoft.com/v1.0/servicePrincipals/SPN-ID/addMember"
    if($Connect) {

        try {

            Write-Verbose "Retrieving Existing SPN Values"

            $script:Headers = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri                 = $restUri
                Method              = "POST"
                ContentType         = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"}
                Body = $Body
                ErrorAction = "Stop"
            }

            $response       = Invoke-RestMethod @invokeRestAPIRequestSplat
            $responseValue         = $response.value

            return $response
        }

        catch {
            Write-Error $_
        }
    }
}

function New-SecretNewCoSPN {
    [CmdletBinding()]
    param (
        [Parameter(
            HelpMessage = 'Application Object ID'
        )]
        [string]
        $AppObjectID, 

        [Parameter()]
        [string]
        $SecretDisplayName,
        [Parameter()]
        [switch]
        $Connect
    )


    $restUri =  "https://graph.microsoft.com/v1.0/servicePrincipals/"
    $restUri += "$AppObjectID"
    $restUri += "/addPassword"



    $Body = @{
        passwordCredential = @{
            displayName = $SecretDisplayName
        }
    } | ConvertTo-Json
    if($Connect) {

        try {

            Write-Verbose "Retrieving Existing SPN Values"

            $script:Headers = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri                 = $restUri
                Method              = "POST"
                ContentType         = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"}
                ErrorAction = "Stop"
                Body = $Body
            }

            $response       = Invoke-RestMethod @invokeRestAPIRequestSplat
            $responseValue         = $response.value

            return $response
        }

        catch {
            Write-Error $_
        }
    }
}


function Get-ListOwnersNewCoSPN {
    [CmdletBinding()]
    param (
        [Parameter(
            HelpMessage = 'Application Object ID'
        )]
        [string]
        $AppObjectID, 

        [Parameter()]
        [switch]
        $Connect
    )


    $restUri =  "https://graph.microsoft.com/v1.0/applications/"
    $restUri += "$AppObjectID"
    $restUri += "/owners"
    if($Connect) {

        try {

            Write-Verbose "Retrieving Existing SPN Values"

            $script:Headers = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri                 = $restUri
                Method              = "GET"
                ContentType         = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"}
                ErrorAction = "Stop"
                
            }

            $response       = Invoke-RestMethod @invokeRestAPIRequestSplat
            $responseValue         = $response.value

            return $responseValue
        }

        catch {
            Write-Error $_
        }
    }
}

function Get-NewCoSPN {
    [CmdletBinding()]
    param (
        [Parameter(
            HelpMessage = 'Application Object ID'
        )]
        [string]
        $AppObjectID, 

        [Parameter()]
        [switch]
        $Connect
    )


    $restUri =  "https://graph.microsoft.com/v1.0/applications/"
    $restUri += $AppObjectID
    if($Connect) {

        try {

            Write-Verbose "Retrieving Existing SPN Values"

            $script:Headers = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri                 = $restUri
                Method              = "GET"
                ContentType         = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"}
                ErrorAction = "Stop"
                
            }

            $response       = Invoke-RestMethod @invokeRestAPIRequestSplat
            $AppDisplayName         = $response.displayName
            $AppTags                = $response.tags

            Write-Verbose "Application objectID: $AppObjectID"
            Write-Verbose "Application DisplayName: $AppDisplayName"
            Write-Verbose "Application Tags: $AppTags"
            return $AppDisplayName
        }

        catch {
            Write-Error $_
        }
    }
}



function Remove-NewCoSPN {
    [CmdletBinding()]
    param (
        [Parameter(
            HelpMessage = 'Application Object ID'
        )]
        [string]
        $AppObjectID, 

        [Parameter()]
        [switch]
        $Connect
    )


    $restUri =  "https://graph.microsoft.com/v1.0/applications/"
    $restUri += $AppObjectID
    if($Connect) {

        try {

            Write-Verbose "Retrieving Existing SPN Values"
            $AppDisplayName = Get-NewCoSPN -AppObjectID $AppObjectID -Connect
            Write-Host "Deleting: $AppDisplayName" -ForegroundColor red
            $script:Headers = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri                 = $restUri
                Method              = "DELETE"
                ContentType         = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"}
                ErrorAction = "Stop"
            }

            $response       = Invoke-RestMethod @invokeRestAPIRequestSplat

            return $response
        }

        catch {
            Write-Error $_
        }
    }
}




function Get-NewCoUsersList {
    [CmdletBinding()]
    param (
        [Parameter(
            HelpMessage = 'Application Object ID'
        )]
        [string]
        $AppObjectID, 

        [Parameter()]
        [switch]
        $Connect
    )


    $restUri =  "https://graph.microsoft.com/v1.0/users"
    if($Connect) {

        try {

          
            $script:Headers = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri                 = $restUri
                Method              = "GET"
                ContentType         = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"}
                ErrorAction = "Stop"
            }

            $response       = Invoke-RestMethod @invokeRestAPIRequestSplat
            # $AppID         = $response.value
            # $AppDisplayName = $response.displayName
            # $bodyContent = @{
            #     Description     = "SPN Exists"
            #     SPNDisplayName =  $AppDisplayName
            #     ApplicationID   =  $AppID
            # } | ConvertTo-Json -Depth 3
            
            return $response
        }

        catch {
            Write-Error $_
        }
    }
}




$string = "'HATWQ'"
$pattern = "^[^a-z?._\-@#%!&(){}[\'\]\s]*$"

if ($string -match $pattern) {
    Write-Host "Match found"
} else {
    Write-Host "No match found"
}
