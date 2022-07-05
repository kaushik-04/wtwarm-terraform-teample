param (
    [CmdletBinding()]
    [Parameter(Mandatory, HelpMessage = "Template path")][string]$TemplateFile
    #[Parameter(HelpMessage = "Output file")][string]$OutputFile = (Join-Path -Path $PSScriptRoot -ChildPath $TemplateFile)
)

Write-Verbose "Test for template presence"

$null = Test-Path $TemplateFile -ErrorAction Stop

Write-Verbose "Test if arm template content is readable"

$text = Get-Content $TemplateFile -Raw -ErrorAction Stop

Write-Verbose "Convert ARM template to an object"

$json = ConvertFrom-Json $text -ErrorAction Stop

Write-Verbose "Creating strings for Resource types"

$resourceHeader = "| Resource Type | Api Version |"
$resourceHeaderDivider = "| :-- | :-- |"
$resourceRow = "| ``{0}`` | {1} |"

Write-Verbose "Creating strings for Parameters"

$parameterHeader = "| Parameter Name | Type | Description | DefaultValue | Possible values |"
$parameterHeaderDivider = "| :-- | :-- | :-- | :-- | :-- |"
$parameterRow = "| ``{0}`` | {1} | {2} | {3} | {4} |"

Write-Verbose "Creating strings for Outputs"

$outputHeader = "| Output Name | Type | Description |"
$outputHeaderDivider = "| :-- | :-- | :-- |"
$outputRow = "| ``{0}`` | {1} | {2} |"

Write-Verbose "Creating Parameters list table"
$StringBuilderParameter = @()
$StringBuilderParameter += $parameterHeader
$StringBuilderParameter += $parameterHeaderDivider

$StringBuilderParameter += $json.parameters | `
    Get-Member -MemberType NoteProperty | `
    ForEach-Object { 
    $parameterRow -f $_.Name,
    $json.parameters.($_.Name).type,
    $json.parameters.($_.Name).metadata.description,
    $json.parameters.($_.Name).defaultValue,
    $json.parameters.($_.Name).allowedValues
}

Write-Verbose "Creating Resource types list table"
$StringBuilderResourceTypes = @()
$StringBuilderResourceTypesOnly = @()
$StringBuilderResourceTypes += $resourceHeader
$StringBuilderResourceTypes += $resourceHeaderDivider
$StringBuilderResourceType += $json.resources
$StringBuilderResourceType += $json.resources.resources
$StringBuilderResourceType += $json.resources.properties.template.resources

$StringBuilderResourceTypesOnly += $StringBuilderResourceType | `
    ForEach-Object {
    $resourceRow -f $_.Type,
    $_.ApiVersion,
    $_.Name,
    $_.Comments 
}
$StringBuilderResourceTypesOnly = $StringBuilderResourceTypesOnly | Sort-object -Unique
foreach ($Resourceobj in $StringBuilderResourceTypesOnly) {
    if ($Resourceobj -like "*[a-zA-Z]*") {
        $StringBuilderResourceTypes += $Resourceobj
    } 
}

Write-Verbose "Creating Outputs list table"
if ($json.outputs -notlike "") {
    $StringBuilderOutput = @()
    $StringBuilderOutput += $outputHeader
    $StringBuilderOutput += $outputHeaderDivider
    $StringBuilderOutput += $json.outputs | `
        Get-Member -MemberType NoteProperty | `
        ForEach-Object { 
        $outputRow -f $_.Name,
        $json.outputs.($_.Name).type,
        $json.outputs.($_.Name).metadata.description,
        $json.outputs.($_.Name).defaultValue
    }  
}
else {
    $StringBuilderOutput = "No Outputs defined."
}

Write-Verbose "Creating Additional resources"
$TemplateReferenceOutputs = @()
Foreach ($rt in ($json.resources)) { 
    $Type, $Resource = $rt.Type -split '/', 2
    $ApiVersion = $rt.ApiVersion
    $TemplateReferenceOutputs += "- [$($Resource.Replace($Resource[0],$Resource[0].ToString().ToUpper()))](https://docs.microsoft.com/en-us/azure/templates/$Type/$ApiVersion/$Resource)" -f $Resource#.Substring(0,1).ToUpper()
}

Write-Verbose "Creating Output"
Write-Output "# Resource`n`n// TODO: Replace Resource and fill in description"
Write-Output "`n## Resource types`n"

$StringBuilderResourceTypes

Write-Output "`n### Resource dependency`n`nThe following resources are required to be able to deploy this resource.`n"
Write-Output "`- *None*"
Write-Output "`n## Parameters`n"

$StringBuilderParameter

Write-Output "`n### Parameter Usage: ``<ParameterPlaceholder>`` `n`n// TODO: Fill in Parameter usage"
Write-Output "`n## Outputs`n"

$StringBuilderOutput

Write-Output "`n## Considerations`n"
Write-Output "`- *None*"
Write-Output "`n## Additional resources`n"
Write-Output "`- [Use tags to organize your Azure resources](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags)"
Write-Output "`- [Azure Resource Manager template reference](https://docs.microsoft.com/en-us/azure/templates/)"

$TemplateReferenceOutputs

Write-Verbose "End"