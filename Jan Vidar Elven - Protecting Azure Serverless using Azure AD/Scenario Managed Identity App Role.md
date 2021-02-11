# Add Microsoft Graph Applications Permissions (Roles Claim) to MSI

The following commands must be run in Windows PowerShell and with the AzureAD Module. Remember to Connect-AzureAD with Global Administrator Privileges first.

## Microsoft Graph App Well Known App Id

```powershell
# Set well known Graph Application Id
$msGraphAppId = "00000003-0000-0000-c000-000000000000"
```

## Display Name of Managed Identity

```powershell
# If System Assigned MSI this is the name of the Function App, if User Assigned MSI use DisplayName
$msiDisplayName=".."
```

## Microsoft Graph Permissions required

```powershell
# Type Graph App Permissions needed
$msGraphPermission = "User.Read.All", "...", "..."
```

## Get Managed Identity Service Principal Name

```powershell
# Get SPN based on MSI Display Name
$msiSpn = (Get-AzureADServicePrincipal -Filter "displayName eq '$msiDisplayName'")
```

## Get Microsoft Graph Service Principal

```powershell
# Get SPN for Microsoft Graph
$msGraphSpn = Get-AzureADServicePrincipal -Filter "appId eq '$msGraphAppId'"
```

## Get the Application Role or Roles for the Graph Permission

```powershell
# Now get all Application Roles matching above Graph Permissions
$appRoles = $msGraphSpn.AppRoles | Where-Object {$_.Value -in $msGraphPermission -and $_.AllowedMemberTypes -contains "Application"}
```

## Assign the Application Role to the Managed Identity

```powershell
# Add Application Roles to MSI SPN
$appRoles | % { New-AzureAdServiceAppRoleAssignment -ObjectId $msiSpn.ObjectId -PrincipalId $msiSpn.ObjectId -ResourceId $msGraphSpn.ObjectId  -Id $_.Id }
```
