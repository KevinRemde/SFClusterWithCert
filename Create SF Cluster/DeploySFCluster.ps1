# Sign into Azure

Login-AzureRmAccount
$subscriptionId = 
    ( Get-AzureRmSubscription |
        Out-GridView `
            -Title "Select an Azure Subscription ..." `
            -PassThru
    ).SubscriptionId

$subscr = Select-AzureRmSubscription -SubscriptionId $subscriptionId

$tenantID = $subscr.Tenant


# collect initials for generating unique names

$init = Read-Host -Prompt "Please type your initials in lower case, and then press ENTER."


# Prompt for the Azure region in which to build the lab machines

<#
Write-Host ""
Write-Host "Where in the world do you want to put this?"
Write-Host "Carefully enter 'East US' or 'West US'"
$loc = Read-Host -Prompt "and then press ENTER."
#>

# Variables 

$rgName = "RG-SFCluster" + $init
# $deploymentName = $init + "AZLab"  # Not required

# Use these if you want to drive the deployment from local template and parameter files..
#
$localAssets = "C:\Code\MyGitHub\SFClusterWithCert\Create SF Cluster\"
$templateFileLoc = $localAssets + "azuredeploy.json"
$parameterFileLoc = $localAssets + "azuredeploy.parameters.json"
# $parameterFileLoc = $localAssets + "azuredeploy.parameters.json"

# Use these if you want to drive the deployment from Github-based template. 
#
# $assetLocation = "https://rawgit.com/KevinRemde/20161115/master/" 
# If the rawgit.com path is not available, you can try un-commenting the following line instead...
# 
# $assetLocation = "https://cgiresources.blob.core.windows.net/files/"
# $assetLocation = "https://raw.githubusercontent.com/KevinRemde/CTest/master/"
# $templateFileURI  = $assetLocation + "azuredeploy.json"
# $parameterFileURI = $assetLocation + "azuredeploy.parameters.json" # Use only if you want to use Kevin's defaults (not recommended)


# Use Test-AzureRmDnsAvailability to create and verify unique DNS names.	
#
# Based on the initials entered, find unique DNS names for the four virtual machines.
# NOTE: You may be wondering why I'm not also looking for unique storage account names.  
# Those names are created by the template using randomly generated complex names, based on 
# the resource group ID.

$loc = "East US 2"

#
# Set up some cluster, keyvault and secret variables 
$clusterName = "karsfcluster" #lowercase, as it's used in the DNS name
$vaultName = "karVault"
$secretName = "sFClusterSecret" + $init
$vaultRG = "RG-vault"

##
# Select or create a new cert, put in key vault, and retain values for SF Cluster deployment
#

# Select the cert if the one you want is already in your local store..
#

$cert = 
    ( Get-ChildItem Cert:\CurrentUser\My |
        Out-GridView `
        -Title "Select a certificate ..." `
        -PassThru
    )

# If not using Enterprise PKI, create self-signed certificate instead

if (!$cert) {

    $certSubject = Read-Host -Prompt “Issue By/To for the certificate”
    $cert = New-SelfSignedCertificate `
        -CertStoreLocation Cert:\CurrentUser\My `
        -Subject "CN=$($certSubject)" `
        -KeySpec KeyExchange `
        -HashAlgorithm SHA256
    }

#
# Export the cert to a .pfx (assigning a password)
# NOTE: Remember to edit these for your own purposes.
$certPath = "cert:\CurrentUser\My\" + $cert.Thumbprint
$filePath = ".\"+$certSubject+".pfx"
$password = "samplecertificate"
$securePassword = ConvertTo-SecureString -String $password -Force -AsPlainText

Export-PfxCertificate -Cert $certPath -FilePath $filePath -Force -Password $securePassword


#
# upload the secret to your key vault
#
$fileContentBytes = Get-Content $filePath -Encoding Byte
$fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)

$jsonObject = @"
{
    "data": "$filecontentencoded",
    "dataType": "pfx",
    "password": "$password"
}
"@

$jsonObjectBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonObject)
$jsonEncoded = [System.Convert]::ToBase64String($jsonObjectBytes)

$secret = ConvertTo-SecureString -String $jsonEncoded -AsPlainText -Force
$keyvaultSecret = Set-AzureKeyVaultSecret -VaultName $vaultName -Name $secretName -SecretValue $secret


$sourceVaultValue = "/subscriptions/"+ $subscr.Subscription.SubscriptionId +"/resourceGroups/"+$vaultRG+"/providers/Microsoft.keyVault/vaults/"+$vaultName

# Get a unique DNS name
#
$machine = $clusterName + "dns"
$uniquename = $false
$counter = 0
while ($uniqueName -eq $false) {
    $clusterDnsName = "$machine" + "$counter" 
    if (Test-AzureRmDnsAvailability -DomainNameLabel $clusterDnsName -Location $loc) {
        $uniquename = $true
    }
    $counter ++
} 
# Populate the parameter object with parameter values for the azuredeploy.json template to use.
# These are the values that do not have defaults in the azuredeploy.json parameter definitions.

$parameterObject = @{
    "clusterLocation" = "eastus2"
    "clusterName" = $clusterName
    "clusterDnsName" = $clusterDnsName
    "adminUserName" = "demoAdmin"
    "vmImageSku" = "2016-Datacenter"
    "certificateThumbprint" = $cert.Thumbprint 
    "sourceVaultValue" = $sourceVaultValue
    "certificateUrlValue" = $keyvaultSecret.Id
    "clusterProtectionLevel" = "EncryptAndSign"
    "nt0InstanceCount" = 5
}

# Create the resource group

New-AzureRMResourceGroup -Name $rgname -Location $loc

# Building the Service Fabric. 
# Note: Takes a while to complete.

Write-Host ""
Write-Host "Deploying the Servic Fabric Cluster.  This will take a while to complete."
Write-Host "Started at" (Get-Date -format T)
Write-Host ""

# THIS IS THE MAIN ONE YOU'LL launch to pull the template file from the repository, and use the created parameter object.
# Measure-Command -expression {New-AzureRMResourceGroupDeployment -ResourceGroupName $rgName -TemplateUri $templateFileURI -TemplateParameterObject $parameterObject}

Measure-Command -expression { `
    New-AzureRMResourceGroupDeployment -ResourceGroupName $rgName `
    -TemplateFile $templateFileLoc `
    -TemplateParameterObject $parameterObject `
    -Verbose}

# use only if you want to use Kevin's default parameters (not recommended)
# New-AzureRMResourceGroupDeployment -ResourceGroupName $rgName -TemplateUri $templateFileURI -TemplateParameterUri $parameterFileURI

#Beep
$([char]7)

Write-Host ""
Write-Host "Completed at" (Get-Date -format T)


# MORE EXAMPLES of what you may want to run later...

# Shut down all lab VMs in the Resource Group when you're not using them.
# Get-AzureRmVM -ResourceGroupName $rgName | Stop-AzureRmVM -Force

# Restart them when you're continuing the lab.
# Get-AzureRmVM -ResourceGroupName $rgName | Start-AzureRmVM 


# Delete the entire resource group (and all of its VMs and other objects).
# Remove-AzureRmResourceGroup -Name $rgName -Force


