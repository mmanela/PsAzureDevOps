
function Submit-PullRequest {
<#
.SYNOPSIS
Submits a pull request to Visual Studio Online

.DESCRIPTION
Calling Submit-PullRequest will create a pull request between the configured branches in your Visual Studio Online project.
If succesfull will launch the pull request in a browser.


.PARAMETER Title
The title of the pull request.

.PARAMETER Description
The description of the pull request.

.PARAMETER SourceBranch
The branch you want to merge from. Can be inherited from a config file.

.PARAMETER TargetBranch
The branch you want to merge to. Can be inherited from a config file.

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
        [Parameter(Mandatory = $false)]
        [string]$SourceBranch,
        [Parameter(Mandatory = $false)]
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

    $accountName         = getFromValueOrConfig $Account $script:config_accountKey
    $projectName         = getFromValueOrConfig $Project $script:config_projectKey
    $repoName            = getFromValueOrConfig $Repository $script:config_repoKey
    $sourceBranchName    = getFromValueOrConfig $SourceBranch $script:config_sourceBranch
    $targetBranchName    = getFromValueOrConfig $TargetBranch $script:config_targetBranch

    $reviewerIds = @()
    if($Reviewers) {
        $reviewerIds = $Reviewers | ForEach-Object { getIdentityId $accountName $_ } | Where-Object { $_ -ne $null }
    }

    $refPrefix = "refs/heads/"
    if(-not $sourceBranchName.ToLower().StartsWith("$refPrefix")) {
        $sourceBranchName = $refPrefix + $sourceBranchName
    }   

    if(-not $targetBranchName.ToLower().StartsWith("$refPrefix")) {
        $targetBranchName = $refPrefix + $targetBranchName
    }

    $payload = @{
        "sourceRefName" = $sourceBranchName
        "targetRefName" = $targetBranchName
        "title"= $Title
        "description" = $Description
        "reviewers" = @($reviewerIds | ForEach-Object { @{ "id" = $_ } })
    }

    $repoId = getRepoId $accountName $projectName $repoName

    
    $url = [System.String]::Format($script:pullRequestUrl, $accountName, $repoId)
    $prResults = postUrl $url $payload

     if($prResults) {
        $webUrl = [System.String]::Format($script:openPullRequestUrl, $accountName, $projectName, $repoName, $prResults.pullRequestId)
        Write-Host "Pull request created at $webUrl"
        Start-Process $webUrl
    }

}
