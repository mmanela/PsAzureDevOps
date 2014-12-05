
function Open-WorkItems {
<#
.SYNOPSIS
Opens the given work item ids in your default web browser

.DESCRIPTION
Open-WorkItems will open the web viewer for the given work item ids


.PARAMETER WorkItemIds
One or more work item ids to open in the browser

.PARAMETER WorkItems
One or more work item objects (e.g. returned by Get-MyWorkItems) to open in the browser

.PARAMETER Account
The acount name to use. Can be inherited from a config file.
If your VSO url is hello.visualstudio.com then this value should be hello.


.Example
Open-WorkitemIds 2

Opens work item 2 in a browser. The account is inherited from config.

.Example
Get-WorkItems -WorkItemIds 1,2,3 -Account MyAccount

Open work items 1, 2 and 3 in the MyAccount project.

.Example 
Get-MyWorkItems -Take 2 | Open-WorkItems

Open the two most recently changes work items created by or assigned to you

.LINK
about_PsVso

#>
    [CmdletBinding(DefaultParameterSetName="WorkItemId")]
    param(
        [Parameter(Position=0, ValueFromPipeline=$True, Mandatory = $true, ParameterSetName="WorkItemId")]
        [int[]]$WorkItemIds,
        [Parameter(Position=0, ValueFromPipeline=$True, Mandatory = $true, ParameterSetName="WorkItem")]
        [object[]]$WorkItems,
        [Parameter(Mandatory = $false)]
        [string]$Account
    )

    Begin {
        refreshCachedConfig
    }

    Process {
        
        if($PsCmdlet.ParameterSetName -eq "WorkItem"){
            $WorkItemIds = $WorkItems.Id
        }

        $accountName  = getFromValueOrConfig $Account $script:config_accountKey

        $WorkItemIds | ForEach-Object { openWorkItemInBrowser $accountName $_}
    }
}
