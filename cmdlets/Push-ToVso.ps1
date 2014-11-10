
function Push-ToVso {
<#
.SYNOPSIS
Clones the current git repo to a VSO project.

.DESCRIPTION
Calling Push-ToVso will clone your git repo to a VSO project. If you don't specify a project it will try to use the default one.
If no default project is configure it will error. You must run this command from inside of your git repo folder.

.PARAMETER Repository
The repository name to use. Can be inherited from a config file.

.PARAMETER Account
The acount name to use. Can be inherited from a config file.
If your VSO url is hello.visualstudio.com then this value should be hello.

.PARAMETER Project
The project name to use. Can be inherited from a config file.

.Example
Push-ToVso 

This will look for a git repo in the current directory and try to find an already configured project/account. 
It will then create a repo in that project and push to it. 

.Example
Push-ToVso -Project MyProject -Account MyAccount

Finds a git repo in current directory and adds it to the given account/project

.LINK
about_PsVso

#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Repository,
        [Parameter(Mandatory = $false)]
        [string]$Account,
        [Parameter(Mandatory = $false)]
        [string]$Project
    )

    if( -not (testForGit)) {
        throw "Could not find the git exe in the path"
    }

   refreshCachedConfig
   
   $accountName = getFromValueOrConfig $Account $script:config_accountKey
   $projectName = getFromValueOrConfig $Project $script:config_projectKey
   $repoName    = getFromValueOrConfig $Repository $script:config_repoKey

   # Create this repo online
   $repoResult = createRepo $accountName $projectName $repoName
   $remoteUrl = $repoResult.remoteUrl

   # Figure out if origin is already defined
   # if so we try to use the psvso remote name
   $currentRemotes = git remote
   $remoteName = "origin"
   if($currentRemotes -and $currentRemotes.Contains("origin")) {
    Write-Host "origin remote already exists so create psvso remote"
    $remoteName = "psvso"
   }

    Write-Host "Add remote $remoteName $remoteUrl"
    git remote add $remoteName $remoteUrl

    Write-Host "Pushing repository"
    git push -u $remoteName --all 
}




function testForGit() {

    $hasGit = $false
    
    try {
        git --version | Out-Null
        $hasGit = $true
    } catch {
        $hasGit = $false
        $ErrorCount -= 1
    }

    return $hasGit
}
