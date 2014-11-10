# Functions and variables used for communication with VSO


$script:cached_HttpClient = $null
$script:cached_accountProjectMap = @{}

$script:projectsUrl =    "https://{0}.visualstudio.com/defaultcollection/_apis/projects?api-version=1.0"
$script:gitReposUrl =    "https://{0}.visualstudio.com/defaultcollection/{1}/_apis/git/repositories?api-version=1.0"
$script:identityUrl =    "https://{0}.visualstudio.com/defaultcollection/_api/_identity/CheckName?name={1}"
$script:pullRequestUrl = "https://{0}.visualstudio.com/defaultcollection/_apis/git/repositories/{1}/pullRequests?api-version=1.0-preview.1"
$script:buildsUrl =      "https://{0}.visualstudio.com/defaultcollection/{1}/_apis/build/builds?definition={2}&`$top=1&status=Failed,PartiallySucceeded,Succeeded&api-version=1.0"

# Temp overrides to run against a local TFS server
if($false) {
    $script:projectsUrl =    "http://{0}:8080/tfs/defaultcollection/_apis/projects?api-version=1.0"
    $script:gitReposUrl =    "http://{0}:8080/tfs/defaultcollection/{1}/_apis/git/repositories?api-version=1.0"
    $script:identityUrl =    "http://{0}:8080/tfs/defaultcollection/_api/_identity/CheckName?name={1}"
    $script:pullRequestUrl = "http://{0}:8080/tfs/defaultcollection/_apis/git/repositories/{1}/pullRequests?api-version=1.0-preview.1"
    $script:buildsUrl =      "http://{0}:8080/tfs/defaultcollection/{1}/_apis/build/builds?definition={2}&`$top=1&status=Failed,PartiallySucceeded,Succeeded&api-version=1.0"
}



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
