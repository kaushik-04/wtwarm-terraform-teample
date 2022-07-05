<#
Description: This script is used to enable Advanced Thread Detection, Vulnerability Assessment, Auditing and Azure Active Directory only authentication (if specified) on Azure SQL Servers.
#>

function Set-SecurityCenterConfiguration {
  [cmdletbinding()]
  param(
      [Parameter(Mandatory)]
      [string] $ParametersFilePath
  )
  $Retry = 5
  $RetryInterval = 20

  # Extracting parameter file properties
  $parametersFile = Get-Content -Raw -Path $ParametersFilePath | ConvertFrom-Json
  $resourceGroupName = $parametersFile.parameters.resourceGroupName.value
  $serverName = $parametersFile.parameters.serverName.value
  $storageAccountName = $parametersFile.parameters.storageAccountName.value
  $notificationRecipientsEmails = $parametersFile.parameters.notificationRecipientsEmails.value
  $auditActionGroups = @( "SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP", "FAILED_DATABASE_AUTHENTICATION_GROUP", "BATCH_COMPLETED_GROUP" )
  $azureADOnlyAuth = $parametersFile.parameters.azureADOnlyAuth.value

  # Enable Advanced Threat Protection
  Update-AzSqlServerAdvancedThreatProtectionSetting -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -NotificationRecipientsEmails ($notificationRecipientsEmails -join (";")) `
    -EmailAdmins $False

  # Enable Vulnerability Assessment Scanning 
  Update-AzSqlServerVulnerabilityAssessmentSetting -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -StorageAccountName $storageAccountName `
    -RecurringScansInterval "Weekly" `
    -EmailAdmins $false `
    -NotificationEmail $notificationRecipientsEmails
  
  # Enable SQL Server Auditing
  $roleName = "Storage Blob Data Contributor"
  $st = Get-AzResource -Name $storageAccountName -ResourceType "Microsoft.Storage/storageAccounts"
  $sqlMI = Get-AzADServicePrincipal -DisplayName $serverName
  # Set permissions
  $ExistingRoleAssignment = $null
  Write-Output "    Fetching RBAC role assignment..."
  $ExistingRoleAssignment = Get-AzRoleAssignment -ObjectId $sqlMI.Id -RoleDefinitionName $roleName -Scope $st.ResourceId -ErrorAction SilentlyContinue
  if (-Not $ExistingRoleAssignment) {
    Write-Output "    Creating RBAC role assignment..."
                            
    for ($i = 1; $i -le $Retry; $i++) {
        try {
            Write-Output "        Creating RBAC role assignment - Attempt #$i"
            $NewRoleAssignment = New-AzRoleAssignment -Scope $st.ResourceId -RoleDefinitionName $roleName -ObjectId $sqlMI.Id
        }
        catch {
            if ($i -ne $Retry) {
                $_
                Write-Output "        Creating RBAC role assignment - Attempt #$i - Failed, retry in $RetryInterval seconds"
                Start-Sleep -Seconds $RetryInterval
                continue
            }
            else {
                Write-Output "        Creating RBAC role assignment - Attempt #$i - Failed. Throwing error."
                throw $_
            }
        }
        break
      }

      if ($NewRoleAssignment) {
          $script:noOfRoleAssignmentsCreated++
          Write-Output "        RBAC role assignments created."
      }
  }
  else {
      Write-Output "        This RBAC Role assignment is already configured."
  }
  
  # Set auditing
  Set-AzSqlServerAudit -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -AuditActionGroup $auditActionGroups `
    -BlobStorageTargetState Enabled `
    -RetentionInDays 90 `
    -StorageAccountResourceId $st.ResourceId

  # Enable Azure Active Directory only authentication (if specified)
  $caado = Get-AzSqlServerActiveDirectoryOnlyAuthentication -ResourceGroupName $resourceGroupName `
      -ServerName $serverName
      
  if ($azureADOnlyAuth) {
    if (-Not $caado.AzureADOnlyAuthentication) {
      Enable-AzSqlServerActiveDirectoryOnlyAuthentication -ResourceGroupName $resourceGroupName `
        -ServerName $serverName
    }    
  }
  else {
    if ($caado.AzureADOnlyAuthentication) {
      Disable-AzSqlServerActiveDirectoryOnlyAuthentication -ResourceGroupName $resourceGroupName `
          -ServerName $serverName
    }
  }
}