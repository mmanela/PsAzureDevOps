function Install-PsVsts($here) {


    $ModulePaths = @($env:PSModulePath -split ';')

    $ExpectedUserModulePath = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath WindowsPowerShell\Modules
    $Destination = $ModulePaths | Where-Object { $_ -eq $ExpectedUserModulePath}

    if (-not $Destination) {
        $Destination = $ModulePaths | Select-Object -Index 0
    }

    if (-not (Test-Path $Destination)) {
        New-Item $Destination -ItemType Directory -Force | Out-Null
    } elseif (Test-Path (Join-Path $Destination "PsVsts")) {
        Remove-Item (Join-Path $Destination "PsVsts") -Recurse -Force
    }

    $PsVstsPath=Join-Path $Destination "PsVsts"
    if(!(test-Path $PsVstsPath)){
        mkdir $PsVstsPath
    }

    Copy-Item "$here/*" $PsVstsPath -Recurse -Force -Exclude ChocolateyInstall.ps1, Setup.*

    $successMsg = @"
The PsVsts Module has been copied to $PsVstsPath and added to your Module path. 

To find more info visit https://github.com/mmanela/PsVsts or use:
PS:>Get-Help PsVsts
"@
    Write-Host $successMsg

}
