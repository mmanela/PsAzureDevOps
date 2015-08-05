# Functions and variables used for communication with VSO


$script:cached_HttpClient = $null
$script:cached_accountProjectMap = @{}

$script:projectsUrl =         "https://{0}.visualstudio.com/defaultcollection/_apis/projects?api-version=1.0"
$script:gitReposUrl =         "https://{0}.visualstudio.com/defaultcollection/{1}/_apis/git/repositories?api-version=1.0"
$script:identityUrl =         "https://{0}.visualstudio.com/defaultcollection/_api/_identity/CheckName?name={1}"
$script:pullRequestUrl =      "https://{0}.visualstudio.com/defaultcollection/_apis/git/repositories/{1}/pullRequests?api-version=1.0-preview.1"
$script:openPullRequestUrl =  "https://{0}.visualstudio.com/defaultcollection/{1}/_git/{2}/pullrequest/{3}"
$script:buildDefinitionsUrl = "https://{0}.visualstudio.com/defaultcollection/{1}/_apis/build/definitions?name={2}&type={3}&`$top=1&api-version=2.0"
$script:buildsUrl =           "https://{0}.visualstudio.com/defaultcollection/{1}/_apis/build/builds?definitions={2}&type={3}&`$top=1&resultFilter=Failed,PartiallySucceeded,Succeeded&api-version=2.0"
$script:runQueryUrl =         "https://{0}.visualstudio.com/defaultcollection/{1}/_apis/wit/wiql?api-version=1.0"
$script:getWorkItemsUrl =     "https://{0}.visualstudio.com/defaultcollection/_apis/wit/workitems?ids={1}&fields=System.Id,System.Title,System.WorkItemType,System.AssignedTo,System.CreatedBy,System.ChangedBy,System.CreatedDate,System.ChangedDate,System.State&api-version=1.0"
$script:openWorkItemUrl=      "https://{0}.visualstudio.com/defaultcollection/_workitems/edit/{1}"

# Override urls to run against a local TFS server
if($PsVso.OnPremiseMode) {
    $script:projectsUrl =         "http://{0}:8080/tfs/defaultcollection/_apis/projects?api-version=1.0"
    $script:gitReposUrl =         "http://{0}:8080/tfs/defaultcollection/{1}/_apis/git/repositories?api-version=1.0"
    $script:identityUrl =         "http://{0}:8080/tfs/defaultcollection/_api/_identity/CheckName?name={1}"
    $script:pullRequestUrl =      "http://{0}:8080/tfs/defaultcollection/_apis/git/repositories/{1}/pullRequests?api-version=1.0-preview.1"
    $script:openPullRequestUrl =  "http://{0}:8080/tfs/defaultcollection/{1}/_git/{2}/pullrequest/{3}"
    $script:buildDefinitionsUrl = "http://{0}:8080/tfs/defaultcollection/{1}/_apis/build/definitions?name={2}&type={3}&`$top=1&api-version=2.0"
    $script:buildsUrl =           "http://{0}:8080/tfs/defaultcollection/{1}/_apis/build/builds?definitions={2}&type={3}&`$top=1&resultFilter=Failed,PartiallySucceeded,Succeeded&api-version=2.0"
    $script:runQueryUrl =         "http://{0}:8080/tfs/defaultcollection/{1}/_apis/wit/wiql?api-version=1.0"
    $script:getWorkItemsUrl=      "http://{0}:8080/tfs/defaultcollection/_apis/wit/workitems?ids={1}&fields=System.Id,System.Title,System.WorkItemType,System.AssignedTo,System.CreatedBy,System.ChangedBy,System.CreatedDate,System.ChangedDate,System.State&api-version=1.0"
    $script:openWorkItemUrl=      "http://{0}:8080/tfs/defaultcollection/_workitems/edit/{1}"
}

$script:stateExcludeFilterQueryPart = "AND ([System.State] NOT IN ({0}))"
$script:stateIncludeFilterQueryPart = "AND ([System.State] IN ({0}))"
$script:identityFilterQueryPart = " [{0}] = @me "
$script:getMyWorkItemsQuery  = "SELECT [System.Id]  
                               FROM WorkItems 
                               WHERE ([System.TeamProject] = @project)
                                     AND ([System.ChangedDate] > '{0}')  
                                     {1} 
                                     AND ({2}) 
                               ORDER BY [{3}] DESC,[System.Id] DESC"



function openWorkItemInBrowser($account, $workItemId) {
    $webWorkItemUrl = [System.String]::Format($script:openWorkItemUrl, $account, $workItemId)

    Start-Process $webWorkItemUrl
}

function getWorkItemsFromQuery($account, $project, $query, $take) {

    $queryUrl = [System.String]::Format($script:runQueryUrl, $account, $project)

    $payload = @{
        "query" = $query
    }

    $queryResults = postUrl $queryUrl $payload

    if(-not $queryResults) {
        return $null
    }
    # The ids of the workitems in sorted order
    $resultIds = $queryResults.workItems.id | Select-Object -First $take

    if($resultIds) {
        $wiIds = $resultIds -join ","
        $workItemsUrl = [System.String]::Format($script:getWorkItemsUrl, $account, $wiIds)
        $workItemsResult = getUrl $workItemsUrl
         
        if($workItemsResult) {
            $workItems = $workItemsResult.value

            # We need to sort the results by the query results since
            # work items rest call doesn't honor order
            $workItemMap = @{}
            $workItems | ForEach-Object { $workItemMap[$_.Id] = $_ }

            $sortedWorkItems = $resultIds | ForEach-Object { $workItemMap[$_] }
            return $sortedWorkItems

        }
    }

}

function getBuilds($account, $project, $definition, $type) {
    
    $getBuildDefinitionUrl = [System.String]::Format($script:buildDefinitionsUrl, $account, $project, $definition, $type)
    $definitionResult = getUrl $getBuildDefinitionUrl
    if($definitionResult.value) {
        $getBuildUrl = [System.String]::Format($script:buildsUrl, $account, $project, $definitionResult.value.id, $type)
        $buildResults = getUrl $getBuildUrl

        if($buildResults) {
            return $buildResults.value
        }
    }

    return $null
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
    
    traceMessage "POST $urlStr"

    $payloadString = ConvertTo-Json $payload
    traceMessage "payload: $payloadString"

    $httpClient = getHttpClient
    $response = $httpClient.PostUrl($urlStr, $payloadString)
    
    return processRestReponse $response
}

function getUrl($urlStr) {
    
    Write-Progress -Activity "Making REST Call" -Status "GET $urlStr"
    traceMessage "GET $urlStr"
    

    $httpClient = getHttpClient
    $response = $httpClient.GetUrl($urlStr)
    return processRestReponse $response
}

function processRestReponse($response) {

    $result = $response.Content.ReadAsStringAsync().Result

    try {
        if($result){
            $obj = ConvertFrom-Json $result


            traceMessage "REST RESPONSE: $obj"
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

    $script:cached_HttpClient = new-object VsoRestProxy.VsoProxy("PsVso/1.0")

    return $script:cached_HttpClient
}

