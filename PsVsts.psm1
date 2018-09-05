# PsVsts

$ErrorActionPreference = "Stop"

$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path
if(-not $Global:PsVsts) { 
    $Global:PsVsts = @{} 
    $PsVsts.EnableLogging=$false
    $PsVsts.OnPremiseMode=$false
    $PsVsts.TimeoutInSeconds=30
}

"$moduleRoot\functions\*.ps1", "$moduleRoot\cmdlets\*.ps1" |
Resolve-Path |
Where-Object { -not ($_.ProviderPath.Contains(".Tests.")) } |
ForEach-Object { . $_.ProviderPath }



Update-FormatData -PrependPath "$moduleRoot\formats\*.ps1xml"`


Export-ModuleMember Push-ToVsts, 
                    Submit-PullRequest,
                    Get-Builds,
					Get-BuildCodeCoverage,
					Get-BuildArtifact,
                    Get-VstsConfig, 
                    Set-VstsConfig, 
                    Get-MyWorkItems,
                    Get-WorkItems, 
                    Open-WorkItems 
                    #,getUrl, postUrl, getProjects, getRepos, getProjectId, getIdentityId, getRepoId,getWorkItemsFromQuery

Export-ModuleMember -Variable PsVsts