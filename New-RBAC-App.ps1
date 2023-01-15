# Application (client) ID, tenant Name and Secret 

<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>

{0}


function Access-Token-RBAC {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            Position = 0,
            HelpMessage = "Client ID of service principal"
        )]
        [ValidatePattern('*-*')]
        [string]$ClientID,

        [Parameter(
            Mandatory = $false,
            Position = 1,
            HelpMessage = "TenantName"
        )]
        [ValidatePattern('*.onmicrosoft.com')]
        [string]$tenantName,

        [Parameter(
            Mandatory = $false,
            Position = 2,
            HelpMessage = "TenantName"
        )]
        [string]$ClientSecret
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
                Client_Id = $clientId
                Client_secret = $clientSecret
            }

            $TokenResponse = Invoke-RestMethod -Uri $Url -Method POST -Body $Body

            # Inspect the token using JWTDetails 
            # JWTDetails PowerShell Module 
            # https://github.com/darrenjrobinson/JWTDetails 
            $JWTToken = Get-JWTDetails($TokenResponse.access_token)
            return $TokenResponse
        }
        
        catch {
           Write-Error $_
        }
    }
    end {
        Write-Verbose "All Done."
    }
}


$clientId
$tenantName
$clientSecret

$ReqTokenBody = @{
    Grant_Type = "client_credentials"
    Scope = "https://graph.microsoft.com/.default"
    Client_Id = $clientId
    Client_secret = $clientSecret
}


$TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token" -Method POST -Body $ReqTokenBody
$TokenResponse
# Inspect the token using JWTDetails 
# JWTDetails PowerShell Module 
# https://github.com/darrenjrobinson/JWTDetails 

Get-JWTDetails($TokenResponse.access_token)

 

$request = @{
    Method = "Get"
    Uri = 'https://graph.microsoft.com/v1.0/Groups/'
    ContentType = "application/json"
    Headers = @{Authorization = "Bearer $($TokenResponse.access_token)"}
}

$Data = Invoke-RestMethod @request
$Users = ($Data | select-object Value).Value
$Users.Count 

