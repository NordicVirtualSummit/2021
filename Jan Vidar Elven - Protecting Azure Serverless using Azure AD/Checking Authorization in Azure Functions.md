# CmdLets for checking Authorization in Azure Functions

The following snippets can be used for checking authorization inside Azure Functions.

## Check if Authorization Header and get Access Token

```azurepowershell
# Check if Authorization Header and get Access Token
$AuthHeader = $Request.Headers.'Authorization'
If ($AuthHeader) {
    $parts = $AuthHeader.Split(" ")
    $accessToken = $parts[1]
    $jwt = $accessToken | Get-JWTDetails
}
```

## Writing some Claims to Output

```azurepowershell
# Just some Informational Output for Debugging, remove when not needed
Write-Host $jwt.scp 
Write-Host $jwt.roles 
Write-Host ($jwt.scp -notmatch "Phone.Write")
Write-Host ($jwt.roles -notcontains "Phone.Write.All")
```

## Checking Auhtorization and calling Graph

```azurepowershell

    # Check Correct Authorization Scopes and/or Roles
    If (($jwt.scp -notmatch "Phone.ReadWrite") -and ($jwt.roles -notcontains "Phone.ReadWrite.All")) {
        $statusCode = [HttpStatusCode]::Forbidden
        $responseBody = "You are not Authorized!"
    } else {

        # Set some Variables for Authentication
        $tenantID = "vikenfk.onmicrosoft.com"
        $scopes = "UserAuthenticationMethod.Read.All", "UserAuthenticationMethod.ReadWrite.All", "User.ReadBasic.All"

        # Check if running with MSI (in Azure) or Interactive User (local VS Code)
        If ($env:MSI_SECRET) {
            
            # Get Managed Service Identity from Function App Environment Setttings
            $msiEndpoint = $env:MSI_ENDPOINT
            $msiSecret = $env:MSI_SECRET

            # Specify URI and Token AuthN Request Parameters
            $apiVersion = "2017-09-01"
            $resourceUri = "https://graph.microsoft.com"
            $tokenAuthUri = $msiEndpoint + "?resource=$resourceUri&api-version=$apiVersion"

            # Authenticate with MSI and get Token
            $tokenResponse = Invoke-RestMethod -Method Get -Headers @{"Secret"="$msiSecret"} -Uri $tokenAuthUri
            # Convert Access Token to Secure String
            $secureAccessToken = ConvertTo-SecureString ($tokenResponse.access_token) -AsPlainText -Force
            Write-Host "Successfully retrieved Access Token for Microsoft Graph using MSI."

            # Connect to Graph with MSI Token
            Connect-MgGraph -AccessToken $tokenResponse.access_token

        } else {

            # Connect to Graph Interactively using Device Code Flow
            Connect-MgGraph -Scopes $scopes -TenantId $tenantID -ForceRefresh
        }

        Select-MgProfile -Name "beta"
            
        If (-Not (Get-Module Microsoft.Graph.Identity.Signins)) { Import-Module Microsoft.Graph.Identity.Signins }

        try {

            switch ($Request.Method) {
                "POST" {  
                    New-MgUserAuthenticationPhoneMethod -UserId $userUpn -PhoneNumber $Request.Body.PhoneNumber -PhoneType $Request.Body.PhoneType -ErrorAction Stop
                    Write-Host "Added Phone Authentication Method for $userUpn."
                    $statusCode = [HttpStatusCode]::OK
                    $responseBody = "Successfully added Phone Authentication Method " + $Request.Body.PhoneType + "."
                }
                "PUT" { 
                    Update-MgUserAuthenticationPhoneMethod -PhoneAuthenticationMethodId $Request.Body.PhoneAuthenticationMethodId -UserId $userUpn -PhoneNumber $Request.Body.PhoneNumber -PhoneType $Request.Body.PhoneType -ErrorAction Stop
                    Write-Host "Updated Phone Authentication Method for $userUpn."
                    $statusCode = [HttpStatusCode]::OK
                    $responseBody = "Successfully updated Phone Authentication Method by Id " + $Request.Body.PhoneAuthenticationMethodId + "."
                }
                "DELETE" {
                    Remove-MgUserAuthenticationPhoneMethod -PhoneAuthenticationMethodId $Request.Body.PhoneAuthenticationMethodId -UserId $userUpn -ErrorAction Stop
                    Write-Host "Deleted Phone Authentication Method for $userUpn."
                    $statusCode = [HttpStatusCode]::OK
                    $responseBody = "Successfully deleted Phone Authentication Method by Id " + $Request.Body.PhoneAuthenticationMethodId + "."
                }
                Default {
                    $statusCode = [HttpStatusCode]::NotImplemented
                    $responseBody = "Method " + $Request.Method + " not valid."
                }
            }
            
        }
        catch [Microsoft.Graph.PowerShell.Runtime.RestException] {
            $statusCode = [HttpStatusCode]::BadRequest
            $responseBody = $_.Exception
        }
        catch {
            $statusCode = [HttpStatusCode]::NotFound
            $responseBody = "No User by UPN $userUpn was found."                
        }

        }     
} else {
    $statusCode = [HttpStatusCode]::NotFound
    $responseBody = "Missing userUpn in Request Query or Body."
}

```