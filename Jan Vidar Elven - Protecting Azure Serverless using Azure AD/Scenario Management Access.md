# Scenario Management Access

When sending requests to Azure Serverless protected by Azure AD OAuth2, one of the basic scenarios to explore is using management resource endpoints for access tokens.

In this example I will show how to get access tokens using Azure CLI and Az PowerShell.

## Azure CLI

You can use Azure CLI in Cloud Shell, or locally installed on your computer. If local, make sure you are logged on first:

```azurecli
az login
```

For specific tenant or to control which browser to authenticate you can use device code flow:

```azurecli-interactive
az login --tenant elven.onmicrosoft.com --use-device-code
```

### Get Access Token

To get an access token, just run:

```azurecli
az account get-access-token
```

Save to variable and copy to clipboard for closer look (for example in [jwt.io](https://jwt.io)):

```azurecli
$accessToken = az account get-access-token | ConvertFrom-Json
$accessToken.accessToken | Clip
```

You can also get an access token for a specific resource endpoint using:

```azurecli
$accessToken = az account get-access-token --resource-type arm | ConvertFrom-Json
```

To show all available resource endpoints use:

```azurecli
az cloud show --query endpoints
```

### Test using Bearer Token in Azure CLI

You can trigger HTTP REST methods in Azure CLI using az rest --method .. --url ...

When using az rest an authorization header with bearer token will be automatically added, trying to use the url as resource endpoint (if url is one of the well known resource endpoints). If using Serverless endpoint as url, we need to specify the resource endpoint as well.

```azurecli
az rest --method POST --resource 'https://management.core.windows.net/' --url 'https://<yourserverlessurl>'
```

## Az PowerShell

If not using Cloud Shell, you need to login to your Azure Subscription by using:

```azurepowershell
Connect-AzAccount
```

If your account has access to multiple subscriptions in multiple tenant, you can use the following command to specify tenant:

```azurepowershell
Connect-AzAccount -Tenant elven.onmicrosoft.com
```

If there are multiple subscriptions, you might need to specify which subscription to access:

```azurepowershell
# Set specified subscription
Set-AzContext -Subscription <Subscription>

# Tip, for listing available subscriptions use: 
Get-AzContext -ListAvailable
```

### Get Access Token AzPS

To get an access token using Az PowerShell, use the following command to save to variable and copy to clipboard:

```azurepowershell
$accessToken = Get-AzAccessToken

$accessToken.Token | Clip
```

As with Azure CLI, you can also specify resource endpoint by using the following command in Az PowerShell specifying the resource Url:

```azurepowershell
$accessToken = Get-AzAccessToken -ResourceUrl 'https://management.core.windows.net'
```

### Test using Bearer Token in Azure PowerShell

Make sure that you get an access token and saving the bearer token to a variable using this command first:

```azurepowershell
$accessToken = Get-AzAccessToken

$bearerToken = $accessToken.Token
```

Set your Logic Apps/Function App Url:

```azurepowershell
$serverlessUrl = 'https://<yourserverlessurl'
```

There are 2 ways you can use Az PowerShell, either using Windows PowerShell or PowerShell Core.

For Windows PowerShell, use Invoke-RestMethod and add a Headers parameter specifying the Authorization header to use Bearer token:

```azurepowershell
Invoke-RestMethod -Method Post -Uri $serverlessUrl -Headers @{"Authorization"="Bearer $bearerToken"}
```

For PowerShell Core, Invoke-RestMethod has now support for using OAuth as authentication, but first you need to convert the Bearer Token to a Secure String:

```azurepowershell
$accessToken = Get-AzAccessToken
$bearerToken = ConvertTo-SecureString ($accessToken.Token) -AsPlainText -Force
```

Then send request using:

```azurepowershell
Invoke-RestMethod -Method Post -Uri $serverlessUrl -Authentication OAuth -Token $bearerToken
```
