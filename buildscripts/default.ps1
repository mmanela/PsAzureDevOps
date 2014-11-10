$psake.use_exit_on_error = $true
properties {
    $baseDir = (Split-Path -parent $psake.build_script_dir)

    $filesDir = "$baseDir\_build"
    $packageDir = "$baseDir\_package"

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
Task Package -depends Clean-PackageFiles, Version-Module, Pack-Zip, Pack-Nuget, Unversion-Module
Task Push-Public -depends Push-Chocolatey



task Pack-Zip {
    
    create $filesDir, $packageDir
    copy-item "$baseDir\LICENSE.txt" -destination $filesDir
    copy-item "$baseDir\PsVso.psm1" -destination $filesDir
    copy-item "$baseDir\PsVso.psd1" -destination $filesDir
    roboexec {robocopy "$baseDir\lib" "$filesDir\lib" /S }
    roboexec {robocopy "$baseDir\functions" "$filesDir\functions" /S }
    roboexec {robocopy "$baseDir\cmdlets" "$filesDir\cmdlets" /S }
    roboexec {robocopy "$baseDir\en-US" "$filesDir\en-US" /S }
    

    pushd $filesDir
    ."$env:chocolateyInstall\bin\7za.bat" a -tzip "$packageDir\PsVso.zip" *
    popd
}


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

Task Version-Module {
    (Get-Content "$baseDir\PsVso.psm1") `
      | % {$_ -replace "\`$version\`$", "$version" } `
      | % {$_ -replace "\`$sha\`$", "$changeset" } `
      | Set-Content "$baseDir\PsVso.psm1"

    (Get-Content "$baseDir\PsVso.psd1") `
      | % {$_ -replace "\`$version\`$", "$version" } `
      | Set-Content "$baseDir\PsVso.psd1"
}

Task Unversion-Module {
    (Get-Content "$baseDir\PsVso.psm1") `
      | % {$_ -replace "$version", "`$version`$" } `
      | % {$_ -replace "$changeset", "`$sha`$" } `
      | Set-Content "$baseDir\PsVso.psm1"


    (Get-Content "$baseDir\PsVso.psd1") `
      | % {$_ -replace "$version", "`$version`$" } `
      | Set-Content "$baseDir\PsVso.psd1"
}

Task Pack-Nuget {
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
    clean $filesDir
}


function create([string[]]$paths) {
  foreach ($path in $paths) {
    if(-not (Test-Path $path)) {
      new-item -path $path -type directory | out-null
    }
  }
}

function clean([string[]]$paths) {
    foreach ($path in $paths) {
        remove-item -force -recurse $path -ErrorAction SilentlyContinue
    }
}


function roboexec([scriptblock]$cmd) {
    & $cmd | out-null
    if ($lastexitcode -eq 0) { throw "No files were copied for command: " + $cmd }
}
