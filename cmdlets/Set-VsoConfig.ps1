
function Set-VsoConfig
{
<#
.SYNOPSIS
Sets values in a (local or global) config file.

.DESCRIPTION
Set-VsoConfig lets you set the value for certain properties of 
cmdlets. By setting these in the config file you no longer need to pass them
to the functions. You can set a value in either a local or global config. 
This lets you put local configs file in your projects and store more global 
values like account centrally.

.PARAMETER Name
The name of the property you want to set

.PARAMETER Value
The value to set the property.

.PARAMETER Local
Flag indicates you want to set value in a local config file.
The file will be created in the current directory if it doesn't exist.
This is the default.

.PARAMETER Global
Flag indicates you want to set value in the global config file.

.Example
Set-VsoConfig -Name Project -Value MyProject

Sets the property Project to the value MyProject in the global config

.Example
Set-VsoConfig -Name Project -Value MyProject -Local

Sets the property Project to the value MyProject in a local config

.LINK
about_PsVso

#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Value,
        [Parameter(Mandatory = $false)]
        [switch]
        $Local = $true,
        [Parameter(Mandatory = $false)]
        [switch]
        $Global

    )

    if((-not $Local) -and (-not $Global)) {
        throw "You must specify Local or Global"
    }


    $configObject = @{}
    $configPath = ""

    if($Local -and -not $Global) {
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


    traceMessage "Wrote to config file at $configPath"

}