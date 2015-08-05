
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
  Closed
  Cut
  Completed

.PARAMETER OrderBy
The field to order by. By default this is System.ChangedDate

.PARAMETER Take
The number of work items to show. Defaults to the 200. Max is 200.

.PARAMETER AssignedToMe
Show work items that are assigned to the current user. 
By default Get-MyWorkItems shows both work items created by you and assigned to you. 
However, if you specify -AssignedToMe and don't specify -CreatedByMe then you
will only see items assigned to you

.PARAMETER CreatedByMe
Show work items that are created by the current user. 
By default Get-MyWorkItems shows both work items created by you and assigned to you. 
However, if you specify -CreatedByMe and don't specify -AssignedToMe then you
will only see items created by you

.PARAMETER IncludeAllStates
By default Get-MyWorkItems trys to filter out "finished" items. This property
prevents this behavior.

.PARAMETER IncludedStates
By default Get-MyWorkItems trys to filter out "finished" items. This property
prevents this behavior and lets you specify just the states you want.

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
        [switch]$AssignedToMe,
        [Parameter(Mandatory = $false)]
        [switch]$CreatedByMe,
        [Parameter(Mandatory = $false)]
        [string]$OrderBy,
        [Parameter(Mandatory = $false)]
        [int]$Take = 200,
        [Parameter(Mandatory = $false)]
        [switch]$IncludeAllStates,
        [Parameter(Mandatory = $false)]
        [string[]]$IncludedStates,
        [Parameter(Mandatory = $false)]
        [string]$Account,
        [Parameter(Mandatory = $false)]
        [string]$Project
    )

    refreshCachedConfig

    $accountName    = getFromValueOrConfig $Account $script:config_accountKey
    $projectName    = getFromValueOrConfig $Project $script:config_projectKey

    $fromDate = (Get-Date).AddDays(-30).ToUniversalTime().Date.ToString("o")


    $identityFilterFields = @()
    # If the user didn't set either filter then assume both are true
    if(-not $CreatedByMe -and -not $AssignedToMe) {
        $CreatedByMe = $true
        $AssignedToMe = $true
    }

    if($CreatedByMe) {
        $identityFilterFields += [System.String]::Format($script:identityFilterQueryPart, "System.CreatedBy")
    }
    if($AssignedToMe) {
        $identityFilterFields += [System.String]::Format($script:identityFilterQueryPart, "System.AssignedTo")
    }

    $identityFilterString = $identityFilterFields -join " OR "

    if(-not $OrderBy) {
        $OrderBy = "System.ChangedDate"
    }

    if($IncludeAllStates) {
        $excludedStates = @()
        $stateFilterPart = ""
    }
    elseif($IncludedStates) {
        $excludedStatesString = ($IncludedStates | ForEach-Object { "`"$_`""}) -join ","
        $stateFilterPart = [System.String]::Format($script:stateIncludeFilterQueryPart, $excludedStatesString)    
    }
    else {
        $excludedStates = @("Done", "Removed", "Closed", "Resolved", "Completed", "Cut")
        $excludedStatesString = ($excludedStates | ForEach-Object { "`"$_`""}) -join ","
        $stateFilterPart = [System.String]::Format($script:stateExcludeFilterQueryPart, $excludedStatesString)         
    }

    $query = [System.String]::Format($script:getMyWorkItemsQuery, $fromDate, $stateFilterPart, $identityFilterString, $OrderBy)

    $workItems = getWorkItemsFromQuery $accountName $projectName $query $Take

    # Transform some properties to make them easily formatted
    $workItems = formatWorkItems $workItems

    return $workItems
}
