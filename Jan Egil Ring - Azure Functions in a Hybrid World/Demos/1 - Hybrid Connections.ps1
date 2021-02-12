Start-Process https://docs.microsoft.com/en-us/azure/azure-functions/functions-hybrid-powershell

# 1) Create a PowerShell function app

# F1 in VS Code, search for function and select "Azure Functions: Create Function"
# HttpTriggerHybrid1

# 2) Create a hybrid connection for the function app (Endpoint hostname must match certificate on target machine)

# 3) Download and install the hybrid connection

# 4) Create an app setting for the password of an administrator account

# 5) Configure an on-premises server for PowerShell remoting (HTTPS listener)

# For configuration of WinRM, see
# https://docs.microsoft.com/windows/win32/winrm/installation-and-configuration-for-windows-remote-management.


# Enable PowerShell remoting on on-prem server
Enable-PSRemoting -Force

# Create firewall rule for WinRM. The default HTTPS port is 5986.
New-NetFirewallRule -Name "WinRM HTTPS" `
                    -DisplayName "WinRM HTTPS" `
                    -Enabled True `
                    -Profile "Any" `
                    -Action "Allow" `
                    -Direction "Inbound" `
                    -LocalPort 5986 `
                    -Protocol "TCP"

# Create new self-signed-certificate to be used by WinRM.
$Thumbprint = (New-SelfSignedCertificate -DnsName $env:COMPUTERNAME  -CertStoreLocation Cert:\LocalMachine\My).Thumbprint

# Create WinRM HTTPS listener.
$Cmd = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname=""$env:COMPUTERNAME ""; CertificateThumbprint=""$Thumbprint""}"
cmd.exe /C $Cmd


# 6 Test the function

<# Insert skeleton
using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

$Service = $Request.Query.Name

# Note that RBKAdminPassword is a function app setting, so I can access it as $env:ContosoUserPassword.
$UserName = "functionsdemo"
$securedPassword = ConvertTo-SecureString  $Env:RBKAdminPassword -AsPlainText -Force
$Credential = [System.management.automation.pscredential]::new($UserName, $SecuredPassword)

# This is the name of the hybrid connection Endpoint.
$HybridEndpoint = "MGMT-JR-02"

$Script = {
    Param(
        [Parameter(Mandatory=$True)]
        [String] $Service
    )
    Get-Service $using:Service
}

Write-Output "Running command via Invoke-Command"
$output = Invoke-Command -ComputerName $HybridEndpoint `
               -Credential $Credential `
               -Port 5986 `
               -UseSSL `
               -ScriptBlock $Script `
               -SessionOption (New-PSSessionOption -SkipCACheck)

               $status = [HttpStatusCode]::OK
               $body = "Status for service $Service is $($output.Status)"

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})
#>

# Deploy to Function App in VS Code Azure extension

Invoke-RestMethod 'https://psfunctiondemo.azurewebsites.net/api/HttpTriggerHybrid1?code=ARobJqEWGaPq1JPw9Vef1/CUMJYCYDu5fA40jPgycSTNzCSi4G6G5g==&Name=spooler'
