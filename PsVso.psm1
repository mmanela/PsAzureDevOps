# PsVso

$ErrorActionPreference = "Stop"

$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path

if(!$Global:PsVso) { 
    $Global:PsVso = @{} 
    $PsVso.SuppressLogging=$true
    $PsVso.OnPremiseMode=$false
}

"$moduleRoot\functions\*.ps1", "$moduleRoot\cmdlets\*.ps1" |
Resolve-Path |
Where-Object { -not ($_.ProviderPath.Contains(".Tests.")) } |
ForEach-Object { . $_.ProviderPath }



Update-FormatData -PrependPath "$moduleRoot\WorkItem.Format.ps1xml"


Export-ModuleMember Push-ToVso, Submit-PullRequest, Get-BuildStatus, Get-VsoConfig, Set-VsoConfig, Get-MyWorkItems,
                    Open-WorkItems #,getUrl, postUrl, getProjects, getRepos, getProjectId, getIdentityId, getRepoId,getWorkItemsFromQuery

Export-ModuleMember -Variable PsVso