
function New-FabricAccessTokenSP {
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
            $Url = "https://login.microsoftonline.com/$TenantName/oauth2/token"
            $Body = @{
                Grant_Type = "client_credentials"
                Scope = "https://graph.microsoft.com/.default"
                Client_Id = $ClientID
                Client_secret = $ClientSecret
                Resource="https://vault.azure.net"
            }

            $TokenResponse = Invoke-RestMethod -Uri $Url -Method POST -Body $Body
            Write-Verbose $Url
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



function Set-KeyvaultSecrets {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            Position = 0,
            HelpMessage = "Key vault Name"
        )]
        [string]$KeyVault,

        [Parameter(
            Mandatory = $false,
            Position = 0,
            HelpMessage = "Key vault secret name"
        )]
        [string]$KeyValutSecretName,

        [Parameter(
            Mandatory = $false,
            Position = 0,
            HelpMessage = "Key vault secret value"
        )]
        [string]$KeyVaultSecretValue,

        [Parameter(
            Mandatory = $false,
            Position = 3, 
            HelpMessage = 'Switch statement for Keyvault'
        )]
        [switch]$Connect
    )

    $CurrentTime = Get-Date
    $UpdateTimeUTCTime = $CurrentTime.ToUniversalTime().ToString('yy-MM-ddTss')
    $UpdatedKeyValutSecretName = "{0}{1}" -f $KeyValutSecretName, $UpdateTimeUTCTime

    $restUri = "https://$KeyVault"
    $restUri += ".vault.azure.net//secrets/"
    $restUri += "$UpdatedKeyValutSecretName"
    $restUri += "?api-version=7.3"
    
    $Body = @{
        value = $KeyVaultSecretValue
        contentType ='Application Account'
        attributes= @{
            exp = $secretExpiration
        }
    } | ConvertTo-Json
    

    if($Connect){
        try {


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
            $responseIdVar = $response.id
            $responseVersion = $responseIdVar.Split('/')[-1]
            Write-Verbose "Successful attached secret to KeyVault: $KeyVault"
            Write-Verbose "Id of Secret: $responseVersion"
            return $response
        }
        catch {
            Write-Error $_.Exception.Message
        }
    }
}

function Set-KeyvaultSecretByValidation {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            Position = 0,
            HelpMessage = "Key vault Name"
        )]
        [string]$KeyVault,

        [Parameter(
            Mandatory = $false,
            Position = 0,
            HelpMessage = "Key vault secret name"
        )]
        [string]$DummyKeyValueSecretName,

        [Parameter(
            Mandatory = $false,
            Position = 0,
            HelpMessage = "Key vault secret value"
        )]
        [string]$DummyKeyVaultSecretValue,

        [Parameter(
            Mandatory = $false,
            Position = 3, 
            HelpMessage = 'Switch statement for Keyvault'
        )]
        [switch]$Connect
    )

    $CurrentTime = Get-Date
    $UpdateTimeUTCTime = $CurrentTime.ToUniversalTime().ToString('yy-MM-ddTss')
    $UpdatedDummyKeyValueSecretName = "{0}{1}" -f $DummyKeyValueSecretName, $UpdateTimeUTCTime


    $restUri = "https://$KeyVault"
    $restUri += ".vault.azure.net//secrets/"
    $restUri += "$UpdatedDummyKeyValueSecretName"
    $restUri += "?api-version=7.3"
    
    $Body = @{
        value = $DummyKeyVaultSecretValue
    } | ConvertTo-Json
    

    if($Connect){
        try {


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
            

            return $response
        }
        catch {
            Write-Verbose $_.Exception.Message
            
        }
    }
}

function New-KeyVaultSecret { 
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            Position = 0,
            HelpMessage = "Key vault Name"
        )]
        [string]$KeyVault = "kv-FabricManagement-01",

        [Parameter(
            Mandatory = $false,
            Position = 0,
            HelpMessage = "Key vault secret name"
        )]
        [string]$DummyKeyValueSecretName = "---KeyVaultWriteTest-ToBeDeleted2---",

        [Parameter(
            Mandatory = $false,
            Position = 0,
            HelpMessage = "Key vault secret value"
        )]
        [string]$DummyKeyVaultSecretValue = "---KeyVaultWriteTest---",

        [Parameter(
            Mandatory = $false,
            Position = 0,
            HelpMessage = "Key vault secret name"
        )]
        [string]$KeyValutSecretName = "Keyvautl-SPN-Test-2-",

        [Parameter(
            Mandatory = $false,
            Position = 0,
            HelpMessage = "Key vault secret value"
        )]
        [string]$KeyVaultSecretValue = "129783210394iu3xasre",

        [Parameter(
            Mandatory = $false,
            Position = 3, 
            HelpMessage = 'Switch statement for Keyvault'
        )]
        [switch]$Connect
    )

    if($Connect){
        try {

            $responseDummySecret = Set-KeyvaultSecretByValidation -KeyVault $KeyVault -DummyKeyValueSecretName $DummyKeyValueSecretName -DummyKeyVaultSecretValue $DummyKeyVaultSecretValue -Connect -Verbose
            Write-Verbose $responseDummySecret

            if ($responseDummySecret) {
                $MainSecret = Set-KeyvaultSecrets -KeyVault $KeyVault -KeyValutSecretName $KeyValutSecretName -KeyVaultSecretValue $KeyVaultSecretValue -Connect -Verbose
                Write-Verbose $MainSecret
                return $MainSecret
            }

            
        }
        catch {
            Write-Verbose $_.Exception.Message
            
        }
    }
}