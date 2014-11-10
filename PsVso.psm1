# PsVso
# Version: $version$
# Changeset: $sha$

$ErrorActionPreference = "Stop"

$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path

"$moduleRoot\functions\*.ps1", "$moduleRoot\cmdlets\*.ps1" |
Resolve-Path |
Where-Object { -not ($_.ProviderPath.Contains(".Tests.")) } |
ForEach-Object { . $_.ProviderPath }




Export-ModuleMember Push-ToVso, Submit-PullRequest, Get-BuildStatus, Get-VsoConfig, Set-VsoConfig, 
                    getUrl, postUrl, getProjects, getRepos, getProjectId, getIdentityId, getRepoId
