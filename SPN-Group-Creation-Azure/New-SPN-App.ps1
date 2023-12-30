
function New-FabricSPN {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false, 
            Position = 0,
            HelpMessage = 'Display Name for SPN'
        )]
        [string]$DisplayName,

        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'DeploymentID of the application'
        )]
        [string]$DeploymentID,

        
        [Parameter(
            Mandatory = $false,
            Position = 2, 
            HelpMessage = 'EngagementID of the application'
        )]
        [string]$EngagementID,

        [Parameter(
            Mandatory = $false,
            Position = 3, 
            HelpMessage = 'Owners of the application'
        )]
        [string]$OWNERTAG,

        [Parameter(
            Mandatory = $false,
            Position = 4, 
            HelpMessage = 'Owners of the application'
        )]
        [string]$OWNER1,

        [Parameter(
            Mandatory = $false,
            Position = 5, 
            HelpMessage = 'Owners of the application'
        )]
        [string]$OWNER2,

        [Parameter(
            Mandatory = $false,
            Position = 6, 
            HelpMessage = 'Owners of the application'
        )]
        [string]$OWNER3,


        [Parameter(
            Mandatory = $false,
            Position = 7, 
            HelpMessage = 'Retrieving the JWT Access Token'
        )]
        [switch]$Connect
    )


    $restUri = "https://graph.microsoft.com/v1.0/applications"
    
    $Body = @{
        displayName = $DisplayName
    } | ConvertTo-Json
        
    if($Connect){
        try {
            New-FabricAccessTokenSP

            Write-Verbose "Creation of SP: $DisplayName"

            $script:Headers = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri = $restUri
                # Method = 'POST'
                Method = 'POST'
                ContentType = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"}
                ErrorAction = 'Stop'
                Body = $Body
            }

            $response = Invoke-RestMethod @invokeRestAPIRequestSplat
            $responseappId = $response.appId
            $responseId = $response.id
            Write-Verbose "Created Application Registration: $responseId"

            # Invoking SPN Secrets 
            $script:SecretsApplicationID = $responseId
            Set-FabricSPNSecrets -Connect -Verbose

            # Involking SPN Tags 
            $script:TagsApplicationID = $responseId
            Set-FabricSPNTags -Connect -DeploymentID $DeploymentID  -EngagementID $EngagementID -OWNER $OWNERTAG 

            #Invoking SPN OWners 
            $script:OwnersApplicationID = $responseId
            Set-FabricSPNOwners -Connect -Owner1 $OWNER1 -Owner2 $OWNER2 -Owner3 $OWNER3 

            #Invoking Set SPN 
            $script:SPNApplicationID = $responseappId
            Set-FabricSPN -Connect

            $script:SPNAPIPermissionObjectIDVar = $responseId

            #Add API permissions 
            $script


            return $responseId

        }
        catch {
            Write-Error $_
        }
    }
}



function New-FabricAccessTokenSP {
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
            $script:TokenVar = $TokenResponse.access_token
            Write-Verbose 'Retrive JWT Token successfully'
        }
        
        catch {
           Write-Error $_
        }
    }
    end {
        Write-Verbose "All Done."
    }
}


function Set-FabricSPNSecrets {
    [CmdletBinding()]
    param (

        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'Switch statement for SPN'
        )]
        [switch]$Connect
    )

    $script:ApplicationIDVar = $SecretsApplicationID
    $restUri = "https://graph.microsoft.com/v1.0/applications/"
    $restUri += "$ApplicationIDVar/addPassword"

    $DisplayName = "Initial-Secret"
    $Body = @{
        passwordCredential = @{
            displayName = $DisplayName
        }
    } | ConvertTo-Json
        
    if($Connect){
        try {
            # New-FabricAccessTokenSP

            Write-Verbose "Creation of Secret: $DisplayName"

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
            $responseSecret = $response.secretText
            $responseDisplay = $response.DisplayName
            Write-Verbose "Created Application Secret: $responseSecret"
            Write-Verbose "Created Application DispayName: $responseDisplay"
        

        }
        catch {
            Write-Error $_
        }
    }
}


function Set-FabricSPNTags {
    param (
        [Parameter(
            Mandatory = $false,
            Position = 0, 
            HelpMessage = 'DeploymentID of the application'
        )]
        [string]$DeploymentID,

        
        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'EngagementID of the application'
        )]
        [string]$EngagementID,

        [Parameter(
            Mandatory = $false,
            Position = 2, 
            HelpMessage = 'Owners of the application'
        )]
        [string]$OWNERTag,

        [Parameter(
            Mandatory = $false,
            Position = 3, 
            HelpMessage = 'Switch statement for SPN'
        )]
        [switch]$Connect
    )
    
    $script:TagsApplicationIDVar = $TagsApplicationID

    
    Write-Verbose "$TagsApplicationID"
    $restUri = "https://graph.microsoft.com/v1.0/applications/"
    $restUri += $TagsApplicationIDVar
    
    $Body = @{
        tags = @(
            "DEPLOYMENT_ID : $DeploymentID" 
            "ENGAGEMENT_ID : $EngagementID" 
            "OWNER : $OWNERTag"
        )
    } | ConvertTo-Json
        
    if($Connect){
        try {
            # New-FabricAccessTokenSP

            Write-Verbose "Attaching of Tags: $TagsApplicationID"
            Write-Verbose "$restUri"
            Write-Verbose "$TagsApplicationIDVar"

            $script:Headers = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri = $restUri
                Method = "PATCH"
                ContentType = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"}
                ErrorAction = "Stop"
                Body = $Body
            }

            $response = Invoke-RestMethod @invokeRestAPIRequestSplat
            Write-Verbose "Tags- DEPLOYMENT_ID: $DeploymentID, ENGAGEMENT_ID: $EngagementID, OWNER: $OWNER"
            Write-Verbose "Attached tags to: $TagsApplicationIDVar"
            # $script:ApplicationID = $responseId
            return $response

        }
        catch {
            Write-Error $_
        }
    }
}



function Set-FabricSPNOwners {
    [CmdletBinding()]
    param (

        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'Owner1 of SPN'
        )]
        [string]$Owner1,

        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'Owner2 of SPN'
        )]
        [string]$Owner2,

        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'Owner3 of SPN'
        )]
        [string]$Owner3,

        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'Switch statement for SPN'
        )]
        [switch]$Connect
    )

    $script:OwnersApplicationIDVar = $OwnersApplicationID

    $Owners = @(
        $Owner1,
        $Owner2,
        $Owner3
    )

    if($Connect){
        try {
            
            Write-Verbose "ApplicationID: $OwnersApplicationIDVar"
            Write-Verbose "Owners: $Owners"
            

            $script:Headers = $TokenVar

            foreach ($Owner in $Owners) {

                $OwnerID = Get-FabricUsersId -UserEmailAddress $Owner -Connect 

                Write-Verbose $OwnerID

                $restUri = "https://graph.microsoft.com/v1.0/applications/"
                $restUri += "$OwnersApplicationIDVar/owners/`$ref"
                
                $Body = @{
                    "@odata.id" =  "https://graph.microsoft.com/v1.0/directoryObjects/$OwnerID"
                } | ConvertTo-Json
            
                

                Write-Verbose $restUri
                Write-Verbose $Body

                $invokeRestAPIRequestSplat = @{
                    Uri = $restUri
                    Method = "POST"
                    ContentType = "application/json"
                    Headers = @{Authorization = "Bearer $($Headers)"}
                    ErrorAction = "Stop"
                    Body = $Body
                }
    
                $response = Invoke-RestMethod @invokeRestAPIRequestSplat
                Write-Verbose $response 
                Write-Verbose "Added User: $Owner as owner to $OwnersApplicationIDVar"
            }
            
        }
        catch {
            Write-Error $_
        }
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
                # New-FabricAccessTokenSP 

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

function Set-FabricSPN {
    [CmdletBinding()]
    param (

        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'Switch statement for Users ID'
        )]
        [string]$ApplicationID, 

        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'Switch statement for Users ID'
        )]
        [switch]$Connect
    )


    $restUri = "https://graph.microsoft.com/v1.0/servicePrincipals"
   
    $script:SPNApplicationIDVar = $SPNApplicationID
    $Body = @{
        appId = $SPNApplicationIDVar
    } | ConvertTo-Json


    if($Connect){
        try {
            
            Write-Verbose "ApplicationID: $SPNApplicationIDVar"
            

            $script:Headers = $TokenVar

          
            Write-Verbose $restUri
            Write-Verbose $Body

            $invokeRestAPIRequestSplat = @{
                Uri = $restUri
                Method = "POST"
                ContentType = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"}
                ErrorAction = "Stop"
                Body = $Body
            }

            $response = Invoke-RestMethod @invokeRestAPIRequestSplat
            Write-Verbose $response 
            Write-Verbose "Created ServicePrincipal for application : $SPNApplicationIDVar"
            
        }
        catch {
            Write-Error $_
        }
    }
}



function Set-FabricSPNAPIPermissions {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Switch]
        $Connect
    )
    # $script:ApplicationIDVar = $ApplicationID

    $script:SPNAPIPermissionObjectIDVar = $SPNAPIPermissionObjectIDVar

    # $ObjectIDVar = "48977227-4dde-476c-a91c-47635d57fd74" 
    
   
    Write-Verbose "$ObjectIDVar"
    $restUri = "https://graph.microsoft.com/v1.0/applications/$SPNAPIPermissionObjectIDVar" 

    $Body = @{
        requiredResourceAccess = @(@{

            resourceAppId
            resourceAccess = @(
            @{
                id      =     #pre register APP Permission ID 
                type    = "Scope"                                   # Scope - Delegated, Role - Application 
            },
            @{
                id      = 
                type    = "Scope" 
            }
            )
        })
    } | ConvertTo-Json -Depth 5

    if($Connect){
        try {

         #    New-FabricAccessTokenSP
            Write-Verbose "$restUri"
            Write-Verbose "$SPNAPIPermissionObjectIDVar"

            $script:Headers = $TokenVar

            $invokeRestAPIRequestSplat = @{
                Uri = $restUri
                Method = "PATCH"
                ContentType = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"}
                ErrorAction = "Stop"
                Body = $Body
            }

            $response = Invoke-RestMethod @invokeRestAPIRequestSplat
            $responseId = $response.value
            Write-Verbose "Attached Admin Consent: $responseId"
            return $response.value
        }
        catch {
            Write-Error $_
        }
    }
}


function Set-FabricSPNAdminConsent {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $Connect
    )


    $restUri = "https://graph.microsoft.com/v1.0/oauth2PermissionGrants/"
    $restUri +=    # We need to Create 


    $Body = @{

        clientId    =  # Service Pricipal Object ID 
        consentType = "AllPrincipals"                       
        resourceId  = # Microsoft Graph Key 
        scope       =# api permission when running Set-FabricSPNAPIPermissions

    } | ConvertTo-Json

    if($Connect) {
        try {
            

            $script:Headers = $TokenVar

            $invokeRestAPIRequestSplat = @{
                Uri = $restUri
                Method = "PATCH"
                ContentType = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"}
                ErrorAction = "Stop"
                 Body = $Body
            }

            $response = Invoke-RestMethod @invokeRestAPIRequestSplat
            
            $responseId = $response.id
            Write-Verbose "Attached Admin Consent: $responseId" 
            return $responseId
        }
        catch {
            Write-Error $_
        }
    }
}




function Get-FabricSPN {

    param (
        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'Switch statement for SPN'
        )]
        [switch]$Connect
    )
    
    $script:ApplicationIDVar = $ApplicationID

    Write-Verbose "$ApplicationIDVar"
    $restUri = "https://graph.microsoft.com/v1.0/applications/"
    $restUri += 
        
    if($Connect){
        try {
        #    New-FabricAccessTokenSP

            Write-Verbose "Creation of Secret: $DisplayName"
            Write-Verbose "$restUri"
            Write-Verbose "$ApplicationIDVar"

            $script:Headers = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri = $restUri
                Method = "GET"
                ContentType = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"}
                ErrorAction = "Stop"
            }

            $response = Invoke-RestMethod @invokeRestAPIRequestSplat
            $responseId = $response.id
            Write-Verbose "Created Application Registration: $responseId"
            # $script:ApplicationID = $responseId
            Write-Verbose $response
            return $response

        }
        catch {
            Write-Error $_
        }
    }
}
   
function Get-FabricSendGrid {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $Connect
    )

    


    
    $restUri = "https://api.sendgrid.com/v3/mail/send"

    $subject = "SPN generated on Fabric Management"

    $contentType = "text/html"
    # $contentBody = "Application ID: $ApplicationID, `n `n SPN ID: $SPNObjectID `n `n Generated on Fabric Management"
    $contentBody = 
    $contentBody = "Application ID: $ApplicationID, `n SPN ID: $SPNObjectID `n Owner: $ToEmailAddress `r`nGenerated on Fabric Management"

    $ToEmailAddress =
    $FromEmailAddress =


    $mailbody = @{
        personalizations = @(@{
            to = @(@{
                email = $ToEmailAddress
            })
            subject = $subject
            # cc = @(
            #     @{
            #         email = $ToEmailAddress
            #     }
                
            # )
        })
        content          = @(@{
            type  = $contentType
            value = $contentBody
        })
        from = @{
            email = $FromEmailAddress
            name =
        }
        reply_to = @{
            email = $FromEmailAddress
            name =
        }
    } | ConvertTo-Json -Depth 6

    if($Connect) {
        try {
            Write-Verbose "Sending Email"

            Write-Verbose "Executing SendGrid API.."
            $invokeRestAPIRequestSplat = @{
                Uri = $restUri
                Method = "POST"
                ContentType = 'application/json'
                Headers = @{'Authorization' = "Bearer $($SendgridToken)"}
                ErrorAction = 'Stop'
                Body = $mailbody
            }

            $response = Invoke-RestMethod @invokeRestAPIRequestSplat
            Write-Verbose "$response"
            return $response
            
        }
        catch {
            Write-Error $_ 
        }
    }
}


function Get-FabricDisplayName {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$DisplayName, 

        [Parameter()]
        [string]$Sequence = 1, 

        [Parameter()]
        [switch]
        $Connect
    )

    $NewDisplayName = "FabricPOC-App-{0}-00{1}" -f $DisplayName, $Sequence

    $restUri =  "https://graph.microsoft.com/v1.0/applications"
    $restUri += "?`$search=`"displayName:" + "$NewDisplayName`""
    $restUri += "&`$count=true"
    $restUri += "&`$select=appId,identifierUris,displayName"

    if($Connect) {

        try {

            Write-Verbose "Verifying DisplayName with existing SPNs"

            $script:Headers         = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri                 = $restUri
                Method              = "GET"
                ContentType         = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"
                ConsistencyLevel    = "eventual"
                }
                ErrorAction = "Stop"
                
            }

            $response       = Invoke-RestMethod @invokeRestAPIRequestSplat
            $responseVar    = $response.value[0]
            $AppID         = $responseVar.appId
            $AppDisplayName = $responseVar.displayName
            if ($AppID) {
                Write-Verbose "SPN exists               : $NewDisplayName"
                Write-Verbose "Application ID          : $AppID"
                Write-Verbose "Application DisplayName : $AppDisplayName"
                $bodyContent = @{
                    Description         = "SPN already Exists"
                    ApplicationID       = $AppID 
                    DisplayName         = $SPNObjectID
                    Owners              = @($OWNER1, $Owner2, $Owner3)
                } | ConvertTo-Json -Depth 3
            }
            else {
                Write-Verbose "There is no existing Application with this name = $NewDisplayName"
                $NewDisplayNameVar = $NewDisplayName 
                return $NewDisplayNameVar
            }
        }

        catch {
            Write-Error $_
        }
    }
}


$DisplayNameExec = Get-FabricDisplayName -DisplayName Lighthouse-DeploymentInfra -Sequence 1 -Connect





function New-DisplayName {
    [CmdletBinding()]
    param (
        
        [Parameter()]
        [string]
        $DisplayName, 
        [Parameter()]
        [switch]
        $Connect
    )
    $NewDisplayName = "FabricPOC-App-{0}-00{1}" -f $DisplayName, $Sequence
    return $NewDisplayName
}


$Test = Test-DisplayName -DisplayName $DisplayNameExec -Connect -Verbose






function Confirm-FabricDisplayName {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$DisplayName,  

        [Parameter()]
        [switch]
        $Connect
    )

    $restUri =  "https://graph.microsoft.com/v1.0/applications"
    $restUri += "?`$search=`"displayName:" + "$DisplayName`""
    $restUri += "&`$count=true"
    $restUri += "&`$select=id,appId,identifierUris,displayName"

    if($Connect) {

        try {

            

            Write-Verbose "Verifying DisplayName with existing SPNs"
            Write-Verbose "DisplayName = $DisplayName"

            $script:Headers = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri                 = $restUri
                Method              = "GET"
                ContentType         = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"
                ConsistencyLevel    = "eventual"
                }
                ErrorAction = "Stop"
                StatusCodeVariable = "SCV"
                
            }

            $response       = Invoke-RestMethod @invokeRestAPIRequestSplat
            Write-Verbose $SCV
            $responseVar    = $response.value[0]
            $AppObjectID    = $responseVar.id
            $AppID          = $responseVar.appId
            $AppDisplayName = $responseVar.displayName
            Write-Verbose "Existing Application ID          : $AppID"
            Write-Verbose "Existing Application DisplayName : $AppDisplayName"
            if ($AppID) {

                Write-Verbose "SPN exists               : $DisplayName"
                Write-Verbose "Application ID          : $AppID"
                Write-Verbose "Application DisplayName : $AppDisplayName"

                return $AppObjectID
            }
            else {
                Write-Verbose "There is no existing Application with this name : $DisplayName"
                return $null
            }
        }

        catch {
            Write-Error $_
        }
    }
}

function Get-FabricSPN {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$AppObjectID, 

        [Parameter()]
        [switch]
        $Connect
    )


    $restUri =  "https://graph.microsoft.com/v1.0/applications/"
    $restUri += "$AppObjectID"
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
            $AppID         = $response.appId
            $AppDisplayName = $response.displayName
            $AppID.GetType()
            $bodyContent = @{
                ApplicationName =  $AppDisplayName
                ApplicationID   =  $AppID
            } | ConvertTo-Json -Depth 3
            
            return $bodyContent
        }
        catch {
            Write-Error $_
        }
    }
}








