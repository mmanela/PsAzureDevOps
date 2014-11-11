function Install-PsVso($here) {


    $ModulePaths = @($env:PSModulePath -split ';')

    $ExpectedUserModulePath = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath WindowsPowerShell\Modules
    $Destination = $ModulePaths | Where-Object { $_ -eq $ExpectedUserModulePath}

    if (-not $Destination) {
        $Destination = $ModulePaths | Select-Object -Index 0
    }

    if (-not (Test-Path $Destination)) {
        New-Item $Destination -ItemType Directory -Force | Out-Null
    } elseif (Test-Path (Join-Path $Destination "PsVso")) {
        Remove-Item (Join-Path $Destination "PsVso") -Recurse -Force
    }

    $PsVsoPath=Join-Path $Destination "PsVso"
    if(!(test-Path $PsVsoPath)){
        mkdir $PsVsoPath
    }

    Copy-Item "$here/*" $PsVsoPath -Recurse -Force -Exclude ChocolateyInstall.ps1, Setup.*

    $successMsg = @"
The PsVso Module has been copied to $PsVsoPath and added to your Module path. 

To find more info visit https://github.com/mmanela/PsVso or use:
PS:>Get-Help PsVso
"@
    Write-Host $successMsg

}
