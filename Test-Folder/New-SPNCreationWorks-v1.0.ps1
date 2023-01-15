



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
        return $TokenVar
        Write-Verbose "All Done."
    }
}

# Help Message : Attaching Tags to SPN
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
            return $response

        }
        catch {
            Write-Error $_.Exception.Message
        }
    }
}

# Help Message : Retrieving User ID for each Owner 
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
                Write-Error $_.Exception.Message
            }
        }
    }
    End{
        return $UserID
    }
}

# Help Message : Generating SPN for APP registration
function Set-FabricSPN {
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
            $script:SPNNameVar = $response.appDisplayName

            Write-Verbose "Created ServicePrincipal for application : $SPNApplicationIDVar"
            
        }
        catch {
            Write-Error $_.Exception.Message
        }
    }
}

function Set-FabricSPNSecrets {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            Position = 0, 
            HelpMessage = 'Switch statement for Users ID'
        )]
        [string]$SPNObjectID ,
        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'Switch statement for Users ID'
        )]
        [string]$SPNName ,
        [Parameter(
            Mandatory = $false,
            Position = 2, 
            HelpMessage = 'Switch statement for Users ID'
        )]
        [switch]$Connect
    )


    $restUri = "https://graph.microsoft.com/v1.0/servicePrincipals/"
    $restUri += $SPNObjectID
    $restUri += "/addPassword"

    $SPNSecretName = "{0}-Secret" -f  $SPNName
    
    $script:SPNApplicationIDVar = $SPNApplicationID

    $CurrentTime = Get-Date
    $AddYear = $CurrentTime.AddYears(1)
    $UpdateTime = $AddYear.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss')

    $Body = @{
        passwordCredential = @{
            displayName = $SPNSecretName
            endDateTime = $UpdateTime
        }
    } | ConvertTo-Json

    
    if($Connect){
        try {
            
            Write-Verbose "URL: $restUri"
            
            $script:Headers = $TokenVar

            Write-Verbose "Creating Secrets"

            $invokeRestAPIRequestSplat = @{
                Uri = $restUri
                Method = "POST"
                ContentType = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"}
                ErrorAction = "Stop"
                Body = $Body
            }

            $response = Invoke-RestMethod @invokeRestAPIRequestSplat 
            $script:SPNSecretIDVar = $response.keyId
            $script:SPNSecretValueVar = $response.secretText


            Write-Verbose "Created a new Secret: $response"
            Write-Verbose "Created a new Secret: $SPNSecretIDVar"
            Write-Verbose "Created a new Secret: $SPNSecretValueVar"
            
        }
        catch {
            Write-Error $_.Exception.Message
            Write-Error "Issue at creating Secrets"
        }
    }
}


# Help Message : Sending Mail to Owners of SPN
function Set-FabricSendGrid {
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
            HelpMessage = 'Email address of requester'
        )]
        [string]$ToEmailAddress,

        [Parameter(HelpMessage = 'Name of SPN')][string]$SPNName,
        [Parameter(HelpMessage = 'ID of SPN')][string]$SPNID,
        [Parameter(HelpMessage = 'Object ID of SPN')][string]$SPNObjectID,
        [Parameter(HelpMessage = 'Secret ID of SPN')][string]$SPNSecretID,
        [Parameter(HelpMessage = 'Secret Value of SPN')][string]$SPNSecretValue,
        [Parameter(HelpMessage = 'Application ID of SPN')][string]$ApplicationID,
        [Parameter(HelpMessage = 'Application Object ID of SPN')][string]$ApplicationObjectID,
        [Parameter(HelpMessage = 'Application Object ID of SPN')][string]$TenantName = "Fabric Management",
        
        [Parameter()][switch]$Connect
    )


    
    $restUri = "https://api.sendgrid.com/v3/mail/send"

    $subject = " "

    $contentType = "text/html"
    # $contentBody = "Application ID: $ApplicationID, `n SPN ID: $SPNObjectID `n Owner: $ToEmailAddress `r`nGenerated on Fabric Management"

    # Email Template 
    
    
    $EmailTemplateBody = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SPN From Cloud Identieis Team</title>
</head>
<body style="margin: 0; padding: 0; background-color: #ffffff; font-family: Calibri, sans-serif;">
   <center class="wrapper" style="width: 100%; background-color: #ffffff; table-layout: fixed; padding-bottom: 40px;">
    <div class="outer" style="max-width: 600px; background-color: #ffffff; border-left: 1px solid #E5ECEE; border-right: 1px solid #E5ECEE;">
        <table class="main" align="center" style="margin: 0 auto; width: 100%; max-width: 600px; border-spacing: 0; font-family: sans-serif; color: #000000;">
             <!-- Top Section -->
            <tr>
                <td>
                    <table width="100%">
                        <tr>
                            <td style="background-color: #faea05; padding: 10px;
                            text-align: left;">
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
             <!-- Mid Section -->
            <tr>
                <td>
                    <table width="100%" style="padding: 20px; padding-bottom: 20px">

                        <tr>
                            <td style="max-width: 100%;" class="main-section">
                                 <table style="width: 100%;">
                                    <tr>
                                        <td style="padding: 10px;">
                                                                   
                                            <table style="width: 100%; padding: 10px 20px;">
                                                <p style="font-weight: bold; font-size: 20px; line-height: 1;">
                                                   CTP Admin Identities Notification
                                                </p>
                                                <p style="font-weight: bold; font-size: 18px; line-height: 1;">
                                                    New SPN got provisined on $TenantName Tenant
                                                </p>
                                                <p style="padding: 10px;">
                                                    Secrets are generated with expiry time of 1 year 
                                                </p>
                                                
                                                <a class="btn" href="https://explore.eyfabric.ey.com/eydx/content/cb324d97-748e-4e91-8dcf-e0d50d49f4cf?section=community&repoName=CTP-Admin-Identities" 
                                                style="padding: 10px 20px; background-color: #000000; color: #ffffff; text-decoration: none; border-radius: 10px;">Learn more...</a>

                                            </table>
                                            
                                            <table style="width: 100%; padding: 10px 20px;">
                                                <tr>
                                                    <th class="table-main-header" style="border-bottom: 1.5pt solid #abaeb3; text-align: left;
                                                    padding: 5px 10px;">
                                                        Settings
                                                    </th>
                                                    <th class="table-main-header" style="border-bottom: 1.5pt solid #abaeb3; text-align: left;
                                                    padding: 5px 10px;">
                                                        Value
                                                    </th>
                                                </tr>

                                                <tr>
                                                    <td class="table-main-child" style=" border-bottom: 1.5pt solid #d0d2d6; text-align: left;
                                                    padding: 2.5px 10px; font-size: 12px;">
                                                        SPN-Name
                                                    </td>
                                                    <td class="table-main-child" style=" border-bottom: 1.5pt solid #d0d2d6; text-align: left;
                                                    padding: 2.5px 10px; font-size: 12px;">
                                                        $SPNName
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td class="table-main-child" style=" border-bottom: 1.5pt solid #d0d2d6; text-align: left;
                                                    padding: 2.5px 10px; font-size: 12px;">
                                                        SPN-ID
                                                    </td>
                                                    <td class="table-main-child" style=" border-bottom: 1.5pt solid #d0d2d6; text-align: left;
                                                    padding: 2.5px 10px; font-size: 12px;">
                                                        $SPNObjectID
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td class="table-main-child" style=" border-bottom: 1.5pt solid #d0d2d6; text-align: left;
                                                    padding: 2.5px 10px; font-size: 12px;">
                                                        SPN-Secret-ID
                                                    </td>
                                                    <td class="table-main-child" style=" border-bottom: 1.5pt solid #d0d2d6; text-align: left;
                                                    padding: 2.5px 10px; font-size: 12px;">
                                                        $SPNSecretID
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td class="table-main-child" style=" border-bottom: 1.5pt solid #d0d2d6; text-align: left;
                                                    padding: 2.5px 10px; font-size: 12px;">
                                                        SPN-Secret-Value
                                                    </td>
                                                    <td class="table-main-child" style=" border-bottom: 1.5pt solid #d0d2d6; text-align: left;
                                                    padding: 2.5px 10px; font-size: 12px;">
                                                        $SPNSecretValue
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td class="table-main-child" style=" border-bottom: 1.5pt solid #d0d2d6; text-align: left;
                                                    padding: 2.5px 10px; font-size: 12px;">
                                                        Application-Registration-App-ID 
                                                    </td>
                                                    <td class="table-main-child" style=" border-bottom: 1.5pt solid #d0d2d6; text-align: left;
                                                    padding: 2.5px 10px; font-size: 12px;">
                                                        $ApplicationID
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td class="table-main-child" style=" border-bottom: 1.5pt solid #d0d2d6; text-align: left;
                                                    padding: 2.5px 10px; font-size: 12px;"> 
                                                        Application-Registration-ID 
                                                    </td>
                                                    <td class="table-main-child" style=" border-bottom: 1.5pt solid #d0d2d6; text-align: left;
                                                    padding: 2.5px 10px; font-size: 12px;">
                                                        $ApplicationObjectID
                                                    </td>
                                                </tr>
                                            </table>
                                            <p>Thank you for using SPN feature from CTP Admin Identities</p>
                                        </td>
                                    </tr>
                                 </table>
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
            <!-- Footer section  -->
            <tr>
                <td style="background-color: #efefef;">
                    <table width="100%" style="padding: 10px;">

                        <tr>
                            <td style="padding: 10px; text-align: left; padding-bottom: 10px;">
                                <p style="font-size: 10px;margin-top:18px; margin-bottom: 10px;">
                                    If you need more information, please visit the section "Identities and Access Management" 
                                    inside the <a href="https://ctp.ey.com/">CTP Portal</a>. 
                                    Should you have any comments or questions, please contact us 
                                    <a href="http://eyct.services-now.com">CT Service Desk</a> or 
                                    feel free to reply this e-mail with your question.
                                </p>
                                
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
        </table>
    </div>
   </center>
</body>
</html>
"@ 

    $FromEmailAddress
    
    
    Write-Verbose $EmailTemplateBody
    $mailbody = @{
        personalizations = @(@{
            to = @(@{
                email = $ToEmailAddress
            })
            subject = $subject
            # TODO: For Multiple Owners adding CC as below. 
            # cc = @(
            #     @{
            #         email = $ToEmailAddress
            #     }
            #     @{
            #         email = $ToEmailAddress
            #     }
            # )
        })
        content          = @(@{
            type  = $contentType
            value = $EmailTemplateBody
        })
        from = @{
            email = $FromEmailAddress
            name = "CTPE_DE_IAM.GID"
        }
        reply_to = @{
            email = $FromEmailAddress
            name = "CTPE_DE_IAM.GID"
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
    $NewDisplayName = "Fabric-App-{0}-00{1}" -f $DisplayName, $Sequence
    return $NewDisplayName
}


# Help Message : Validating with existing SPN 
# If exists, return Application Display Name and Application Object ID

function Confirm-FabricDisplayName {
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

            New-FabricAccessTokenSP -ClientID $ClientID -ClientSecret $ClientSecret -TenantName $TenantName

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

                Write-Verbose "SPN exists              : $DisplayName"
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
function Get-FabricSPN {
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
        } | ConvertTo-Json
    }

    process {
        if($Connect){
            try {
                
                New-FabricAccessTokenSP -ClientID $ClientID -ClientSecret $ClientSecret -TenantName $TenantName

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
                $ApplicationObjectID = $response.Id
                $ApplicationID = $response.appId
                Write-Verbose "Created Application Registration: $responseId"

                

                # Invoking SPN Tags 
                $script:TagsApplicationID = $ApplicationObjectID
                Set-FabricSPNTags -Connect -DeploymentID $DeploymentIDTAG  -EngagementID $EngagementIDTAG -OWNER $OWNERTAG 


                #Invoking Set SPN 
                $script:SPNApplicationID = $ApplicationID
                Set-FabricSPN -Connect 


                #Create Secrets for SPN 
                $script:SPNObjectID = $SPNObjectIDVar
                $script:SPNName = $SPNNameVar
                Set-FabricSPNSecrets -SPNObjectID $SPNObjectID -SPNName SPNName -Connect -Verbose

                # Invoking SendGrid 
                $script:SPNSecretID = $SPNSecretIDVar
                $script:SPNSecretValue = $SPNSecretValueVar

                Set-FabricSendGrid -SendgridToken $SendgridToken -ToEmailAddress $OWNER1 -SPNName $SPNName -SPNObjectID $SPNObjectID `
                -SPNSecretID $SPNSecretID -SPNSecretValue $SPNSecretValue -ApplicationID $ApplicationID `
                -ApplicationObjectID $ApplicationObjectID -Connect -Verbose

                
                $bodyContent = @{
                    ApplicationID       = $SPNApplicationID 
                    ServicePrincipalID  = $SPNObjectID
                    Owners              = @($OWNER1, $OWNER2, $OWNER3)
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
$ValidateApp = Confirm-FabricDisplayName -DisplayName $NewDisplayName -Connect -Verbose

$script:AppObjectIDs = $AppObjectIDVar

# Help Message : Logic for Validation of SPN exists or not. 
if($ValidateApp -eq $NewDisplayName) {

    $ExistingSPN = Get-FabricSPN -AppObjectID $AppObjectIDs -Connect -Verbose

    $bodyContent = $ExistingSPN
    
} 

else {
    
    $NewSPN = New-FabricSPN -DisplayName  $NewDisplayName -DeploymentID $DeploymentID -EngagementID $EngagementID -OWNERTAG $OWNERTAG -OWNER1 $OWNER1 `
    -OWNER2 $OWNER2 -OWNER3 $OWNER3 -ClientID $ClientID -ClientSecret $ClientSecret -TenantName $TenantName -Connect -Verbose

    $bodyContent = $NewSPN
    
} 

Write-Verbose $bodyContent