# PsAzureDevOps

$ErrorActionPreference = "Stop"

$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path
if(-not $Global:PsAzureDevOps) { 
    $Global:PsAzureDevOps = @{} 
    $PsAzureDevOps.EnableLogging=$false
    $PsAzureDevOps.OnPremiseMode=$false
    $PsAzureDevOps.TimeoutInSeconds=30
}

"$moduleRoot\functions\*.ps1", "$moduleRoot\cmdlets\*.ps1" |
Resolve-Path |
Where-Object { -not ($_.ProviderPath.Contains(".Tests.")) } |
ForEach-Object { . $_.ProviderPath }



Update-FormatData -PrependPath "$moduleRoot\formats\*.ps1xml"`


Export-ModuleMember Push-ToAzureDevOps, 
                    Submit-PullRequest,
                    Get-Builds,
					Get-BuildCodeCoverage,
					Get-BuildArtifact,
                    Get-PsAzureDevOpsConfig, 
                    Set-PsAzureDevOpsConfig, 
                    Get-MyWorkItems,
                    Get-WorkItems, 
                    Open-WorkItems 
                    #,getUrl, postUrl, getProjects, getRepos, getProjectId, getIdentityId, getRepoId,getWorkItemsFromQuery

Export-ModuleMember -Variable PsAzureDevOps