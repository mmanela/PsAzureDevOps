# PsVso

$ErrorActionPreference = "Stop"

$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path
if(-not $Global:PsVso) { 
    $Global:PsVso = @{} 
    $PsVso.EnableLogging=$false
    $PsVso.OnPremiseMode=$false
    $PsVso.TimeoutInSeconds=30
}

"$moduleRoot\functions\*.ps1", "$moduleRoot\cmdlets\*.ps1" |
Resolve-Path |
Where-Object { -not ($_.ProviderPath.Contains(".Tests.")) } |
ForEach-Object { . $_.ProviderPath }



Update-FormatData -PrependPath "$moduleRoot\WorkItem.Format.ps1xml"


Export-ModuleMember Push-ToVso, 
                    Submit-PullRequest,
                    Get-BuildStatus, 
                    Get-VsoConfig, 
                    Set-VsoConfig, 
                    Get-MyWorkItems,
                    Query-WorkItems, 
                    Open-WorkItems 
                    #,getUrl, postUrl, getProjects, getRepos, getProjectId, getIdentityId, getRepoId,getWorkItemsFromQuery

Export-ModuleMember -Variable PsVso