
function Get-VsoConfig
{
<#
.SYNOPSIS
Get the values stored in the config files

.DESCRIPTION
Get-VsoConfig gets the values in the active config files. You can choose to see values 
defined in the local config file, global config file, or both.

By default a combined result is shown which shows all config values that are 
currently applied. This is computed by combine the local and global config.


.PARAMETER Local
Flag indicates you want to see the local config values

.PARAMETER Global
Flag indicates you want to see the global config values

.Example
Get-VsoConfig 

Gets all the config values by take the global config and overriding matching properties 
with local config values

.Example
Get-VsoConfig -Global

Gets all the global config values.

.LINK
about_PsVso

#>
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
