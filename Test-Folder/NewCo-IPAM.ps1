function Get-restAccessToken {
    #Get-restAccessToken -applicationClientId $applicationClientId -applicationSecret $applicationSecret -ResourceUrl "https://graph.microsoft.com/.default" -TenantId $TenantId
        Param (
        [Parameter(Mandatory = $true)][string]$applicationClientId,
        [Parameter(Mandatory = $true)][string]$applicationSecret,
        [Parameter(Mandatory = $true)][string]$ResourceUrl,
        [Parameter(Mandatory = $false)][string]$azureCloud="AzureCloud",
        [Parameter(Mandatory = $true)][string]$TenantId
        )
        switch($azureCloud)
        {
            'AzureChinaCloud'{$azureLoginEndpoint="login.partner.microsoftonline.cn"}
            'AzureCloud'{$azureLoginEndpoint="login.microsoftonline.com"}
            default{Write-Output "Specify an existing AzureCloud. Available values: 'AzureCloud','AzureChinaCloud'"}
        }
        $uri = "https://$azureLoginEndpoint/$TenantId/oauth2/v2.0/token"
        $body = @{
            client_id     = $applicationClientId
            scope         = $ResourceUrl
            client_secret = $applicationSecret
            grant_type    = "client_credentials"
        }
        $tokenRequest = Invoke-WebRequest -Method Post -Uri $uri -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing
        $tokenResponse = $tokenRequest.Content | ConvertFrom-Json
        $accessToken=$tokenResponse.access_token
        return $accessToken
    }
    function Get-restServicePrincipal{
    #Get-restServicePrincipal -applicationDisplayName $applicationDisplayName -accessToken $accessToken
            Param (
                [Parameter(Mandatory = $true)][string]$applicationDisplayName,
                [Parameter(Mandatory = $true)][string]$accessToken
            )
            $uri="https://graph.microsoft.com/v1.0/servicePrincipals?%24filter=displayName%20eq%20%27$applicationDisplayName%27"
            $parameters = @{
                Uri         = $uri
                Headers     = @{ 'Authorization' = "Bearer $accessToken" 
                                'Content-Type' = 'application/json'
                                }
                Method      = 'GET'
            }
            $response=Invoke-RestMethod @parameters
            $response=$response.value
            return $response
    }
    function New-restServiceAppRoleAssignment {
    #New-restServiceAppRoleAssignment -ObjectId $ObjectId -PrincipalId $PrincipalId -ResourceId $ResourceId -Id $Id -accessToken $accessToken
        Param(
            [Parameter(Mandatory = $true)][string]$ObjectId,
            [Parameter(Mandatory = $true)][string]$PrincipalId,
            [Parameter(Mandatory = $true)][string]$ResourceId,
            [Parameter(Mandatory = $true)][string]$Id,
            [Parameter(Mandatory = $true)][string]$accessToken
        )
        $uri="https://graph.microsoft.com/v1.0/servicePrincipals/$ObjectId/appRoleAssignments"
        $body = @{
            principalId = $PrincipalId
            resourceId = $ResourceId
            appRoleId = $Id
        } | ConvertTo-Json
        $parameters = @{
            Uri         = $uri
            Body        = $body
            Headers     = @{ 'Authorization' = "Bearer $accessToken" 
                            'Content-Type' = 'application/json'
                            }
            Method      = 'POST'
        }
        $response=Invoke-RestMethod @parameters
        return $response
    }
    #NewCo
    $applicationClientId
    $applicationSecret
    $tenantId



    #NewCo-Input
    $applicationDisplayName="<IPAM-Name>"
    $servicePrincipalDisplayName= "<SPN-Name"

    #Fabric-Input
    # $applicationDisplayName="Fabric-App-CloudConnectivity-IPAMProd-001"
    # $servicePrincipalDisplayName= "Fabric-App-IdentityPlatform-DevOps-002"
    #Main
    $accesstoken=Get-restAccessToken -applicationClientId $applicationClientId -applicationSecret $applicationSecret -ResourceUrl "https://graph.microsoft.com/.default" -TenantId $tenantId
    $applicationObjectIdTarget=(Get-restServicePrincipal -applicationDisplayName $applicationDisplayName -accessToken $accessToken).id
    $servicePrincipalObjectIdTarget=(Get-restServicePrincipal -applicationDisplayName $servicePrincipalDisplayName -accessToken $accessToken).id

    # New-Co 
    New-restServiceAppRoleAssignment -ObjectId $servicePrincipalObjectIdTarget -PrincipalId $servicePrincipalObjectIdTarget -ResourceId $applicationObjectIdTarget -Id ([Guid]::Empty) -accessToken $accessToken

