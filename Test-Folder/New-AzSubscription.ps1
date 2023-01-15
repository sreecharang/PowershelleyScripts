
function Fabric-AccessToken {
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
                Scope = "https://management.azure.com/.default"
                Client_Id = $clientId
                Client_secret = $clientSecret
            }

            $TokenResponse = Invoke-RestMethod -Uri $Url -Method POST -Body $Body

            $script:TokenVar = $TokenResponse.access_token
        }
        
        catch {
           Write-Error $_
        }
    }
    end {
        Write-Verbose "All Done."
    }
}


function Fabric-CreateSub {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            Position = 0,
            HelpMessage = "Run function with this parameter"
        )]
        [switch]
        $Connect,

        [Parameter(
            Mandatory = $false,
            Position = 1,
            HelpMessage = "Subscription Name"
        )]
        [string]
        $SubscriptionName = "VMM-003"
    )

    Write-Verbose "Creation of Subscription : $SubscriptionName"

    try {

        $FabricSubscription = "Fabric-SUB-" + $SubscriptionName

        # $restUri = "https://management.azure.com/providers/Microsoft.Billing/billingaccounts/?api-version=2020-05-01"
        
        $restUri = "https://management.azure.com/providers/Microsoft.Subscription/"
        $restUri += "aliases/$FabricSubscription"
        $restUri += "?api-version=2021-10-01"

        

        $Body = @{
            properties = @{
                billdingScope   = "/providers/Microsoft.Billing/BillingAccounts/8187752/enrollmentAccounts/66743744"
                DisplayName     = $FabricSubscription
                Workload        = "Production"
            }
        } | ConvertTo-Json

        if ($Connect){

            Fabric-AccessToken
            $script:Headers = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri = $restUri
                Method = "PUT"
                ContentType = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"}
                ErrorAction = "Stop"
                Body = $Body
            }
            
            $response = Invoke-RestMethod @invokeRestAPIRequestSplat 
            
            Write-Verbose "Creation of Subscription : $SubscriptionName"
            return $response
        }
    }
    catch {
        Write-Error $_
    }
}