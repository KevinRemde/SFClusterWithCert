#
# This script: 
# - creates a certificate, 
# - exports it to a .pfx file, 
# - sends it into your Azure key vault, and
# - Deletes the key from the local store.

# 
# Login to Azure
# 
Login-AzureRmAccount
$subscriptionId = 
    ( Get-AzureRmSubscription |
        Out-GridView `
            -Title "Select an Azure Subscription ..." `
            -PassThru
    ).SubscriptionId

Select-AzureRmSubscription -SubscriptionId $subscriptionId

#
# Set up cluster, keyvault and secret variables 
$vaultName = "karVault"
$secretName = "sFClusterSecret"
$vaultRG = "RG-vault"

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
# NOTE: Yo
$certPath = "cert:\CurrentUser\My\" + $cert.Thumbprint
$filePath = ".\Test.pfx"
$password = "Passw0rd!"
$securePassword = ConvertTo-SecureString -String $password -Force -AsPlainText

$pfxData = Export-PfxCertificate -Cert $certPath -FilePath $filePath -Force -Password $securePassword


#
# upload the secret to you key vault
#
$fileContentBytes = get-content $filePath -Encoding Byte
$fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)

$jsonObject = @"
{
    "data": "$filecontentencoded",
    "dataType" :"pfx",
    "password": "$password"
}
"@

$jsonObjectBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonObject)
$jsonEncoded = [System.Convert]::ToBase64String($jsonObjectBytes)

$secret = ConvertTo-SecureString -String $jsonEncoded -AsPlainText -Force
$keyvaultSecret = Set-AzureKeyVaultSecret -VaultName $vaultName -Name $secretName -SecretValue $secret

#
# Remove the cert from the personal store
