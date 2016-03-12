
function Get-WorkItems {
<#
.SYNOPSIS
Gets workitems given a query

.DESCRIPTION
Get-WorkItems by running a query and returning the results

.PARAMETER Query
The query to run

.PARAMETER Take
The number of work items to show. Defaults to the 200. Max is 200.

.PARAMETER Account
The acount name to use. Can be inherited from a config file.
If your VSTS url is hello.visualstudio.com then this value should be hello.

.PARAMETER Project
The project name to use. Can be inherited from a config file.

.Example
Get-WorkItems -Query  "SELECT [System.Id], [System.Title] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.AssignedTo] = 'Joe Smith'"

Gets work items assigned to current user

.Example
Get-WorkItems -Query  "SELECT [System.Id], [System.Title] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.AssignedTo] = 'Joe Smith'" -Take 10


.LINK
about_PsVsts

#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Query,
        [Parameter(Mandatory = $false)]
        [int]$Take = 200,
        [Parameter(Mandatory = $false)]
        [string]$Account,
        [Parameter(Mandatory = $false)]
        [string]$Project
    )

    refreshCachedConfig

    $accountName    = getFromValueOrConfig $Account $script:config_accountKey
    $projectName    = getFromValueOrConfig $Project $script:config_projectKey

   
    $workItems = getWorkItemsFromQuery $accountName $projectName $Query $Take

    # Transform some properties to make them easily formatted
    $workItems = formatWorkItems $workItems

    return $workItems
}
