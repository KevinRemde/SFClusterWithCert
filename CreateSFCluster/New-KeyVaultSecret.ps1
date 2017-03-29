<# 
.SYNOPSIS 
  This runbook will store a secret in the given key vault. 
   
.DESCRIPTION 
  This runbook will store a secret in the given key vault. 
 
  PREREQUISITE 
  The automation account has to be created with a "Run As" account (Service Principal). Automation accounts with a run as account  
  can be identified by verifying that they contain the two assets: "AzureRunAsConnection" and "AzureRunAsCertificate".  
  See https://azure.microsoft.com/en-us/documentation/articles/automation-sec-configure-azure-runas-account/ for more information. 
 
  PREREQUISITE 
  The modules "AzureRM.profile" and "AzureRM.keyvault" have to be imported into the automation account. They can be imported from 
  the Module Gallery. See https://azure.microsoft.com/en-us/blog/announcing-azure-resource-manager-support-azure-automation-runbooks/ 
  for more information. 
 
.PARAMETER VaultName  
  Mandatory 
  This is the name of the key vault. 
   
.PARAMETER ResourceGroupName  
  Mandatory 
  This is the name of the resource group that the key vault is in. 
   
.PARAMETER SecretName   
  Mandatory 
  This is the name of the secret. 
 
.PARAMETER SecretValue   
  Mandatory 
  This is the value of the secret. 
   
.NOTES 
  AUTHOR: Andreas Wieberneit 
  LASTEDIT: April 15, 2016 
#> 
 
param 
( 
    [Parameter (Mandatory=$true)] 
    [string] $VaultName, 
    [Parameter (Mandatory=$true)] 
    [string] $ResourceGroupName, 
    [Parameter (Mandatory=$true)] 
    [string] $SecretName, 
    [Parameter (Mandatory=$true)] 
    [string] $SecretValue 
) 
<#
# Authenticate to Azure with service principal and certificate, and set subscription 
$connectionAssetName = "AzureRunAsConnection" 
$conn = Get-AutomationConnection -Name $ConnectionAssetName 
if ($conn -eq $null) 
{ 
    throw "Could not retrieve $connectionAssetName connection asset. Check that this asset exists in the automation account." 
} 
Add-AzureRmAccount -ServicePrincipal -Tenant $conn.TenantID -ApplicationId $conn.ApplicationId -CertificateThumbprint $conn.CertificateThumbprint -ErrorAction Stop | Write-Verbose 
Set-AzureRmContext -SubscriptionId $conn.SubscriptionId -ErrorAction Stop | Write-Verbose 
#> 

# Try to retrieve the key vault. 
$keyVault = Get-AzureRMKeyVault -VaultName $VaultName -ResourceGroupName $ResourceGroupName  
if ($keyVault -eq $null) 
{ 
    throw "Could not retrieve key vault $VaultName. Check that a key vault with this name exists in the resource group $ResourceGroupName." 
} 
 
$secretAsSecureString = ConvertTo-SecureString $SecretValue -AsPlainText -Force 
$secret = Set-AzureKeyVaultSecret -VaultName $VaultName -Name $SecretName -SecretValue $secretAsSecureString 
if ($secret -eq $null) 
{ 
    throw "Could not create secret $SecretName." 
} 
 
# Return the secret. 
$secret[0]