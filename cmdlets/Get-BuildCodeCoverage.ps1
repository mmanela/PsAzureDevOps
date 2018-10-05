
function Get-BuildCodeCoverage {
<#
.SYNOPSIS
Gets latest build code coverage

.DESCRIPTION
Get-BuildCodeCoverage will query your AzureDevOps project to get the recent build's code coverage results

.PARAMETER BuildDefinition
The name of the build definition.  Can be inherited from a config file.

.PARAMETER Account
The acount name to use. Can be inherited from a config file.
If your AzureDevOps url is hello.visualstudio.com then this value should be hello.

.PARAMETER Project
The project name to use. Can be inherited from a config file.

.Example
Get-Builds -BuildDefinition myBuildDef -Account myAccount -Project myProject

.LINK
about_PsAzureDevOps

#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$BuildDefinition,
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

    $codeCoverageResults = getBuildCodeCoverage $accountName $projectName $definitionName $Type

    $codeCoverageResults = formatCoverage $codeCoverageResults

    return $codeCoverageResults

}
