
function Get-BuildArtifact {
<#
.SYNOPSIS
Gets latest build artifact by name

.DESCRIPTION
Get-BuildArtifact will query your AzureDevOps project to get the recent build's artifact by name

.PARAMETER BuildDefinition
The name of the build definition.  Can be inherited from a config file.

.PARAMETER Account
The acount name to use. Can be inherited from a config file.
If your AzureDevOps url is hello.visualstudio.com then this value should be hello.

.PARAMETER Project
The project name to use. Can be inherited from a config file.

.PARAMETER Artifact
The artifact name to get artifact for.

.Example
Get-Artifact -BuildDefinition myBuildDef -Account myAccount -Project myProject -Artifact myArtifactName

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
        [string]$Artifact,
        [Parameter(Mandatory = $false)]
        [ValidateSet('build','xaml')]
        [string]$Type = "build"
    )

    refreshCachedConfig

    $definitionName = getFromValueOrConfig $BuildDefinition $script:config_buildDefinitionKey
    $accountName    = getFromValueOrConfig $Account $script:config_accountKey
    $projectName    = getFromValueOrConfig $Project $script:config_projectKey

    $buildArtifactResults = getBuildArtifact $accountName $projectName $definitionName $Artifact $Type

    $buildArtifactResults = formatArtifact $buildArtifactResults $Artifact

    return $buildArtifactResults
}
