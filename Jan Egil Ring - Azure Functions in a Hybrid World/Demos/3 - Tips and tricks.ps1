# 1) Only WSMan-based remoting works on Windows workers, let`s try to see what happens when using SSH-based remoting

Start-Process https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse
Start-Process https://docs.microsoft.com/en-us/powershell/scripting/learn/remoting/ssh-remoting-in-powershell-core?view=powershell-7

# Manual test into a Linux VM

ssh-keygen

$Session = New-PSSession -HostName centos7.rbk.ad -UserName rbkautomation -KeyFilePath C:\Users\janring\.ssh\id_rsa

$Session | Enter-PSSession

Get-PSSession | Remove-PSSession

# Create a Key Vault in order to store passwords and RSA private keys for remoting into machines from Functions

$KeyVault = @{
    Name = 'nvs'
    ResourceGroupName = 'nvs-rg'
    Location = 'Norway East'
}

New-AzKeyVault @KeyVault

# An access policy defines who can access keys & secrets inside a vault

$AccessPolicy = @{
    VaultName = 'nvs-2'
    ResourceGroupName = 'nvs-rg'
    EmailAddress = 'jan.egil.ring_outlook.com#EXT#@janegilring.onmicrosoft.com'
    PermissionsToSecrets = 'set','delete','get','list'
    PermissionsToKeys = 'encrypt','list','get','decrypt','wrapKey','create','import','backup'
}
Set-AzKeyVaultAccessPolicy @AccessPolicy

# A managed identity from Azure Active Directory (Azure AD) allows your app to easily access other Azure AD-protected resources such as Azure Key Vault. The identity is managed by the Azure platform and does not require you to provision or rotate any secrets.
Get-AzFunctionApp -Name psfunctiondemo -ResourceGroupName nvs-rg | fl *identity*
Get-AzFunctionApp -Name psfunctiondemo -ResourceGroupName nvs-rg | Update-AzFunctionApp -IdentityType SystemAssigned

# Grant the Managed Identity access to the secrets inside the vault

$AzADServicePrincipal = Get-AzADServicePrincipal -ObjectId (Get-AzFunctionApp -Name psfunctiondemo -ResourceGroupName nvs-rg).IdentityPrincipalId

$AccessPolicy = @{
    VaultName = 'nvs'
    ResourceGroupName = 'nvs-rg'
    ObjectId = $AzADServicePrincipal.Id
    PermissionsToSecrets = 'get','list'
    PermissionsToKeys = 'get','decrypt','list'
}
Set-AzKeyVaultAccessPolicy @AccessPolicy


@Microsoft.KeyVault(SecretUri={copied identifier for the username secret})
@Microsoft.KeyVault(SecretUri=https://nvs.vault.azure.net/secrets/RBKAutomation/4a814b653aa545b4a085e19010709be1)

$data = Get-Content -Path ~\.ssh\id_rsa -Raw
$bytes = [System.Text.Encoding]::Unicode.GetBytes($data)
$encodeddata = [Convert]::ToBase64String($bytes)

$Secret = ConvertTo-SecureString -String $encodeddata -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName nvs-2 -Name RBKAutomationRSAKey -SecretValue $Secret
$Secret = (Get-AzKeyVaultSecret -VaultName nvs-2 -Name RBKAutomationRSAKey | Select-Object -ExpandProperty SecretValueText)

# From an Azure Function we can decode the private key
$RSAKey = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($Secret))

$RBKAutomationPrivateKey = Join-Path -Path $env:temp -ChildPath id_rsa_rbk_automation
$RSAKey | Set-Content -Path $RBKAutomationPrivateKey

Write-Output "Path to SSH key: $RBKAutomationPrivateKey"
Write-Output "SSH key:"

Get-Content $RBKAutomationPrivateKey

Invoke-Command -HostName centos7.rbk.ad -UserName rbkautomation -KeyFilePath $RBKAutomationPrivateKey -ScriptBlock {$PSVersionTable.PSVersion.ToString()}


# 3) Create a PowerShell function app

# F1 in VS Code, search for function and select "Azure Functions: Create Function"
# HttpTriggerHybrid3

Invoke-RestMethod 'https://psfunctiondemo.azurewebsites.net/api/httptriggerhybrid3?code=xHo8G3296w5Wrv1TaPYmiz1VKpucCCeQTD2/RxtD9/znBFHcvbidlg==&Name=Jan'

# 2) Making the second hop in PowerShell Remoting
Start-Process https://docs.microsoft.com/en-us/powershell/scripting/learn/remoting/ps-remoting-second-hop?view=powershell-7

# Custom session configuration with domain user specified as the RunAs account might be a good option

Register-PSSessionConfiguration -Name azureonpremadmin -RunAsCredential rbk\svc.azureonpremadmin -MaximumReceivedDataSizePerCommandMB 1000 -MaximumReceivedObjectSizeMB 1000

Invoke-Command -ComputerName MGMT-AZ-01.rbk.ad -Credential $Credential -ConfigurationName azureonpremadmin -ScriptBlock {whoami}

Invoke-Command -ComputerName MGMT-AZ-01.rbk.ad -Credential $Credential -ScriptBlock {dir \\hpv-jr-02\d$\Hyper-V}

Invoke-Command -ComputerName MGMT-AZ-01.rbk.ad -Credential $Credential -ConfigurationName azureonpremadmin -ScriptBlock {dir \\hpv-jr-02\d$\Hyper-V}

# 3) Cim commands from Windows just works (with -Credential)

$UserName = "Administrator"
$securedPassword = ConvertTo-SecureString  $Env:RBKAdminPassword -AsPlainText -Force
$Credential = [System.management.automation.pscredential]::new($UserName, $SecuredPassword)

$CimSession = New-CimSession -Credential $Credential -ComputerName MGMT-AZ-01.rbk.ad
Get-NetAdapter -CimSession $CimSession

Get-Command -ParameterName CimSession | Format-Wide

# Tip: Combine with PSDefaultParameterValues

$PSDefaultParameterValues=@{"CmdletName:ParameterName"="DefaultValue"}

$PSDefaultParameterValues=@{"*:CimSession"=$CimSession}

Get-NetAdapter

Get-NetAdapter | Format-Table PSComputerName,Name,Status,MacAddress

hostname