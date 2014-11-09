# PsVso
# Version: $version$
# Changeset: $sha$

$ErrorActionPreference = "Stop"

$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path

$script:configFileName = "PsVso.json"
$script:globalConfigPath = Join-Path ([System.Environment]::ExpandEnvironmentVariables("%userprofile%")) $configFileName

$script:config_projectKey           = "project"
$script:config_accountKey           = "account"
$script:config_repoKey              = "repository"
$script:config_buildDefinitionKey   = "builddefinition"

$script:cached_config = @{}
$script:cached_HttpClient = $null
$script:cached_accountProjectMap = @{}

$script:projectsUrl =    "https://{0}.visualstudio.com/defaultcollection/_apis/projects?api-version=1.0"
$script:gitReposUrl =    "https://{0}.visualstudio.com/defaultcollection/{1}/_apis/git/repositories?api-version=1.0"
$script:identityUrl =    "https://{0}.visualstudio.com/defaultcollection/_api/_identity/CheckName?name={1}"
$script:pullRequestUrl = "https://{0}.visualstudio.com/defaultcollection/_apis/git/repositories/{1}/pullRequests?api-version=1.0-preview.1"
$script:buildsUrl =      "https://{0}.visualstudio.com/defaultcollection/{1}/_apis/build/builds?definition={2}&`$top=1&api-version=1.0"

# Temp overrides to run against a local TFS server
if($false) {
    $script:projectsUrl =    "http://{0}:8080/tfs/defaultcollection/_apis/projects?api-version=1.0"
    $script:gitReposUrl =    "http://{0}:8080/tfs/defaultcollection/{1}/_apis/git/repositories?api-version=1.0"
    $script:identityUrl =    "http://{0}:8080/tfs/defaultcollection/_api/_identity/CheckName?name={1}"
    $script:pullRequestUrl = "http://{0}:8080/tfs/defaultcollection/_apis/git/repositories/{1}/pullRequests?api-version=1.0-preview.1"
    $script:buildsUrl =      "http://{0}:8080/tfs/defaultcollection/{1}/_apis/build/builds?definition={2}&`$top=1&api-version=1.0"
}



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


function Submit-PullRequest {
<#
.SYNOPSIS
Submits a pull request to Visual Studio Online

.DESCRIPTION
Calling Submit-PullRequest will create a pull request between the configured branches in your Visual Studio Online project.


.PARAMETER Title
The title of the pull request.

.PARAMETER Description
The description of the pull request.

.PARAMETER SourceBranch
The branch you want to merge from.

.PARAMETER TargetBranch
The branch you want to merge to.

.PARAMETER Reviewers
The list of people to add to the PR. This should be their display name or email address.

.PARAMETER Repository
The repository name to use. Can be inherited from a config file.

.PARAMETER Account
The acount name to use. Can be inherited from a config file.
If your VSO url is hello.visualstudio.com then this value should be hello.

.PARAMETER Project
The project name to use. Can be inherited from a config file.

.Example
Submit-PullRequest -Title "This is good"  -Reviewers "Matthew Manela", "john@gmail.com"  -Repository someRepo -SourceBranch someBranch -TargetBranch master -Account myAccount -Project myProject

.LINK
about_PsVso

#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        [Parameter(Mandatory = $false)]
        [string]$Description,
        [Parameter(Mandatory = $true)]
        [string]$SourceBranch,
        [Parameter(Mandatory = $true)]
        [string]$TargetBranch,
        [Parameter(Mandatory = $false)]
        [string[]]$Reviewers,
        [Parameter(Mandatory = $false)]
        [string]$Repository,
        [Parameter(Mandatory = $false)]
        [string]$Account,
        [Parameter(Mandatory = $false)]
        [string]$Project
    )

    refreshCachedConfig

    $accountName = getFromValueOrConfig $Account $script:config_accountKey
    $projectName = getFromValueOrConfig $Project $script:config_projectKey
    $repoName    = getFromValueOrConfig $Repository $script:config_repoKey

    $reviewerIds = @()
    if($Reviewers) {
        $reviewerIds = $Reviewers | ForEach-Object { getIdentityId $accountName $_ } | Where-Object { $_ -ne $null }
    }

    $refPrefix = "refs/heads/"
    if(-not $SourceBranch.ToLower().StartsWith("$refPrefix")) {
        $SourceBranch = $refPrefix + $SourceBranch
    }   

    if(-not $TargetBranch.ToLower().StartsWith("$refPrefix")) {
        $TargetBranch = $refPrefix + $TargetBranch
    }

    $payload = @{
        "sourceRefName" = $SourceBranch
        "targetRefName" = $TargetBranch
        "title"= $Title
        "description" = $Description
        "reviewers" = $reviewerIds | ForEach-Object { @{ "id" = $_ } }
    }

    $repoId = getRepoId $accountName $projectName $repoName


    $url = [System.String]::Format($script:pullRequestUrl, $accountName, $repoId)
    $repoResults = postUrl $url $payload

    if($repoResults) {
         Write-Host "Pull request created at $($repoResults.url)"
    }

}


function Get-BuildStatus {
<#
.SYNOPSIS
Gets the current status of the build

.DESCRIPTION
Get-BuildStatus will query your VSO project to see the status of the last build. This is usefull to make sure you don't push 
changes when the build is not green

.PARAMETER BuildDefinition
The name of the build definition.  Can be inherited from a config file.

.PARAMETER Account
The acount name to use. Can be inherited from a config file.
If your VSO url is hello.visualstudio.com then this value should be hello.

.PARAMETER Project
The project name to use. Can be inherited from a config file.

.Example
Get-BuildStatus -BuildDefinition myBuildDef -Account myAccount -Project myProject

.LINK
about_PsVso

#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$BuildDefinition,
        [Parameter(Mandatory = $false)]
        [string]$Account,
        [Parameter(Mandatory = $false)]
        [string]$Project
    )

    refreshCachedConfig

    $definitionName = getFromValueOrConfig $BuildDefinition $script:config_buildDefinitionKey
    $accountName    = getFromValueOrConfig $Account $script:config_accountKey
    $projectName    = getFromValueOrConfig $Project $script:config_projectKey

    $buildResults = getBuilds $accountName $projectName $definitionName

    if($buildResults) {
        if($buildResults[0].status -eq "succeeded") {
            Write-Host "Build $($buildResults[0].buildNumber) SUCCEEDED" -ForegroundColor Green
        }
        elseif($buildResults[0].status -eq "failed") {
            Write-Host "Build $($buildResults[0].buildNumber) FAILED" -ForegroundColor Red
        }
        else {
            Write-Host "Build $($buildResults[0].buildNumber) $($buildResults[0].status.ToUpper())"
        }
        
    }
    else {
        Write-Warning "Unable to find build for $definitionName"
    }

}


function Set-VsoConfig
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Value,
        [Parameter(Mandatory = $false)]
        [switch]
        $Local,
        [Parameter(Mandatory = $false)]
        [switch]
        $Global = $true

    )

    if((-not $Local) -and (-not $Global)) {
        throw "You must specify Local or Global"
    }


    $configObject = @{}
    $configPath = ""

    if($Local) {
        $configPath = getLocalConfigPath
        if(-not $configPath) {
            $configPath = Join-Path (Get-Location) $configFileName
        }

        $configObject = Get-VsoConfig -Local
    }
    else {
        $configPath = $script:globalConfigPath
        $configObject = Get-VsoConfig -Global
    }

    if(-not (Test-Path $configPath)) {
        Write-Host "Creating config file at $configPath"
    }

    $configObject[$Name] = $Value

    $configJson = ConvertTo-Json $configObject
    Set-Content -Path $configPath -Value $configJson


    Write-Host "Wrote to config file at $configPath"

}

function Get-VsoConfig
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]
        $Local,
        [Parameter(Mandatory = $false)]
        [switch]
        $Global   
    )


    # Gets the global config from the known location
    $globalConfig = readConfigFile $script:globalConfigPath

    # Get the local config path
    $localConfigPath = getLocalConfigPath
    $localConfig = readConfigFile $localConfigPath


    if($Local -and -not $Global) {
        return $localConfig
    }
    elseif($Global -and -not $Local) {
        return $globalConfig
    }
    else {
        return mergeHashTables $globalConfig $localConfig
    }
}


function refreshCachedConfig() {
    $script:cached_config = Get-VsoConfig
}

# Checks a given value and if it is not empty return it 
# otherwise look up a value from the cached config
function getFromValueOrConfig($value, $keyName, [hashtable] $config) {


    # If passed in value is empty then check the config
    if(-not $value) {
        $value = $script:cached_config[$keyName]
    }

    # If we can't find a value throw
    if(-not $value) {
        throw "The $keyName name must be specified as an argument or in the config"
    }

    return $value
}


function mergeHashTables ([hashtable] $first, [hashtable] $second) {

    $result = @{}

    # Apply the first hash table
    $first.GetEnumerator() | ForEach-Object { $result[$_.Name] = $_.Value }

    # Apply the second hash table possibly overwriting values
    $second.GetEnumerator() | ForEach-Object { $result[$_.Name] = $_.Value }

    # union both sets
    return $result;
}


# Get the local config which is found by probing form the current directory up
function getLocalConfigPath {

    $directory = Get-Location
    $localConfigPath = Join-Path $directory $configFileName
    while ($localConfigPath -and -not (Test-Path $localConfigPath)) {
       
       $directory = Split-Path -Parent $directory

        if($directory) {
            $localConfigPath = Join-Path $directory $configFileName 
        }
        else {
            $localConfigPath = $null
        }
    }

    return $localConfigPath
}

function readConfigFile($filePath) {
    $configHash = @{}
    if($filePath -and (Test-Path $filePath)) {
        $content = Get-Content $filePath -Raw
        $jsonObject = ConvertFrom-Json $content
        $jsonObject.psobject.Properties | ForEach-Object { $configHash[$_.Name] = $_.Value }
    }

    return $configHash
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


# Http Helpers

function getBuilds($account, $project, $definition) {
    
    $url = [System.String]::Format($script:buildsUrl, $account, $project, $definition)
    $buildResults = getUrl $url


    if($buildResults) {
        return $buildResults.value
    }
    else {
        return $null
    }
}

function createRepo($account, $project, $repo) {
   $projectId = getProjectId $account $project
   $payload = @{
    "name" = $repoName
    "project" = @{ "id" = $projectId }
   }

    $url = [System.String]::Format($script:gitReposUrl, $account, $project)
    $repoResults = postUrl $url $payload

    if($repoResults) {
        return $repoResults
    }
}


function getRepos($account, $project) {

    $url = [System.String]::Format($script:gitReposUrl, $account, $project)
    $repoResults = getUrl $url

    if($repoResults) {
        return $repoResults.value
    }
    else {
        return $null
    }
}

function getRepoId($account, $project, $repository) {
    
    $repos = getRepos $account $project
    $repos = @($repos | Where-Object { $_.name -eq $repository })

    if($repos.Count -le 0){
        throw "Unable to find repository id for a repository named $repository"
    }

    return $repos[0].id
}


function getProjectId($account, $project) {
    
    # Check in the cache first for this account/project
    $projectId = getProjectIdFromCache $account $project

    # Check if a cache miss call the service and try again
    if(-not $projectId) {
        buildProjectMap $account
        $projectId = getProjectIdFromCache $account $project
    }

    if(-not $projectId) {
        throw "Unable to find the project $project in account $account"
    }

    return $projectId
}

function getProjectIdFromCache($account, $project) {
    
    # Check in the cache first for this account/project
    $projectId = $null
    $projectIdMap = $script:cached_accountProjectMap[$account]
    if($projectIdMap) {
        $projectId = $projectIdMap[$project]
    }

    return $projectId
}


function getProjects($account) {

    $url = [System.String]::Format($script:projectsUrl, $account)
    $projectResults = getUrl $url

    if($projectResults) {
        return $projectResults.value
    }
    else {
        return $null
    }
}

function getIdentityId($account, $name) {

    $url = [System.String]::Format($script:identityUrl, $account, $name)
    
    try {
        $identityResult = getUrl $url
    } catch {

    }

    if($identityResult -and $identityResult.Identity.TeamFoundationId) {
        return $identityResult.Identity.TeamFoundationId
    }
    else {
        Write-Warning "Unable to resolve the name $name"
        return $null
    }
}

function buildProjectMap($account) {
    
    $projectResults = getProjects $account

    if($projectResults) {
        $projectIdMap = @{}

        $projectResults | ForEach-Object { $projectIdMap[$_.name] = $_.id }

        $script:cached_accountProjectMap[$account] = $projectIdMap    
    }
    else {
        Write-Error "Unable to get projects for $account"
    }
}

function postUrl($urlStr, $payload) {
    
    Write-Progress -Activity "Making REST Call" -Status "POST $urlStr"
    
    Write-Host "POST $urlStr"

    $payloadString = ConvertTo-Json $payload
    Write-Host "payload: $payloadString"

    $content = New-Object System.Net.Http.StringContent($payloadString, [System.Text.Encoding]::UTF8, "application/json")

    $httpClient = getHttpClient
    $url = New-Object System.Uri($urlStr)
    $response = $httpClient.PostAsync($urlStr, $content).Result
    
    return processRestReponse $response
}

function getUrl($urlStr) {
    
    Write-Progress -Activity "Making REST Call" -Status "GET $urlStr"
    Write-Host "GET $urlStr"
    

    $httpClient = getHttpClient
    $url = New-Object System.Uri($urlStr)
    $response = $httpClient.GetAsync($urlStr).Result
    return processRestReponse $response
}

function processRestReponse($response) {
    $result = $response.Content.ReadAsStringAsync().Result

    try {
        if($result){
            $obj = ConvertFrom-Json $result
        }
    }
    catch {

    }

    if($response.IsSuccessStatusCode) {
        return $obj
    }
    else {
        # TODO: Handle errors from the server
        throw "Recieved an error code of $($response.StatusCode) from the server"
    } 
}


function getHttpClient() {

    if($script:cached_HttpClient){
        return $script:cached_HttpClient;
    }

    $credentials = New-Object Microsoft.VisualStudio.Services.Client.VssClientCredentials
    $credentials.Storage = New-Object Microsoft.VisualStudio.Services.Client.VssClientCredentialStorage("VssApp", "VisualStudio")
    $requestSettings = New-Object Microsoft.VisualStudio.Services.Common.VssHttpRequestSettings
    $messageHandler = New-Object Microsoft.VisualStudio.Services.Common.VssHttpMessageHandler($credentials, $requestSettings)
    $httpClient = New-Object System.Net.Http.HttpClient($messageHandler)
    $httpClient.Timeout = [System.TimeSpan]::FromMinutes(30)
    $httpClient.DefaultRequestHeaders.Add("User-Agent", "PsVso/1.0");
    
    $script:cached_HttpClient = $httpClient

    return $httpClient
}



Export-ModuleMember Push-ToVso, Submit-PullRequest, Get-BuildStatus, Get-VsoConfig, Set-VsoConfig, getUrl, postUrl, getProjects, getRepos, getProjectId, getIdentityId, getRepoId