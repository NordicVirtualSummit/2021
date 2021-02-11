# Add Required Modules for Azure Functions automatically

## In requirements.psd1

For example adding some Graph SDK modules

```azurepowershell
# This file enables modules to be automatically managed by the Functions service.
# See https://aka.ms/functionsmanageddependency for additional information.
#
@{
    'Az' = '5.*'
    'JWTDetails' = '1.*'
    'Microsoft.Graph.Authentication' = '1.2'
    'Microsoft.Graph.Users' = '1.2'
    'Microsoft.Graph.Identity.Signins' = '1.2'
}
```
