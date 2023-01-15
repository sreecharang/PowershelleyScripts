using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$ClientID 
$ClientSecret
$TenantName  
$SendgridToken
$DisplayName  
$Sequence     
$DeploymentID 
$EngagementID 
$OWNER1       
$OWNER2       
$OWNER3       


$OWNERTAG   = $OWNER1 + ";" + $OWNER2 + ";" + $OWNER3


# Help Message : Generating Accessing Token
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
        return $TokenVar
    }
}

# Help Message : Attaching Tags to SPN
function Set-NewCoSPNTags {
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
            # New-NewCoAccessTokenSP

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
            return $response

        }
        catch {
            Write-Error $_.Exception.Message
        }
    }
}


# Help Message : Attaching Owners to SPN
function Set-NewCoSPNOwners {
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

                $OwnerID = Get-NewCoUsersId -UserEmailAddress $Owner -Connect 

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
            Write-Error $_.Exception.Message
        }
    }
}

# Help Message : Retrieving User ID for each Owner 
function Get-NewCoUsersId {
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

        $restUri = "https://graph.microsoft.com/v1.0/users?`$select=displayName,id&`$filter=userPrincipalName eq "
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
                Write-Error $_.Exception.Message
            }
        }
    }
    End{
        return $UserID
    }
}

# Help Message : Generating SPN for APP registration
function Set-NewCoSPN {
    [CmdletBinding()]
    param (

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

            Write-Verbose "Invoking Creation of SPN"

            $invokeRestAPIRequestSplat = @{
                Uri = $restUri
                Method = "POST"
                ContentType = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"}
                ErrorAction = "Stop"
                Body = $Body
            }

            $response = Invoke-RestMethod @invokeRestAPIRequestSplat 
            $script:SPNObjectIDVar = $response.id

            Write-Verbose "Created ServicePrincipal for application : $SPNApplicationIDVar"
            
        }
        catch {
            Write-Error $_.Exception.Message
        }
    }
}

# Help Message : Sending Mail to Owners of SPN
function Set-NewCoSendGrid {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            Position = 0, 
            HelpMessage = 'Send grid API Token'
        )]
        [string]$SendgridToken,

        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'Owners Email address'
        )]
        [string]$OWNER1,

        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'Owners Email address'
        )]
        [string]$OWNER2,

        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'Owners Email address'
        )]
        [string]$OWNER3,

        [Parameter(
            HelpMessage = 'Application ID of SPN'
        )]
        [string]$ApplicationID,

        [Parameter(
            HelpMessage = 'Object ID of SPN'
        )]
        [string]$SPNObjectID,

        [Parameter()][switch]$Connect
    )


    
    $restUri = "https://api.sendgrid.com/v3/mail/send"

    $subject = "SPN generated on NewCo Management"

    $contentType = "text/html"
    $contentBody = "Application ID: $ApplicationID, `n SPN ID: $SPNObjectID `n Owners: $OWNER1, $OWNER2, $OWNER3 `r`nGenerated on NewCo Management"

    $FromEmailAddress 



    $mailbody = @{
        personalizations = @(@{
            to = @(@{
                email = $OWNER1
            })
            subject = $subject
            # TODO: For Multiple Owners adding CC as below. 
            cc = @(
                @{
                    email = $OWNER2
                }
                @{
                    email = $OWNER3
                }
                @{
                    email = $FromEmailAddress
                }
            )
        })
        content          = @(@{
            type  = $contentType
            value = $contentBody
        })
        from = @{
            email = $FromEmailAddress
            name 
        }
        reply_to = @{
            email = $FromEmailAddress
            name 
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
            Write-Error $_.Exception.Message
        }
    }
}



# Help Message : Attaching Prefix to DisplayName 
function New-DisplayName {
    [CmdletBinding()]
    param (
        
        [Parameter(
            HelpMessage = 'Display Name for SPN'
        )]
        [string]
        $DisplayName, 

        [Parameter(
            HelpMessage = 'Squence for SPN'
        )]
        [int]
        $Sequence, 
        [Parameter()]
        [switch]
        $Connect
    )
    $NewDisplayName = "NewCo-App-{0}-00{1}" -f $DisplayName, $Sequence
    return $NewDisplayName
}


# Help Message : Validating with existing SPN 
# If exists, return Application Display Name and Application Object ID

function Confirm-NewCoDisplayName {
    [CmdletBinding()]
    param (
        [Parameter(
            HelpMessage = 'New Display Name for SPN'
        )]
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

            New-NewCoAccessTokenSP -ClientID $ClientID -ClientSecret $ClientSecret -TenantName $TenantName

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
            $AppObjectID    = $responseVar.id | Out-String
            $AppID          = $responseVar.appId
            $AppDisplayName = $responseVar.displayName

            # Exposing Application Object ID 
            $script:AppObjectIDVar = $AppObjectID
            if ($AppID) {

                Write-Verbose "SPN exists               : $DisplayName"
                Write-Verbose "Application ID          : $AppID"
                Write-Verbose "Application DisplayName : $AppDisplayName"
                
                # Returning Application DisplayName
                return $AppDisplayName
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

# Help Message : If SPN exists, Retrieve Display Name and Application ID 
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
            $bodyContent = @{
                Description     = "SPN Exists"
                SPNDisplayName =  $AppDisplayName
                ApplicationID   =  $AppID
            } | ConvertTo-Json -Depth 3

            return $bodyContent
        }

        catch {
            Write-Error $_
        }
    }
}


# Help Message : Running all function related to creation of SPN  
function New-NewCoSPN {
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
        [string]$DeploymentIDTAG,

        
        [Parameter(
            Mandatory = $false,
            Position = 2, 
            HelpMessage = 'EngagementID of the application'
        )]
        [string]$EngagementIDTAG,

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
            HelpMessage = "Client ID of service principal"
        )]
        [string]$ClientID,

        [Parameter(
            Mandatory = $false,
            Position = 8,
            HelpMessage = "TenantName"
        )]
        [string]$TenantName,

        [Parameter(
            Mandatory = $false,
            Position = 9,
            HelpMessage = "ClientSecret"
        )]
        [string]$ClientSecret,


        [Parameter(
            Mandatory = $false,
            Position = 10, 
            HelpMessage = 'Retrieving the JWT Access Token'
        )]
        [switch]$Connect
    )

    begin {
        
        $restUri = "https://graph.microsoft.com/v1.0/applications"
    
        $Body = @{
            displayName = $DisplayName
            signInAudience = "AzureADMyOrg"
        } | ConvertTo-Json
    }

    process {
        if($Connect){
            try {
                
                New-NewCoAccessTokenSP -ClientID $ClientID -ClientSecret $ClientSecret -TenantName $TenantName

                Write-Verbose "Creation of SP: $DisplayName"

                $script:Headers = $TokenVar
                Write-Verbose $Headers
                $invokeRestAPIRequestSplat = @{
                    Uri = $restUri
                    Method = 'POST'
                    ContentType = "application/json"
                    Headers = @{Authorization = "Bearer $($Headers)"}
                    ErrorAction = 'Stop'
                    Body = $Body
                }

                $response = Invoke-RestMethod @invokeRestAPIRequestSplat
                $SPNApplicationID = $response.appId
                $responseId = $response.id
                Write-Verbose "Created Application Registration: $responseId"
                Write-Verbose "Application ObjectID: $responseId "
                

                # Invoking SPN Tags 
                $script:TagsApplicationID = $responseId
                Set-NewCoSPNTags -Connect -DeploymentID $DeploymentIDTAG  -EngagementID $EngagementIDTAG -OWNER $OWNERTAG 

                #Invoking SPN OWners 
                $script:OwnersApplicationID = $responseId
                Set-NewCoSPNOwners -Connect -Owner1 $OWNER1 -Owner2 $OWNER2 -Owner3 $OWNER3 

                #Invoking Set SPN 
                $script:SPNApplicationID = $SPNApplicationID
                Set-NewCoSPN -Connect 

                # Invoking SendGrid 
                $script:SPNObjectID = $SPNObjectIDVar
                # Set-NewCoSendGrid -Connect -SendgridToken $SendgridToken -OWNER1 $Owner1 -OWNER2 $OWNER2-OWNER3 $OWNER3 -SPNObjectID $SPNObjectID `
                # -ApplicationID $SPNApplicationID

                
                $bodyContent = @{
                    ApplicationID       = $SPNApplicationID 
                    ServicePrincipalID  = $SPNObjectID
                    Owners              = @($OWNER1, $Owner2, $Owner3)
                } | ConvertTo-Json -Depth 3

                return $bodyContent

            }
            catch {
                Write-Error $_.Exception.Message
            }
        }
    }

    end {
       Write-Verbose "Created New SPN, with Tags, Owners and Sent mail to Owners"
    }
}


# Help Message : Running Display Name function 
$NewDisplayName = New-DisplayName -DisplayName $DisplayName -Sequence $Sequence -Connect

# Help Message : Running Validation function
$ValidateApp = Confirm-NewCoDisplayName -DisplayName $NewDisplayName -Connect -Verbose

$script:AppObjectIDs = $AppObjectIDVar

# Help Message : Logic for Validation of SPN exists or not. 
if($ValidateApp -eq $NewDisplayName) {

    $ExistingSPN = Get-NewCoSPN -AppObjectID $AppObjectIDs -Connect -Verbose

    $bodyContent = $ExistingSPN
    
} 

else {
    
    $NewSPN = New-NewCoSPN -DisplayName  $NewDisplayName -DeploymentID $DeploymentID -EngagementID $EngagementID -OWNERTAG $OWNERTAG -OWNER1 $OWNER1 `
    -OWNER2 $OWNER2 -OWNER3 $OWNER3 -ClientID $ClientID -ClientSecret $ClientSecret -TenantName $TenantName -Connect -Verbose

    $bodyContent = $NewSPN
    
} 



# # Associate values to output bindings by calling 'Push-OutputBinding'.
# Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
#     StatusCode = [System.Net.HttpStatusCode]::OK
#     Body = $bodyContent
# })
   

Write-Host $bodyContent


