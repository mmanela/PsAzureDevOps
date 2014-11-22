
function Get-MyWorkItems {
<#
.SYNOPSIS
Queries the work items connected to you

.DESCRIPTION
Get-MyWorkItems queries for the open work items that are created by or assigned
to you. By default it will include just items updated in the last 30 days and 
filter out any work items that are in a "finished" state according to the
agile, scrum or cmmi templates. 

Items are considered "finished" if State is any of the following values
  Done
  Removed
  Resolved
  Removed
  Closed
  Cut
  Closed


.PARAMETER OrderBy
The field to order by. By default this is System.ChangedDate

.PARAMETER Take
The number of work items to show. Defaults to the 200. Max is 200.

.PARAMETER IncludeAllStates
By default Get-MyWorkItems trys to filter out "finished" items. This property
prevents this behavior.

.PARAMETER Account
The acount name to use. Can be inherited from a config file.
If your VSO url is hello.visualstudio.com then this value should be hello.

.PARAMETER Project
The project name to use. Can be inherited from a config file.

.Example
Get-MyWorkItems

Gets work items assigned to current user

.Example
Get-WorkItems -Take 10 -OrderBy System.AssignedTo

Gets the first 10 work items assigned to or created by the current user ordered by assignedto name


.LINK
about_PsVso

#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$OrderBy,
        [Parameter(Mandatory = $false)]
        [int]$Take = 200,
        [Parameter(Mandatory = $false)]
        [switch]$IncludeAllStates,
        [Parameter(Mandatory = $false)]
        [string]$Account,
        [Parameter(Mandatory = $false)]
        [string]$Project
    )

    refreshCachedConfig

    $accountName    = getFromValueOrConfig $Account $script:config_accountKey
    $projectName    = getFromValueOrConfig $Project $script:config_projectKey

    $fromDate = (Get-Date).AddDays(-30).ToShortDateString()

    if(-not $OrderBy) {
        $OrderBy = "System.ChangedDate"
    }

    if($IncludeAllStates) {
        $excludedStates = @()
        $stateFilterPart = ""
    }
    else {
        $excludedStates = @("Done", "Removed", "Closed", "Resolved")
        $excludedStatesString = ($excludedStates | ForEach-Object { "`"$_`""}) -join ","
        $stateFilterPart = [System.String]::Format($script:stateFilterQueryPart, $excludedStatesString)         
    }

    $query = [System.String]::Format($script:getMyWorkItemsQuery, $fromDate, $stateFilterPart, $OrderBy)

    $workItems = getWorkItemsFromQuery $accountName $projectName $query $take

    $global:__res = $workItems
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


    # Add type name
    $workItems | ForEach-Object { $_.PSObject.TypeNames.Insert(0,'WorkItem') }

    return $workItems
}
