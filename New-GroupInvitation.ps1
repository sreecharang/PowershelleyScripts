##########
#Functions
##########
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
            'AzureChinaCloud'{$azureEndpoint="login.partner.microsoftonline.cn"}
            'AzureCloud'{$azureEndpoint="login.microsoftonline.com"}
            default{Write-Output "Specify an existing AzureCloud. Available values: 'AzureCloud','AzureChinaCloud'"}
        }
        $uri = "https://$azureEndpoint/$TenantId/oauth2/v2.0/token"
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
    function Get-restUser{
    #Get-restUser -UserEmailAddress "john.doe@ey.com" -accessToken $accessToken
        Param(
        [Parameter(Mandatory = $true)][string]$UserEmailAddress,
        [Parameter(Mandatory = $true)][string]$accessToken
        )
        $uri="https://graph.microsoft.com/v1.0/users/?%24filter=mail%20eq%20%27$UserEmailAddress%27"
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
    function New-restGroup{
    #New-restGroup -DisplayName $DisplayName -Description $Description -Members "john.doe@ey.com,jane.doe@ey.com" -Owners "john.doe@ey.com,jane.doe@ey.com" -accessToken $accessToken
        Param(
        [Parameter(Mandatory = $true)][string]$DisplayName,
        [Parameter(Mandatory = $true)][string]$Description,
        [Parameter(Mandatory = $true)][string]$Owners,
        [Parameter(Mandatory = $true)][string]$Members,
        [Parameter(Mandatory = $true)][string]$accessToken
        )
        $uri="https://graph.microsoft.com/v1.0/groups"
        #Owners
        $GroupOwners=$GroupOwners.split(',')
        foreach($User in $GroupOwners){
            $UserObjectId=(Get-restUser -UserEmailAddress $User -accessToken $accessToken).id
            $OwnersArray+="https://graph.microsoft.com/v1.0/users/"+$UserObjectId+","
        }
        $OwnersArray=$OwnersArray.remove(($OwnersArray.length)-1,1)
        $OwnersArray=$OwnersArray.split(',')
        #Members
        $GroupMembers=$GroupMembers.split(',')
        foreach($User in $GroupMembers){
            $UserObjectId=(Get-restUser -UserEmailAddress $User -accessToken $accessToken).id
            $MembersArray+="https://graph.microsoft.com/v1.0/users/"+$UserObjectId+","
        }
        $MembersArray=$MembersArray.remove(($MembersArray.length)-1,1)
        $MembersArray=$MembersArray.split(',')
        $body = @{
            displayName = $DisplayName
            description = $Description
            groupTypes = @()
            mailEnabled = $false
            mailNickname = $DisplayName
            securityEnabled = $true
            'owners@odata.bind' = @($OwnersArray)
            'members@odata.bind' = @($MembersArray)
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
    function Get-restGroup{
    #Get-restGroup -DisplayName $DisplayName -accessToken $accessToken
        Param(
        [Parameter(Mandatory = $true)][string]$DisplayName,
        [Parameter(Mandatory = $true)][string]$accessToken
        )
        $uri="https://graph.microsoft.com/v1.0/groups?%24search=%22displayName%3A$DisplayName%22"
        $parameters = @{
            Uri         = $uri
            Headers     = @{ 'Authorization' = "Bearer $accessToken"
                            'Content-Type' = 'application/json'
                            'ConsistencyLevel' = "eventual"
                            }
            Method      = 'GET'
        }
        $response=Invoke-RestMethod @parameters
        $response=$response.value
        return $response
    }
    ######
    #Main
    ######
    $DisplayName
    $Description
    $GroupOwners
    $GroupMembers=$GroupOwners
    $accessToken=Get-restAccessToken -applicationClientId $applicationClientId -applicationSecret $applicationSecret -ResourceUrl "https://graph.microsoft.com/.default" -TenantId $TenantId
    $GroupOwnersArray=$GroupOwners.split(',')
    foreach ($UserEmailAddress in $GroupOwnersArray){
        try{
            $isOnboard=Get-restUser -UserEmailAddress $UserEmailAddress -accessToken $accessToken
            if($isOnboard){
                Write-Host "The following user $($isOnboard.mail) is onboarded." -ForegroundColor Green
            }else{
                Write-Host "The following user $UserEmailAddress is not onboarded." -ForegroundColor Yellow
            }
        }catch{
            Write-Output $_
            Write-Host "There was an error with the following user: $UserEmailAddress" -ForegroundColor Red
        }
    }
    $isCreated=Get-restGroup -DisplayName $DisplayName -accessToken $accessToken
    if($isCreated){
        Write-Host "The following group $($isCreated.displayName) already exists." -ForegroundColor Yellow
    }else{
        try{
            New-restGroup -DisplayName $DisplayName -Description $Description -Owners $GroupOwners -Members $GroupMembers -accessToken $accessToken
            Write-Host "The following group $DisplayName has been created." -ForegroundColor Green
        }catch{
            Write-Output $_
            Write-Host "There was an error with the following group: $DisplayName" -ForegroundColor Red
        }
    }