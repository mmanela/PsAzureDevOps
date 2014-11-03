# PsVso
# Version: $version$
# Changeset: $sha$

$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path

$script:configFileName = "PsVso.json"
$script:globalConfigPath = Join-Path ([System.Environment]::ExpandEnvironmentVariables("%userprofile%")) $configFileName

$script:config_projectKey =  "project"
$script:config_accountKey =  "account"
$script:config_repoKey    =  "repository"


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
If your VSO url is hello.visualstudio.com then this value should be hello.

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
        [string]$Project,
        [Parameter(Mandatory = $false)]
        [string]$Repository
    )

    if( -not $Path ) {
        throw "You cannot specify a null path"
    }

    if( -not testForGit) {
        throw "Could not the git exe in the path"
    }


   $gitFolderPath = $Path

   # If path is not path to .git folder make it one
   if((Split-Path -Leaf $Path).ToLower() -ne ".git") {
        $gitFolderPath = Join-Path $Path ".git"    
   }

   if(-not (Test-Path $gitFolderPath)) {
        throw "Did not find a .git folder at $Path"
   }

   $config = Get-VsoConfig
   
   $projectName = getFromValueOrConfig $Project $config_projectKey $config
   $accountName = getFromValueOrConfig $Account $config_accountKey $config
   $repoName    = getFromValueOrConfig $Repository $config_repoKey $config

   if(-not $projectName){
    throw "The project name must be specified as an argument or in the config"
   }

   if(-not $repoName){
    throw "The account name must be specified as an argument or in the config"
   }

   if(-not $repoName){
    throw "The repository name must be specified as an argument or in the config"
   }

   


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
        throw "You must specify Local or Global"
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


    Write-Host "Wrote to config file at $configPath"

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

# Checks a given value and if it is not empty return it 
# otherwise look up a value from the cached config
function getFromValueOrConfig($value, $keyName, [hashtable] $config) {
    if($value) {
        return $value
    }
    else {
        return $config[$keyName]
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


# Get the local config which is found by probing form the current directory up
function getLocalConfigPath {

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


function testForGit() {

    $hasGit = $false
    
    try {
        git --version | Out-Null
        $hasGit = $true
    } catch {
        $hasGit = $false
        $ErrorCount -= 1
    }

    return $hasGit
}

Export-ModuleMember Push-ToVso, Get-VsoConfig, Set-VsoConfig