##########
#Functions
##########
function Get-restAccessToken {
  
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
    function New-restInvitation{
    #New-restInvitation -invitedUserEmailAddress "john.doe@ey.com" -accessToken $accessToken
        Param (
            [Parameter(Mandatory = $true)][string]$InvitedUserEmailAddress,
            [Parameter(Mandatory = $true)][string]$accessToken
        )
        $uri="https://graph.microsoft.com/v1.0/invitations"
        $InvitedUserDisplayName=Get-userDisplayName -UserEmailAddress $InvitedUserEmailAddress
        $InvitedUserEmailAddress=$InvitedUserEmailAddress.ToLower()
        $body = @{
            invitedUserDisplayName = $InvitedUserDisplayName
            invitedUserEmailAddress = $InvitedUserEmailAddress
            inviteRedirectUrl = "https://myapplications.microsoft.com"
            sendInvitationMessage = $true
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
    function Get-restUser{
    
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
    function Get-userFirstLastName{
    #Get-firstLastName -UserEmailAddress "john.doe@ey.com"
        Param(
            [Parameter(Mandatory = $true)][string]$UserEmailAddress
        )
        $UserEmailAddress=( Get-Culture ).TextInfo.ToTitleCase( $UserEmailAddress.ToLower() )
        $UserEmailAddress=$UserEmailAddress.split('@')[0]
        $FirstName=$UserEmailAddress.split('.')[0]
        $LastName=$UserEmailAddress.Substring($UserEmailAddress.indexof('.')+1)
        $LastName=$LastName.replace('.',' ')
        $response=@([pscustomobject]@{FirstName=$FirstName;LastName=$LastName})
        return $response
    }
    function Get-userDisplayName{
    # Get-userDisplayName -UserEmailAddress "john.doe@ey.com"
        Param(
            [Parameter(Mandatory = $true)][string]$UserEmailAddress
        )
        $UserEmailAddress=( Get-Culture ).TextInfo.ToTitleCase( $UserEmailAddress.ToLower() )
        $UserEmailAddress=$UserEmailAddress.split('@')[0]
        $response=$UserEmailAddress.replace('.',' ')
        return $response
    }
    function Set-restUser {
    #Set-restUser -UserEmailAddress "john.doe@ey.com" -accessToken $accessToken
        Param(
            [Parameter(Mandatory = $true)][string]$UserEmailAddress,
            [Parameter(Mandatory = $true)][string]$accessToken
        )
        $response=Get-userFirstLastName -UserEmailAddress $UserEmailAddress
        $givenName=$response.FirstName
        $surName=$response.LastName
        $UserObjectId=(Get-restUser -UserEmailAddress $UserEmailAddress -accessToken $accessToken).id
        $uri = "https://graph.microsoft.com/v1.0/users/$UserObjectId"
        $body = @{
            givenName = $givenName
            surname = $surName
        } | Convertto-json
        $parameters = @{
            Uri         = $uri
            Body        = $body
            Headers     = @{ 'Authorization' = "Bearer $accessToken"
                            'Content-Type' = 'application/json'
                            }
            Method      = 'PATCH'
        }
        $response=Invoke-RestMethod @parameters
    }
    function List-restUser {
    # List-restUser -accessToken $accessToken [-externalUserState]
        Param(
            [Parameter(Mandatory = $false)][switch]$externalUserState,
            [Parameter(Mandatory = $true)][string]$accessToken
        )
        if($externalUserState){
                $uri="https://graph.microsoft.com/v1.0/users?%24select=displayName%2CexternalUserState%2CexternalUserStateChangeDateTime%2CuserType&%24filter=%20userType%20eq%20%27Guest%27"
            }else{
                $uri="https://graph.microsoft.com/v1.0/users"
            }
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
    #####
    #Main
    #####
    $UserList=
    $UserList=$UserList.Split([Environment]::NewLine);$UserList=$UserList | where {$_ -ne ""}
    $accessToken=Get-restAccessToken -applicationClientId $applicationClientId -applicationSecret $applicationSecret -ResourceUrl "https://graph.microsoft.com/.default" -TenantId $TenantId
    try{
        foreach ($InvitedUserEmailAddress in $UserList){
            $isOnboard=Get-restUser -UserEmailAddress $InvitedUserEmailAddress -accessToken $accessToken
            if($isOnboard){
                Write-Host "The following user $($isOnboard.mail) is already onboarded." -ForegroundColor Yellow
            }else{
                $NoOutput=New-restInvitation -invitedUserEmailAddress $InvitedUserEmailAddress -accessToken $accessToken
                while(-not(Get-restUser -UserEmailAddress $InvitedUserEmailAddress -accessToken $accessToken)){
                    Start-Sleep 1
                }
                Set-restUser -UserEmailAddress $InvitedUserEmailAddress -accessToken $accessToken
                Write-Host "The following user $InvitedUserEmailAddress has been onboarded." -ForegroundColor Green
            }
        }
    }catch{
        Write-Output $_
        Write-Host "There was an error with the following user: $InvitedUserEmailAddress" -ForegroundColor Red
    }