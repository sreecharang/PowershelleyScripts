

function Access-Token-SP {
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

            # Inspect the token using JWTDetails 
            # JWTDetails PowerShell Module 
            # https://github.com/darrenjrobinson/JWTDetails 
            $JWTToken = Get-JWTDetails($TokenResponse.access_token)

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



function List-Users {
    [CmdletBinding()]
    param (

        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'Retrieving the JWT Access Token'
        )]
        [switch]$Connect
    )
    

    $restUri = "https://graph.microsoft.com/v1.0/users"
    $ListUsersresults = [System.Collections.ArrayList]@()
        
    if($Connect){
        try {

            Access-Token-SP

            Write-Verbose "Connected to Azure using App Registration"

            $Global:Headers = $TokenVar
            $invokeRestAPIRequestSplat = @{
                Uri = $restUri
                Method = 'GET'
                ContentType = "application/json"
                Headers = @{Authorization = "Bearer $($Headers)"}
                ErrorAction = 'Stop'
                # Body = $Body
            }

            $response = Invoke-RestMethod @invokeRestAPIRequestSplat

            $responseCount = $response.value.Count

            Write-Verbose "Response Count: $responseCount"

            for ($i = 0; $i -lt $responseCount; $i++) {
                
                $childObject = $null #Reset 
                $childObject = $response.value[$i]
        
                $obj = [PSCustomObject]@{
                    Id              = $childObject.id
                    UserPrincipal   = $childObject.userPrincipalName
                    FirstName       = $childObject.givenName
                    LastName        = $childObject.surname
                }  
                $ListUsersresults.Add($obj) | Out-Null
    
            }

            $ListUserPrincipal = $ListUsersresults.UserPrincipal
            $script:responseUserPrincipal = $ListUserPrincipal


            Write-Verbose "User Principal: $ListUserPrincipal "
            $script:responseUserResults = $ListUsersresults
            
            Update-Check -Connect
            

        }
        catch {
            Write-Error $_
        }
    } #if_connect

    $script:EmailFirstLastVar = $EmailFirstLastVar
    
}
    
function Update-Check {
    [CmdletBinding()]
    param (

        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'Retrieving the JWT Access Token'
        )]
        [switch]$Connect
    )
    

    if($Connect) {
        try {

            Access-Token-SP

            Write-Verbose "Connected to Azure using App Registration"

            $script:Headers = $TokenVar
            $script:responseUserResults = $responseUserResults
           
            $InputCountVar      = $responseUserResults.Count

            Write-Verbose "Count of UserPrincipal : $InputCountVar"

            for ($i = 0; $i -lt $InputCountVar; $i++) {


                $InputUserInformation   = $responseUserResults[$i]
                $InputId                = $InputUserInformation.Id
                $InputUserPrincipal     = $InputUserInformation.UserPrincipal
                $InputFirstName         = $InputUserInformation.FirstName


                Write-Verbose "calling Userprincipal: $InputUserPrincipal"
                Write-Verbose "calling FirstName: $InputFirstName"
    
                
                $restUri = "https://graph.microsoft.com/v1.0/users"
                $resturi += "/$InputId"

                

                if ($null -eq $InputFirstName){

                    Write-Verbose "Invoking REST Method to update First and Last Name."
                    
                    Convert-Specific -UserPrincipal $InputUserPrincipal

                    $script:EmailFirstLastVar = $EmailFirstLastVar
                   
                    $DisplayNameVar = $EmailFirstLastVar.First+ " " + $EmailFirstLastVar.Last
                    $FirstNameVar = $EmailFirstLastVar.First
                    $LastNameVar  = $EmailFirstLastVar.Last

                    $DisplayName    = (Get-Culture).TextInfo.ToTitleCase($DisplayNameVar)
                    $FirstName      = (Get-Culture).TextInfo.ToTitleCase($FirstNameVar)
                    $LastName       = (Get-Culture).TextInfo.ToTitleCase($LastNameVar)

                    $Body = @{
                        displayName = $DisplayName
                        givenName   = $FirstName
                        surname     = $LastName
                        
                    } | ConvertTo-Json

                    $invokeRestAPIRequestSplat = @{
                        Uri = $restUri
                        Method = 'PATCH'
                        ContentType = "application/json"
                        Headers = @{Authorization = "Bearer $($Headers)"}
                        ErrorAction = 'Stop'
                        Body = $Body
                    }

                    $response = Invoke-RestMethod @invokeRestAPIRequestSplat

                    Write-Verbose $response
                    
                }
                else {
                    Write-Verbose "$InputUserPrincipal  : Already got firstName"
                }
                
            }

        }
        catch {
            Write-Error $_
        }
    }
}

function Convert-Specific {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            Position = 1, 
            HelpMessage = 'UserPrincipal of user'
        )]
        [string]$UserPrincipal
    )

    $resultsVar     = [System.Collections.ArrayList]@()
    $emailList      = [System.Collections.ArrayList]@()
    $emailFinal     = [System.Collections.ArrayList]@()

    try {

        $regex                  = "^[^\.]*[a-zA-z0-9^\.]*"
        $regexFirstLastName     = ".+?(?=_)"

        Write-Verbose "Running Regex expressions...."

        $childObject = $UserPrincipal
        $childObject -match $regex | Out-Null
        $objVar = [PSCustomObject]@{
            FirstLastName = $Matches.Values
        }

        $resultsVar.Add($objVar) | Out-Null

        $childObjectFirstLast = $resultsVar.FirstLastName 

        foreach ($emailListVar in $childObjectFirstLast) {
            $emailListVar -match $regexFirstLastName | Out-Null
            $objEmailListVar = [PSCustomObject]@{
                FirstAndLastName = $Matches.Values
            }
        }
        $emailList.Add($objEmailListVar) | Out-Null

        $childObjectFirstLastVar = $emailList.FirstAndLastName

        foreach ($emailFirstLastVar in $childObjectFirstLastVar) {
                
            $firstName, $lastName = $emailFirstLastVar.Split(".",2)

            $objEmailFirstLastVar = [PSCustomObject]@{
                First = $firstName
                Last = $lastName
            }
        }
        $emailFinal.Add($objEmailFirstLastVar) | Out-Null

        $script:EmailFirstLastVar = $emailFinal
    }
    catch {
        Write-Error $_
    }
}


function Convert-Users {
    [CmdletBinding()]
    
    param (
    )

    $resultsVar     = [System.Collections.ArrayList]@()
    $emailList      = [System.Collections.ArrayList]@()
    $emailFinal     = [System.Collections.ArrayList]@()

    try {

        $regex                  = "^[^\.]*[a-zA-z0-9^\.]*"
        $regexFirstLastName     = ".+?(?=_)"


        Write-Verbose "Running Regex expressions...."
        $script:responseInputVar = $responseUserPrincipal

        $InputCountVar = $responseInputVar.Count 

        for ($i = 0; $i -lt $InputCountVar; $i++) {
        
            $childObjectVar = $null #Reset 
            $childObjectVar = $responseInputVar[$i]

            foreach ($userVar in $childObjectVar) {
                $userVar -match $regex | Out-Null
                $objVar = [PSCustomObject]@{
                    FirstLastName = $Matches.Values
                }
            }
            $resultsVar.Add($objVar) | Out-Null

        }

        $InputResultsCountVar = $resultsVar.Count 
        for ($i = 0; $i -lt $InputResultsCountVar; $i++) {
        
            $childObjectVar1 = $null #Reset 
            $childObjectVar1 = $resultsVar.FirstLastName[$i]
            
            foreach ($emailListVar in $childObjectVar1) {
                $emailListVar -match $regexFirstLastName | Out-Null
                $objEmailListVar = [PSCustomObject]@{
                    FirstAndLastName = $Matches.Values
                }
            }
            $emailList.Add($objEmailListVar) | Out-Null
        }   

        
        $InputResultsCountVar = $emailList.Count 
        for ($i = 0; $i -lt $InputResultsCountVar; $i++) {
        
            $childObjectVar2 = $null #Reset 
            $childObjectVar2 = $emailList.FirstAndLastName[$i]
            
            foreach ($emailFirstLastVar in $childObjectVar2) {
                
                $firstName, $lastName = $emailFirstLastVar.Split(".",2)

                $objEmailFirstLastVar = [PSCustomObject]@{
                    First = $firstName
                    Last = $lastName
                }
            }
            $emailFinal.Add($objEmailFirstLastVar) | Out-Null
        }
        

        $script:EmailFirstLastVar   = $emailFinal
    }
    catch {
        Write-Error $_
    }
}
