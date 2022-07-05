# Parameter help description
param (
  [Parameter()][string]$script:MachineLearningHomePath = 'modules\machinelearning\0.1',
  [Parameter()][string]$script:KeyVaultHomePath = 'modules\keyvault\1.1',
  [Parameter()][string]$script:TemplateFileName = 'deploy.json',
  [Parameter()][string]$script:ParameterFileName = 'parameters\machinelearning.deploy.parameters.json',
  [Parameter()][string]$script:ResourceGroupName = 'pxs-bdp-plt-s-rg-mls'
)

#region Extracting parameter file properties
$ParameterFile = (Get-Content (Join-Path -Path $MachineLearningHomePath -ChildPath $ParameterFileName)) | ConvertFrom-Json -ErrorAction SilentlyContinue -AsHashtable
$Location = $ParameterFile.parameters.location.value
$Tags = $ParameterFile.parameters.tags.value
$KeyVaultName = $ParameterFile.parameters.keyVaultName.value
$StorageAccountName = $ParameterFile.parameters.storageAccountName.value
$AppInsightName = $ParameterFile.parameters.appInsightName.value
$ContainerRegistryName = $ParameterFile.parameters.containerRegistryName.value
#endregion

# Create Resource Group
Write-Information "Creating resource group: $ResourceGroupName"
$rg = New-AzResourceGroup -Name $ResourceGroupName -Tag $tags -Location $Location -Force

# Create a Storage Account, KeyVault, AppInsight and ContainerRegistry
# Using certified product templates (ARM Deployment)
$kv = Get-AzKeyVault -VaultName $KeyVaultName -ResourceGroupName $ResourceGroupName
if ($kv) {
    Write-Information "KeyVault $KeyVaultName exists. Skipping KeyVault creation."
} else {
    Write-Information "Deploying Certified KeyVault: $KeyVaultName"
    $keyVaultDeployment = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile "$KeyVaultHomePath\deploy.json" -TemplateParameterFile "$MachineLearningHomePath\parameters\keyvault.deploy.parameters.json"
}

# At present writing, the storageAccount Certified Product enforced Hsn, which is not supported by Machine Learning
#$storageAccountDeployment = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile 'modules\storageaccount\1.0\deploy.json' -TemplateParameterFile 'modules\machinelearning\1.0\parameters\storageaccount.deploy.parameters.json'

# Using PowerShell (no certified templates available at present writing)
Write-Information "Deploying Non-Certified StorageAccount: $StorageAccountName"
$storageAccount = New-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -Location $rg.Location -Kind 'StorageV2' -AccessTier 'Hot' -SkuName 'Standard_LRS' -Tag $tags -ErrorAction SilentlyContinue

Write-Information "Deploying Non-Certified ApplicationInsight: $AppInsightName"
$appInsight = New-AzApplicationInsights -ResourceGroupName $ResourceGroupName -Name $AppInsightName -Location $rg.Location -Tag $tags -ErrorAction SilentlyContinue

Write-Information "Deploying Non-Certified ContainerRegistry: $ContainerRegistryName"
$containerRegistry = New-AzContainerRegistry -ResourceGroupName $ResourceGroupName -Name $ContainerRegistryName -Sku Basic -Location $rg.Location -Tag $tags -EnableAdminUser -ErrorAction SilentlyContinue
