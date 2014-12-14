# Functions and variables used for the config related operations

$script:configFileName = "PsVso.json"
$script:globalConfigPath = Join-Path ([System.Environment]::ExpandEnvironmentVariables("%userprofile%")) $configFileName


$script:cached_config = @{}
$script:config_projectKey           = "project"
$script:config_accountKey           = "account"
$script:config_repoKey              = "repository"
$script:config_buildDefinitionKey   = "builddefinition"
$script:config_sourceBranch         = "sourceBranch"
$script:config_targetBranch         = "targetBranch"

function refreshCachedConfig() {
    $script:cached_config = Get-VsoConfig
}

# Checks a given value and if it is not empty return it 
# otherwise look up a value from the cached config
function getFromValueOrConfig($value, $keyName, [hashtable] $config) {


    # If passed in value is empty then check the config
    if(-not $value) {
        $value = $script:cached_config[$keyName]
    }

    # If we can't find a value throw
    if(-not $value) {
        throw "The $keyName name must be specified as an argument or in the config"
    }

    return $value
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

        if($content) {
            $jsonObject = ConvertFrom-Json $content
            $jsonObject.psobject.Properties | ForEach-Object { $configHash[$_.Name] = $_.Value }
        }
    }

    return $configHash
}
