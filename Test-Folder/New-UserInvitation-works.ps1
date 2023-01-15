# $ClientID       = $env:SPNClientID
# $ClientSecret   = $env:SPNClientSecret
# $TenantName     = $env:SPNTenantName
# $SendgridToken  = $env:SendgridAPIToken
# $UserEmailAddress    = $Request.Body.DisplayName
# $Sequence       = $Request.Body.SequenceNumber
# $DeploymentID   = $Request.Body.DeploymentID
# $EngagementID   = $Request.Body.EngagementID
# $OWNER1         = $Request.Body.OWNER1
# $OWNER2         = $Request.Body.OWNER2
# $OWNER3         = $Request.Body.OWNER3 

function New-FabricAccessTokenSP {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            Position = 0,
            HelpMessage = "Client ID of service principal"
        )]
        [string]$ClientID,

        [Parameter(
            Mandatory = $false,
            Position = 1,
            HelpMessage = "TenantName"
        )]
        [string]$TenantName,

        [Parameter(
            Mandatory = $false,
            Position = 2,
            HelpMessage = "ClientSecret of Service principal"
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
        # return $TokenVar
        Write-Verbose "All Done."
    }
}


function Get-FabricUserFirstLastName{
#Get-firstLastName -UserEmailAddress "john.doe@ey.com"
    param (
        [Parameter(Mandatory = $false)][string]$UserEmailAddress
    )

    $UserEmailAddress=( Get-Culture ).TextInfo.ToTitleCase( $UserEmailAddress.ToLower() )
    $UserEmailAddress=$UserEmailAddress.split('@')[0]
    $FirstName=$UserEmailAddress.split('.')[0]
    $LastName=$UserEmailAddress.Substring($UserEmailAddress.indexof('.')+1)
    $LastName=$LastName.replace('.',' ')
    $response=@([pscustomobject]@{FirstName=$FirstName;LastName=$LastName})
    return $response
}


function New-FabricUserInvitation{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)][string]$InvitedUserEmailAddress,
        [Parameter(Mandatory = $false)][switch]$Connect
    )

   
    $script:Headers = $TokenVar

    $uri="https://graph.microsoft.com/v1.0/invitations"
    # $InvitedUserDisplayName=Get-FabricUserFirstLastName -UserEmailAddress $InvitedUserEmailAddress
    $InvitedUserEmailAddress=$InvitedUserEmailAddress.ToLower()
    if($Connect) {

        
        
        $body = @{
            # invitedUserDisplayName = $InvitedUserDisplayName
            invitedUserEmailAddress = $InvitedUserEmailAddress
            inviteRedirectUrl = "https://myapplications.microsoft.com"
            # sendInvitationMessage = $true
        } | ConvertTo-Json
        
        $parameters = @{
            Uri         = $uri
            Body        = $body
            ContentType = "application/json"
            Headers = @{Authorization = "Bearer $($Headers)"}
            Method      = 'POST'
        }
        
        $response=Invoke-RestMethod @parameters
        return $response
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

function Set-FabricUserFirstLastName {
    #Set-restUser -UserEmailAddress "john.doe@ey.com" -accessToken $accessToken
        Param(
            [Parameter(Mandatory = $false)][string]$UserEmailAddress,
            [Parameter(Mandatory = $false)][switch]$Connect
        )
        $script:Headers = $TokenVar

        $response=Get-FabricUserFirstLastName -UserEmailAddress $UserEmailAddress


        $givenName=$response.FirstName
        $surName=$response.LastName
        $UserObjectId=Get-FabricUsersId -UserEmailAddress $UserEmailAddress -Connect
        $uri = "https://graph.microsoft.com/v1.0/users/" + "$UserObjectId"
        Write-Verbose $uri

        $body = @{
            givenName = $givenName
            surname = $surName
        } | Convertto-json
        $parameters = @{
            Uri         = $uri
            Body        = $body
            Method      = 'PATCH'
            ContentType = "application/json"
            Headers = @{Authorization = "Bearer $($Headers)"}
            ErrorAction = "Stop"
        }
        $response=Invoke-RestMethod @parameters
}

function Get-FunctionOutput {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]
        $UserEmailAddress = (),
        [Parameter()]
        [switch]
        $Connect
    )
    $FinalOutput = @()
    If($Connect) {
        
        New-FabricAccessTokenSP -ClientID $ClientID -ClientSecret $ClientSecret -TenantName $TenantName
        
        foreach ($s in $UserEmailAddress) {
            $UserEmailID = Get-FabricUsersId -UserEmailAddress $s -Connect
            if($UserEmailID) {
                $Status = "User is already Existed"
            }
            else {
                New-FabricUserInvitation -InvitedUserEmailAddress $s -Connect
                Set-FabricUserFirstLastName -UserEmailAddress $s -Connect
                $Status = "Successfully got onboarded"
            }

            $bodyObject = @{
                'Username' = $s
                'UserStatus'= $Status
            }
            $FinalOutput += New-Object psobject -Property $bodyObject
        }

        return $FinalOutput
    }
}

$bodyContent =@{
    value = Get-FunctionOutput -Connect -Verbose
} | ConvertTo-Json -Depth 6

$bodyContent