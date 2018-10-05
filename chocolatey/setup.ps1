function Install-PsAzureDevOps($here) {


    $ModulePaths = @($env:PSModulePath -split ';')

    $ExpectedUserModulePath = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath WindowsPowerShell\Modules
    $Destination = $ModulePaths | Where-Object { $_ -eq $ExpectedUserModulePath}

    if (-not $Destination) {
        $Destination = $ModulePaths | Select-Object -Index 0
    }

    if (-not (Test-Path $Destination)) {
        New-Item $Destination -ItemType Directory -Force | Out-Null
    } elseif (Test-Path (Join-Path $Destination "PsAzureDevOps")) {
        Remove-Item (Join-Path $Destination "PsAzureDevOps") -Recurse -Force
    }

    $PsAzureDevOpsPath=Join-Path $Destination "PsAzureDevOps"
    if(!(test-Path $PsAzureDevOpsPath)){
        mkdir $PsAzureDevOpsPath
    }

    Copy-Item "$here/*" $PsAzureDevOpsPath -Recurse -Force -Exclude ChocolateyInstall.ps1, Setup.*

    $successMsg = @"
The PsAzureDevOps Module has been copied to $PsAzureDevOpsPath and added to your Module path. 

To find more info visit https://github.com/mmanela/PsAzureDevOps or use:
PS:>Get-Help PsAzureDevOps
"@
    Write-Host $successMsg

}
