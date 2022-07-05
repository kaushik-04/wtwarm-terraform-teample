function Set-SasKeysInFile {

	[CmdletBinding(SupportsShouldProcess)]
	param (
		[Parameter()]
		[string] $filePath
	)

	$parameterFileContent = Get-Content -Path $filePath
	$saslines = $parameterFileContent | Where-Object { $_ -like "*<SAS>*" } | ForEach-Object { $_.Trim() } 

	Write-Verbose ("Found [{0}] lines with sas tokens (<SAS>) to replace" -f $saslines.Count)

	foreach ($line in $saslines) {
		Write-Verbose "Evaluate line [$line]" -Verbose
		$null = $line -cmatch "https.*<SAS>"
		$fullPath = $Matches[0].Replace('https://', '').Replace('<SAS>', '')
        $pathElements = $fullPath.Split('/')
        $containerName = $pathElements[1]
        $fileName = $pathElements[2]
        $storageAccountName = $pathElements[0].Replace('.blob.core.windows.net', '')

		$storageAccountResource = Get-AzResource -Name $storageAccountName -ResourceType 'Microsoft.Storage/storageAccounts'

		if(-not $storageAccountResource) {
			throw "Storage account [$storageAccountName] not found"
		}

		$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $storageAccountResource.ResourceGroupName -Name $storageAccountName)[0].Value
		$storageContext = New-AzStorageContext $StorageAccountName -StorageAccountKey $storageAccountKey

		$sasToken = New-AzStorageBlobSASToken -Container $containerName -Blob $fileName -Permission 'r' -StartTime (Get-Date) -ExpiryTime (Get-Date).AddHours(2) -Context $storageContext

		$newString = $line.Replace('<SAS>', $sasToken)

		$parameterFileContent = $parameterFileContent.Replace($line, $newString)
	}
		
	if ($PSCmdlet.ShouldProcess("File in path [$filePath]", "Overwrite")) {
		Set-Content -Path $filePath -Value $parameterFileContent -Force
	}
}