function Get-ADOProject {
    [CmdletBinding()]
    param (
        [switch]
        $ListAvailable
    )

    if ($PSBoundParameters.ContainsKey('ListAvailable')) {
        $TaskDescriptor = "Get All Azure DevOps Projects"
        $cmd = "az devops project list --detect false | ConvertFrom-Json | Select-Object -ExpandProperty value"
        try {
            Write-Verbose $TaskDescriptor
            $List = Invoke-Expression $cmd
            Write-Verbose "$TaskDescriptor - Found $($List.count) project(s)"
            return $List
        } catch {
            Write-Verbose "$TaskDescriptor - Failed"
        }
    } else {
        $CurrentConfig = Get-ADOCurrentConfig

        if ($null -ne $CurrentConfig) {
            $ProjectName = ($CurrentConfig | Where-Object {$_ -like "project*"}).split('=')[-1].trim() # Extracting only the name in a string like 'project = Project name with spaces'.
            Write-Verbose "$TaskDescriptor - Project is '$ProjectName'"
            if ($null -ne $ProjectName) {
                $TaskDescriptor = "Getting info on Azure DevOps Project - '$ProjectName'"
                $cmd = "az devops project show --project '$ProjectName' --detect false | ConvertFrom-Json"
                try {
                    Write-Verbose $TaskDescriptor
                    $ProjectObj = Invoke-Expression $cmd
                    if ($null -ne $ProjectObj) {
                        Write-Verbose "$TaskDescriptor - Found project"
                        return $ProjectObj
                    } else {
                        Write-Verbose "$TaskDescriptor - No project found"
                        return $null
                    }
                } catch {
                    Write-Verbose "$TaskDescriptor - Failed"
                    throw $_
                }
            } else {
                Write-Warning "There is no project set in the client. Try running Set-ADOProject."
                return $null
            }            
        } else {
            Write-Warning "There are no settings on the local client."
            return $null
        }
    }
}