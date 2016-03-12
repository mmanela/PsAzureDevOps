
function Get-Builds {
<#
.SYNOPSIS
Gets builds

.DESCRIPTION
Get-Builds will query your VSO project to get the recent builds

.PARAMETER BuildDefinition
The name of the build definition.  Can be inherited from a config file.

.PARAMETER Take
The number of builds to show. Defaults to the 5.

.PARAMETER Account
The acount name to use. Can be inherited from a config file.
If your VSO url is hello.visualstudio.com then this value should be hello.

.PARAMETER Project
The project name to use. Can be inherited from a config file.

.Example
Get-Builds -BuildDefinition myBuildDef -Account myAccount -Project myProject

.LINK
about_PsVso

#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$BuildDefinition,
        [Parameter(Mandatory = $false)]
        [int]$Take = 5,
        [Parameter(Mandatory = $false)]
        [string]$Account,
        [Parameter(Mandatory = $false)]
        [string]$Project,
        [Parameter(Mandatory = $false)]
        [ValidateSet('build','xaml')]
        [string]$Type = "build"
    )

    refreshCachedConfig

    $definitionName = getFromValueOrConfig $BuildDefinition $script:config_buildDefinitionKey
    $accountName    = getFromValueOrConfig $Account $script:config_accountKey
    $projectName    = getFromValueOrConfig $Project $script:config_projectKey

    $buildResults = getBuilds $accountName $projectName $definitionName $Type $Take

    $buildResults = formatBuilds $buildResults

    return $buildResults

}
