# PsVso
# Version: $version$
# Changeset: $sha$

$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path

$script:configFileName = "PsVso.json"
$script:globalConfigPath = Join-Path ([System.Environment]::ExpandEnvironmentVariables("%userprofile%")) $configFileName

function Push-ToVso {
<#
.SYNOPSIS
Clones the current git repo to a VSO project.

.DESCRIPTION
Calling Push-ToVso will clone your git repo to a VSO project. If you don't specify a project it will try to use the default one.
If no default project is configure it will error.

.PARAMETER Path
The path where Push-ToVso looks for a git repo. The default is the current directory.

.PARAMETER Account
Informs Push-ToVso what acount name to use. Can be inherited from a global config.

.PARAMETER Project
Informs Push-ToVso what project name to use. Can be inherited from a global config.

.Example
Push-ToVso 

This will look for a git repo in the current directory and try to find an already configured project/account. 
It will then create a repo in that project and push to it. 

.Example
Push-ToVso -Project MyProject -Account MyAccount

Finds a git repo in current directory and adds it to the given account/project

.LINK
about_PsVso

#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Path = ".",
        [Parameter(Mandatory = $false)]
        [string]$Account,
        [Parameter(Mandatory = $false)]
        [switch]$Project
    )

   

}

function Set-VsoConfig
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Value,
        [Parameter(Mandatory = $false)]
        [switch]
        $Local,
        [Parameter(Mandatory = $false)]
        [switch]
        $Global = $true

    )

    if((-not $Local) -and (-not $Global)) {
        Write-Error "You must specify Local or Global"
        return
    }


    $configObject = @{}
    $configPath = ""

    if($Local) {
        $configPath = getLocalConfigPath
        if(-not $configPath) {
            $configPath = Join-Path (Get-Location) $configFileName
        }

        $configObject = Get-VsoConfig -Local
    }
    else {
        $configPath = $script:globalConfigPath
        $configObject = Get-VsoConfig -Global
    }

    if(-not (Test-Path $configPath)) {
        Write-Host "Creating config file at $configPath"
    }

    $configObject[$Name] = $Value

    $configJson = ConvertTo-Json $configObject
    Set-Content -Path $configPath -Value $configJson

}

function Get-VsoConfig
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]
        $Local,
        [Parameter(Mandatory = $false)]
        [switch]
        $Global   
    )


    # Gets the global config from the known location
    $globalConfig = readConfigFile $script:globalConfigPath

    # Get the local config path
    $localConfigPath = getLocalConfigPath
    $localConfig = readConfigFile $localConfigPath


    if($Local -and -not $Global) {
        return $localConfig
    }
    elseif($Global -and -not $Local) {
        return $globalConfig
    }
    else {
        return mergeHashTables $globalConfig $localConfig
    }
}


function mergeHashTables ([hashtable] $first, [hashtable] $second) {

    $result = @{}

    # Apply the first hash table
    $first.GetEnumerator() | ForEach-Object { $result[$_.Name] = $_.Value }

    # Apply the second hash table possibly overwriting values
    $second.GetEnumerator() | ForEach-Object { $result[$_.Name] = $_.Value }

    # union both sets
    return $result;
}

function getLocalConfigPath {

    # Get the local config which is found by probing form the current directory up

    $directory = Get-Location
    $localConfigPath = Join-Path $directory $configFileName
    while ($localConfigPath -and -not (Test-Path $localConfigPath)) {
       
       $directory = Split-Path -Parent $directory

        if($directory) {
            $localConfigPath = Join-Path $directory $configFileName 
        }
        else {
            $localConfigPath = $null
        }
    }

    return $localConfigPath
}

function readConfigFile($filePath) {
    $configHash = @{}
    if($filePath -and (Test-Path $filePath)) {
        $content = Get-Content $filePath -Raw
        $jsonObject = ConvertFrom-Json $content
        $jsonObject.psobject.Properties | ForEach-Object { $configHash[$_.Name] = $_.Value }
    }

    return $configHash
}




Export-ModuleMember Push-ToVso, Get-VsoConfig, Set-VsoConfig