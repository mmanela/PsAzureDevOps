$psake.use_exit_on_error = $true
properties {
    $baseDir = (Split-Path -parent $psake.build_script_dir)
    $packageDir = "$baseDir\_build"

    $version="1.0.0"
    $changeset = "0"

<#
    if(Get-Command Git -ErrorAction SilentlyContinue) {
        $versionTag = git describe --abbrev=0 --tags
        $version = $versionTag + "."
        $version += (git log $($version + '..') --pretty=oneline | measure-object).Count
        $changeset=(git log -1 $($versionTag + '..') --pretty=format:%H)
    }
#>

    $nugetExe = "$env:ChocolateyInstall\ChocolateyInstall\nuget"
}


Task default -depends Build
Task Build -depends Test, Package
Task Package -depends Clean-PackageFiles, Version-Module, Pack-Nuget, Unversion-Module
Task Push-Public -depends Push-Chocolatey

Task Test {
    pushd "$baseDir"
    $pesterDir = (dir $env:ChocolateyInstall\lib\Pester*)
    if($pesterDir.length -gt 0) {$pesterDir = $pesterDir[-1]}
    if($testName){
        exec {."$pesterDir\tools\bin\Pester.bat" $baseDir/tests -testName $testName}
    }
    else{
        exec {."$pesterDir\tools\bin\Pester.bat" $baseDir/tests }
    }
    popd
}

Task Version-Module{
    (Get-Content "$baseDir\PsVso.psm1") `
      | % {$_ -replace "\`$version\`$", "$version" } `
      | % {$_ -replace "\`$sha\`$", "$changeset" } `
      | Set-Content "$baseDir\PsVso.psm1"

    (Get-Content "$baseDir\PsVso.psd1") `
      | % {$_ -replace "\`$version\`$", "$version" } `
      | Set-Content "$baseDir\PsVso.psd1"
}

Task Unversion-Module{
    (Get-Content "$baseDir\PsVso.psm1") `
      | % {$_ -replace "$version", "`$version`$" } `
      | % {$_ -replace "$changeset", "`$sha`$" } `
      | Set-Content "$baseDir\PsVso.psm1"


    (Get-Content "$baseDir\PsVso.psd1") `
      | % {$_ -replace "$version", "`$version`$" } `
      | Set-Content "$baseDir\PsVso.psd1"
}

Task Pack-Nuget {
    if (Test-Path $packageDir) {
      Remove-Item $packageDir -Recurse -Force
    }

    mkdir $packageDir
    exec {
      . $nugetExe pack "$baseDir\PsVso.nuspec" -OutputDirectory $packageDir `
      -NoPackageAnalysis -version $version
    }
}

Task Push-Chocolatey -depends Set-Version {
    exec { chocolatey push $packageDir\PsVso.$version.nupkg }
}

Task Clean-PackageFiles {
    clean $packageDir
}



function clean([string[]]$paths) {
    foreach ($path in $paths) {
        remove-item -force -recurse $path -ErrorAction SilentlyContinue
    }
}
