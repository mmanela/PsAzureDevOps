
function Query-WorkItems {
<#
.SYNOPSIS
Queries for work items given WIQL

.DESCRIPTION
Get-MyWorkItems queries for the open work items that are created by or assigned
to you. By default it will include just items updated in the last 30 days and 
filter out any work items that are in a "finished" state according to the
agile, scrum or cmmi templates. 

.PARAMETER Query
The query to run

.PARAMETER Take
The number of work items to show. Defaults to the 200. Max is 200.

.PARAMETER Account
The acount name to use. Can be inherited from a config file.
If your VSO url is hello.visualstudio.com then this value should be hello.

.PARAMETER Project
The project name to use. Can be inherited from a config file.

.Example
Query-WorkItems -Query  "SELECT [System.Id], [System.Title] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.AssignedTo] = 'Joe Smith'"

Gets work items assigned to current user

.Example
Query-WorkItems -Query  "SELECT [System.Id], [System.Title] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.AssignedTo] = 'Joe Smith'" -Take 10


.LINK
about_PsVso

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
    $workItems = $workItems.fields | 
    ForEach-Object { 
            [PSCustomObject]@{
                Id=$_.'System.Id'
                Title=$_.'System.Title'
                WorkItemType=$_.'System.WorkItemType'
                AssignedTo=$_.'System.AssignedTo'
                CreatedBy=$_.'System.CreatedBy'
                CreatedDate=$_.'System.CreatedDate'
                ChangedDate=$_.'System.ChangedDate'
                State=$_.'System.State'
                Fields=$_
            } 
        }


    # Transform some properties to make them easily formatted
    $workItems = formatWorkItems $workItems

    return $workItems
}
