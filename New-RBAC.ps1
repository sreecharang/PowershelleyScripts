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

function Connect-Account {

    [CmdletBinding()]
    param (
        
        [Parameter(
            Position = 0,
            ValueFromPipeline = $true,
            HelpMessage = 'Scope of the RestAPI'
        )]
        [ValidatePattern('*/*')]
        [string]$Scope,

        [Parameter(
            Position = 1,
            ValueFromPipeline = $true,
            HelpMessage = 'API Version of RestAPI'
        )]
        [ValidatePattern('*?api-version*')]
        [string]$ApiVersion = '?api-version=2020-01-01'

    )

    begin {
        Write-Verbose 'Logging to Azure account'
    }

    process {
        try {
            $azContext = Get-AzContext
            $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
            $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
            $token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
            $authHeader = @{
                'Content-Type'='application/json'
                'Authorization'='Bearer ' + $token.AccessToken
            }
        
            # Invoke the REST API
            $restUri = "https://management.azure.com/"
            $restUri += "$Scope$ApiVersion"
            $invokeRestAPIRequestSplat = @{
                Uri = $restUri
                Method = 'Get'
                Headers = $authHeader
                ErrorAction = 'Stop'
            }
            $response = Invoke-RestMethod @invokeRestAPIRequestSplat
            $script:HeadersVar = $invokeRestAPIRequestSplat.Headers
            Write-Verbose 'Connected to Azure Successfully'
        }
        catch {
            Write-Error $_ 
        }
    }

    end {
        Write-Verbose "All done"
    }
}

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

    # FGMT:: 8b111ab9-bf11-4343-991f-056f684e9fe4
    # Poc: ec266dad-e856-43e6-bfb1-18fd21b30b15

    # FGMT: fabricmgmt.onmicrosoft.com
    # Poc: fabricpoc01.onmicrosoft.com

    # FGMT-Secret: fbL8Q~cPy.poxxU11VEmifRLLFc1l0PKyeOSpc~t
    # Poc-Secret: XyT8Q~ZX1XZBGSdseFnVS3wXjBoB_VuQCn1hPdtd
#>

{1}

function Access-Token-RBAC {
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
            # $JWTToken = Get-JWTDetails($TokenResponse.access_token)

            # Exposing Access token for other functions 
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

{2}
function Create-NewRBAC {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline =$false, 
            Position = 1,
            HelpMessage = 'Name of RBAC Group need to be created.'
        )]
        [string] $DisplayName,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline =$false, 
            Position = 1,
            HelpMessage = 'Name of RBAC Group need to be created.'
        )]
        [string] $Description,
        # [Parameter(
        #     Mandatory = $false,
        #     ValueFromPipeline =$false, 
        #     Position = 2,
        #     HelpMessage = 'Role Assignment for RBAC group.'
        # )]
        # [string] $MailNicName,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline =$false, 
            Position = 3,
            HelpMessage = 'Security enabled for RBAC'
        )]
        [ValidateSet('true', 'false')]
        [string] $securityEnabeld = 'true',

        [Parameter(
            ValueFromPipeline =$false,
            Position = 4,
            HelpMessage = 'Switch statement for connecting Azure'
        )]
        [switch] $Connect
        )
    
    Write-Verbose "Creation of RBAC Group: $DisplayName"

    try {



        $restUri = "https://graph.microsoft.com/v1.0/groups"
        

        $Body = @{
            description = $Description
            displayName = $DisplayName
            groupTypes = @()
            mailEnabled = 'false'
            # mailNickName = $MailNicName
            securityEnabled = 'true'
        } | ConvertTo-Json
        
        if ($Connect){

            Access-Token-RBAC
            $Global:Headers = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri = $restUri
                Method = 'POST'
                ContentType = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"}
                ErrorAction = 'Stop'
                # Body = $Body
            }
            
            $response = Invoke-RestMethod @invokeRestAPIRequestSplat
            
            Write-Verbose "Created RBAC Group: $DisplayName"
            return $response
        }
       
    }
    catch {
        Write-Error $_
    }
}


function Fabric-Inviite {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline =$false, 
            Position = 1,
            HelpMessage = 'Name of RBAC Group need to be created.'
        )]
        [string] $InviteUserEmailAddress,
        
        [Parameter(
            ValueFromPipeline =$false,
            Position = 4,
            HelpMessage = 'Switch statement for connecting Azure'
        )]
        [switch] $Connect
    )

    try {



        $restUri = "https://graph.microsoft.com/v1.0/invitations"
        

        $Body = @{
            invitedUserEmailAddress = $InviteUserEmailAddress
            inviteRedirectUrl = "https://myapplications.microsoft.com"
        } | ConvertTo-Json
        
        if ($Connect){

            Access-Token-RBAC
            $Global:Headers = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri = $restUri
                Method = 'POST'
                ContentType = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"}
                ErrorAction = 'Stop'
                Body = $Body
            }
            
            $response = Invoke-RestMethod @invokeRestAPIRequestSplat
            
            Write-Verbose "Invitation Sent"
            return $response
        }
       
    }
    catch {
        Write-Error $_
    }

}

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

{3}

function RoleAssign-RBAC {

    [CmdletBinding()]
    param (
        
        [Parameter(
            Mandatory = $false,
            Position = 0,
            HelpMessage = 'Id of RBAC Group'
        )]
        [string]$RBACID,

        
        [Parameter(
            Mandatory = $true,
            Position = 1,
            HelpMessage = 'Id of resource service principal for which the assignement made'
        )]
        [ValidateSet('Management', 'Subscription', 'Resource-Group')]
        [string]$ScopeValue="Management",



        # [Parameter(Mandatory = $false, ParameterSetName = 'ManagementIDAll')]
        # [Parameter(
        #     Mandatory = $false,
        #     ParameterSetName = 'ManagementID',
        #     ValueFromPipeline = $true,
        #     HelpMessage = 'Id of resource service principal for which the assignement made'
        # )][string]$ManagementId,
        

        # [Parameter(Mandatory = $false, ParameterSetName = 'ManagementID')]
        # [switch]$Management,


        [Parameter(
            Mandatory = $true,
            Position = 2,
            HelpMessage = 'Id of resource service principal for which the assignement made'
        )]
        [ValidateSet('Owner', 'Contributor', 'Reader')]
        [string]$RoleName="Contributor",

        [Parameter(
            Mandatory = $false,
            Position = 3,
            HelpMessage = 'Id of resource service principal for which the assignement made'
        )]
        [switch]$Connect
    )

    DynamicParam {

        if($ScopeValue -eq "Management") {
            

            $parameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $parameterAttribute.Position = 4
            $parameterAttribute.Mandatory = $true
            
      
            $attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $attributeCollection.Add($parameterAttribute)
      
            $dynParam = New-Object System.Management.Automation.RuntimeDefinedParameter('ManagementID', [string], $attributeCollection)
      
            $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $paramDictionary.Add('ManagementID', $dynParam)
            return $paramDictionary


            # # Set the dynamic parameters' name
            # $ParamName_scopegroup = 'Scope'


            # # Create the collection of attributes
            # $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]


            # # Create and set the parameters' attributes
            # $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            # $ParameterAttribute.Mandatory = $false
            # $ParameterAttribute.Position = 1


            # # Add the attributes to the attributes collection
            # $AttributeCollection.Add($ParameterAttribute)

            # # Create the dictionary 
            # $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

            # # Generate and set the ValidateSet 
            # $arrSet = "providers/Microsoft.Management/managementGroups/$managementgroupID"
            # $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
            
            # # Add the ValidateSet to the attributes collection
            # $AttributeCollection.Add($ValidateSetAttribute)


            # # Create and return the dynamic parameter
            # $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParamName_scopegroup = 'Scope', [string], $AttributeCollection)
            # $RuntimeParameterDictionary.Add($ParamName_scopegroup, $RuntimeParameter)

        }

        elseif ($ScopeValue -eq "Subscription") {



            $parameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $parameterAttribute.Position = 5
            $parameterAttribute.Mandatory = $true
            
      
            $attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $attributeCollection.Add($parameterAttribute)
      
            $dynParam = New-Object System.Management.Automation.RuntimeDefinedParameter('SubscriptionID', [string], $attributeCollection)
      
            $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $paramDictionary.Add('SubscriptionID', $dynParam)
            return $paramDictionary

        }

        elseif ($ScopeValue -eq "Resource-Group") {

            $parameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $parameterAttribute.Position = 6
            $parameterAttribute.Mandatory = $true
            
            $parameterAttributeRGSub = New-Object System.Management.Automation.ParameterAttribute
            $parameterAttributeRGSub.Position = 7
            $parameterAttributeRGSub.Mandatory = $true
      
            $attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $attributeCollectionRGSub = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $attributeCollection.Add($parameterAttribute)
            $attributeCollectionRGSub.Add($parameterAttributeRGSub)

            $dynParam = New-Object System.Management.Automation.RuntimeDefinedParameter('ResourceGroupID', [string], $attributeCollection)
            $dynParamRGSub = New-Object System.Management.Automation.RuntimeDefinedParameter('RGSubscriptionID', [string], $attributeCollectionRGSub)

            $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $paramDictionary.Add('ResourceGroupID', $dynParam)
            $paramDictionary.Add('RGSubscriptionID', $dynParamRGSub)

            return $paramDictionary

        }

        if ($RoleName -eq "Contributor") {

            $parameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $parameterAttribute.Position = 8
            $parameterAttribute.Mandatory = $true
      
            $attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $attributeCollection.Add($parameterAttribute)
            
            
             
            $dynParam = New-Object System.Management.Automation.RuntimeDefinedParameter('ContributorID', [string], $attributeCollection)
            $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $paramDictionary.Add('ContributorID', $dynParam)
            return $paramDictionary

        }


        elseif ($RoleName = "Owner") {


            $parameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $parameterAttribute.Position = 9
            $parameterAttribute.Mandatory = $true
      
            $attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $attributeCollection.Add($parameterAttribute)
            
            
             
            $dynParam = New-Object System.Management.Automation.RuntimeDefinedParameter('OwnerID', [string], $attributeCollection)
            $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $paramDictionary.Add('OwnerID', $dynParam)
            return $paramDictionary
           

        }

        elseif ($RoleName = "Reader") {

            $parameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $parameterAttribute.Position = 10
            $parameterAttribute.Mandatory = $true
      
            $attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $attributeCollection.Add($parameterAttribute)
            
            
             
            $dynParam = New-Object System.Management.Automation.RuntimeDefinedParameter('ReaderID', [string], $attributeCollection)
            $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $paramDictionary.Add('ReaderID', $dynParam)
            return $paramDictionary

        }
    }

    begin {

        if ($RoleName -eq "Contributor") {
            $PsBoundParameters.ContributorID
            $RoleNameId = $PsBoundParameters.ContributorID
        }

        elseif ($RoleName -eq "Owner"){
            $PsBoundParameters.OwnerID
            $RoleNameId = $PsBoundParameters.OwnerID
        }

        elseif ($RoleName -eq "Reader"){
            $PsBoundParameters.ReaderID
            $RoleNameId = $PsBoundParameters.ReaderID
        }

        

    }

    process {

        # $ScopeId = $PsBoundParameters[$ParamName_scopegroup]
        # $ManagementID = $PsBoundParameters.ManagementID
        # $RoleNameId = $PsBoundParameters.ContributorID
        
        
        


        if ($ScopeValue -eq "Management") {
            $ManagementID = $PsBoundParameters.ManagementID
            $Scope = "providers/Microsoft.Management/managementGroups/$ManagementID"
            Write-Verbose "Assigning RBAC group at Management Level: $ManagementID"
        }

        elseif ($ScopeValue -eq "Subscription") {
            $SubscriptionID = $PsBoundParameters.SubscriptionID
            $Scope = "subscriptions/$SubscriptionID"
            Write-Verbose "Assigning RBAC group at Subscription Level: $SubscriptionID"
        }

        elseif ($ScopeValue -eq "Resource-Group") {

            $ResourceGroupID = $PsBoundParameters.ResourceGroupID
            $RGSubscriptionID = $PsBoundParameters.RGSubscriptionID
            $Scope = "subscriptions/$RGSubscriptionID/resourceGroups/$ResourceGroupID"
            Write-Verbose "Assigning RBAC group at Resource-Group Level: $ResourceGroupID"
        }
        
        
        try {

        

            $RoleAssignmentID = New-Guid

            $restUri = "https://management.azure.com/$Scope"
            $restUri += "/providers/Microsoft.Authorization/roleAssignments/$RoleAssignmentID"
            $restUri += "?api-version=2015-07-01"
            
            
            $resourceID = "/$Scope/providers/Microsoft.Authorization/roleAssignments/$RoleNameId"
   
            $Body = @{
                properties = @{
                    principalId = $RBACID
                    roleDefinitionId = $resourceID    
                }
            } | ConvertTo-Json
    
            
            if($Connect) {

                Connect-Account
                $Global:Headers = $HeadersVar
    
    
                $invokeRestAPIRequestSplat = @{
                    Uri = $restUri
                    Method = 'PUT'
                    ContentType = "application/json"
                    Headers = $Headers
                    ErrorAction = 'Stop'
                    Body = $Body
                }
    
                $response = Invoke-RestMethod @invokeRestAPIRequestSplat
                $responseID = $response.id

                Write-Verbose "Assinging RBAC Group: $RBACID"
                Write-Verbose "at Scope of : $Scope"
                Write-Verbose "With responseID: $responseID"

                return $response.id
    
            }
        }
        catch {
            Write-Error $_
        }
    }
    end {
        Write-Verbose "Done."
    } 
}