<#

The Azure Functions Premium plan (sometimes referred to as Elastic Premium plan) is a hosting option
for function apps. The Premium plan provides features like VNet connectivity, no cold start,
and premium hardware. Multiple function apps can be deployed to the same Premium plan,
and the plan allows you to configure compute instance size, base plan size, and maximum plan size.

Azure Functions deployed to a Premium plan takes advantage of new VNet integration for web apps.

#>

Start-Process https://docs.microsoft.com/en-gb/azure/azure-functions/functions-premium-plan

# 1) Enable VNet integration
Start-Process https://docs.microsoft.com/en-gb/azure/app-service/web-sites-integrate-with-vnet

# 2) Test connectivity from console (Function App->Development Tools->Console in the portal)

tcpping 172.28.0.5:5985

nameresolver.exe rbk.ad

tcpping hpv-jr-02.rbk.ad:5985

# 3) Create a PowerShell function app

# F1 in VS Code, search for function and select "Azure Functions: Create Function"
# HttpTriggerHybrid2


<# Insert skeleton
using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Note that RBKAdminPassword is a function app setting, so I can access it as $env:ContosoUserPassword.
$UserName = "functionsdemo"
$securedPassword = ConvertTo-SecureString  $Env:RBKAdminPassword -AsPlainText -Force
$Credential = [System.management.automation.pscredential]::new($UserName, $SecuredPassword)


$Output = Invoke-Command -ComputerName HPV-JR-02.rbk.ad `
               -Credential $Credential `
               -Port 5986 `
               -UseSSL `
               -ScriptBlock {Get-VM | Select-Object Name,Status} `
                            -SessionOption (New-PSSessionOption -SkipCACheck -SkipCNCheck)

                            $Output

               $status = [HttpStatusCode]::OK
               $body = "Got $($output.Count) VMs from on-prem Hyper-V host HPV-JR-02 "

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})
#>

# Deploy to Function App in VS Code Azure extension

Invoke-RestMethod 'https://psfunctiondemo.azurewebsites.net/api/HttpTriggerHybrid2?code=onavaIIKYC6cvKUlcgpNdwqBME71V7S/zSni2rLNSpeB4SmNXX6xfg=='

